class NoteModel {
  final String id;
  final String userId;
  final String folderId;
  final String title;
  final String contentJson;
  final String contentText;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final int? deletedAt;
  final bool isLocked;
  final String? customCss;
  final int position;
  final int createdAt;
  final int updatedAt;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.folderId,
    required this.title,
    required this.contentJson,
    required this.contentText,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
    this.isLocked = false,
    this.customCss,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      folderId: json['folderId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      contentJson: json['contentJson'] as String? ?? '{"type":"doc","content":[]}',
      contentText: json['contentText'] as String? ?? '',
      isPinned: json['isPinned'] == true || json['isPinned'] == 1,
      isArchived: json['isArchived'] == true || json['isArchived'] == 1,
      isDeleted: json['isDeleted'] == true || json['isDeleted'] == 1,
      deletedAt: json['deletedAt'] as int?,
      isLocked: json['isLocked'] == true || json['isLocked'] == 1,
      customCss: json['customCss'] as String?,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'folderId': folderId,
      'title': title,
      'contentJson': contentJson,
      'contentText': contentText,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'isLocked': isLocked,
      'customCss': customCss,
      'position': position,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  NoteModel copyWith({
    String? title,
    String? contentJson,
    String? contentText,
    String? folderId,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    int? deletedAt,
    String? customCss,
    int? updatedAt,
  }) {
    return NoteModel(
      id: id,
      userId: userId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      contentText: contentText ?? this.contentText,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isLocked: isLocked,
      customCss: customCss ?? this.customCss,
      position: position,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

