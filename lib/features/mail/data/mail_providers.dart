import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MailFolder { inbox, sent, drafts, trash, archive, spam }

class MailModel {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final MailFolder folder;
  final int date;
  final bool isRead;
  final bool isStarred;
  final List<String> attachments;

  const MailModel({required this.id, required this.from, required this.to, required this.subject, this.body = '', this.folder = MailFolder.inbox, this.date = 0, this.isRead = false, this.isStarred = false, this.attachments = const []});

  MailModel copyWith({MailFolder? folder, bool? isRead, bool? isStarred, List<String>? attachments}) => MailModel(id: id, from: from, to: to, subject: subject, body: body, folder: folder ?? this.folder, date: date, isRead: isRead ?? this.isRead, isStarred: isStarred ?? this.isStarred, attachments: attachments ?? this.attachments);
}

class MailState {
  final List<MailModel> mails;
  final MailFolder currentFolder;
  final bool isLoading;

  const MailState({this.mails = const [], this.currentFolder = MailFolder.inbox, this.isLoading = false});
  MailState copyWith({List<MailModel>? mails, MailFolder? currentFolder, bool? isLoading}) => MailState(mails: mails ?? this.mails, currentFolder: currentFolder ?? this.currentFolder, isLoading: isLoading ?? this.isLoading);
  List<MailModel> get filtered => mails.where((m) => m.folder == currentFolder).toList();
}

class MailNotifier extends StateNotifier<MailState> {
  MailNotifier() : super(const MailState());

  void selectFolder(MailFolder folder) => state = state.copyWith(currentFolder: folder);

  Future<void> sendMail(String to, String subject, String body) async {
    final mail = MailModel(id: DateTime.now().millisecondsSinceEpoch.toString(), from: 'me', to: to, subject: subject, body: body, folder: MailFolder.sent, date: DateTime.now().millisecondsSinceEpoch);
    state = state.copyWith(mails: [...state.mails, mail]);
  }

  Future<void> saveDraft(String to, String subject, String body) async {
    final mail = MailModel(id: DateTime.now().millisecondsSinceEpoch.toString(), from: 'me', to: to, subject: subject, body: body, folder: MailFolder.drafts, date: DateTime.now().millisecondsSinceEpoch);
    state = state.copyWith(mails: [...state.mails, mail]);
  }

  void markRead(String id) {
    state = state.copyWith(mails: state.mails.map((m) => m.id == id ? m.copyWith(isRead: true) : m).toList());
  }

  void toggleStar(String id) {
    state = state.copyWith(mails: state.mails.map((m) => m.id == id ? m.copyWith(isStarred: !m.isStarred) : m).toList());
  }

  void moveToArchive(String id) {
    state = state.copyWith(mails: state.mails.map((m) => m.id == id ? m.copyWith(folder: MailFolder.archive) : m).toList());
  }

  void moveToSpam(String id) {
    state = state.copyWith(mails: state.mails.map((m) => m.id == id ? m.copyWith(folder: MailFolder.spam) : m).toList());
  }

  void moveToTrash(String id) {
    state = state.copyWith(mails: state.mails.map((m) => m.id == id ? m.copyWith(folder: MailFolder.trash) : m).toList());
  }

  void deletePermanently(String id) {
    state = state.copyWith(mails: state.mails.where((m) => m.id != id).toList());
  }
}

final mailProvider = StateNotifierProvider<MailNotifier, MailState>((ref) => MailNotifier());
