import 'package:wayassist/features/auth/auth.dart';

class UserMapper {
  static User userJsonToEntity(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        lastname: json['lastname'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        dni: json['dni'] ?? '',
        isActive: json['isActive'] ?? false,
        verify: json['verify'] ?? false,
        birthday: DateTime.parse(json['birthday']) ?? DateTime.now(),
        roles: List<String>.from(json['roles'].map((x) => x)) ?? [],
        token: json['token'] ?? '',
        createdAt: DateTime.parse(json['createdAt']) ?? DateTime.now(),
      );
}
