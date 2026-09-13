class TagModel {
  final String id;
  final String name;
  final String color;
  final int? createdAt;
  final int? noteCount;

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
    this.createdAt,
    this.noteCount,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? 'gray',
      createdAt: json['createdAt'] as int?,
      noteCount: json['noteCount'] is int ? json['noteCount'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  TagModel copyWith({String? name, String? color}) {
    return TagModel(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      noteCount: noteCount,
    );
  }
}
