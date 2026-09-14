import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _autoSaveTimer;
  String _saveStatus = 'saved'; // saved | saving | unsaved

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
    bool inCodeBlock = false;
    String codeLanguage = '';
    List<Map<String, dynamic>> codeLines = [];
    bool inTable = false;
    List<Map<String, dynamic>> tableRows = [];

    for (final line in lines) {
      // Code block toggle
      if (line.startsWith('```')) {
        if (inCodeBlock) {
          content.add({'type': 'codeBlock', 'attrs': {'language': codeLanguage.isEmpty ? null : codeLanguage}, 'content': codeLines});
          codeLines = [];
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeLanguage = line.substring(3).trim();
        }
        continue;
      }
      if (inCodeBlock) {
        codeLines.add({'type': 'text', 'text': line});
        continue;
      }
      // Table rows
      if (line.startsWith('|') && line.endsWith('|')) {
        if (!inTable) inTable = true;
        final cells = line.split('|').where((c) => c.isNotEmpty).map((c) => c.trim()).toList();
        if (cells.every((c) => RegExp(r'^[-:]+$').hasMatch(c))) continue; // separator row
        tableRows.add({'type': 'tableRow', 'content': cells.map((c) => {'type': 'tableCell', 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': c}]}]}).toList()});
        continue;
      } else if (inTable) {
        content.add({'type': 'table', 'content': tableRows});
        tableRows = [];
        inTable = false;
      }
      // Math blocks
      if (line.startsWith('\$\$') && line.endsWith('\$\$') && line.length > 4) {
        content.add({'type': 'math', 'attrs': {'latex': line.substring(2, line.length - 2)}});
        continue;
      }
      // Headings
      if (line.startsWith('### ')) {
        content.add({'type': 'heading', 'attrs': {'level': 3}, 'content': _inlineContent(line.substring(4))});
      } else if (line.startsWith('## ')) {
        content.add({'type': 'heading', 'attrs': {'level': 2}, 'content': _inlineContent(line.substring(3))});
      } else if (line.startsWith('# ')) {
        content.add({'type': 'heading', 'attrs': {'level': 1}, 'content': _inlineContent(line.substring(2))});
      } else if (line.startsWith('- [ ] ')) {
        content.add({'type': 'taskItem', 'attrs': {'checked': false}, 'content': _inlineContent(line.substring(6))});
      } else if (line.startsWith('- [x] ')) {
        content.add({'type': 'taskItem', 'attrs': {'checked': true}, 'content': _inlineContent(line.substring(6))});
      } else if (line.startsWith('> ')) {
        content.add({'type': 'blockquote', 'content': [{'type': 'paragraph', 'content': _inlineContent(line.substring(2))}]});
      } else if (line.startsWith('- ')) {
        content.add({'type': 'bulletItem', 'content': _inlineContent(line.substring(2))});
      } else if (line.isEmpty) {
        content.add({'type': 'paragraph', 'content': []});
      } else {
        content.add({'type': 'paragraph', 'content': _inlineContent(line)});
      }
    }
    // Close any open code block or table
    if (inCodeBlock && codeLines.isNotEmpty) {
      content.add({'type': 'codeBlock', 'attrs': {'language': codeLanguage.isEmpty ? null : codeLanguage}, 'content': codeLines});
    }
    if (inTable && tableRows.isNotEmpty) {
      content.add({'type': 'table', 'content': tableRows});
    }
    return jsonEncode({'type': 'doc', 'content': content});
  }

  /// Parse inline marks: **bold**, *italic*, ~~strike~~, ==highlight==, `code`, [[wikilink]], @mention, ![image]
  List<Map<String, dynamic>> _inlineContent(String text) {
    final result = <Map<String, dynamic>>[];
    final regex = RegExp(r'(\*\*(.+?)\*\*|\*(.+?)\*|~~(.+?)~~|==(.+?)==|`(.+?)`|\[\[(.+?)\]\]|@(\w+)|!\[(.+?)\]\((.+?)\))');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        result.add({'type': 'text', 'text': text.substring(lastEnd, match.start)});
      }
      if (match.group(2) != null) {
        result.add({'type': 'text', 'text': match.group(2), 'marks': [{'type': 'bold'}]});
      } else if (match.group(3) != null) {
        result.add({'type': 'text', 'text': match.group(3), 'marks': [{'type': 'italic'}]});
      } else if (match.group(4) != null) {
        result.add({'type': 'text', 'text': match.group(4), 'marks': [{'type': 'strike'}]});
      } else if (match.group(5) != null) {
        result.add({'type': 'text', 'text': match.group(5), 'marks': [{'type': 'highlight'}]});
      } else if (match.group(6) != null) {
        result.add({'type': 'text', 'text': match.group(6), 'marks': [{'type': 'code'}]});
      } else if (match.group(7) != null) {
        result.add({'type': 'text', 'text': match.group(7), 'marks': [{'type': 'wikilink'}]});
      } else if (match.group(8) != null) {
        result.add({'type': 'text', 'text': '@${match.group(8)}', 'marks': [{'type': 'mention'}]});
      } else if (match.group(9) != null && match.group(10) != null) {
        result.add({'type': 'image', 'attrs': {'src': match.group(10), 'alt': match.group(9)}});
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      result.add({'type': 'text', 'text': text.substring(lastEnd)});
    }
    if (result.isEmpty && text.isNotEmpty) {
      result.add({'type': 'text', 'text': text});
    }
    return result;
  }

  Future<void> _save() async {
    if (!_hasChanges) return;
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final contentJson = _buildTipTapJson(_contentController.text);
    try {
      await ref.read(notesRepositoryProvider).updateNote(widget.noteId, title: title, contentJson: contentJson);
      setState(() { _hasChanges = false; _saveStatus = 'saved'; });
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
      _contentController.selection = TextSelection.collapsed(offset: pos + noteName.length + 4);
      setState(() => _hasChanges = true);
    }
  }

  void _insertTable() {
    final pos = _contentController.selection.base.offset;
    const table = '| Header 1 | Header 2 | Header 3 |\n| --- | --- | --- |\n| Cell 1 | Cell 2 | Cell 3 |\n| Cell 4 | Cell 5 | Cell 6 |';
    _contentController.text = _contentController.text.replaceRange(pos, pos, '\n$table\n');
    _contentController.selection = TextSelection.collapsed(offset: pos + table.length + 2);
    setState(() => _hasChanges = true);
  }

  void _insertCodeBlock() async {
    final languages = ['', 'dart', 'javascript', 'python', 'java', 'kotlin', 'swift', 'rust', 'go', 'sql', 'html', 'css', 'json', 'yaml', 'bash'];
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Code Block Language'),
        children: languages.map((l) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, l),
          child: Text(l.isEmpty ? 'Plain text' : l),
        )).toList(),
      ),
    );
    final pos = _contentController.selection.base.offset;
    final langStr = lang ?? '';
    final block = '\n```$langStr\n\n```\n';
    _contentController.text = _contentController.text.replaceRange(pos, pos, block);
    _contentController.selection = TextSelection.collapsed(offset: pos + 4 + langStr.length);
    setState(() => _hasChanges = true);
  }

  void _insertMathBlock() async {
    final controller = TextEditingController();
    final latex = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Math (LaTeX)'),
        content: TextField(controller: controller, autofocus: true, maxLines: 3,
          decoration: const InputDecoration(hintText: 'E = mc^2', border: OutlineInputBorder()),
          style: const TextStyle(fontFamily: 'monospace')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Insert')),
        ],
      ),
    );
    if (latex != null && latex.isNotEmpty) {
      final pos = _contentController.selection.base.offset;
      _contentController.text = _contentController.text.replaceRange(pos, pos, '\n\$\$$latex\$\$\n');
      setState(() => _hasChanges = true);
    }
  }

  void _insertMention() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('@ Mention'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Person name', hintText: 'e.g. john')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Insert')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final pos = _contentController.selection.base.offset;
      _contentController.text = _contentController.text.replaceRange(pos, pos, '@$name ');
      setState(() => _hasChanges = true);
    }
  }

  void _insertImage() async {
    final urlCtrl = TextEditingController();
    final altCtrl = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Image'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://...')),
          const SizedBox(height: 8),
          TextField(controller: altCtrl, decoration: const InputDecoration(labelText: 'Alt text')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, {'url': urlCtrl.text.trim(), 'alt': altCtrl.text.trim()}), child: const Text('Insert')),
        ],
      ),
    );
    if (result != null && result['url']!.isNotEmpty) {
      final pos = _contentController.selection.base.offset;
      final alt = result['alt']!.isEmpty ? 'image' : result['alt']!;
      _contentController.text = _contentController.text.replaceRange(pos, pos, '![$alt](${result['url']})');
      setState(() => _hasChanges = true);
    }
  }

  void _applySmartTypography() {
    var text = _contentController.text;
    // Smart quotes
    text = text.replaceAllMapped(RegExp(r'"([^"]*?)"'), (m) => '\u201C${m.group(1)}\u201D');
    text = text.replaceAllMapped(RegExp(r"'([^']*?)'"), (m) => '\u2018${m.group(1)}\u2019');
    // Em dash
    text = text.replaceAll('---', '\u2014');
    // En dash
    text = text.replaceAll('--', '\u2013');
    // Ellipsis
    text = text.replaceAll('...', '\u2026');
    _contentController.text = text;
    setState(() => _hasChanges = true);
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


  // ── Tag picker ──
  void _showTagPicker() async {
    try {
      await ref.read(tagsProvider.notifier).loadTags();
      if (!mounted) return;
      final allTags = ref.read(tagsProvider).tags;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('Tags', style: TextStyle(fontWeight: FontWeight.bold))),
              if (allTags.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('No tags available'))
              else
                ...allTags.map((tag) => ListTile(
                  leading: CircleAvatar(backgroundColor: _tagColor(tag.color), radius: 12),
                  title: Text(tag.name),
                  trailing: const Icon(Icons.add, size: 16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.dio.dio.post('${Endpoints.notes}/${widget.noteId}/tags', data: {'tagId': tag.id});
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tag "${tag.name}" added')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load tags: $e')));
    }
  }

  Color _tagColor(String colorName) {
    const map = {'gray': Colors.grey, 'red': Colors.red, 'orange': Colors.orange, 'yellow': Colors.amber, 'green': Colors.green, 'blue': Colors.blue, 'purple': Colors.purple, 'pink': Colors.pink};
    return map[colorName] ?? Colors.grey;
  }

  void _onContentChanged() {
    setState(() { _hasChanges = true; _saveStatus = 'unsaved'; });
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_hasChanges) _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (!_hasChanges) return;
    setState(() => _saveStatus = 'saving');
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final contentJson = _buildTipTapJson(_contentController.text);
    try {
      await ref.read(notesRepositoryProvider).updateNote(widget.noteId, title: title, contentJson: contentJson);
      setState(() { _hasChanges = false; _saveStatus = 'saved'; });
    } catch (_) {
      setState(() => _saveStatus = 'unsaved');
    }
  }

  void _pasteImage() async {
    try {
      final data = await Clipboard.getData('image/png');
      if (data?.text != null) {
        final pos = _contentController.selection.base.offset;
        _contentController.text = _contentController.text.replaceRange(pos, pos, '![pasted image](${data!.text})');
        setState(() => _hasChanges = true);
        return;
      }
      // Fallback: pick from gallery
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final formData = FormData.fromMap({'file': await MultipartFile.fromFile(file.path!, filename: file.name)});
        final api = ref.read(apiClientProvider);
        await api.dio.dio.post('${Endpoints.attachments}/${widget.noteId}', data: formData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image attached')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paste failed: $e')));
    }
  }

  void _detectRichEmbed() {
    final text = _contentController.text;
    final urlPatterns = [
      RegExp(r'https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([\w-]+)'),
      RegExp(r'https?://(?:www\.)?(?:twitter\.com|x\.com)/\w+/status/\d+'),
      RegExp(r'https?://maps\.google\.com|goo\.gl/maps'),
    ];
    for (final pattern in urlPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final url = match.group(0)!;
        final type = url.contains('youtube') || url.contains('youtu.be') ? 'YouTube'
            : url.contains('twitter') || url.contains('x.com') ? 'Tweet' : 'Map';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$type link detected: ${url.substring(0, url.length.clamp(0, 40))}...'),
            action: SnackBarAction(label: 'Embed', onPressed: () {
              final icon = type == 'YouTube' ? '\ud83c\udfac' : type == 'Tweet' ? '\ud83d\udc26' : '\ud83d\uddfa\ufe0f';
              final pos = _contentController.selection.base.offset;
              _contentController.text = _contentController.text.replaceRange(pos, pos, '\n$icon $type: $url\n');
              setState(() => _hasChanges = true);
            }),
          ));
        }
        break;
      }
    }
  }

  void _showWikilinkPreview() async {
    final text = _contentController.text;
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No wikilinks found')));
      return;
    }
    final links = matches.map((m) => m.group(1)!).toList();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Preview Wikilink'),
        children: links.map((name) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, name), child: Text(name))).toList(),
      ),
    );
    if (selected == null) return;
    try {
      final notes = await ref.read(notesRepositoryProvider).getNotes();
      final match = notes.where((n) => n.title.toLowerCase() == selected.toLowerCase()).toList();
      if (match.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note "$selected" not found')));
        return;
      }
      final note = match.first;
      if (!mounted) return;
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(child: Text(note.contentText.isNotEmpty ? note.contentText.substring(0, note.contentText.length.clamp(0, 500)) : 'Empty note')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(onPressed: () { Navigator.pop(ctx); context.push('/notes/${note.id}'); }, child: const Text('Open')),
        ],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
    }
  }

  void dispose() { _autoSaveTimer?.cancel(); _titleController.dispose(); _contentController.dispose(); super.dispose(); }

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
            if (_saveStatus != 'saved')
              Padding(padding: const EdgeInsets.only(right: 4), child: Text(
                _saveStatus == 'saving' ? 'Saving...' : 'Unsaved',
                style: theme.textTheme.labelSmall?.copyWith(color: _saveStatus == 'saving' ? Colors.orange : Colors.red),
              )),
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
                _toolBtn(Icons.format_underline, 'Underline', () => _wrapSelection('__', '__')),
                _toolBtn(Icons.highlight, 'Highlight', () => _wrapSelection('==', '==')),
                _toolBtn(Icons.code, 'Code', () => _wrapSelection('`', '`')),
                _toolBtn(Icons.format_quote, 'Quote', () => _prependLine('> ')),
                _toolBtn(Icons.title, 'H1', () => _prependLine('# ')),
                _toolBtn(Icons.title, 'H2', () => _prependLine('## ')),
                _toolBtn(Icons.format_list_bulleted, 'List', () => _prependLine('- ')),
                _toolBtn(Icons.check_box, 'Task', () => _prependLine('- [ ] ')),
                _toolBtn(Icons.link, 'Wikilink', _insertWikilink),
                _toolBtn(Icons.open_in_new, 'Follow', _navigateToWikilink),
                _toolBtn(Icons.preview, 'Wiki Preview', _showWikilinkPreview),
                _toolBtn(Icons.paste, 'Paste Image', _pasteImage),
                _toolBtn(Icons.table_chart, 'Table', _insertTable),
                _toolBtn(Icons.code, 'Code Block', _insertCodeBlock),
                _toolBtn(Icons.functions, 'Math', _insertMathBlock),
                _toolBtn(Icons.alternate_email, 'Mention', _insertMention),
                _toolBtn(Icons.image, 'Image', _insertImage),
                _toolBtn(Icons.text_fields, 'Typography', _applySmartTypography),
                const SizedBox(width: 4),
                _toolBtn(Icons.attach_file, 'Attach', _attachFile),
                _toolBtn(Icons.mic, 'Voice', _showVoiceRecording),
                _toolBtn(Icons.brush, 'Draw', _showDrawingCanvas),
                _toolBtn(Icons.label_outline, 'Tags', _showTagPicker),
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
              onChanged: (_) {
                _onContentChanged();
                // Detect URLs for rich embeds every few chars
                if (_contentController.text.length % 20 == 0) _detectRichEmbed();
              },
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
