import '../domain.dart';

abstract class AuthRepository {
  Future<User> loginGoogle(String googleToken);
  Future<User> checkAuthStatus(String token);
}
