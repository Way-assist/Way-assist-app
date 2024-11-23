import 'package:wayassist/features/auth/auth.dart';
import 'package:wayassist/features/main/main.dart';
import 'package:wayassist/features/main/presentation/screens/main_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(ref) {
  return GoRouter(
    initialLocation: '/check-permissions',
    redirect: (context, state) {
      final authStatus = ref.watch(authProvider).authStatus;
      final isAuthenticated = authStatus == AuthStatus.authenticated;
      final isChecking = authStatus == AuthStatus.checking;
      final isConfiguredBluetooth =
          authStatus == AuthStatus.configuredBluetooth;

      final isGoingToAuth = state.matchedLocation.contains('/auth');
      final isGoingToMap = state.matchedLocation.contains('/home/map');
      final isGoingToChecking = state.matchedLocation == '/checking';

      if (state.matchedLocation == '/check-permissions') return null;

      if (isChecking) return '/checking';

      if (isConfiguredBluetooth) return '/bluetooth';

      if (!isAuthenticated && !isGoingToAuth && !isGoingToChecking) {
        return '/auth';
      }

      if (isAuthenticated && isGoingToAuth) {
        return '/home';
      }

      if (isAuthenticated &&
          (isGoingToMap || state.matchedLocation == '/home')) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/checking',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
        routes: [
          GoRoute(
            path: 'inicio',
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: 'favoritos',
            builder: (context, state) => const FavoriteView(),
          ),
          GoRoute(
            path: 'ayuda',
            builder: (context, state) => HelpView(),
          ),
          GoRoute(
            path: 'perfil',
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),
      GoRoute(
        path: '/bluetooth',
        builder: (context, state) => BluetoothScreen(),
      ),
      GoRoute(
        path: '/home/map/origin/:origin/destination/:destination/name/:name',
        builder: (context, state) => NavigationScreen(
          origin: state.pathParameters['origin'] ?? '',
          destination: state.pathParameters['destination'] ?? '',
          destinationName: state.pathParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/check-permissions',
        builder: (context, state) => const PermissionsScreen(),
      )
    ],
  );
}
