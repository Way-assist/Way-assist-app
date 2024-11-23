import 'package:wayassist/config/config.dart';
import 'package:wayassist/features/auth/auth.dart';
import 'package:wayassist/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Al continuar, aceptas nuestros términos de servicio y política de privacidad',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: colors.secondary.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
              ),
        ),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          const _CustomSliverAppBar(),
          SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => const AuthForm(),
                  childCount: 1)),
        ],
      ),
    );
  }
}

class _CustomSliverAppBar extends StatelessWidget {
  const _CustomSliverAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: MediaQuery.of(context).size.height * 0.38,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        background: Stack(
          children: [
            Semantics(
              excludeSemantics: true,
              child: Container(
                padding: EdgeInsets.only(top: 35, left: 20, right: 20),
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(120),
                        bottomRight: Radius.circular(0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ]),
                child: SizedBox.expand(
                  child: Image.asset('assets/images/logo2.jpg'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthForm extends ConsumerWidget {
  const AuthForm({super.key});
  void showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).colorScheme;
    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isEmpty) return;
      if (next.errorMessage.isEmpty && next.user == null) return;
      if (next.errorMessage.isEmpty && next.user!.id.isNotEmpty) {
        return showSnackbar(context, 'Bienvenido, nos alegra de verte denuevo.',
            MaterialTheme.success.seed);
      }

      showSnackbar(
          context, next.errorMessage, Theme.of(context).colorScheme.error);
    });

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
        child: Column(
          children: [
            Semantics(
              header: true,
              child: Text(
                'Bienvenido a WayAssist',
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Instrucciones de inicio de sesión: Solo con Google',
              child: Text(
                'Para continuar debes iniciar sesión con tu cuenta de Google',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: colors.secondary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      fontSize: 16,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 150,
              child: CustomFilledButton(
                text: 'Iniciar sesión con Google',
                onPressed: authState.authStatus != AuthStatus.checking
                    ? () {
                        ref.read(authProvider.notifier).loginGoogle();
                      }
                    : null,
                leadingIconSvg: 'assets/icons/google.svg',
                borderColor: colors.secondary.withOpacity(0.2),
                textColor: colors.secondary,
                buttonColor: colors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
