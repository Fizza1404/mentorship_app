class User {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String? skills;
  final String? experience;
  final DateTime createdAt;

  User({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.skills,
    this.experience,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      phone: json['phone'] ?? '',
      skills: json['skills'],
      experience: json['experience'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'skills': skills,
      'experience': experience,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}