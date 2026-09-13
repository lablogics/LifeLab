class BookmarkModel {
  final String id;
  final String url;
  final String title;
  final String description;
  final int createdAt;
  final int updatedAt;

  const BookmarkModel({
    required this.id,
    required this.url,
    this.title = '',
    this.description = '',
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'description': description,
  };
}
