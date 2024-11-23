import 'package:wayassist/features/main/presentation/providers/bluetooth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bluetoohh_connection_provider.g.dart';

@Riverpod(keepAlive: true)
class BluetoothConnection extends _$BluetoothConnection {
  @override
  Future<void> build() async {
    final bluetooth = ref.watch(bluetoothProvider);

    ref.listen(bluetoothProvider, (previous, next) {
      if (previous?.isConnected != next.isConnected) {
        print('Estado de conexión cambiado: ${next.isConnected}');
      }
    });

    ref.onDispose(() {
      if (bluetooth.isConnected) {
        ref.read(bluetoothProvider.notifier).disconnect();
      }
    });
  }
}
