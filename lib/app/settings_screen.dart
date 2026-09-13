import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/di/core_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const SizedBox(height: 16),
        CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 16),
        Center(child: Text(auth.name ?? 'User', style: theme.textTheme.titleLarge)),
        Center(child: Text(auth.email ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(leading: const Icon(Icons.person), title: const Text('Edit Profile'), onTap: () {}),
        ListTile(leading: const Icon(Icons.lock), title: const Text('Change Password'), onTap: () {}),
        ListTile(leading: const Icon(Icons.devices), title: const Text('Active Sessions'), onTap: () {}),
        ListTile(leading: const Icon(Icons.security), title: const Text('Two-Factor Auth'), onTap: () {}),
        ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifications'), onTap: () {}),
        const Divider(),
        ListTile(leading: const Icon(Icons.info), title: const Text('About LifeLab'), subtitle: const Text('Version 1.0.0')),
        const Divider(),
        Padding(padding: const EdgeInsets.all(16), child: FilledButton.tonal(onPressed: () => ref.read(authProvider.notifier).logout(), child: const Text('Sign Out'))),
      ]),
    );
  }
}
