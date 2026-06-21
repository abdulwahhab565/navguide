class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // Student, Visitor, Staff
  final DateTime createdAt;
  final List<String> bookmarkedLocationIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
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
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'Visitor',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
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
}
