import 'package:wayassist/features/auth/auth.dart';
import 'package:wayassist/features/main/presentation/providers/bluetooth_provider.dart';
import 'package:wayassist/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Configuración',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: colors.surface)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: 60,
          child: CustomFilledButton(
            text: 'Cerrar sesión',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            leadingIconSvg: 'assets/icons/exit.svg',
            borderColor: colors.secondary.withOpacity(0.2),
            textColor: colors.secondary,
            buttonColor: colors.surface,
            iconColor: colors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                '${user!.name} ${user.lastname}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(LineIcons.user),
                  title: const Text('Personalizar Perfil'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Acción al presionar "Personalizar Perfil"
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(LineIcons.bluetooth2),
                  title: const Text('Conexión Bluetooth'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => ref
                      .read(bluetoothProvider.notifier)
                      .disconnectAndForget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
