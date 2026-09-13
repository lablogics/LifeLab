class TodoModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool completed;
  final String? parentId;
  final String? noteId;
  final String priority;
  final String? dueDate;
  final String? reminderType;
  final String? reminderDate;
  final String? recurringPattern;
  final int position;
  final int createdAt;
  final int updatedAt;

  const TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.completed = false,
    this.parentId,
    this.noteId,
    this.priority = 'none',
    this.dueDate,
    this.reminderType,
    this.reminderDate,
    this.recurringPattern,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] == true || json['completed'] == 1,
      parentId: json['parentId'] as String?,
      noteId: json['noteId'] as String?,
      priority: json['priority'] as String? ?? 'none',
      dueDate: json['dueDate'] as String?,
      reminderType: json['reminderType'] as String?,
      reminderDate: json['reminderDate'] as String?,
      recurringPattern: json['recurringPattern'] as String?,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      if (description != null) 'description': description,
      'completed': completed,
      if (parentId != null) 'parentId': parentId,
      if (noteId != null) 'noteId': noteId,
      'priority': priority,
      if (dueDate != null) 'dueDate': dueDate,
      if (reminderType != null) 'reminderType': reminderType,
      if (reminderDate != null) 'reminderDate': reminderDate,
      if (recurringPattern != null) 'recurringPattern': recurringPattern,
      'position': position,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  TodoModel copyWith({
    String? title,
    String? description,
    bool? completed,
    String? priority,
    String? dueDate,
    String? recurringPattern,
    int? position,
    int? updatedAt,
  }) {
    return TodoModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      parentId: parentId,
      noteId: noteId,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      reminderType: reminderType,
      reminderDate: reminderDate,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
