class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String? email;
  final String role;
  final String status;
  final DateTime createdAt;

  bool get isAdmin => role == 'admin' && status == 'approved';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'].toString(),
      email: map['email'] as String?,
      role: map['role'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}
