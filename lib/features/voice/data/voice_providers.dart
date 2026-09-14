import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceNote {
  final String id;
  final String title;
  final int duration; // seconds
  final int createdAt;
  final List<String> tags;
  const VoiceNote({required this.id, required this.title, this.duration = 0, this.createdAt = 0, this.tags = const []});
}

class VoiceState {
  final List<VoiceNote> notes;
  final bool isRecording;
  const VoiceState({this.notes = const [], this.isRecording = false});
  VoiceState copyWith({List<VoiceNote>? notes, bool? isRecording}) => VoiceState(notes: notes ?? this.notes, isRecording: isRecording ?? this.isRecording);
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(const VoiceState());

  void startRecording() => state = state.copyWith(isRecording: true);
  void stopRecording() {
    final note = VoiceNote(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Voice Note ${state.notes.length + 1}', duration: 10, createdAt: DateTime.now().millisecondsSinceEpoch);
    state = state.copyWith(notes: [...state.notes, note], isRecording: false);
  }
  void deleteNote(String id) => state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());

  void renameNote(String id, String newTitle) {
    state = state.copyWith(notes: state.notes.map((n) => n.id == id ? VoiceNote(id: n.id, title: newTitle, duration: n.duration, createdAt: n.createdAt, tags: n.tags) : n).toList());
  }

  void setTags(String id, List<String> tags) {
    state = state.copyWith(notes: state.notes.map((n) => n.id == id ? VoiceNote(id: n.id, title: n.title, duration: n.duration, createdAt: n.createdAt, tags: tags) : n).toList());
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) => VoiceNotifier());
