class User {
  final String id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String dni;
  final String token;
  final bool verify;
  final bool isActive;
  final List<String> roles;
  final DateTime birthday;
  final DateTime createdAt;

  User({
    required this.id,
    required this.isActive,
    required this.email,
    required this.name,
    required this.lastname,
    required this.token,
    required this.phone,
    required this.dni,
    required this.verify,
    required this.roles,
    required this.birthday,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? lastname,
    String? token,
    String? phone,
    String? dni,
    bool? verify,
    bool? isActive,
    List<String>? roles,
    DateTime? birthday,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      token: token ?? this.token,
      phone: phone ?? this.phone,
      dni: dni ?? this.dni,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      lastname: lastname ?? this.lastname,
      verify: verify ?? this.verify,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      birthday: birthday ?? this.birthday,
    );
  }
}
