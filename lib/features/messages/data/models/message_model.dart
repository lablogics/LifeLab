class MessageModel {
  final String id;
  final String contactId;
  final String direction; // 'inbound' or 'outbound'
  final String content;
  final int sentAt;
  final int createdAt;

  const MessageModel({
    required this.id,
    required this.contactId,
    required this.direction,
    required this.content,
    this.sentAt = 0,
    this.createdAt = 0,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      direction: json['direction'] as String? ?? 'inbound',
      content: json['content'] as String? ?? '',
      sentAt: json['sentAt'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'direction': direction,
    'content': content,
    'sentAt': sentAt,
  };
}
