import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notes_providers.dart';
import '../data/models/note_model.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _hasChanges = false;
  NoteModel? _originalNote;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getNote(widget.noteId);
      _originalNote = note;
      _titleController.text = note.title;

      // Extract plain text from TipTap JSON for editing
      try {
        final doc = jsonDecode(note.contentJson);
        _contentController.text = _extractPlainText(doc);
      } catch (_) {
        _contentController.text = note.contentText;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load note: $e')),
        );
      }
    }
  }

  String _extractPlainText(dynamic node) {
    if (node == null) return '';
    if (node is String) return node;

    final buffer = StringBuffer();
    if (node is Map<String, dynamic>) {
      if (node['text'] != null) {
        buffer.write(node['text']);
      }
      if (node['type'] == 'heading' && node['content'] != null) {
        for (final child in (node['content'] as List)) {
          buffer.write(_extractPlainText(child));
        }
        buffer.writeln();
      } else if (node['content'] != null) {
        for (final child in (node['content'] as List)) {
          buffer.write(_extractPlainText(child));
        }
      }
    } else if (node is List) {
      for (final child in node) {
        buffer.write(_extractPlainText(child));
      }
    }
    return buffer.toString();
  }

  String _buildTipTapJson(String plainText) {
    final lines = plainText.split('\n');
    final content = <Map<String, dynamic>>[];

    for (final line in lines) {
      if (line.startsWith('### ')) {
        content.add({
          'type': 'heading',
          'attrs': {'level': 3},
          'content': [if (line.substring(4).isNotEmpty) {'type': 'text', 'text': line.substring(4)}],
        });
      } else if (line.startsWith('## ')) {
        content.add({
          'type': 'heading',
          'attrs': {'level': 2},
          'content': [if (line.substring(3).isNotEmpty) {'type': 'text', 'text': line.substring(3)}],
        });
      } else if (line.startsWith('# ')) {
        content.add({
          'type': 'heading',
          'attrs': {'level': 1},
          'content': [if (line.substring(2).isNotEmpty) {'type': 'text', 'text': line.substring(2)}],
        });
      } else if (line.startsWith('- [ ] ')) {
        content.add({
          'type': 'taskItem',
          'attrs': {'checked': false},
          'content': [if (line.substring(6).isNotEmpty) {'type': 'text', 'text': line.substring(6)}],
        });
      } else if (line.startsWith('- [x] ')) {
        content.add({
          'type': 'taskItem',
          'attrs': {'checked': true},
          'content': [if (line.substring(6).isNotEmpty) {'type': 'text', 'text': line.substring(6)}],
        });
      } else if (line.isEmpty) {
        content.add({'type': 'paragraph', 'content': []});
      } else {
        content.add({
          'type': 'paragraph',
          'content': [{'type': 'text', 'text': line}],
        });
      }
    }

    return jsonEncode({'type': 'doc', 'content': content});
  }

  Future<void> _save() async {
    if (!_hasChanges) return;

    final title = _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim();
    final contentJson = _buildTipTapJson(_contentController.text);

    try {
      await ref.read(notesRepositoryProvider).updateNote(
        widget.noteId,
        title: title,
        contentJson: contentJson,
      );
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  
  void _insertWikilink() async {
    final controller = TextEditingController();
    final noteName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert [[Wikilink]]'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Note name', hintText: 'e.g. My Note')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Insert')),
        ],
      ),
    );
    if (noteName != null && noteName.isNotEmpty) {
      final pos = _contentController.selection.base.offset;
      final insert = '[[$noteName]]';
      _contentController.text = _contentController.text.replaceRange(pos, pos, insert);
      setState(() => _hasChanges = true);
    }
  }
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _showUnsavedDialog(context);
                if (shouldPop && context.mounted) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Form(
            key: _formKey,
            child: TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.titleMedium,
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.link), tooltip: 'Insert [[wikilink]]', onPressed: _insertWikilink),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: _hasChanges ? _save : null,
            ),
            if (_originalNote?.isPinned == true)
              IconButton(
                icon: const Icon(Icons.push_pin),
                tooltip: 'Unpin',
                onPressed: () {
                  ref.read(notesProvider.notifier).togglePin(widget.noteId, false);
                },
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Start writing...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
        ),
      ),
    );
  }

  Future<bool> _showUnsavedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard unsaved changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          TextButton(
            onPressed: () async {
              await _save();
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
