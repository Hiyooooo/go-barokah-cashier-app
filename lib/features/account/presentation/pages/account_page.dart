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
  bool _editing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _fillForm(UserProfile profile) {
    if (_editing) return;
    _nameController.text = profile.name;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(profileUpdateProvider.notifier)
          .saveProfile(
            name: _nameController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (_) {
      // Keep the form open so the cashier can correct and retry.
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun kasir?'),
        content: const Text(
          'Sesi kasir akan diakhiri. Anda perlu login kembali untuk mengakses transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Keluar'),
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
        constraints: const BoxConstraints(maxWidth: 880),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;
            final identity = _IdentityPanel(
              profile: profile,
              isLoggingOut: isLoggingOut,
              isUpdating: isUpdating,
              onLogout: onLogout,
            );
            final details = _ProfilePanel(
              profile: profile,
              editing: editing,
              formKey: formKey,
              nameController: nameController,
              update: update,
              isUpdating: isUpdating,
              onEdit: onEdit,
              onCancel: onCancel,
              onSave: onSave,
            );
            return isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: identity),
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

class _IdentityPanel extends ConsumerWidget {
  const _IdentityPanel({
    required this.profile,
    required this.isLoggingOut,
    required this.isUpdating,
    required this.onLogout,
  });

  final UserProfile profile;
  final bool isLoggingOut;
  final bool isUpdating;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.cream,
                child: Text(
                  _initials(profile.name),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _RoleBadge(role: profile.role),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Status Akun',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _VerificationStatus(label: 'Email', verified: profile.emailVerified),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Informasi Aplikasi',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SystemInfoRow(label: 'Aplikasi', value: 'Go-Barokah POS Kasir'),
          _SystemInfoRow(label: 'Versi', value: '1.0.0 (Release)'),
          _SystemInfoRow(label: 'Status Sesi', value: 'Aktif Terhubung'),
          const SizedBox(height: AppSpacing.xl),
          // Tombol Logout Bergaya Aksi Destruktif yang Tegas
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: isLoggingOut || isUpdating ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(Icons.logout, color: AppColors.error),
            label: Text(
              isLoggingOut ? 'Mengakhiri sesi...' : 'Keluar dari Akun Kasir',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
    required this.update,
    required this.isUpdating,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final UserProfile profile;
  final bool editing;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final AsyncValue<void> update;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text(
                'Data Profil Kasir',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!editing)
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Ubah profil'),
                ),
            ],
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
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Nama minimal 3 karakter.'
                        : null,
                  ),
                  if (update.hasError) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileError(error: update.error!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isUpdating ? null : onCancel,
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: isUpdating ? null : onSave,
                          child: Text(
                            isUpdating ? 'Menyimpan...' : 'Simpan perubahan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            _InfoRow(label: 'Nama Lengkap', value: profile.name),
            _InfoRow(label: 'Alamat Email', value: profile.email),
            _InfoRow(label: 'Peran / Hak Akses', value: profile.role.toUpperCase()),
          ],
        ],
      ),
    ),
  );
}

class _VerificationStatus extends StatelessWidget {
  const _VerificationStatus({
    required this.label,
    required this.verified,
  });

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.forestGreen : AppColors.warmBrown;
    final statusText = verified ? 'Terverifikasi' : 'Belum diverifikasi';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            verified ? Icons.verified_outlined : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                children: [
                  TextSpan(
                    text: statusText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
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
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    ),
  );
}

class _SystemInfoRow extends StatelessWidget {
  const _SystemInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
          ),
        ),
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
