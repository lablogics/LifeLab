class ContactModel {
  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String phone;
  final String company;
  final String notes;
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
    this.notes = '',
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
      notes: json['notes'] as String? ?? '',
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
    'notes': notes,
  };
}
