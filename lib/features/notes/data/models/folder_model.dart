class FolderModel {
  final String id;
  final String userId;
  final String? parentId;
  final String name;
  final int position;
  final int createdAt;
  final int updatedAt;

  const FolderModel({
    required this.id,
    required this.userId,
    this.parentId,
    required this.name,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      parentId: json['parentId'] as String?,
      name: json['name'] as String,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'parentId': parentId,
      'name': name,
      'position': position,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  FolderModel copyWith({String? name, String? parentId}) {
    return FolderModel(
      id: id,
      userId: userId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      position: position,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
