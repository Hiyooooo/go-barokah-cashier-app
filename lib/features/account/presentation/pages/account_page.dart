import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/user_profile.dart';
import '../providers/user_profile_provider.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _fillForm(UserProfile profile) {
    if (_editing) return;
    _nameController.text = profile.name;
    _phoneController.text = profile.phoneNumber ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(profileUpdateProvider.notifier)
          .saveProfile(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile berhasil diperbarui.')),
      );
    } catch (_) {
      // Keep the form open so the cashier can correct and retry.
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text(
          'Anda perlu login kembali untuk menggunakan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(auth.error!, fallback: 'Logout belum berhasil.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final update = ref.watch(profileUpdateProvider);
    final auth = ref.watch(authProvider);
    final isUpdating = update.isLoading;
    final isLoggingOut = auth.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: profile.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(
            error,
            fallback: 'Profile belum dapat dimuat.',
          ),
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (value) {
          _fillForm(value);
          return _AccountContent(
            profile: value,
            editing: _editing,
            formKey: _formKey,
            nameController: _nameController,
            phoneController: _phoneController,
            update: update,
            isUpdating: isUpdating,
            isLoggingOut: isLoggingOut,
            onEdit: () => setState(() => _editing = true),
            onCancel: () => setState(() => _editing = false),
            onSave: _save,
            onLogout: _logout,
          );
        },
      ),
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent({
    required this.profile,
    required this.editing,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.update,
    required this.isUpdating,
    required this.isLoggingOut,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.onLogout,
  });

  final UserProfile profile;
  final bool editing;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final AsyncValue<void> update;
  final bool isUpdating;
  final bool isLoggingOut;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xxl,
      AppSpacing.lg,
      AppSpacing.xxxl,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;
            final identity = _IdentityPanel(profile: profile);
            final details = _ProfilePanel(
              profile: profile,
              editing: editing,
              formKey: formKey,
              nameController: nameController,
              phoneController: phoneController,
              update: update,
              isUpdating: isUpdating,
              isLoggingOut: isLoggingOut,
              onEdit: onEdit,
              onCancel: onCancel,
              onSave: onSave,
              onLogout: onLogout,
            );
            return isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 280, child: identity),
                      const SizedBox(width: AppSpacing.xxl),
                      Expanded(child: details),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: AppSpacing.lg),
                      details,
                    ],
                  );
          },
        ),
      ),
    ),
  );
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.cream,
            child: Text(
              _initials(profile.name),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.forestGreen),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _RoleBadge(role: profile.role),
          const SizedBox(height: AppSpacing.xl),
          _VerificationStatus(label: 'Email', verified: profile.emailVerified),
          _VerificationStatus(
            label: 'Nomor telepon',
            verified: profile.phoneNumberVerified,
          ),
        ],
      ),
    ),
  );
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.profile,
    required this.editing,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.update,
    required this.isUpdating,
    required this.isLoggingOut,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.onLogout,
  });

  final UserProfile profile;
  final bool editing;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final AsyncValue<void> update;
  final bool isUpdating;
  final bool isLoggingOut;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informasi profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (editing)
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Nama minimal 3 karakter.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nomor telepon',
                      hintText: 'Opsional',
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isNotEmpty &&
                          !RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(phone)) {
                        return 'Masukkan nomor telepon yang valid.';
                      }
                      return null;
                    },
                  ),
                  if (update.hasError) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileError(error: update.error!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: isUpdating ? null : onSave,
                    child: Text(
                      isUpdating ? 'Menyimpan...' : 'Simpan perubahan',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: isUpdating ? null : onCancel,
                    child: const Text('Batal'),
                  ),
                ],
              ),
            )
          else ...[
            _InfoRow(label: 'Nama', value: profile.name),
            _InfoRow(label: 'Email', value: profile.email),
            _InfoRow(label: 'Role', value: profile.role),
            _InfoRow(label: 'Nomor telepon', value: profile.phoneNumber ?? '-'),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: isLoggingOut || isUpdating ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(isLoggingOut ? 'Keluar...' : 'Keluar dari aplikasi'),
          ),
        ],
      ),
    ),
  );
}

class _VerificationStatus extends StatelessWidget {
  const _VerificationStatus({required this.label, required this.verified});

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.forestGreen : AppColors.warmBrown;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            verified ? Icons.verified_outlined : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$label: ${verified ? 'Terverifikasi' : 'Belum terverifikasi'}',
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Text(
      role.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.warmBrown,
        letterSpacing: .6,
      ),
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => _StatusMessage(
    icon: Icons.error_outline,
    color: Theme.of(context).colorScheme.error,
    message: userFacingError(
      error,
      fallback: 'Profile belum dapat diperbarui.',
    ),
  );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
