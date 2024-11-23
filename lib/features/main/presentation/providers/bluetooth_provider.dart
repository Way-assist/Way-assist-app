import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:wayassist/config/router/app_router.dart';
import 'package:wayassist/features/auth/auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'bluetooth_provider.g.dart';

class BluetoothState {
  final List<BluetoothDevice> devices;
  final List<String> messages;
  final bool isConnected;
  final bool isLoading;
  final String messageError;
  final BluetoothConnection? connection;

  BluetoothState({
    this.devices = const [],
    this.messages = const [],
    this.isConnected = false,
    this.isLoading = false,
    this.messageError = '',
    this.connection,
  });

  BluetoothState copyWith({
    List<BluetoothDevice>? devices,
    List<String>? messages,
    bool? isConnected,
    bool? isLoading,
    String? messageError,
    BluetoothConnection? connection,
  }) {
    return BluetoothState(
      devices: devices ?? this.devices,
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      messageError: messageError ?? this.messageError,
      connection: connection ?? this.connection,
    );
  }
}

@Riverpod(keepAlive: true)
class Bluetooth extends _$Bluetooth {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  StreamSubscription? _messageSubscription;
  Timer? _connectionCheckTimer;

  @override
  BluetoothState build() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (state.isConnected) {
        print('Dispositivo conectado: ${state.connection?.isConnected}');
      } else {
        print('No hay dispositivo conectado');
      }
    });

    ref.onDispose(() {
      _connectionCheckTimer?.cancel();
    });

    Future.microtask(() async {
      await loadDevices();
      await _loadSavedDevice();
    });
    return BluetoothState();
  }

  Future<bool> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.camera,
        Permission.location,
        Permission.microphone,
        Permission.sms,
        Permission.phone,
      ];
      bool allGranted = true;

      for (var permission in permissions) {
        if (!await permission.isGranted) {
          final status = await permission.request();
          if (!status.isGranted) {
            state = state.copyWith(
              messageError: 'Permiso no otorgado: $permission',
            );
            allGranted = false;
            break;
          }
        }
      }

      if (allGranted) {
        ref.read(appRouterProvider).go('/auth');
      }
    }
    return true;
  }

  Future<void> _loadSavedDevice() async {
    state = state.copyWith(isLoading: true);
    try {
      if (await _checkBluetoothPermissions()) {
        final prefs = await SharedPreferences.getInstance();
        final savedAddress = prefs.getString('raspberryAddress');
        if (savedAddress != null) {
          final devices = await _bluetooth.getBondedDevices();
          final device = devices.firstWhere(
            (d) => d.address == savedAddress,
            orElse: () => throw Exception('Dispositivo no encontrado'),
          );
          print('Conectando a dispositivo guardado: $device');
          await connectToDevice(device);
        }
      }
    } catch (e) {
      state = state.copyWith(messageError: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true);
    try {
      if (await _checkBluetoothPermissions()) {
        final devices = await _bluetooth.getBondedDevices();
        state = state.copyWith(devices: devices);
      }
    } catch (e) {
      state = state.copyWith(messageError: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (state.isConnected && state.connection != null) {
      await disconnect();
    }

    state = state.copyWith(isLoading: true);
    try {
      if (await _checkBluetoothPermissions()) {
        final connection = await BluetoothConnection.toAddress(device.address);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('raspberryAddress', device.address);

        _startListening(connection);

        state = state.copyWith(
          connection: connection,
          isConnected: true,
        );
        ref
            .read(authProvider.notifier)
            .configureBluetoothIs(AuthStatus.authenticated);
      }
    } catch (e) {
      state =
          state.copyWith(messageError: "Error al conectar: ${e.toString()}");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void _startListening(BluetoothConnection connection) {
    _messageSubscription = connection.input?.listen(
      (Uint8List data) {
        try {
          String message = utf8.decode(data);
          state = state.copyWith(
            messages: [...state.messages, "Raspberry: $message"],
          );
        } catch (e) {
          String hexData = data
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(' ');
          state = state.copyWith(
            messages: [...state.messages, "Raspberry (hex): $hexData"],
          );
        }
      },
      onError: (error) {
        state = state.copyWith(
          messageError: "Error en la conexión: ${error.toString()}",
          isConnected: false,
        );
        disconnect();
      },
    );
  }

  Future<void> sendMessage(String message) async {
    if (state.connection?.isConnected ?? false) {
      try {
        List<int> bytes = utf8.encode(message + '\n');
        Uint8List data = Uint8List.fromList(bytes);

        state.connection!.output.add(data);
        await state.connection!.output.allSent;

        state = state.copyWith(
          messages: [...state.messages, "Tú: $message"],
        );
      } catch (e) {
        state = state.copyWith(messageError: e.toString());
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await state.connection?.close();
      _messageSubscription?.cancel();
      state = state.copyWith(
        isConnected: false,
        connection: null,
        messages: [],
      );
    } catch (e) {
      state =
          state.copyWith(messageError: "Error al desconectar: ${e.toString()}");
    }
  }

  Future<bool> isBluetoothConnected() async {
    return state.isConnected;
  }

  Future<void> disconnectAndForget() async {
    state = state.copyWith(isLoading: true);
    try {
      await _messageSubscription?.cancel();

      await state.connection?.close();
      ref
          .read(authProvider.notifier)
          .configureBluetoothIs(AuthStatus.configuredBluetooth);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('raspberryAddress');

      state = state.copyWith(
        isConnected: false,
        connection: null,
        messages: [],
        messageError: '',
      );
    } catch (e) {
      state = state.copyWith(messageError: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void dispose() {
    _connectionCheckTimer?.cancel();
    _messageSubscription?.cancel();
    disconnect();
  }
}
