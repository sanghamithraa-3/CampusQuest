class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.rollNumber,
    this.department,
    this.yearOfStudy,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? rollNumber;
  final String? department;
  final int? yearOfStudy;
  final bool isActive;

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id']).toString(),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      rollNumber: json['rollNumber'] as String?,
      department: json['department'] as String?,
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
