class TotpModel {
  final String id;
  final String name;
  final String issuer;
  final String secret;
  final String algorithm;
  final int digits;
  final int period;
  final int createdAt;

  const TotpModel({
    required this.id,
    required this.name,
    this.issuer = '',
    required this.secret,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    this.createdAt = 0,
  });

  factory TotpModel.fromJson(Map<String, dynamic> json) {
    return TotpModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'SHA1',
      digits: json['digits'] as int? ?? 6,
      period: json['period'] as int? ?? 30,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'issuer': issuer,
    'secret': secret,
    'algorithm': algorithm,
    'digits': digits,
    'period': period,
  };
}
