import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/voice_providers.dart';

class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Notes')),
      body: state.notes.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mic_none, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No voice notes yet')]))
          : ListView.builder(itemCount: state.notes.length, itemBuilder: (ctx, i) {
              final note = state.notes[i];
              return ListTile(leading: const Icon(Icons.mic), title: Text(note.title), subtitle: Text('${note.duration}s'), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => notifier.deleteNote(note.id)));
            }),
      floatingActionButton: FloatingActionButton(onPressed: () { if (state.isRecording) { notifier.stopRecording(); } else { notifier.startRecording(); } }, backgroundColor: state.isRecording ? Colors.red : null, child: Icon(state.isRecording ? Icons.stop : Icons.mic)),
    );
  }
}
