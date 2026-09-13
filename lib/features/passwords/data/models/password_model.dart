class PasswordModel {
  final String id;
  final String siteName;
  final String url;
  final String username;
  final String encryptedPassword;
  final String notes;
  final int createdAt;
  final int updatedAt;

  const PasswordModel({
    required this.id,
    required this.siteName,
    this.url = '',
    this.username = '',
    this.encryptedPassword = '',
    this.notes = '',
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    return PasswordModel(
      id: json['id'] as String,
      siteName: json['siteName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      username: json['username'] as String? ?? '',
      encryptedPassword: json['encryptedPassword'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'siteName': siteName,
    'url': url,
    'username': username,
    'encryptedPassword': encryptedPassword,
    'notes': notes,
  };
}
