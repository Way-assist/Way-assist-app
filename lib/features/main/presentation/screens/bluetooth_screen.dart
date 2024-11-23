import 'package:wayassist/features/auth/auth.dart';
import 'package:wayassist/features/main/presentation/providers/bluetooth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class BluetoothScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothState = ref.watch(bluetoothProvider);
    final bluetooth = ref.read(bluetoothProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => bluetooth.loadDevices(),
          ),
          if (bluetoothState.isConnected)
            IconButton(
              icon: Icon(Icons.maps_home_work),
              onPressed: () {
                ref
                    .read(authProvider.notifier)
                    .configureBluetoothIs(AuthStatus.authenticated);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (!bluetoothState.isConnected)
            Expanded(
              child: ListView.builder(
                itemCount: bluetoothState.devices.length,
                itemBuilder: (context, index) {
                  final device = bluetoothState.devices[index];
                  return ListTile(
                    title: Text(device.name ?? "Desconocido"),
                    subtitle: Semantics(
                        excludeSemantics: true, child: Text(device.address)),
                    trailing: ElevatedButton(
                      onPressed: () => bluetooth.connectToDevice(device),
                      child: Text('Conectar'),
                    ),
                  );
                },
              ),
            ),
          if (bluetoothState.isConnected) ...[
            Expanded(
              child: ListView.builder(
                itemCount: bluetoothState.messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(bluetoothState.messages[index]),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          bluetooth.sendMessage(value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enviar mensaje',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
