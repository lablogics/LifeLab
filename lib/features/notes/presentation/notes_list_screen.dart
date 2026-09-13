import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/notes_providers.dart';
import '../data/models/note_model.dart';
import '../data/note_templates.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notesProvider.notifier).loadNotes();
      ref.read(foldersProvider.notifier).loadFolders();
      ref.read(tagsProvider.notifier).loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final foldersState = ref.watch(foldersProvider);
    final tagsState = ref.watch(tagsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Folders',
            onPressed: () => _showFoldersSheet(context, foldersState),
          ),
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Tags',
            onPressed: () => _showTagsSheet(context, tagsState),
          ),
          if (notesState.selectedFolderId != null || notesState.selectedTagId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: () => ref.read(notesProvider.notifier).selectFolder(null),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: notesState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(notesProvider.notifier).setSearchQuery(''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: ref.read(notesProvider.notifier).setSearchQuery,
            ),
          ),
          // Filter chips
          if (notesState.selectedFolderId != null || notesState.selectedTagId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  if (notesState.selectedFolderId != null)
                    Chip(
                      label: Text(_folderName(notesState.selectedFolderId!, foldersState)),
                      onDeleted: () => ref.read(notesProvider.notifier).selectFolder(null),
                    ),
                  if (notesState.selectedTagId != null)
                    Chip(
                      label: Text(_tagName(notesState.selectedTagId!, tagsState)),
                      onDeleted: () => ref.read(notesProvider.notifier).selectTag(null),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          // Notes list
          Expanded(
            child: notesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notesState.error != null
                    ? Center(child: Text('Error: ${notesState.error}'))
                    : notesState.filteredNotes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.note_add, size: 64, color: theme.colorScheme.outline),
                                const SizedBox(height: 16),
                                Text(
                                  notesState.searchQuery.isNotEmpty
                                      ? 'No notes match your search'
                                      : 'No notes yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: notesState.filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = notesState.filteredNotes[index];
                                return _NoteCard(
                                  note: note,
                                  onTap: () => context.push('/notes/${note.id}'),
                                  onPinToggle: () => ref
                                      .read(notesProvider.notifier)
                                      .togglePin(note.id, !note.isPinned),
                                  onTrash: () => _confirmTrash(context, note),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _folderName(String id, FoldersState state) {
    try {
      return state.folders.firstWhere((f) => f.id == id).name;
    } catch (_) {
      return 'Folder';
    }
  }

  String _tagName(String id, TagsState state) {
    try {
      return state.tags.firstWhere((t) => t.id == id).name;
    } catch (_) {
      return 'Tag';
    }
  }

  void _createNewNote(BuildContext context) async {
    final template = await _showTemplatePicker(context);
    if (template == null) return;
    final note = await ref.read(notesProvider.notifier).createNote(
      title: template.title.isEmpty ? 'Untitled' : template.title,
    );
    if (note != null && template.content.isNotEmpty) {
      // Update with template content
      await ref.read(notesRepositoryProvider).updateNote(
        note.id,
        contentJson: _buildTemplateJson(template.content),
  
      );
    }
    if (note != null && context.mounted) {
      context.push('/notes/${note.id}');
    }
  }

  String _buildTemplateJson(String plainText) {
    if (plainText.isEmpty) return '{"type":"doc","content":[]}';
    final lines = plainText.split('\n');
    final content = <Map<String, dynamic>>[];
    for (final line in lines) {
      if (line.startsWith('### ')) {
        content.add({'type': 'heading', 'attrs': {'level': 3}, 'content': [if (line.substring(4).isNotEmpty) {'type': 'text', 'text': line.substring(4)}]});
      } else if (line.startsWith('## ')) {
        content.add({'type': 'heading', 'attrs': {'level': 2}, 'content': [if (line.substring(3).isNotEmpty) {'type': 'text', 'text': line.substring(3)}]});
      } else if (line.startsWith('# ')) {
        content.add({'type': 'heading', 'attrs': {'level': 1}, 'content': [if (line.substring(2).isNotEmpty) {'type': 'text', 'text': line.substring(2)}]});
      } else if (line.startsWith('- [ ] ')) {
        content.add({'type': 'taskItem', 'attrs': {'checked': false}, 'content': [if (line.substring(6).isNotEmpty) {'type': 'text', 'text': line.substring(6)}]});
      } else if (line.isEmpty) {
        content.add({'type': 'paragraph', 'content': []});
      } else {
        content.add({'type': 'paragraph', 'content': [{'type': 'text', 'text': line}]});
      }
    }
    return '{"type":"doc","content":$content}';
  }

  Future<NoteTemplate?> _showTemplatePicker(BuildContext context) async {
    return showModalBottomSheet<NoteTemplate>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose a Template', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...noteTemplates.map((t) => ListTile(
              leading: Icon(_iconForTemplate(t.id)),
              title: Text(t.name),
              subtitle: t.content.isNotEmpty
                  ? Text(t.content.split('\n').where((l) => l.isNotEmpty && !l.startsWith('#')).take(1).join(), maxLines: 1, overflow: TextOverflow.ellipsis)
                  : const Text('Empty note'),
              onTap: () => Navigator.pop(ctx, t),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _iconForTemplate(String id) {
    switch (id) {
      case 'daily': return Icons.today;
      case 'meeting': return Icons.groups;
      case 'project': return Icons.work;
      case 'idea': return Icons.lightbulb;
      default: return Icons.note_add;
    }
  }

  void _confirmTrash(BuildContext context, NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('"${note.title}" will be moved to trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trash', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(notesProvider.notifier).trashNote(note.id);
    }
  }

  void _showFoldersSheet(BuildContext context, FoldersState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Folders', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    onPressed: () => _showCreateFolderDialog(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.folders.isEmpty
                  ? const Center(child: Text('No folders'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: state.folders.length,
                      itemBuilder: (ctx, i) {
                        final folder = state.folders[i];
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(folder.name),
                          onTap: () {
                            ref.read(notesProvider.notifier).selectFolder(folder.id);
                            Navigator.pop(ctx);
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _showRenameFolderDialog(ctx, folder.id, folder.name);
                                  break;
                                case 'delete':
                                  ref.read(foldersProvider.notifier).deleteFolder(folder.id);
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'rename', child: Text('Rename')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagsSheet(BuildContext context, TagsState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Tags', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showCreateTagDialog(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.tags.isEmpty
                  ? const Center(child: Text('No tags'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: state.tags.length,
                      itemBuilder: (ctx, i) {
                        final tag = state.tags[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _tagColor(tag.color),
                            radius: 12,
                          ),
                          title: Text(tag.name),
                          subtitle: tag.noteCount != null ? Text('${tag.noteCount} notes') : null,
                          onTap: () {
                            ref.read(notesProvider.notifier).selectTag(tag.id);
                            Navigator.pop(ctx);
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _showRenameTagDialog(ctx, tag.id, tag.name);
                                  break;
                                case 'delete':
                                  ref.read(tagsProvider.notifier).deleteTag(tag.id);
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'rename', child: Text('Rename')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(foldersProvider.notifier).createFolder(name);
    }
  }

  void _showRenameFolderDialog(BuildContext context, String id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(foldersProvider.notifier).renameFolder(id, name);
    }
  }

  void _showCreateTagDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(tagsProvider.notifier).createTag(name);
    }
  }

  void _showRenameTagDialog(BuildContext context, String id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Tag'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(tagsProvider.notifier).renameTag(id, name);
    }
  }

  Color _tagColor(String colorName) {
    const map = {
      'gray': Colors.grey,
      'red': Colors.red,
      'orange': Colors.orange,
      'yellow': Colors.amber,
      'green': Colors.green,
      'blue': Colors.blue,
      'purple': Colors.purple,
      'pink': Colors.pink,
    };
    return map[colorName] ?? Colors.grey;
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;
  final VoidCallback onTrash;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onPinToggle,
    required this.onTrash,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.contentText.length > 120
        ? '${note.contentText.substring(0, 120)}...'
        : note.contentText;
    final date = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                    ),
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: note.isPinned ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  )),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: onPinToggle,
                    tooltip: note.isPinned ? 'Unpin' : 'Pin',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onTrash,
                    tooltip: 'Trash',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

