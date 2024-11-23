import '../domain.dart';

abstract class AuthDataSouce {
  Future<User> loginGoogle(String googleToken);
  Future<User> checkAuthStatus(String token);
}
