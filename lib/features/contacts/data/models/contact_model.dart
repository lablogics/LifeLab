class ContactModel {
  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String phone;
  final String company;
  final String jobTitle;
  final String birthday;
  final String address;
  final String notes;
  final String avatarUrl;
  final bool isFavorite;
  final int createdAt;
  final int updatedAt;

  const ContactModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.displayName = '',
    this.email = '',
    this.phone = '',
    this.company = '',
    this.jobTitle = '',
    this.birthday = '',
    this.address = '',
    this.notes = '',
    this.avatarUrl = '',
    this.isFavorite = false,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isFavorite: json['isFavorite'] == true || json['isFavorite'] == 1,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'company': company,
    'jobTitle': jobTitle,
    'birthday': birthday,
    'address': address,
    'notes': notes,
  };

  ContactModel copyWith({
    String? firstName, String? lastName, String? displayName,
    String? email, String? phone, String? company,
    String? jobTitle, String? birthday, String? address,
    String? notes, String? avatarUrl, bool? isFavorite,
    int? createdAt, int? updatedAt,
  }) {
    return ContactModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      birthday: birthday ?? this.birthday,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
