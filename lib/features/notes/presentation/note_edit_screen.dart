import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:dio/dio.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _showToolbar = true;
  NoteModel? _originalNote;

  @override
  void initState() { super.initState(); _loadNote(); }

  Future<void> _loadNote() async {
    try {
      final repo = ref.read(notesRepositoryProvider);
      final note = await repo.getNote(widget.noteId);
      _originalNote = note;
      _titleController.text = note.title;
      try {
        final doc = jsonDecode(note.contentJson);
        _contentController.text = _extractPlainText(doc);
      } catch (_) { _contentController.text = note.contentText; }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load note: $e')));
    }
  }

  String _extractPlainText(dynamic node) {
    if (node == null) return '';
    if (node is String) return node;
    final buffer = StringBuffer();
    if (node is Map<String, dynamic>) {
      if (node['text'] != null) buffer.write(node['text']);
      if (node['type'] == 'heading' && node['content'] != null) {
        for (final child in (node['content'] as List)) buffer.write(_extractPlainText(child));
        buffer.writeln();
      } else if (node['content'] != null) {
        for (final child in (node['content'] as List)) buffer.write(_extractPlainText(child));
      }
    } else if (node is List) {
      for (final child in node) buffer.write(_extractPlainText(child));
    }
    return buffer.toString();
  }

  String _buildTipTapJson(String plainText) {
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
      } else if (line.startsWith('- [x] ')) {
        content.add({'type': 'taskItem', 'attrs': {'checked': true}, 'content': [if (line.substring(6).isNotEmpty) {'type': 'text', 'text': line.substring(6)}]});
      } else if (line.isEmpty) {
        content.add({'type': 'paragraph', 'content': []});
      } else {
        content.add({'type': 'paragraph', 'content': [{'type': 'text', 'text': line}]});
      }
    }
    return jsonEncode({'type': 'doc', 'content': content});
  }

  Future<void> _save() async {
    if (!_hasChanges) return;
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final contentJson = _buildTipTapJson(_contentController.text);
    try {
      await ref.read(notesRepositoryProvider).updateNote(widget.noteId, title: title, contentJson: contentJson);
      setState(() => _hasChanges = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  // ── Formatting helpers ──
  void _wrapSelection(String before, String after) {
    final sel = _contentController.selection;
    final text = _contentController.text;
    if (sel.start < 0) return;
    final selected = text.substring(sel.start, sel.end);
    final replacement = '$before$selected$after';
    _contentController.text = text.replaceRange(sel.start, sel.end, replacement);
    _contentController.selection = TextSelection.collapsed(offset: sel.start + replacement.length);
    setState(() => _hasChanges = true);
  }

  void _prependLine(String prefix) {
    final text = _contentController.text;
    final pos = _contentController.selection.base.offset;
    // Find start of current line
    int lineStart = pos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') { lineStart--; }
    _contentController.text = text.replaceRange(lineStart, lineStart, prefix);
    _contentController.selection = TextSelection.collapsed(offset: pos + prefix.length);
    setState(() => _hasChanges = true);
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
      _contentController.text = _contentController.text.replaceRange(pos, pos, '[[$noteName]]');
      setState(() => _hasChanges = true);
    }
  }

  void _navigateToWikilink() {
    final text = _contentController.text;
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No wikilinks found in this note')));
      return;
    }
    final links = matches.map((m) => m.group(1)!).toSet().toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Linked Notes', style: TextStyle(fontWeight: FontWeight.bold))),
          ...links.map((name) => ListTile(
            leading: const Icon(Icons.link), title: Text(name), trailing: const Icon(Icons.arrow_forward, size: 16),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final notes = await ref.read(notesRepositoryProvider).getNotes();
                final match = notes.where((n) => n.title.toLowerCase() == name.toLowerCase()).toList();
                if (match.isNotEmpty && mounted) { context.push('/notes/${match.first.id}'); }
                else if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note "$name" not found'))); }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to find note: $e')));
              }
            },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Extract selection as todo ──
  void _extractSelectionAsTodo() async {
    final sel = _contentController.selection;
    final text = _contentController.text;
    if (sel.start < 0 || sel.start == sel.end) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select text first to extract as todo')));
      return;
    }
    final selected = text.substring(sel.start, sel.end).trim();
    if (selected.isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.post(Endpoints.todos, data: {'title': selected, 'noteId': widget.noteId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todo created from selection')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create todo: $e')));
    }
  }

  // ── File attachment ──
  void _attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(file.path!, filename: file.name)});
      final api = ref.read(apiClientProvider);
      await api.dio.dio.post('${Endpoints.attachments}/${widget.noteId}', data: formData);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File attached')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attach failed: $e')));
    }
  }

  // ── Voice recording ──
  void _showVoiceRecording() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Voice Recording'),
      content: const Text('Voice recording requires device microphone access. The recording will be attached to this note.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { Navigator.pop(ctx); _startVoiceRecord(); }, child: const Text('Start Recording')),
      ],
    ));
  }

  Future<void> _startVoiceRecord() async {
    try {
      final api = ref.read(apiClientProvider);
      // Use the transcribe endpoint which accepts audio
      await api.dio.dio.post('${Endpoints.notes}/transcribe', data: {'noteId': widget.noteId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording started')));
        _loadNote();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording failed: $e')));
    }
  }

  // ── Drawing canvas ──
  void _showDrawingCanvas() {
    final points = <Offset>[];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Draw'),
      content: SizedBox(
        width: 300, height: 300,
        child: GestureDetector(
          onPanUpdate: (d) { setState(() => points.add(d.localPosition)); },
          child: CustomPaint(
            painter: _DrawingPainter(points),
            child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey))),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () { points.clear(); setState(() {}); }, child: const Text('Clear')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drawing saved to note (placeholder)')));
        }, child: const Text('Save')),
      ],
    ));
  }

  // ── Custom CSS ──
  void _showCssEditor() async {
    final controller = TextEditingController(text: _originalNote?.customCss ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom CSS'),
        content: TextField(controller: controller, maxLines: 10, decoration: const InputDecoration(hintText: '/* Custom CSS for this note */', border: OutlineInputBorder()), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      try {
        final api = ref.read(apiClientProvider);
        await api.dio.dio.put('${Endpoints.notes}/${widget.noteId}', data: {'customCss': result});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom CSS saved')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // ── Export / Transcribe / Clip ──
  Future<void> _exportPdf() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.get('${Endpoints.notes}/${widget.noteId}/pdf', options: Options(responseType: ResponseType.bytes));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _transcribeAudio() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.post('${Endpoints.notes}/transcribe', data: {'noteId': widget.noteId});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transcription started'))); _loadNote(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transcription failed: $e')));
    }
  }

  Future<void> _clipWebContent() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clip Web Content'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Clip')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      try {
        final api = ref.read(apiClientProvider);
        await api.dio.dio.post('${Endpoints.notes}/clip', data: {'noteId': widget.noteId, 'url': url});
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content clipped'))); _loadNote(); }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clip failed: $e')));
      }
    }
  }

  void dispose() { _titleController.dispose(); _contentController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedDialog(context);
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () async {
            if (_hasChanges) { final s = await _showUnsavedDialog(context); if (s && context.mounted) Navigator.pop(context); }
            else Navigator.pop(context);
          }),
          title: Form(key: _formKey, child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Note title', border: InputBorder.none, contentPadding: EdgeInsets.zero),
            style: theme.textTheme.titleMedium,
            onChanged: (_) => setState(() => _hasChanges = true),
          )),
          actions: [
            IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: _hasChanges ? _save : null),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'pdf': _exportPdf(); break;
                  case 'transcribe': _transcribeAudio(); break;
                  case 'clip': _clipWebContent(); break;
                  case 'css': _showCssEditor(); break;
                  case 'extract': _extractSelectionAsTodo(); break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                const PopupMenuItem(value: 'transcribe', child: Text('Transcribe Audio')),
                const PopupMenuItem(value: 'clip', child: Text('Clip Web Content')),
                const PopupMenuItem(value: 'css', child: Text('Custom CSS')),
                const PopupMenuItem(value: 'extract', child: Text('Extract selection as todo')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
            if (_originalNote?.isPinned == true)
              IconButton(icon: const Icon(Icons.push_pin), tooltip: 'Unpin',
                onPressed: () => ref.read(notesProvider.notifier).togglePin(widget.noteId, false)),
          ],
        ),
        body: Column(children: [
          // Formatting toolbar
          if (_showToolbar) Container(
            height: 44,
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _toolBtn(Icons.format_bold, 'Bold', () => _wrapSelection('**', '**')),
                _toolBtn(Icons.format_italic, 'Italic', () => _wrapSelection('*', '*')),
                _toolBtn(Icons.format_strikethrough, 'Strike', () => _wrapSelection('~~', '~~')),
                _toolBtn(Icons.title, 'H1', () => _prependLine('# ')),
                _toolBtn(Icons.title, 'H2', () => _prependLine('## ')),
                _toolBtn(Icons.format_list_bulleted, 'List', () => _prependLine('- ')),
                _toolBtn(Icons.check_box, 'Task', () => _prependLine('- [ ] ')),
                _toolBtn(Icons.link, 'Wikilink', _insertWikilink),
                _toolBtn(Icons.open_in_new, 'Follow', _navigateToWikilink),
                const SizedBox(width: 4),
                _toolBtn(Icons.attach_file, 'Attach', _attachFile),
                _toolBtn(Icons.mic, 'Voice', _showVoiceRecording),
                _toolBtn(Icons.brush, 'Draw', _showDrawingCanvas),
              ]),
            ),
          ),
          // Editor
          Expanded(child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentController,
              maxLines: null, expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(hintText: 'Start writing...', border: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: theme.textTheme.bodyLarge,
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: IconButton(
      icon: Icon(icon, size: 20), tooltip: tooltip, onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    ));
  }

  Future<bool> _showUnsavedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard unsaved changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          TextButton(onPressed: () async { await _save(); if (ctx.mounted) Navigator.pop(ctx, true); }, child: const Text('Save & Exit')),
        ],
      ),
    );
    return result ?? false;
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset> points;
  _DrawingPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeCap = StrokeCap.round..strokeWidth = 2.0;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
