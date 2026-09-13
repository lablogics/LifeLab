import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_providers.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});
  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() { super.initState(); Future.microtask(() => ref.read(activityProvider.notifier).loadActivity()); }

  IconData _iconForAction(String action) {
    switch (action) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Activity'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(activityProvider.notifier).loadActivity()),
      ]),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No recent activity')]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(activityProvider.notifier).loadActivity(),
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (ctx, i) {
                      final item = state.items[i];
                      final date = item.createdAt != null ? DateTime.fromMillisecondsSinceEpoch(item.createdAt!) : null;
                      return ListTile(
                        leading: Icon(_iconForAction(item.action), color: theme.colorScheme.primary),
                        title: Text('${item.action} ${item.entityType}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                        trailing: date != null ? Text('${date.month}/${date.day}', style: theme.textTheme.labelSmall) : null,
                      );
                    },
                  ),
                ),
    );
  }
}
