

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String direction;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.direction,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';
  bool get isManager => role.toLowerCase() == 'manager';
  bool get isRegularUser => !isAdmin && !isSuperAdmin && !isManager;

  factory User.empty() {
    return User(
      id: -1,
      name: 'Unknown User',
      email: 'No email',
      role: '',
      direction: '',
      avatarUrl: null,
      createdAt: DateTime.now(), // Default to current time instead of null
    );
  }

  factory User.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return User.empty();
    }
    
    return User(
      id: json['id'] as int? ?? -1,
      name: json['name'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? 'No email',
      role: (json['role'] as String? ?? '').toLowerCase(),
      direction: json['direction'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'direction': direction,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? direction,
    String? avatarUrl,
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    direction: direction ?? this.direction,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  String toString() => 'User($id, "$name", "$email", "$role")';

  @override
  bool operator ==(Object other) => identical(this, other) || 
      (other is User &&
       runtimeType == other.runtimeType &&
       id == other.id &&
       name == other.name &&
       email == other.email &&
       role == other.role);

  @override
  int get hashCode => Object.hash(id, name, email, role);
}