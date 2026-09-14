import 'dart:convert';
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
  bool _showTrash = false;
  List<NoteModel> _trashedNotes = [];
  bool _loadingTrash = false;
  bool _bulkMode = false;

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
    final isGrid = notesState.viewMode == NotesViewMode.grid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          if (!_showTrash && !_bulkMode) ...[
            IconButton(
              icon: Icon(notesState.starredOnly ? Icons.star : Icons.star_border),
              tooltip: 'Starred',
              onPressed: () => ref.read(notesProvider.notifier).setStarredOnly(!notesState.starredOnly),
            ),
            PopupMenuButton<NotesSortMode>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort',
              onSelected: (m) => ref.read(notesProvider.notifier).setSortMode(m),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: NotesSortMode.updated, child: Text('Last updated')),
                const PopupMenuItem(value: NotesSortMode.created, child: Text('Date created')),
                const PopupMenuItem(value: NotesSortMode.title, child: Text('Title')),
              ],
            ),
            IconButton(
              icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
              tooltip: isGrid ? 'List view' : 'Grid view',
              onPressed: () => ref.read(notesProvider.notifier).setViewMode(
                isGrid ? NotesViewMode.list : NotesViewMode.grid,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select',
              onPressed: () => setState(() => _bulkMode = true),
            ),
          ],
          if (_bulkMode) ...[
            TextButton(onPressed: () => ref.read(notesProvider.notifier).selectAllNotes(), child: const Text('All')),
            TextButton(onPressed: () => ref.read(notesProvider.notifier).clearSelection(), child: const Text('None')),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
              onPressed: notesState.selectedIds.isEmpty ? null : () => _confirmBulkDelete(),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () { ref.read(notesProvider.notifier).clearSelection(); setState(() => _bulkMode = false); },
            ),
          ],
          if (!_showTrash && !_bulkMode) ...[
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
          ],
          if (notesState.selectedFolderId != null || notesState.selectedTagId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: () {
                ref.read(notesProvider.notifier).selectFolder(null);
                ref.read(notesProvider.notifier).selectTag(null);
              },
            ),
          if (!_showTrash)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                switch (v) {
                  case 'export_all': _exportAllMarkdown(); break;
                  case 'import_md': _showImportMarkdown(); break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'export_all', child: Text('Export all as Markdown')),
                const PopupMenuItem(value: 'import_md', child: Text('Import Markdown')),
              ],
            ),
          IconButton(
            icon: Icon(_showTrash ? Icons.delete : Icons.delete_outline),
            tooltip: _showTrash ? 'Back to notes' : 'Trash',
            onPressed: () {
              setState(() => _showTrash = !_showTrash);
              if (_showTrash) _loadTrash();
            },
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    Chip(label: Text(_folderName(notesState.selectedFolderId!, foldersState)),
                      onDeleted: () => ref.read(notesProvider.notifier).selectFolder(null)),
                  if (notesState.selectedTagId != null)
                    Chip(label: Text(_tagName(notesState.selectedTagId!, tagsState)),
                      onDeleted: () => ref.read(notesProvider.notifier).selectTag(null)),
                ],
              ),
            ),
          if (notesState.starredOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Chip(label: const Text('Starred only'), onDeleted: () => ref.read(notesProvider.notifier).setStarredOnly(false)),
            ),
          const SizedBox(height: 4),
          // Notes list/grid
          Expanded(
            child: _showTrash
                ? _buildTrashView(theme)
                : notesState.isLoading
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
                                          : notesState.starredOnly ? 'No starred notes' : 'No notes yet',
                                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
                                child: isGrid
                                    ? _buildGridView(notesState, theme)
                                    : _buildListView(notesState, theme),
                              ),
          ),
        ],
      ),
      floatingActionButton: _bulkMode ? null : FloatingActionButton(
        onPressed: () => _createNewNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(NotesState notesState, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notesState.filteredNotes.length,
      itemBuilder: (context, index) {
        final note = notesState.filteredNotes[index];
        final selected = notesState.selectedIds.contains(note.id);
        return _NoteCard(
          note: note,
          selected: selected,
          bulkMode: _bulkMode,
          onTap: () {
            if (_bulkMode) {
              ref.read(notesProvider.notifier).toggleSelectNote(note.id);
            } else {
              context.push('/notes/${note.id}');
            }
          },
          onPinToggle: () => ref.read(notesProvider.notifier).togglePin(note.id, !note.isPinned),
          onTrash: () => _confirmTrash(context, note),
          onDuplicate: () => _duplicateNote(note),
        );
      },
    );
  }

  Widget _buildGridView(NotesState notesState, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
      ),
      itemCount: notesState.filteredNotes.length,
      itemBuilder: (context, index) {
        final note = notesState.filteredNotes[index];
        final selected = notesState.selectedIds.contains(note.id);
        return _NoteGridCard(
          note: note,
          selected: selected,
          bulkMode: _bulkMode,
          onTap: () {
            if (_bulkMode) {
              ref.read(notesProvider.notifier).toggleSelectNote(note.id);
            } else {
              context.push('/notes/${note.id}');
            }
          },
          onPinToggle: () => ref.read(notesProvider.notifier).togglePin(note.id, !note.isPinned),
        );
      },
    );
  }

  Widget _buildTrashView(ThemeData theme) {
    if (_loadingTrash) return const Center(child: CircularProgressIndicator());
    if (_trashedNotes.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.delete_outline, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Trash is empty', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTrash,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trashedNotes.length,
        itemBuilder: (context, index) {
          final note = _trashedNotes[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(note.title),
              subtitle: Text(note.contentText.length > 60 ? '${note.contentText.substring(0, 60)}...' : note.contentText),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.restore), tooltip: 'Restore', onPressed: () => _confirmRestore(note)),
                  IconButton(icon: const Icon(Icons.delete_forever), tooltip: 'Delete', onPressed: () => _confirmPermanentDelete(note), color: Colors.red),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmBulkDelete() async {
    final count = ref.read(notesProvider).selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected notes?'),
        content: Text('$count note(s) will be moved to trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notesProvider.notifier).bulkTrashNotes();
      setState(() => _bulkMode = false);
    }
  }

  String _folderName(String id, FoldersState state) {
    try { return state.folders.firstWhere((f) => f.id == id).name; } catch (_) { return 'Folder'; }
  }

  String _tagName(String id, TagsState state) {
    try { return state.tags.firstWhere((t) => t.id == id).name; } catch (_) { return 'Tag'; }
  }

  Future<void> _loadTrash() async {
    setState(() => _loadingTrash = true);
    try {
      final notes = await ref.read(notesRepositoryProvider).getTrashedNotes();
      setState(() { _trashedNotes = notes; _loadingTrash = false; });
    } catch (e) { setState(() => _loadingTrash = false); }
  }

  void _confirmRestore(NoteModel note) async {
    await ref.read(notesRepositoryProvider).restoreNote(note.id);
    _loadTrash();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${note.title}" restored')));
  }

  void _confirmPermanentDelete(NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('"${note.title}" will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notesRepositoryProvider).permanentDeleteNote(note.id);
      _loadTrash();
    }
  }

  String _buildTipTapJson(String plainText) {
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

  void _showImportMarkdown() async {
    final controller = TextEditingController();
    final markdown = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Markdown'),
        content: TextField(controller: controller, maxLines: 10, decoration: const InputDecoration(hintText: 'Paste markdown content here...', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Import')),
        ],
      ),
    );
    if (markdown != null && markdown.trim().isNotEmpty) {
      final lines = markdown.trim().split('\n');
      final title = lines.isNotEmpty && lines[0].startsWith('# ') ? lines[0].substring(2) : 'Imported Note';
      final note = await ref.read(notesProvider.notifier).createNote(title: title);
      if (note != null) {
        final contentJson = _buildTipTapJson(markdown.trim());
        await ref.read(notesRepositoryProvider).updateNote(note.id, contentJson: contentJson);
        if (mounted) context.push('/notes/${note.id}');
      }
    }
  }

  void _exportAllMarkdown() {
    final notes = ref.read(notesProvider).filteredNotes;
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No notes to export')));
      return;
    }
    final buffer = StringBuffer();
    for (final note in notes) {
      buffer.writeln('# ${note.title}');
      buffer.writeln();
      try {
        final doc = jsonDecode(note.contentJson);
        final contentNodes = (doc as Map<String, dynamic>)['content'] as List? ?? [];
        for (final node in contentNodes) {
          final n = node as Map<String, dynamic>;
          final type = n['type'] as String? ?? '';
          final text = _extractNodeTextGlobal(n);
          switch (type) {
            case 'heading':
              final level = (n['attrs'] as Map<String, dynamic>?)?['level'] as int? ?? 1;
              buffer.writeln('${'#' * level} $text');
              break;
            case 'taskItem':
              final checked = (n['attrs'] as Map<String, dynamic>?)?['checked'] == true;
              buffer.writeln('- [${checked ? 'x' : ' '}] $text');
              break;
            case 'paragraph':
              buffer.writeln(text);
              break;
            default:
              buffer.writeln(text);
          }
        }
      } catch (_) {
        buffer.write(note.contentText);
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Export All Notes'),
      content: SingleChildScrollView(child: SelectableText(buffer.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }

  String _extractNodeTextGlobal(Map<String, dynamic> node) {
    final content = node['content'] as List?;
    if (content == null) return '';
    return content.map((c) {
      final m = c as Map<String, dynamic>;
      return m['text'] as String? ?? _extractNodeTextGlobal(m);
    }).join();
  }

  void _duplicateNote(NoteModel note) async {
    try {
      final dup = await ref.read(notesRepositoryProvider).duplicateNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Duplicated as "${dup.title}"')));
        ref.read(notesProvider.notifier).loadNotes();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to duplicate: $e')));
    }
  }

  void _createNewNote(BuildContext context) async {
    final template = await _showTemplatePicker(context);
    if (template == null) return;
    final note = await ref.read(notesProvider.notifier).createNote(
      title: template.title.isEmpty ? 'Untitled' : template.title,
    );
    if (note != null && template.content.isNotEmpty) {
      await ref.read(notesRepositoryProvider).updateNote(note.id, contentJson: _buildTemplateJson(template.content));
    }
    if (note != null && context.mounted) context.push('/notes/${note.id}');
  }

  String _buildTemplateJson(String plainText) => _buildTipTapJson(plainText);

  Future<NoteTemplate?> _showTemplatePicker(BuildContext context) async {
    return showModalBottomSheet<NoteTemplate>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Choose a Template', style: TextStyle(fontWeight: FontWeight.bold))),
            ...noteTemplates.map((t) => ListTile(
              leading: Icon(_iconForTemplate(t.id)),
              title: Text(t.name),
              subtitle: t.content.isNotEmpty ? Text(t.content.split('\n').where((l) => l.isNotEmpty && !l.startsWith('#')).take(1).join(), maxLines: 1, overflow: TextOverflow.ellipsis) : const Text('Empty note'),
              onTap: () => Navigator.pop(ctx, t),
            )),
            ListTile(leading: const Icon(Icons.import_export), title: const Text('Import Markdown'), onTap: () { Navigator.pop(ctx); _showImportMarkdown(); }),
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Trash', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) ref.read(notesProvider.notifier).trashNote(note.id);
  }

  void _showFoldersSheet(BuildContext context, FoldersState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.8, expand: false,
        builder: (ctx, scrollController) => Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Text('Folders', style: Theme.of(ctx).textTheme.titleLarge),
            const Spacer(),
            IconButton(icon: const Icon(Icons.create_new_folder_outlined), onPressed: () => _showCreateFolderDialog(ctx)),
          ])),
          Expanded(child: state.folders.isEmpty ? const Center(child: Text('No folders')) : ListView.builder(
            controller: scrollController, itemCount: state.folders.length,
            itemBuilder: (ctx, i) {
              final folder = state.folders[i];
              return ListTile(
                leading: const Icon(Icons.folder_outlined), title: Text(folder.name),
                onTap: () { ref.read(notesProvider.notifier).selectFolder(folder.id); Navigator.pop(ctx); },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) { switch (value) { case 'rename': _showRenameFolderDialog(ctx, folder.id, folder.name); break; case 'delete': ref.read(foldersProvider.notifier).deleteFolder(folder.id); break; } },
                  itemBuilder: (ctx) => [const PopupMenuItem(value: 'rename', child: Text('Rename')), const PopupMenuItem(value: 'delete', child: Text('Delete'))],
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showTagsSheet(BuildContext context, TagsState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.8, expand: false,
        builder: (ctx, scrollController) => Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Text('Tags', style: Theme.of(ctx).textTheme.titleLarge),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateTagDialog(ctx)),
          ])),
          Expanded(child: state.tags.isEmpty ? const Center(child: Text('No tags')) : ListView.builder(
            controller: scrollController, itemCount: state.tags.length,
            itemBuilder: (ctx, i) {
              final tag = state.tags[i];
              return ListTile(
                leading: CircleAvatar(backgroundColor: _tagColor(tag.color), radius: 12),
                title: Text(tag.name),
                subtitle: tag.noteCount != null ? Text('${tag.noteCount} notes') : null,
                onTap: () { ref.read(notesProvider.notifier).selectTag(tag.id); Navigator.pop(ctx); },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) { switch (value) { case 'rename': _showRenameTagDialog(ctx, tag.id, tag.name); break; case 'delete': ref.read(tagsProvider.notifier).deleteTag(tag.id); break; } },
                  itemBuilder: (ctx) => [const PopupMenuItem(value: 'rename', child: Text('Rename')), const PopupMenuItem(value: 'delete', child: Text('Delete'))],
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Folder name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) ref.read(foldersProvider.notifier).createFolder(name);
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
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) ref.read(foldersProvider.notifier).renameFolder(id, name);
  }

  void _showCreateTagDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Tag name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) ref.read(tagsProvider.notifier).createTag(name);
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
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) ref.read(tagsProvider.notifier).renameTag(id, name);
  }

  Color _tagColor(String colorName) {
    const map = {'gray': Colors.grey, 'red': Colors.red, 'orange': Colors.orange, 'yellow': Colors.amber, 'green': Colors.green, 'blue': Colors.blue, 'purple': Colors.purple, 'pink': Colors.pink};
    return map[colorName] ?? Colors.grey;
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;
  final VoidCallback onTrash;
  final VoidCallback? onDuplicate;
  final bool selected;
  final bool bulkMode;

  const _NoteCard({required this.note, required this.onTap, required this.onPinToggle, required this.onTrash, this.onDuplicate, this.selected = false, this.bulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.contentText.length > 120 ? '${note.contentText.substring(0, 120)}...' : note.contentText;
    final date = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (bulkMode) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: selected ? theme.colorScheme.primary : theme.colorScheme.outline)),
              if (note.isPinned) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary)),
              Expanded(child: Text(note.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: note.isPinned ? FontWeight.w600 : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ]),
            if (preview.isNotEmpty) ...[const SizedBox(height: 4), Text(preview, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)],
            if (!bulkMode) ...[
              const SizedBox(height: 8),
              Row(children: [
                IconButton(icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18), visualDensity: VisualDensity.compact, onPressed: onPinToggle, tooltip: note.isPinned ? 'Unpin' : 'Pin'),
                const Spacer(),
                if (onDuplicate != null) IconButton(icon: const Icon(Icons.copy, size: 18), visualDensity: VisualDensity.compact, onPressed: onDuplicate, tooltip: 'Duplicate'),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18), visualDensity: VisualDensity.compact, onPressed: onTrash, tooltip: 'Trash'),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _NoteGridCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;
  final bool selected;
  final bool bulkMode;

  const _NoteGridCard({required this.note, required this.onTap, required this.onPinToggle, this.selected = false, this.bulkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.contentText.length > 80 ? '${note.contentText.substring(0, 80)}...' : note.contentText;

    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (bulkMode) Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: selected ? theme.colorScheme.primary : theme.colorScheme.outline),
              if (note.isPinned) Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
              const Spacer(),
              if (!bulkMode) IconButton(icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16), visualDensity: VisualDensity.compact, onPressed: onPinToggle),
            ]),
            const SizedBox(height: 8),
            Text(note.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Expanded(child: Text(preview, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 4, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}
