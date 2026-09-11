import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hardware permission service handling runtime OS device permissions
class HardwarePermissionService {
  static const MethodChannel _channel = MethodChannel('com.khantlin.mobile_pos/hardware');

  /// Request Bluetooth permissions (Scan & Connect on Android)
  static Future<bool> requestBluetoothPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('requestBluetoothPermissions');
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Check current Bluetooth permission status
  static Future<bool> hasBluetoothPermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('checkBluetoothPermissions');
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Request Camera permission for camera barcode scanner
  static Future<bool> requestCameraPermission() async {
    // Camera permissions are requested automatically by mobile_scanner / Camera plugin
    return true;
  }

  /// Open application system settings if permanently denied
  static Future<void> openSettings() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }
}
