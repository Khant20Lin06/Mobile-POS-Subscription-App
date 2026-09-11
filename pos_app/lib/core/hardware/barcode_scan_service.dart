import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for Barcode Scan Gun (USB Laser / Bluetooth HID / Camera)
class ScanGunConfig {
  final String scannerType; // 'usb_hid', 'bluetooth_hid', 'camera'
  final bool autoAddToCart;
  final bool soundFeedback;
  final bool vibrateFeedback;
  final int minBarcodeLength;
  final int maxKeystrokeDelayMs;

  const ScanGunConfig({
    this.scannerType = 'usb_hid',
    this.autoAddToCart = true,
    this.soundFeedback = true,
    this.vibrateFeedback = true,
    this.minBarcodeLength = 3,
    this.maxKeystrokeDelayMs = 90,
  });

  ScanGunConfig copyWith({
    String? scannerType,
    bool? autoAddToCart,
    bool? soundFeedback,
    bool? vibrateFeedback,
    int? minBarcodeLength,
    int? maxKeystrokeDelayMs,
  }) {
    return ScanGunConfig(
      scannerType: scannerType ?? this.scannerType,
      autoAddToCart: autoAddToCart ?? this.autoAddToCart,
      soundFeedback: soundFeedback ?? this.soundFeedback,
      vibrateFeedback: vibrateFeedback ?? this.vibrateFeedback,
      minBarcodeLength: minBarcodeLength ?? this.minBarcodeLength,
      maxKeystrokeDelayMs: maxKeystrokeDelayMs ?? this.maxKeystrokeDelayMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'scannerType': scannerType,
        'autoAddToCart': autoAddToCart,
        'soundFeedback': soundFeedback,
        'vibrateFeedback': vibrateFeedback,
        'minBarcodeLength': minBarcodeLength,
        'maxKeystrokeDelayMs': maxKeystrokeDelayMs,
      };

  factory ScanGunConfig.fromJson(Map<String, dynamic> json) {
    return ScanGunConfig(
      scannerType: json['scannerType'] as String? ?? 'usb_hid',
      autoAddToCart: json['autoAddToCart'] as bool? ?? true,
      soundFeedback: json['soundFeedback'] as bool? ?? true,
      vibrateFeedback: json['vibrateFeedback'] as bool? ?? true,
      minBarcodeLength: (json['minBarcodeLength'] as num?)?.toInt() ?? 3,
      maxKeystrokeDelayMs: (json['maxKeystrokeDelayMs'] as num?)?.toInt() ?? 90,
    );
  }
}

/// StateNotifier to persist Scan Gun settings in SharedPreferences
class ScanGunConfigNotifier extends StateNotifier<ScanGunConfig> {
  static const _storageKey = 'dot_pos_scangun_config';

  ScanGunConfigNotifier() : super(const ScanGunConfig()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = ScanGunConfig.fromJson(map);
      }
    } catch (_) {}
  }

  Future<void> updateConfig(ScanGunConfig newConfig) async {
    state = newConfig;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newConfig.toJson()));
    } catch (_) {}
  }
}

final scanGunConfigProvider = StateNotifierProvider<ScanGunConfigNotifier, ScanGunConfig>((ref) {
  return ScanGunConfigNotifier();
});

/// Global Barcode Scan Gun Listener for USB and Bluetooth HID Keyboards
class BarcodeScanGunListener {
  final List<String> _buffer = [];
  DateTime? _lastKeystrokeTime;
  Function(String barcode)? _onScanCallback;
  bool _isListening = false;
  final ScanGunConfig config;

  BarcodeScanGunListener({this.config = const ScanGunConfig()});

  bool get isListening => _isListening;

  /// Start listening for hardware barcode scanner events
  void start(Function(String barcode) onScan) {
    if (_isListening) return;
    _onScanCallback = onScan;
    _buffer.clear();
    _lastKeystrokeTime = null;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _isListening = true;
  }

  /// Stop listening for hardware barcode scanner events
  void stop() {
    if (!_isListening) return;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _buffer.clear();
    _onScanCallback = null;
    _isListening = false;
  }

  /// Handles raw hardware key events from USB and Bluetooth barcode guns
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    final logicalKey = event.logicalKey;

    // Check for Enter key which signifies end of barcode scan
    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_buffer.length >= config.minBarcodeLength) {
        final barcode = _buffer.join().trim();
        _buffer.clear();
        _lastKeystrokeTime = null;

        if (barcode.isNotEmpty) {
          if (config.soundFeedback) {
            playSuccessBeep();
          }
          if (config.vibrateFeedback) {
            HapticFeedback.mediumImpact();
          }
          _onScanCallback?.call(barcode);
          return true; // Consume enter so it doesn't trigger unexpected UI submit
        }
      }
      _buffer.clear();
      _lastKeystrokeTime = null;
      return false;
    }

    // Reset buffer if delay exceeds threshold (human typed slowly or scanner paused)
    if (_lastKeystrokeTime != null) {
      final delay = now.difference(_lastKeystrokeTime!).inMilliseconds;
      if (delay > config.maxKeystrokeDelayMs && _buffer.isNotEmpty) {
        // If slow typing detected, clear buffer so manual keyboard entry is not confused
        _buffer.clear();
      }
    }

    // Collect printable alphanumeric and symbol characters
    final char = event.character;
    if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32) {
      _buffer.add(char);
      _lastKeystrokeTime = now;
    }

    return false;
  }

  /// Plays POS scanner success beep
  static void playSuccessBeep() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Plays POS scanner error sound
  static void playErrorBeep() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
