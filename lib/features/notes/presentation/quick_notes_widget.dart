import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notes_providers.dart';

/// Floating quick notes widget for creating notes from anywhere
class QuickNotesWidget extends ConsumerStatefulWidget {
  const QuickNotesWidget({super.key});
  @override
  ConsumerState<QuickNotesWidget> createState() => _QuickNotesWidgetState();
}

class _QuickNotesWidgetState extends ConsumerState<QuickNotesWidget> {
  bool _isOpen = false;
  bool _isMinimized = false;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _createQuickNote() async {
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final note = await ref.read(notesProvider.notifier).createNote(
        title: _titleCtrl.text.trim().isEmpty ? 'Quick Note' : _titleCtrl.text.trim(),
      );
      if (note != null && _contentCtrl.text.trim().isNotEmpty) {
        final lines = _contentCtrl.text.trim().split('\n');
        final content = lines.map((l) => l.isEmpty
            ? '{"type":"paragraph","content":[]}'
            : '{"type":"paragraph","content":[{"type":"text","text":"${l.replaceAll('"', '\"')}"}]}').join(',');
        await ref.read(notesRepositoryProvider).updateNote(
          note.id,
          contentJson: '{"type":"doc","content":[$content]}',
        );
      }
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() { _saving = false; _isOpen = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quick note saved')));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return FloatingActionButton.small(
        heroTag: 'quick_note',
        onPressed: () => setState(() => _isMinimized = false),
        child: const Icon(Icons.sticky_note_2, size: 20),
      );
    }
    if (!_isOpen) {
      return FloatingActionButton.small(
        heroTag: 'quick_note',
        onPressed: () => setState(() => _isOpen = true),
        child: const Icon(Icons.sticky_note_2),
      );
    }
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 280,
        height: 320,
        child: Column(
          children: [
            Row(
              children: [
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.sticky_note_2, size: 18)),
                const Expanded(child: Text('Quick Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                IconButton(icon: const Icon(Icons.minimize, size: 16), onPressed: () => setState(() => _isMinimized = true), visualDensity: VisualDensity.compact),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _isOpen = false), visualDensity: VisualDensity.compact),
              ],
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'Title', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _contentCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(hintText: 'Write something...', isDense: true, border: OutlineInputBorder()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _createQuickNote,
                  icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 16),
                  label: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
