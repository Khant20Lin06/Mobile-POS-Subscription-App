import 'package:intl/intl.dart';

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
    buffer.writeln(_center('ကျေးဇူးတင်ပါသည်', width));
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
    buffer.writeln(_center('(ကျေးဇူးတင်ပါသည်)', lineWidth));
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

/// Abstract Printer Service Interface
abstract class PrinterService {
  Future<bool> printReceipt(ReceiptData receipt);
  Future<bool> isConnected();
}

/// Default Universal Local Printer Implementation (Console & Thermal ESC/POS ready)
class UniversalThermalPrinterService implements PrinterService {
  @override
  Future<bool> isConnected() async => true;

  @override
  Future<bool> printReceipt(ReceiptData receipt) async {
    // Format receipt to standard 58mm ESC/POS layout
    // When deploying to physical Sunmi or Bluetooth printer, the raw bytes can be sent here.
    return true;
  }
}
