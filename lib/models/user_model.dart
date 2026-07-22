class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final DateTime createdAt;
  final List<String> bookmarkedLocationIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'Student',
    required this.createdAt,
    this.bookmarkedLocationIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'bookmarkedLocationIds': bookmarkedLocationIds,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Campus User',
      role: map['role'] ?? 'Student',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      bookmarkedLocationIds: List<String>.from(map['bookmarkedLocationIds'] ?? []),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    DateTime? createdAt,
    List<String>? bookmarkedLocationIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      bookmarkedLocationIds: bookmarkedLocationIds ?? this.bookmarkedLocationIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, role: $role)';
  }
}
