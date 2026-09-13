import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/versions_providers.dart';

class VersionsScreen extends ConsumerStatefulWidget {
  final String noteId; final String noteTitle;
  const VersionsScreen({super.key, required this.noteId, required this.noteTitle});
  @override
  ConsumerState<VersionsScreen> createState() => _VersionsScreenState();
}

class _VersionsScreenState extends ConsumerState<VersionsScreen> {
  @override
  void initState() { super.initState(); Future.microtask(() => ref.read(versionsProvider.notifier).loadVersions(widget.noteId)); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(versionsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('History: ${widget.noteTitle}')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.versions.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No version history')]))
              : ListView.builder(
                  itemCount: state.versions.length,
                  itemBuilder: (ctx, i) {
                    final v = state.versions[i];
                    final date = v.createdAt != null ? DateTime.fromMillisecondsSinceEpoch(v.createdAt!) : null;
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(v.title ?? 'Version ${state.versions.length - i}'),
                      subtitle: date != null ? Text('${date.toLocal()}') : null,
                      trailing: FilledButton.tonal(onPressed: () async {
                        final ok = await ref.read(versionsProvider.notifier).restoreVersion(widget.noteId, v.id);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Restored!' : 'Failed to restore')));
                      }, child: const Text('Restore')),
                    );
                  },
                ),
    );
  }
}
