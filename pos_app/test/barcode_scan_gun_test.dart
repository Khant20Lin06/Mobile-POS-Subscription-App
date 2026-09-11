import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/hardware/barcode_scan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Barcode Scan Gun Unit Tests', () {
    test('ScanGunConfig default initialization and JSON serialization', () {
      const config = ScanGunConfig(
        scannerType: 'bluetooth_hid',
        autoAddToCart: false,
        soundFeedback: true,
        vibrateFeedback: false,
        minBarcodeLength: 5,
        maxKeystrokeDelayMs: 120,
      );

      final json = config.toJson();
      expect(json['scannerType'], 'bluetooth_hid');
      expect(json['autoAddToCart'], false);
      expect(json['soundFeedback'], true);
      expect(json['vibrateFeedback'], false);
      expect(json['minBarcodeLength'], 5);
      expect(json['maxKeystrokeDelayMs'], 120);

      final fromJson = ScanGunConfig.fromJson(json);
      expect(fromJson.scannerType, config.scannerType);
      expect(fromJson.autoAddToCart, config.autoAddToCart);
      expect(fromJson.soundFeedback, config.soundFeedback);
      expect(fromJson.vibrateFeedback, config.vibrateFeedback);
      expect(fromJson.minBarcodeLength, config.minBarcodeLength);
      expect(fromJson.maxKeystrokeDelayMs, config.maxKeystrokeDelayMs);
    });

    test('BarcodeScanGunListener starts and stops listening cleanly', () {
      final listener = BarcodeScanGunListener();
      expect(listener.isListening, isFalse);

      String? captured;
      listener.start((barcode) {
        captured = barcode;
      });
      expect(listener.isListening, isTrue);

      listener.stop();
      expect(listener.isListening, isFalse);
      expect(captured, isNull);
    });

    test('BarcodeScanGunListener sound feedback calls execute safely', () {
      expect(() => BarcodeScanGunListener.playSuccessBeep(), returnsNormally);
      expect(() => BarcodeScanGunListener.playErrorBeep(), returnsNormally);
    });
  });
}
