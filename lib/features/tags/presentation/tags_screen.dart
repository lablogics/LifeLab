import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tags_providers.dart';
import '../../notes/data/models/tag_model.dart';

const _tagColors = ['red', 'blue', 'green', 'purple', 'yellow', 'gray', 'orange', 'pink', 'teal'];
Color _colorForTag(String colorName) {
  switch (colorName) {
    case 'red': return Colors.red;
    case 'blue': return Colors.blue;
    case 'green': return Colors.green;
    case 'purple': return Colors.purple;
    case 'yellow': return Colors.amber;
    case 'orange': return Colors.orange;
    case 'pink': return Colors.pink;
    case 'teal': return Colors.teal;
    default: return Colors.grey;
  }
}

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});
  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  @override
  void initState() { super.initState(); Future.microtask(() => ref.read(tagsProvider.notifier).loadTags()); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tags'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(tagsProvider.notifier).refresh()),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateDialog, child: const Icon(Icons.add)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.tags.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.label_outline, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No tags yet')]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(tagsProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: state.tags.length,
                    itemBuilder: (ctx, i) {
                      final tag = state.tags[i];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: _colorForTag(tag.color).withOpacity(0.2), child: Icon(Icons.label, color: _colorForTag(tag.color), size: 20)),
                        title: Text(tag.name),
                        subtitle: tag.noteCount != null ? Text('${tag.noteCount} notes') : null,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => _handleAction(v, tag),
                          itemBuilder: (_) => const [PopupMenuItem(value: 'rename', child: Text('Rename')), PopupMenuItem(value: 'color', child: Text('Change color')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _handleAction(String action, TagModel tag) {
    switch (action) {
      case 'rename': _showRenameDialog(tag); break;
      case 'color': _showColorDialog(tag); break;
      case 'delete': _showDeleteDialog(tag); break;
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    String selectedColor = 'gray';
    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('New Tag'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tag name'), autofocus: true),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: _tagColors.map((c) => GestureDetector(
              onTap: () => setDialogState(() => selectedColor = c),
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: _colorForTag(c), shape: BoxShape.circle, border: selectedColor == c ? Border.all(width: 3, color: Colors.white) : null)),
            )).toList()),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () { if (nameCtrl.text.trim().isNotEmpty) { ref.read(tagsProvider.notifier).createTag(nameCtrl.text.trim(), selectedColor); Navigator.pop(ctx); } }, child: const Text('Create')),
          ],
        );
      });
    });
  }

  void _showRenameDialog(TagModel tag) {
    final ctrl = TextEditingController(text: tag.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Rename Tag'),
      content: TextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { ref.read(tagsProvider.notifier).renameTag(tag.id, ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Save')),
      ],
    ));
  }

  void _showColorDialog(TagModel tag) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tag Color'),
      content: Wrap(spacing: 12, runSpacing: 12, children: _tagColors.map((c) => GestureDetector(
        onTap: () { ref.read(tagsProvider.notifier).updateTagColor(tag.id, c); Navigator.pop(ctx); },
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _colorForTag(c), shape: BoxShape.circle, border: tag.color == c ? Border.all(width: 3) : null)),
      )).toList()),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }

  void _showDeleteDialog(TagModel tag) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Tag'),
      content: Text('Delete "${tag.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.tonal(onPressed: () { ref.read(tagsProvider.notifier).deleteTag(tag.id); Navigator.pop(ctx); }, child: const Text('Delete')),
      ],
    ));
  }
}
