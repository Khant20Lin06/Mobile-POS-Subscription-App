import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle runtime device permissions for Thermal Printers and Barcode Scan Guns
class HardwarePermissionService {
  /// Request Bluetooth permissions (Scan & Connect on Android 12+, Bluetooth & Location on Android 11-)
  static Future<bool> requestBluetoothPermissions() async {
    // Desktop (Windows, macOS, Linux) and Web do not require Android runtime permission prompts
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetooth,
          Permission.locationWhenInUse,
        ].request();

        final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
        final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
        final legacyGranted = statuses[Permission.bluetooth]?.isGranted ?? false;

        return scanGranted || connectGranted || legacyGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.request();
        return status.isGranted;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Check current Bluetooth permission status
  static Future<bool> hasBluetoothPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final scan = await Permission.bluetoothScan.status;
        final connect = await Permission.bluetoothConnect.status;
        final legacy = await Permission.bluetooth.status;
        return scan.isGranted || connect.isGranted || legacy.isGranted;
      } else if (Platform.isIOS) {
        return await Permission.bluetooth.isGranted;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Request Camera permission for camera barcode scanner
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return true;
    }

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Open application system settings if permanently denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
