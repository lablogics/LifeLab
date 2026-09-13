class ProjectModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String color;
  final String status;
  final String? startDate;
  final String? endDate;
  final int position;
  final int createdAt;
  final int updatedAt;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.color = 'blue',
    this.status = 'active',
    this.startDate,
    this.endDate,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? 'blue',
      status: json['status'] as String? ?? 'active',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'userId': userId, 'name': name, 'description': description,
    'color': color, 'status': status, 'position': position,
    'createdAt': createdAt, 'updatedAt': updatedAt,
  };

  ProjectModel copyWith({
    String? name, String? description, String? color, String? status,
    String? startDate, String? endDate,
  }) {
    return ProjectModel(
      id: id, userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      position: position, createdAt: createdAt, updatedAt: updatedAt,
    );
  }
}

class BoardModel {
  final String id;
  final String userId;
  final String projectId;
  final String name;
  final int position;
  final int createdAt;
  final int updatedAt;

  const BoardModel({
    required this.id, required this.userId, required this.projectId,
    required this.name, required this.position,
    required this.createdAt, required this.updatedAt,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}

class BoardColumnModel {
  final String id;
  final String boardId;
  final String name;
  final int position;
  final String? color;
  final List<CardModel> cards;

  const BoardColumnModel({
    required this.id, required this.boardId, required this.name,
    required this.position, this.color, this.cards = const [],
  });

  factory BoardColumnModel.fromJson(Map<String, dynamic> json) {
    return BoardColumnModel(
      id: json['id'] as String,
      boardId: json['boardId'] as String,
      name: json['name'] as String,
      position: json['position'] as int? ?? 0,
      color: json['color'] as String?,
      cards: (json['cards'] as List?)?.map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class CardModel {
  final String id;
  final String boardId;
  final String columnId;
  final String title;
  final String description;
  final String? noteId;
  final int position;
  final int createdAt;
  final int updatedAt;

  const CardModel({
    required this.id, required this.boardId, required this.columnId,
    required this.title, this.description = '', this.noteId,
    required this.position, required this.createdAt, required this.updatedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      boardId: json['boardId'] as String,
      columnId: json['columnId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      noteId: json['noteId'] as String?,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  CardModel copyWith({String? title, String? columnId, int? position}) {
    return CardModel(
      id: id, boardId: boardId,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description, noteId: noteId,
      position: position ?? this.position,
      createdAt: createdAt, updatedAt: updatedAt,
    );
  }
}
