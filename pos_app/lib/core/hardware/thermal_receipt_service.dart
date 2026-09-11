import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptLineItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

class ReceiptData {
  final String shopName;
  final String? shopPhone;
  final String? shopAddress;
  final String currency;
  final String orderNumber;
  final DateTime orderDate;
  final String cashierName;
  final String? customerName;
  final List<ReceiptLineItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final double tenderAmount;
  final double changeDue;
  final String paymentMethod;
  final String? notes;

  const ReceiptData({
    required this.shopName,
    this.shopPhone,
    this.shopAddress,
    this.currency = 'MMK',
    required this.orderNumber,
    required this.orderDate,
    required this.cashierName,
    this.customerName,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalAmount,
    required this.tenderAmount,
    required this.changeDue,
    required this.paymentMethod,
    this.notes,
  });
}

/// Formatter for standard ESC/POS Thermal Printers (58mm = 32 chars, 80mm = 48 chars)
class ThermalReceiptFormatter {
  static final _currencyFormat = NumberFormat('#,##0', 'en_US');
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Generate formatted ASCII receipt string suitable for 58mm thermal printers (32 columns)
  static String format58mm(ReceiptData data) {
    const width = 32;
    final buffer = StringBuffer();

    // Header
    buffer.writeln(_center(data.shopName.toUpperCase(), width));
    if (data.shopAddress != null && data.shopAddress!.isNotEmpty) {
      buffer.writeln(_center(data.shopAddress!, width));
    }
    if (data.shopPhone != null && data.shopPhone!.isNotEmpty) {
      buffer.writeln(_center('Tel: ${data.shopPhone!}', width));
    }
    buffer.writeln('=' * width);

    // Meta
    buffer.writeln(_twoColumns('Inv:', data.orderNumber, width));
    buffer.writeln(_twoColumns('Date:', _dateFormat.format(data.orderDate.toLocal()), width));
    buffer.writeln(_twoColumns('Cashier:', data.cashierName, width));
    if (data.customerName != null && data.customerName!.isNotEmpty) {
      buffer.writeln(_twoColumns('Customer:', data.customerName!, width));
    }
    buffer.writeln('-' * width);

    // Item Header
    buffer.writeln(_twoColumns('ITEM x QTY', 'AMOUNT', width));
    buffer.writeln('-' * width);

    // Items
    for (final item in data.items) {
      buffer.writeln(item.name);
      final qtyPrice = '  ${item.quantity} x ${_currencyFormat.format(item.unitPrice)}';
      final itemTotal = '${_currencyFormat.format(item.subtotal)} ${data.currency}';
      buffer.writeln(_twoColumns(qtyPrice, itemTotal, width));
    }
    buffer.writeln('-' * width);

    // Totals
    buffer.writeln(_twoColumns('Subtotal:', '${_currencyFormat.format(data.subtotal)} ${data.currency}', width));
    if (data.discount > 0) {
      buffer.writeln(_twoColumns('Discount:', '-${_currencyFormat.format(data.discount)} ${data.currency}', width));
    }
    if (data.tax > 0) {
      buffer.writeln(_twoColumns('Tax:', '+${_currencyFormat.format(data.tax)} ${data.currency}', width));
    }
    buffer.writeln('=' * width);
    buffer.writeln(_twoColumns('TOTAL:', '${_currencyFormat.format(data.totalAmount)} ${data.currency}', width));
    buffer.writeln('=' * width);

    // Payment info
    buffer.writeln(_twoColumns('Payment Mode:', data.paymentMethod, width));
    if (data.paymentMethod == 'CASH') {
      buffer.writeln(_twoColumns('Paid:', '${_currencyFormat.format(data.tenderAmount)} ${data.currency}', width));
      buffer.writeln(_twoColumns('Change Due:', '${_currencyFormat.format(data.changeDue)} ${data.currency}', width));
    }
    buffer.writeln('-' * width);

    // Footer
    buffer.writeln(_center('Thank You! Come Again', width));
    buffer.writeln('\n\n\n'); // Paper feed

    return buffer.toString();
  }

  /// Format 58mm/80mm ESC/POS Debt Repayment Voucher Slip
  static String formatDebtRepaymentSlip({
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    required String customerName,
    String? customerPhone,
    required String receiptId,
    required DateTime date,
    required double previousDebt,
    required double amountPaid,
    required double remainingDebt,
    required String paymentMethod,
    String? notes,
    int lineWidth = 32,
  }) {
    final buffer = StringBuffer();
    final div = '=' * lineWidth;
    final thinDiv = '-' * lineWidth;

    buffer.writeln(_center(shopName.toUpperCase(), lineWidth));
    if (shopPhone != null && shopPhone.isNotEmpty) {
      buffer.writeln(_center('Tel: $shopPhone', lineWidth));
    }
    if (shopAddress != null && shopAddress.isNotEmpty) {
      buffer.writeln(_center(shopAddress, lineWidth));
    }
    buffer.writeln(div);
    buffer.writeln(_center('** DEBT REPAYMENT SLIP **', lineWidth));
    buffer.writeln(_center('(အကြွေးဆပ်ပြေစာ)', lineWidth));
    buffer.writeln(thinDiv);

    buffer.writeln(_twoColumns('Voucher #:', receiptId.length > 12 ? receiptId.substring(0, 12) : receiptId, lineWidth));
    buffer.writeln(_twoColumns('Date:', _dateFormat.format(date), lineWidth));
    buffer.writeln(_twoColumns('Customer:', customerName, lineWidth));
    if (customerPhone != null && customerPhone.isNotEmpty) {
      buffer.writeln(_twoColumns('Phone:', customerPhone, lineWidth));
    }
    buffer.writeln(_twoColumns('Payment Mode:', paymentMethod, lineWidth));
    buffer.writeln(thinDiv);

    buffer.writeln(_twoColumns('Previous Debt:', '${_currencyFormat.format(previousDebt)} MMK', lineWidth));
    buffer.writeln(_twoColumns('Amount Repaid:', '${_currencyFormat.format(amountPaid)} MMK', lineWidth));
    buffer.writeln(thinDiv);
    buffer.writeln(_twoColumns('REMAINING DEBT:', '${_currencyFormat.format(remainingDebt)} MMK', lineWidth));
    buffer.writeln(div);

    if (notes != null && notes.isNotEmpty) {
      buffer.writeln('Note: $notes');
      buffer.writeln(thinDiv);
    }

    buffer.writeln(_center('Thank you for your payment!', lineWidth));
    buffer.writeln('\n\n');

    return buffer.toString();
  }

  /// Format 58mm/80mm ESC/POS Customer Account Statement Slip
  static String formatCustomerStatementSlip({
    required String shopName,
    String? shopPhone,
    required String customerName,
    String? customerPhone,
    required DateTime date,
    required double totalDebt,
    required List<Map<String, dynamic>> transactions,
    int lineWidth = 32,
  }) {
    final buffer = StringBuffer();
    final div = '=' * lineWidth;
    final thinDiv = '-' * lineWidth;

    buffer.writeln(_center(shopName.toUpperCase(), lineWidth));
    if (shopPhone != null && shopPhone.isNotEmpty) {
      buffer.writeln(_center('Tel: $shopPhone', lineWidth));
    }
    buffer.writeln(div);
    buffer.writeln(_center('** CUSTOMER ACCOUNT STATEMENT **', lineWidth));
    buffer.writeln(_center('(အကြွေးရှင်းတမ်း မှတ်တမ်း)', lineWidth));
    buffer.writeln(thinDiv);

    buffer.writeln(_twoColumns('Statement Date:', _dateFormat.format(date), lineWidth));
    buffer.writeln(_twoColumns('Customer:', customerName, lineWidth));
    if (customerPhone != null && customerPhone.isNotEmpty) {
      buffer.writeln(_twoColumns('Phone:', customerPhone, lineWidth));
    }
    buffer.writeln(thinDiv);

    buffer.writeln(_center('-- RECENT MOVEMENTS --', lineWidth));
    for (final tx in transactions) {
      final txDate = tx['date'] as DateTime? ?? DateTime.now();
      final type = tx['type'] as String? ?? 'TX';
      final amount = tx['amount'] as double? ?? 0.0;
      final isIncrease = type == 'DEBT_INCREASE';

      final typeLabel = isIncrease ? '[CREDIT +]' : '[PAID -]';
      buffer.writeln('${_dateFormat.format(txDate).substring(5, 16)} $typeLabel');
      buffer.writeln(_twoColumns('Amount:', '${_currencyFormat.format(amount)} MMK', lineWidth));
    }

    buffer.writeln(div);
    buffer.writeln(_twoColumns('TOTAL OUTSTANDING:', '${_currencyFormat.format(totalDebt)} MMK', lineWidth));
    buffer.writeln(div);
    buffer.writeln(_center('DOT POS System Generated', lineWidth));
    buffer.writeln('\n\n');

    return buffer.toString();
  }

  /// Format 58mm/80mm ESC/POS Shift Closing Slip (X-Report / Shift Audit)
  static String formatShiftClosingSlip({
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    required String shiftId,
    required String cashierName,
    required DateTime openedAt,
    required DateTime closedAt,
    required double openingFloat,
    required double cashSales,
    required double nonCashSales,
    required double cashIn,
    required double cashOut,
    required double expectedCash,
    required double actualCash,
    required double difference,
    String? notes,
    int lineWidth = 32,
  }) {
    final buffer = StringBuffer();
    final div = '=' * lineWidth;
    final thinDiv = '-' * lineWidth;

    buffer.writeln(_center(shopName.toUpperCase(), lineWidth));
    if (shopPhone != null && shopPhone.isNotEmpty) {
      buffer.writeln(_center('Tel: $shopPhone', lineWidth));
    }
    buffer.writeln(div);
    buffer.writeln(_center('** SHIFT CLOSING SLIP **', lineWidth));
    buffer.writeln(_center('(အဆိုင်းပိတ် ငွေစာရင်းရှင်းတမ်း)', lineWidth));
    buffer.writeln(thinDiv);

    buffer.writeln(_twoColumns('Shift #:', shiftId.length > 12 ? shiftId.substring(0, 12) : shiftId, lineWidth));
    buffer.writeln(_twoColumns('Cashier:', cashierName, lineWidth));
    buffer.writeln(_twoColumns('Opened:', _dateFormat.format(openedAt), lineWidth));
    buffer.writeln(_twoColumns('Closed:', _dateFormat.format(closedAt), lineWidth));
    buffer.writeln(thinDiv);

    buffer.writeln(_twoColumns('Starting Float:', '${_currencyFormat.format(openingFloat)} MMK', lineWidth));
    buffer.writeln(_twoColumns('Cash Sales (+):', '${_currencyFormat.format(cashSales)} MMK', lineWidth));
    buffer.writeln(_twoColumns('Pay In / Cash (+):', '${_currencyFormat.format(cashIn)} MMK', lineWidth));
    buffer.writeln(_twoColumns('Pay Out / Drop (-):', '${_currencyFormat.format(cashOut)} MMK', lineWidth));
    buffer.writeln(thinDiv);
    buffer.writeln(_twoColumns('EXPECTED IN DRAWER:', '${_currencyFormat.format(expectedCash)} MMK', lineWidth));
    buffer.writeln(_twoColumns('ACTUAL COUNTED:', '${_currencyFormat.format(actualCash)} MMK', lineWidth));
    buffer.writeln(thinDiv);

    String diffLabel = 'BALANCED';
    if (difference > 0) {
      diffLabel = 'OVER (+${_currencyFormat.format(difference)})';
    } else if (difference < 0) {
      diffLabel = 'SHORT (${_currencyFormat.format(difference)})';
    }
    buffer.writeln(_twoColumns('DISCREPANCY:', diffLabel, lineWidth));
    buffer.writeln(div);

    buffer.writeln(_twoColumns('Digital / Non-Cash:', '${_currencyFormat.format(nonCashSales)} MMK', lineWidth));
    final totalRevenue = cashSales + nonCashSales;
    buffer.writeln(_twoColumns('Total Shift Revenue:', '${_currencyFormat.format(totalRevenue)} MMK', lineWidth));
    buffer.writeln(thinDiv);

    if (notes != null && notes.isNotEmpty) {
      buffer.writeln('Audit Note: $notes');
      buffer.writeln(thinDiv);
    }

    buffer.writeln('\n');
    buffer.writeln(_twoColumns('Cashier Sign', 'Manager Sign', lineWidth));
    buffer.writeln(_twoColumns('------------', '------------', lineWidth));
    buffer.writeln('\n\n');

    return buffer.toString();
  }

  static String _center(String text, int width) {
    if (text.length >= width) return text;
    final leftPadding = (width - text.length) ~/ 2;
    return '${' ' * leftPadding}$text';
  }

  static String _twoColumns(String left, String right, int width) {
    final available = width - left.length - right.length;
    if (available <= 0) return '$left $right';
    return '$left${' ' * available}$right';
  }
}

/// Printer Configuration Model
class PrinterConfig {
  final String connectionType; // 'bluetooth', 'wifi', 'usb', 'builtin'
  final String paperSize; // '58mm', '80mm'
  final String ipAddress;
  final int port;
  final String? selectedPrinterName;
  final bool autoPrint;

  const PrinterConfig({
    this.connectionType = 'bluetooth',
    this.paperSize = '58mm',
    this.ipAddress = '192.168.1.100',
    this.port = 9100,
    this.selectedPrinterName,
    this.autoPrint = true,
  });

  PrinterConfig copyWith({
    String? connectionType,
    String? paperSize,
    String? ipAddress,
    int? port,
    String? selectedPrinterName,
    bool? autoPrint,
  }) {
    return PrinterConfig(
      connectionType: connectionType ?? this.connectionType,
      paperSize: paperSize ?? this.paperSize,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      selectedPrinterName: selectedPrinterName ?? this.selectedPrinterName,
      autoPrint: autoPrint ?? this.autoPrint,
    );
  }

  Map<String, dynamic> toJson() => {
        'connectionType': connectionType,
        'paperSize': paperSize,
        'ipAddress': ipAddress,
        'port': port,
        'selectedPrinterName': selectedPrinterName,
        'autoPrint': autoPrint,
      };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      connectionType: json['connectionType'] as String? ?? 'bluetooth',
      paperSize: json['paperSize'] as String? ?? '58mm',
      ipAddress: json['ipAddress'] as String? ?? '192.168.1.100',
      port: (json['port'] as num?)?.toInt() ?? 9100,
      selectedPrinterName: json['selectedPrinterName'] as String?,
      autoPrint: json['autoPrint'] as bool? ?? true,
    );
  }
}

/// Printer State Notifier for Persistent Storage
class PrinterConfigNotifier extends StateNotifier<PrinterConfig> {
  static const _storageKey = 'dot_pos_printer_config';

  PrinterConfigNotifier() : super(const PrinterConfig()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = PrinterConfig.fromJson(map);
      }
    } catch (_) {}
  }

  Future<void> updateConfig(PrinterConfig newConfig) async {
    state = newConfig;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newConfig.toJson()));
    } catch (_) {}
  }
}

final printerConfigProvider = StateNotifierProvider<PrinterConfigNotifier, PrinterConfig>((ref) {
  return PrinterConfigNotifier();
});

/// Print Execution Result
class PrintResult {
  final bool success;
  final String message;

  const PrintResult({required this.success, required this.message});

  @override
  String toString() => success ? 'Success: $message' : 'Error: $message';
}

/// Low-level ESC/POS Binary Command Generator
class EscPosBuilder {
  final List<int> _bytes = [];

  List<int> get bytes => List.unmodifiable(_bytes);

  void init() {
    _bytes.addAll([0x1B, 0x40]); // ESC @ (Initialize printer)
  }

  void alignLeft() {
    _bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0
  }

  void alignCenter() {
    _bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1
  }

  void alignRight() {
    _bytes.addAll([0x1B, 0x61, 0x02]); // ESC a 2
  }

  void bold(bool enabled) {
    _bytes.addAll([0x1B, 0x45, enabled ? 0x01 : 0x00]); // ESC E n
  }

  void doubleSize(bool enabled) {
    _bytes.addAll([0x1D, 0x21, enabled ? 0x11 : 0x00]); // GS ! n
  }

  void feed([int lines = 1]) {
    for (int i = 0; i < lines; i++) {
      _bytes.add(0x0A); // LF
    }
  }

  void cut() {
    feed(4);
    _bytes.addAll([0x1D, 0x56, 0x41, 0x10]); // GS V A 16 (Full Cut)
  }

  void cashDrawer() {
    _bytes.addAll([0x1B, 0x70, 0x00, 0x19, 0xFA]); // ESC p 0 25 250 (Kick Drawer)
  }

  void text(String str) {
    _bytes.addAll(utf8.encode(str));
  }

  void writeln([String str = '']) {
    if (str.isNotEmpty) {
      text(str);
    }
    _bytes.add(0x0A);
  }

  List<int> buildReceipt(ReceiptData data, {int width = 32}) {
    init();
    alignCenter();
    bold(true);
    doubleSize(true);
    writeln(data.shopName.toUpperCase());
    doubleSize(false);
    bold(false);

    if (data.shopAddress != null && data.shopAddress!.isNotEmpty) {
      writeln(data.shopAddress!);
    }
    if (data.shopPhone != null && data.shopPhone!.isNotEmpty) {
      writeln('Tel: ${data.shopPhone!}');
    }
    writeln('=' * width);

    writeln(ThermalReceiptFormatter._twoColumns('Inv:', data.orderNumber, width));
    writeln(ThermalReceiptFormatter._twoColumns('Date:', ThermalReceiptFormatter._dateFormat.format(data.orderDate.toLocal()), width));
    writeln(ThermalReceiptFormatter._twoColumns('Cashier:', data.cashierName, width));
    if (data.customerName != null && data.customerName!.isNotEmpty) {
      writeln(ThermalReceiptFormatter._twoColumns('Customer:', data.customerName!, width));
    }
    writeln('-' * width);

    writeln(ThermalReceiptFormatter._twoColumns('ITEM x QTY', 'AMOUNT', width));
    writeln('-' * width);

    for (final item in data.items) {
      writeln(item.name);
      final qtyPrice = '  ${item.quantity} x ${ThermalReceiptFormatter._currencyFormat.format(item.unitPrice)}';
      final itemTotal = '${ThermalReceiptFormatter._currencyFormat.format(item.subtotal)} ${data.currency}';
      writeln(ThermalReceiptFormatter._twoColumns(qtyPrice, itemTotal, width));
    }
    writeln('-' * width);

    writeln(ThermalReceiptFormatter._twoColumns('Subtotal:', '${ThermalReceiptFormatter._currencyFormat.format(data.subtotal)} ${data.currency}', width));
    if (data.discount > 0) {
      writeln(ThermalReceiptFormatter._twoColumns('Discount:', '-${ThermalReceiptFormatter._currencyFormat.format(data.discount)} ${data.currency}', width));
    }
    if (data.tax > 0) {
      writeln(ThermalReceiptFormatter._twoColumns('Tax:', '+${ThermalReceiptFormatter._currencyFormat.format(data.tax)} ${data.currency}', width));
    }
    writeln('=' * width);

    bold(true);
    writeln(ThermalReceiptFormatter._twoColumns('TOTAL:', '${ThermalReceiptFormatter._currencyFormat.format(data.totalAmount)} ${data.currency}', width));
    bold(false);
    writeln('=' * width);

    writeln(ThermalReceiptFormatter._twoColumns('Payment Mode:', data.paymentMethod, width));
    if (data.paymentMethod == 'CASH') {
      writeln(ThermalReceiptFormatter._twoColumns('Paid:', '${ThermalReceiptFormatter._currencyFormat.format(data.tenderAmount)} ${data.currency}', width));
      writeln(ThermalReceiptFormatter._twoColumns('Change Due:', '${ThermalReceiptFormatter._currencyFormat.format(data.changeDue)} ${data.currency}', width));
    }
    writeln('-' * width);

    alignCenter();
    writeln('Thank You! Come Again');
    cut();

    return bytes;
  }

  List<int> buildRawText(String rawText) {
    init();
    alignLeft();
    final lines = rawText.split('\n');
    for (final line in lines) {
      writeln(line);
    }
    cut();
    return bytes;
  }
}

/// Raw TCP Socket Network Thermal Printer Service
class NetworkThermalPrinterService {
  static Future<PrintResult> testConnection(String ip, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
      sw.stop();
      socket.destroy();
      return PrintResult(
        success: true,
        message: 'Connected to $ip:$port (${sw.elapsedMilliseconds}ms)',
      );
    } catch (e) {
      sw.stop();
      return PrintResult(
        success: false,
        message: 'Cannot reach printer at $ip:$port (${e.toString().replaceAll('SocketException: ', '')})',
      );
    }
  }

  static Future<PrintResult> printBytes(String ip, int port, List<int> bytes) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return PrintResult(
        success: true,
        message: 'Printed via Network $ip:$port',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Network Print Error ($ip:$port): ${e.toString().replaceAll('SocketException: ', '')}',
      );
    }
  }
}

/// Represents a paired or discovered Bluetooth Printer
class BluetoothPrinterDevice {
  final String name;
  final String address;
  final int type;

  const BluetoothPrinterDevice({
    required this.name,
    required this.address,
    this.type = 0,
  });

  factory BluetoothPrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothPrinterDevice(
      name: (map['name'] as String?) ?? 'Unknown Printer',
      address: (map['address'] as String?) ?? '',
      type: (map['type'] as int?) ?? 0,
    );
  }
}

/// Native Android Bluetooth ESC/POS Thermal Printer Service via MethodChannel
class BluetoothThermalPrinterService {
  static const MethodChannel _channel = MethodChannel('com.khantlin.mobile_pos/hardware');

  /// List all bonded (paired) Bluetooth printers
  static Future<List<BluetoothPrinterDevice>> listPairedPrinters() async {
    if (kIsWeb || !Platform.isAndroid) {
      return [];
    }
    try {
      final List<dynamic>? rawList = await _channel.invokeListMethod('getBluetoothPrinters');
      if (rawList == null) return [];
      return rawList
          .map((item) => BluetoothPrinterDevice.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Test connection to a paired Bluetooth printer
  static Future<PrintResult> testConnection(String address) async {
    if (kIsWeb || !Platform.isAndroid) {
      return const PrintResult(
        success: false,
        message: 'Bluetooth printing is only supported on Android devices.',
      );
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'testBluetoothConnection',
        {'address': address},
      );
      final success = res?['success'] as bool? ?? false;
      final message = res?['message'] as String? ?? 'Connection failed';
      return PrintResult(success: success, message: message);
    } catch (e) {
      return PrintResult(success: false, message: 'Bluetooth Test Error: $e');
    }
  }

  /// Send ESC/POS raw bytes directly to Bluetooth printer
  static Future<PrintResult> printBytes(String address, Uint8List bytes) async {
    if (kIsWeb || !Platform.isAndroid) {
      return const PrintResult(
        success: false,
        message: 'Bluetooth printing is only supported on Android devices.',
      );
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'printBluetoothEscPos',
        {
          'address': address,
          'bytes': bytes,
        },
      );
      final success = res?['success'] as bool? ?? false;
      final message = res?['message'] as String? ?? 'Print failed';
      return PrintResult(success: success, message: message);
    } catch (e) {
      return PrintResult(success: false, message: 'Bluetooth Print Error: $e');
    }
  }
}

/// Native System / Spooler / Built-in / USB Thermal Printer Service
class SystemThermalPrinterService {
  static Future<List<Printer>> listPrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return [];
    }
  }

  static PdfPageFormat getFormat(String paperSize) {
    final is80mm = paperSize.toLowerCase() == '80mm';
    final widthMm = is80mm ? 80.0 : 58.0;
    final widthPt = widthMm * PdfPageFormat.mm;
    return PdfPageFormat(
      widthPt,
      double.infinity,
      marginAll: 2 * PdfPageFormat.mm,
    );
  }

  static Future<PrintResult> printReceipt({
    required ReceiptData receipt,
    required PrinterConfig config,
  }) async {
    try {
      final doc = pw.Document();
      final pageFormat = getFormat(config.paperSize);
      final is80mm = config.paperSize.toLowerCase() == '80mm';
      final currencyFmt = NumberFormat('#,##0', 'en_US');
      final dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.ConstrainedBox(
                constraints: pw.BoxConstraints(maxWidth: is80mm ? 220 : 160),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Shop Header
                      pw.Center(
                        child: pw.Text(
                          receipt.shopName.toUpperCase(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 12 : 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      if (receipt.shopAddress != null && receipt.shopAddress!.isNotEmpty)
                        pw.Center(
                          child: pw.Text(
                            receipt.shopAddress!,
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      if (receipt.shopPhone != null && receipt.shopPhone!.isNotEmpty)
                        pw.Center(
                          child: pw.Text(
                            'Tel: ${receipt.shopPhone!}',
                            style: const pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

                      // Metadata
                      _pdfTwoColumn('Inv:', receipt.orderNumber, is80mm),
                      _pdfTwoColumn('Date:', dateFmt.format(receipt.orderDate.toLocal()), is80mm),
                      _pdfTwoColumn('Cashier:', receipt.cashierName, is80mm),
                      if (receipt.customerName != null && receipt.customerName!.isNotEmpty)
                        _pdfTwoColumn('Customer:', receipt.customerName!, is80mm),
                      pw.Divider(thickness: 0.5),

                      // Items Header
                      _pdfTwoColumn('ITEM x QTY', 'AMOUNT', is80mm, isBold: true),
                      pw.Divider(thickness: 0.5),

                      // Items List
                      ...receipt.items.map((item) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(fontSize: is80mm ? 9.0 : 8.0, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('  ${item.quantity} x ${currencyFmt.format(item.unitPrice)}', style: const pw.TextStyle(fontSize: 7.5)),
                                  pw.Text('${currencyFmt.format(item.subtotal)} ${receipt.currency}', style: pw.TextStyle(fontSize: is80mm ? 8.5 : 7.5, fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      pw.Divider(thickness: 0.5),

                      // Totals
                      _pdfTwoColumn('Subtotal:', '${currencyFmt.format(receipt.subtotal)} ${receipt.currency}', is80mm),
                      if (receipt.discount > 0)
                        _pdfTwoColumn('Discount:', '-${currencyFmt.format(receipt.discount)} ${receipt.currency}', is80mm),
                      if (receipt.tax > 0)
                        _pdfTwoColumn('Tax:', '+${currencyFmt.format(receipt.tax)} ${receipt.currency}', is80mm),
                      pw.Divider(thickness: 0.8),
                      _pdfTwoColumn('TOTAL:', '${currencyFmt.format(receipt.totalAmount)} ${receipt.currency}', is80mm, isBold: true, fontSize: is80mm ? 10.5 : 9.0),
                      pw.Divider(thickness: 0.8),

                      // Payment mode
                      _pdfTwoColumn('Payment Mode:', receipt.paymentMethod, is80mm),
                      if (receipt.paymentMethod == 'CASH') ...[
                        _pdfTwoColumn('Paid:', '${currencyFmt.format(receipt.tenderAmount)} ${receipt.currency}', is80mm),
                        _pdfTwoColumn('Change Due:', '${currencyFmt.format(receipt.changeDue)} ${receipt.currency}', is80mm),
                      ],
                      pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

                      // Footer
                      pw.SizedBox(height: 3),
                      pw.Center(
                        child: pw.Text(
                          'Thank You! Come Again',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      return _dispatchPdf(pdfBytes, config, 'Slip_${receipt.orderNumber}');
    } catch (e) {
      return PrintResult(success: false, message: 'Print Error: ${e.toString()}');
    }
  }

  static Future<PrintResult> printRawText({
    required String text,
    required PrinterConfig config,
    String jobName = 'POS_Slip',
  }) async {
    try {
      final doc = pw.Document();
      final pageFormat = getFormat(config.paperSize);
      final is80mm = config.paperSize.toLowerCase() == '80mm';

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.ConstrainedBox(
                constraints: pw.BoxConstraints(maxWidth: is80mm ? 220 : 160),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      font: pw.Font.courier(),
                      fontSize: is80mm ? 8.0 : 6.5,
                      lineSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      return _dispatchPdf(pdfBytes, config, jobName);
    } catch (e) {
      return PrintResult(success: false, message: 'Print Error: ${e.toString()}');
    }
  }

  static Future<PrintResult> _dispatchPdf(Uint8List pdfBytes, PrinterConfig config, String jobName) async {
    final printers = await listPrinters();
    Printer? target;

    if (config.selectedPrinterName != null && config.selectedPrinterName!.isNotEmpty) {
      target = printers.where((p) => p.name == config.selectedPrinterName || p.url == config.selectedPrinterName).firstOrNull;
      if (target == null && config.connectionType == 'usb') {
        return PrintResult(
          success: false,
          message: 'Selected printer "${config.selectedPrinterName}" not found or disconnected.',
        );
      }
    }

    if (target != null) {
      final ok = await Printing.directPrintPdf(
        printer: target,
        onLayout: (_) async => pdfBytes,
        name: jobName,
      );
      return PrintResult(
        success: ok,
        message: ok ? 'Printed to ${target.name}' : 'Print failed on ${target.name}',
      );
    }

    if (printers.isNotEmpty) {
      final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull ?? printers.first;
      final ok = await Printing.directPrintPdf(
        printer: defaultPrinter,
        onLayout: (_) async => pdfBytes,
        name: jobName,
      );
      return PrintResult(
        success: ok,
        message: ok ? 'Printed to ${defaultPrinter.name}' : 'Print failed on ${defaultPrinter.name}',
      );
    }

    // Spooler fallback only
    final ok = await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: jobName,
      format: getFormat(config.paperSize),
    );
    return PrintResult(
      success: ok,
      message: ok ? 'Sent to Print Spooler' : 'Print cancelled or failed',
    );
  }

  static pw.Widget _pdfTwoColumn(String left, String right, bool is80mm, {bool isBold = false, double? fontSize}) {
    final size = fontSize ?? (is80mm ? 8.5 : 7.2);
    final style = pw.TextStyle(fontSize: size, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(left, style: style),
          pw.Text(right, style: style),
        ],
      ),
    );
  }
}

/// Abstract Printer Service Interface
abstract class PrinterService {
  Future<PrintResult> printReceipt(ReceiptData receipt);
  Future<PrintResult> printRawText(String text, {String jobName});
  Future<PrintResult> testConnection();
}

/// Universal Hardware Thermal Printer Service
class UniversalThermalPrinterService implements PrinterService {
  final Ref _ref;
  UniversalThermalPrinterService(this._ref);

  @override
  Future<PrintResult> printReceipt(ReceiptData receipt) async {
    final config = _ref.read(printerConfigProvider);
    if (config.connectionType == 'wifi') {
      final width = config.paperSize == '80mm' ? 48 : 32;
      final builder = EscPosBuilder();
      final bytes = builder.buildReceipt(receipt, width: width);
      return NetworkThermalPrinterService.printBytes(config.ipAddress, config.port, bytes);
    } else if (config.connectionType == 'bluetooth') {
      if (config.selectedPrinterName == null || config.selectedPrinterName!.trim().isEmpty) {
        return const PrintResult(
          success: false,
          message: 'No Bluetooth printer selected! Please select a paired Bluetooth printer in Settings.',
        );
      }
      final width = config.paperSize == '80mm' ? 48 : 32;
      final builder = EscPosBuilder();
      final bytes = builder.buildReceipt(receipt, width: width);
      return BluetoothThermalPrinterService.printBytes(config.selectedPrinterName!.trim(), Uint8List.fromList(bytes));
    } else {
      return SystemThermalPrinterService.printReceipt(receipt: receipt, config: config);
    }
  }

  @override
  Future<PrintResult> printRawText(String text, {String jobName = 'POS_Slip'}) async {
    final config = _ref.read(printerConfigProvider);
    if (config.connectionType == 'wifi') {
      final builder = EscPosBuilder();
      final bytes = builder.buildRawText(text);
      return NetworkThermalPrinterService.printBytes(config.ipAddress, config.port, bytes);
    } else if (config.connectionType == 'bluetooth') {
      if (config.selectedPrinterName == null || config.selectedPrinterName!.trim().isEmpty) {
        return const PrintResult(
          success: false,
          message: 'No Bluetooth printer selected! Please select a paired Bluetooth printer in Settings.',
        );
      }
      final builder = EscPosBuilder();
      final bytes = builder.buildRawText(text);
      return BluetoothThermalPrinterService.printBytes(config.selectedPrinterName!.trim(), Uint8List.fromList(bytes));
    } else {
      return SystemThermalPrinterService.printRawText(text: text, config: config, jobName: jobName);
    }
  }

  @override
  Future<PrintResult> testConnection() async {
    final config = _ref.read(printerConfigProvider);
    if (config.connectionType == 'wifi') {
      return NetworkThermalPrinterService.testConnection(config.ipAddress, config.port);
    } else if (config.connectionType == 'bluetooth') {
      if (config.selectedPrinterName == null || config.selectedPrinterName!.trim().isEmpty) {
        return const PrintResult(
          success: false,
          message: 'No Bluetooth printer selected! Please pair your printer in Android Settings and select it in Settings.',
        );
      }
      return BluetoothThermalPrinterService.testConnection(config.selectedPrinterName!.trim());
    } else {
      final printers = await SystemThermalPrinterService.listPrinters();
      if (printers.isEmpty) {
        return const PrintResult(
          success: false,
          message: 'No system/USB printers detected. Please connect your printer.',
        );
      }
      final target = config.selectedPrinterName != null && config.selectedPrinterName!.isNotEmpty
          ? printers.where((p) => p.name == config.selectedPrinterName).firstOrNull
          : null;
      if (target != null) {
        return PrintResult(
          success: true,
          message: 'Printer "${target.name}" is ready and connected!',
        );
      }
      return PrintResult(
        success: false,
        message: 'Printer "${config.selectedPrinterName ?? 'Default'}" not found in system printers list.',
      );
    }
  }
}

final printerServiceProvider = Provider<UniversalThermalPrinterService>((ref) {
  return UniversalThermalPrinterService(ref);
});
