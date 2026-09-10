import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _fillForm(String name, String? phoneNumber) {
    if (_editing) return;
    _nameController.text = name;
    _phoneController.text = phoneNumber ?? '';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 3 characters.')),
      );
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }
    try {
      await ref
          .read(profileUpdateProvider.notifier)
          .saveProfile(name: name, phoneNumber: phone.isEmpty ? null : phone);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } catch (_) {
      // The update provider retains the form and exposes the error below.
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Widget _profileContent(BuildContext context, UserProfile value) {
    final update = ref.watch(profileUpdateProvider);
    final updating = update.isLoading;
    _fillForm(value.name, value.phoneNumber);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        if (_editing) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: updating ? null : _save,
            child: Text(updating ? 'Saving...' : 'Save'),
          ),
          TextButton(
            onPressed: updating ? null : () => setState(() => _editing = false),
            child: const Text('Cancel'),
          ),
          if (update.hasError)
            Text(
              userFacingError(
                update.error!,
                fallback: 'Unable to update profile.',
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ] else ...[
          _InfoRow(label: 'Name', value: value.name),
          _InfoRow(label: 'Email', value: value.email),
          _InfoRow(label: 'Role', value: value.role),
          _InfoRow(label: 'Phone', value: value.phoneNumber ?? '-'),
          _InfoRow(
            label: 'Email verified',
            value: value.emailVerified ? 'Yes' : 'No',
          ),
          _InfoRow(
            label: 'Phone verified',
            value: value.phoneNumberVerified ? 'Yes' : 'No',
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => _editing = true),
            child: const Text('Edit profile'),
          ),
        ],
        const SizedBox(height: 32),
        FilledButton.tonal(
          onPressed: updating ? null : _logout,
          child: const Text('Log out'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: profile.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(error, fallback: 'Unable to load profile.'),
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (value) => _profileContent(context, value),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
