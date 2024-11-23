import 'package:wayassist/features/auth/auth.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDataSouce dataSource;
  AuthRepositoryImpl({AuthDataSouce? dataSource})
      : dataSource = dataSource ?? AuthDatasourceImpl();

  @override
  Future<User> checkAuthStatus(String token) {
    return dataSource.checkAuthStatus(token);
  }

  @override
  Future<User> loginGoogle(String googleToken) {
    return dataSource.loginGoogle(googleToken);
  }
}
