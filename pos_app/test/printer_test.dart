import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/hardware/thermal_receipt_service.dart';

void main() {
  group('Hardware Printer & ESC/POS Unit Tests', () {
    test('PrinterConfig default initialization and JSON serialization', () {
      const config = PrinterConfig(
        connectionType: 'wifi',
        paperSize: '80mm',
        ipAddress: '192.168.1.200',
        port: 9100,
        selectedPrinterName: 'Kitchen-Printer',
        autoPrint: false,
      );

      final json = config.toJson();
      expect(json['connectionType'], 'wifi');
      expect(json['paperSize'], '80mm');
      expect(json['ipAddress'], '192.168.1.200');
      expect(json['port'], 9100);
      expect(json['selectedPrinterName'], 'Kitchen-Printer');
      expect(json['autoPrint'], false);

      final reconstructed = PrinterConfig.fromJson(json);
      expect(reconstructed.connectionType, config.connectionType);
      expect(reconstructed.paperSize, config.paperSize);
      expect(reconstructed.ipAddress, config.ipAddress);
      expect(reconstructed.port, config.port);
      expect(reconstructed.selectedPrinterName, config.selectedPrinterName);
      expect(reconstructed.autoPrint, config.autoPrint);
    });

    test('EscPosBuilder generates proper ESC/POS binary commands', () {
      final builder = EscPosBuilder();
      builder.init();
      builder.alignCenter();
      builder.bold(true);
      builder.writeln('TEST RECEIPT');
      builder.bold(false);
      builder.cut();

      final bytes = builder.bytes;
      expect(bytes, isNotEmpty);
      // ESC @ (0x1B, 0x40)
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
      // ESC a 1 (0x1B, 0x61, 0x01)
      expect(bytes[2], 0x1B);
      expect(bytes[3], 0x61);
      expect(bytes[4], 0x01);
      // Ends with cut GS V A 16 (0x1D, 0x56, 0x41, 0x10)
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x41, 0x10]);
    });

    test('EscPosBuilder builds full receipt with items and totals', () {
      final receipt = ReceiptData(
        shopName: 'DOT Store',
        orderNumber: 'ORD-999',
        orderDate: DateTime(2026, 9, 12, 12, 0),
        cashierName: 'Ko Khant',
        items: const [
          ReceiptLineItem(name: 'Espresso', quantity: 2, unitPrice: 2500, subtotal: 5000),
        ],
        subtotal: 5000,
        totalAmount: 5000,
        tenderAmount: 5000,
        changeDue: 0,
        paymentMethod: 'CASH',
      );

      final builder = EscPosBuilder();
      final bytes = builder.buildReceipt(receipt, width: 32);

      expect(bytes, isNotEmpty);
      expect(bytes.first, 0x1B); // ESC
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x41, 0x10]); // Cut
    });

    test('BluetoothPrinterDevice model serialization and instantiation', () {
      final device = BluetoothPrinterDevice.fromMap({
        'name': 'POS-58-Bluetooth',
        'address': '66:22:33:44:55:66',
        'type': 1,
      });

      expect(device.name, 'POS-58-Bluetooth');
      expect(device.address, '66:22:33:44:55:66');
      expect(device.type, 1);
    });

    test('SystemThermalPrinterService getFormat respects 58mm and 80mm roll width', () {
      final format58 = SystemThermalPrinterService.getFormat('58mm');
      final format80 = SystemThermalPrinterService.getFormat('80mm');

      expect(format58.width, lessThan(format80.width));
      expect(format58.width, closeTo(58 * 72 / 25.4, 0.5));
      expect(format80.width, closeTo(80 * 72 / 25.4, 0.5));
    });
  });
}
