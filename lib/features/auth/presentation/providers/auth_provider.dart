import 'package:wayassist/features/main/presentation/providers/bluetooth_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wayassist/features/auth/auth.dart';
import 'package:wayassist/features/shared/shared.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
  newInApp,
  configuredBluetooth,
}

class AuthState {
  final AuthStatus authStatus;
  final User? user;
  final String? id;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking,
    this.user,
    this.id = '',
    this.errorMessage = '',
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage,
    String? id,
  }) =>
      AuthState(
          authStatus: authStatus ?? this.authStatus,
          user: user ?? this.user,
          errorMessage: errorMessage ?? this.errorMessage,
          id: id ?? this.id);
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  late final AuthRepository _authRepository;
  late final KeyValueStorageService _keyValueStorage;
  late final GoogleSignIn googleSignIn;
  @override
  AuthState build() {
    _authRepository = _initializeAuthRepository();
    _keyValueStorage = KeyValueStorageSericeImpl();
    googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'openid',
      ],
      clientId:
          '43975334678-5775fj8kte6befmqbeu4aceldu9kuje2.apps.googleusercontent.com',
      serverClientId:
          '43975334678-ii3ld95dip00lk55i145n7k83bkraeee.apps.googleusercontent.com',
    );
    checkAuthStatus();
    return AuthState();
  }

  AuthRepository _initializeAuthRepository() {
    return AuthRepositoryImpl();
  }

  Future<void> loginGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        if (googleAuth.idToken != null) {
          User user = await _authRepository.loginGoogle(googleAuth.idToken!);

          _setLoggedUser(user);
        } else {}
      }
    } catch (error) {
      print(error);
      logout(errorMessage: 'Error al iniciar sesión con Google');
    }
  }

  Future<void> messageError({String? errorMessage}) async {
    state = state.copyWith(
      errorMessage: errorMessage ?? '',
    );
  }

  Future<void> checkIfNewInstall() async {
    final isFirstTime =
        await _keyValueStorage.getValue<bool>('isFirstTime') ?? true;
    if (isFirstTime) {
      await _keyValueStorage.setKeyValue('isFirstTime', false);
      state = AuthState(authStatus: AuthStatus.newInApp);
    } else {
      checkAuthStatus();
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await _keyValueStorage.getValue<String>('token');
    if (token == null) {
      return logout();
    }

    try {
      final user = await _authRepository.checkAuthStatus(token);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout(errorMessage: e.message);
    } catch (e) {
      logout(errorMessage: 'error no controlado');
    }
  }

  Future<void> logout({String? errorMessage}) async {
    await _keyValueStorage.removeKey('token');
    await _keyValueStorage.removeKey('user');

    state = state.copyWith(
      authStatus: AuthStatus.unauthenticated,
      user: null,
      errorMessage: errorMessage ?? '',
    );
  }

  void configureBluetoothIs(AuthStatus status) {
    state = state.copyWith(
      authStatus: status,
    );
  }

  void _setLoggedUser(User user) async {
    await _keyValueStorage.setKeyValue('token', user.token);
    await _keyValueStorage.setKeyValue('user', user.id);
    final bluetoothConnected =
        await ref.read(bluetoothProvider.notifier).isBluetoothConnected() ??
            false;
    if (user.verify) {
      if (!bluetoothConnected) {
        state = AuthState(
          authStatus: AuthStatus.configuredBluetooth,
          user: user,
          id: user.id,
          errorMessage: '',
        );
      } else {
        state = AuthState(
          authStatus: AuthStatus.authenticated,
          user: user,
          id: user.id,
          errorMessage: '',
        );
      }
    } else {
      state = AuthState(
        authStatus: AuthStatus.unauthenticated,
        user: user,
        id: user.id,
        errorMessage: '',
      );
    }
  }
}
