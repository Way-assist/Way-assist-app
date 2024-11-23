import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'package:go_router/go_router.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    // Determinar si el dispositivo usa Android 12 o superior
    bool isAndroid12OrAbove = await _isAndroid12OrAbove();

    final permissions = [
      Permission.camera,
      Permission.location,
      Permission.microphone,
      Permission.sms,
      Permission.phone,
      if (isAndroid12OrAbove) ...[
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ] else ...[
        Permission.bluetooth,
      ],
    ];

    bool allGranted = true;
    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    if (allGranted && mounted) {
      context.go('/auth');
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isChecking = true);

    final permissions = [
      Permission.camera,
      Permission.location,
      Permission.microphone,
      Permission.sms,
      Permission.phone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetooth,
    ];

    final statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted && mounted) {
      context.go('/auth');
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<bool> _isAndroid12OrAbove() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 31;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Permisos Necesarios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Para usar la aplicación necesitamos acceso a:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _PermissionItem(
                icon: Icons.camera_alt_outlined,
                text: 'Cámara',
              ),
              const _PermissionItem(
                icon: Icons.location_on_outlined,
                text: 'Ubicación',
              ),
              const _PermissionItem(
                icon: Icons.mic_outlined,
                text: 'Micrófono',
              ),
              const _PermissionItem(
                icon: Icons.bluetooth,
                text: 'Bluetooth',
              ),
              const _PermissionItem(
                icon: Icons.phone,
                text: 'Teléfono',
              ),
              const _PermissionItem(
                icon: Icons.sms,
                text: 'Mensajes',
              ),
              const SizedBox(height: 32),
              if (_isChecking)
                const Center(child: CircularProgressIndicator())
              else ...[
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _requestPermissions,
                    child: const Text('Conceder permisos'),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: AppSettings.openAppSettings,
                    child: Text('Abrir configuraciones'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PermissionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
