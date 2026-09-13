import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/di/core_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(authProvider.notifier).logout())],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome${authState.name != null ? ', ${authState.name}' : ''}!',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Row(children: [
              _StatCard(title: 'Notes', value: '0', icon: Icons.note, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              _StatCard(title: 'Todos', value: '0', icon: Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _StatCard(title: 'Projects', value: '0', icon: Icons.work, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(width: 16),
              _StatCard(title: 'Calendar', value: '0', icon: Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      ),
    );
  }
}
