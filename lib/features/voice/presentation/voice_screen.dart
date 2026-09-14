import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/voice_providers.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});
  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  String _searchQuery = '';
  String? _playingId;

  List<VoiceNote> get _filteredNotes {
    final notes = ref.read(voiceProvider).notes;
    if (_searchQuery.isEmpty) return notes;
    final q = _searchQuery.toLowerCase();
    return notes.where((n) => n.title.toLowerCase().contains(q) || n.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);
    final theme = Theme.of(context);
    final notes = _filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.tag), tooltip: 'Manage Tags', onPressed: () => _showTagManager(context)),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: TextField(
            decoration: const InputDecoration(hintText: 'Search notes...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _searchQuery = v),
          )),
        ),
      ),
      body: notes.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mic_none, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No voice notes yet')]))
          : ListView.builder(itemCount: notes.length, itemBuilder: (ctx, i) {
              final note = notes[i];
              final isPlaying = _playingId == note.id;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(children: [
                  ListTile(
                    leading: IconButton(
                      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, color: isPlaying ? Colors.red : null),
                      onPressed: () => setState(() => _playingId = isPlaying ? null : note.id),
                    ),
                    title: Text(note.title),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${note.duration}s · ${DateTime.fromMillisecondsSinceEpoch(note.createdAt).toLocal().toString().substring(0, 16)}'),
                      if (note.tags.isNotEmpty)
                        Wrap(children: note.tags.map((t) => Padding(padding: const EdgeInsets.only(right: 4), child: Chip(label: Text(t), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))).toList()),
                    ]),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => _handleNoteAction(v, note),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'rename', child: Text('Rename')),
                        const PopupMenuItem(value: 'tags', child: Text('Edit Tags')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                  // Waveform visualization
                  if (isPlaying)
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _WaveformPainter(theme.colorScheme.primary),
                      ),
                    ),
                ]),
              );
            }),
      floatingActionButton: FloatingActionButton(onPressed: () { if (state.isRecording) { notifier.stopRecording(); } else { notifier.startRecording(); } }, backgroundColor: state.isRecording ? Colors.red : null, child: Icon(state.isRecording ? Icons.stop : Icons.mic)),
    );
  }

  void _handleNoteAction(String action, VoiceNote note) {
    final notifier = ref.read(voiceProvider.notifier);
    switch (action) {
      case 'rename':
        final ctrl = TextEditingController(text: note.title);
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Rename'),
          content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () { notifier.renameNote(note.id, ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Save')),
          ],
        ));
        break;
      case 'tags':
        final currentTags = note.tags.join(', ');
        final ctrl = TextEditingController(text: currentTags);
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Edit Tags'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final tags = ctrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
              notifier.setTags(note.id, tags);
              Navigator.pop(ctx);
            }, child: const Text('Save')),
          ],
        ));
        break;
      case 'delete':
        notifier.deleteNote(note.id);
        break;
    }
  }

  void _showTagManager(BuildContext context) {
    final allTags = <String>{};
    for (final note in ref.read(voiceProvider).notes) {
      allTags.addAll(note.tags);
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('All Tags', style: TextStyle(fontWeight: FontWeight.bold))),
        if (allTags.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No tags yet'))
        else
          Wrap(children: allTags.map((t) => Padding(padding: const EdgeInsets.all(4), child: Chip(label: Text(t)))).toList()),
        const SizedBox(height: 8),
      ])),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  _WaveformPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    final barWidth = 3.0;
    final gap = 2.0;
    final numBars = (size.width / (barWidth + gap)).floor();
    for (int i = 0; i < numBars; i++) {
      final x = i * (barWidth + gap);
      final h = (size.height * 0.3) + (size.height * 0.7 * ((i % 5 + 1) / 5.0));
      final y = (size.height - h) / 2;
      path.moveTo(x + barWidth / 2, y);
      path.lineTo(x + barWidth / 2, y + h);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
