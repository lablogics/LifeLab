import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/sync/sync_providers.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          if (syncState.pendingCount > 0 || syncState.isSyncing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: syncState.isSyncing
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.tertiaryContainer,
              child: Row(
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: syncState.isSyncing
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(Icons.cloud_off, size: 14, color: theme.colorScheme.tertiary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncState.isSyncing
                          ? 'Syncing changes...'
                          : '${syncState.pendingCount} pending change${syncState.pendingCount == 1 ? "" : "s"}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Todos'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/notes')) return 1;
    if (location.startsWith('/todos')) return 2;
    return 3;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/notes'); break;
      case 2: context.go('/todos'); break;
      case 3: context.go('/more'); break;
    }
  }
}
