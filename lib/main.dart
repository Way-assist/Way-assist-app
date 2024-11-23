import 'package:wayassist/features/main/presentation/providers/bluetoohh_connection_provider.dart';
import 'package:flutter/material.dart';
import 'package:wayassist/config/config.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wayassist/config/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Enviroment.initEnviroment();

  runApp(
    const ProviderScope(
      child: InitApp(),
    ),
  );
}

class InitApp extends ConsumerWidget {
  const InitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(bluetoothConnectionProvider);

    return const MyApp();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF08a8dd),
      systemNavigationBarColor: Theme.of(context).colorScheme.onSurface,
    ));

    final appRouter = ref.watch(appRouterProvider);
    TextTheme textTheme = createTextTheme(context, "Manrope", "Roboto");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      title: 'Way Assist',
      theme: theme.light(),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
