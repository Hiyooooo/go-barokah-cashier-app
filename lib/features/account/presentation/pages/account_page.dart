import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
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
    if (name.length < 3) return;
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(
          name: name,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
    if (mounted && !ref.read(userProfileProvider).hasError) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Unable to load profile.')),
        data: (value) {
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
                FilledButton(onPressed: _save, child: const Text('Save')),
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text('Cancel'),
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
              if (profile.hasError && _editing) ...[
                const SizedBox(height: 12),
                Text(
                  'Unable to update profile.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Log out'),
              ),
            ],
          );
        },
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
