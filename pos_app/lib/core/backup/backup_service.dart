import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class BackupExportResult {
  final String filePath;
  final String fileName;
  final int recordCount;
  final String? contentPreview;

  const BackupExportResult({
    required this.filePath,
    required this.fileName,
    required this.recordCount,
    this.contentPreview,
  });
}

class BackupRestoreResult {
  final bool success;
  final String message;
  final int restoredRecords;

  const BackupRestoreResult({
    required this.success,
    required this.message,
    required this.restoredRecords,
  });
}

class BackupService {
  final AppDatabase db;
  final Directory? customBackupDirectory;

  BackupService(this.db, {this.customBackupDirectory});

  /// Generates a full JSON database backup file
  Future<BackupExportResult> exportDatabaseToJson() async {
    final shops = await db.select(db.shops).get();
    final categories = await db.select(db.categories).get();
    final products = await db.select(db.products).get();
    final customers = await db.select(db.customers).get();
    final ledgers = await db.select(db.customerLedgers).get();
    final orders = await db.select(db.orders).get();
    final orderItems = await db.select(db.orderItems).get();
    final shifts = await db.select(db.shifts).get();
    final users = await db.select(db.users).get();

    final backupPayload = {
      'version': '1.0.0',
      'appName': 'DOT POS',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'stats': {
        'products': products.length,
        'categories': categories.length,
        'customers': customers.length,
        'orders': orders.length,
        'shifts': shifts.length,
      },
      'data': {
        'shops': shops.map((s) => s.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'products': products.map((p) => p.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
        'customerLedgers': ledgers.map((l) => l.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
        'orderItems': orderItems.map((oi) => oi.toJson()).toList(),
        'shifts': shifts.map((sh) => sh.toJson()).toList(),
        'users': users.map((u) => {
          'id': u.id,
          'shopId': u.shopId,
          'name': u.name,
          'role': u.role,
          'pinCode': u.pinCode,
          'isActive': u.isActive,
          'createdAt': u.createdAt.toIso8601String(),
          'updatedAt': u.updatedAt.toIso8601String(),
        }).toList(),
      }
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);
    final dir = await _getBackupDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'dot_pos_backup_$dateStr.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString, flush: true);

    final total = products.length + categories.length + customers.length + orders.length;

    return BackupExportResult(
      filePath: file.path,
      fileName: fileName,
      recordCount: total,
      contentPreview: jsonString.length > 500 ? '${jsonString.substring(0, 500)}...' : jsonString,
    );
  }

  /// Exports products, sales, and customers to Excel-compatible CSV files (UTF-8 with BOM)
  Future<List<BackupExportResult>> exportExcelCsv() async {
    final dir = await _getBackupDirectory();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final results = <BackupExportResult>[];

    // 1. Products Excel (CSV)
    final products = await db.select(db.products).get();
    final categories = await db.select(db.categories).get();
    final catMap = {for (final c in categories) c.id: c.name};

    final productBuffer = StringBuffer();
    // Prepend UTF-8 BOM for Microsoft Excel compatibility
    productBuffer.write('\uFEFF');
    productBuffer.writeln('Product ID,Product Name,Barcode,Category,Cost Price (MMK),Selling Price (MMK),Stock Quantity,Is Active');

    for (final p in products) {
      if (p.deletedAt != null) continue;
      final catName = p.categoryId != null ? (catMap[p.categoryId] ?? 'Uncategorized') : 'All Items';
      final safeName = '"${p.name.replaceAll('"', '""')}"';
      final safeBarcode = p.barcode ?? '';
      productBuffer.writeln('${p.id},$safeName,$safeBarcode,"$catName",${p.costPrice},${p.sellingPrice},${p.stockQuantity},${p.isActive}');
    }

    final productFileName = 'products_excel_$dateStr.csv';
    final productFile = File('${dir.path}/$productFileName');
    await productFile.writeAsString(productBuffer.toString(), flush: true);
    results.add(BackupExportResult(
      filePath: productFile.path,
      fileName: productFileName,
      recordCount: products.where((p) => p.deletedAt == null).length,
    ));

    // 2. Customers & Debt Excel (CSV)
    final customers = await db.select(db.customers).get();
    final customerBuffer = StringBuffer();
    customerBuffer.write('\uFEFF');
    customerBuffer.writeln('Customer ID,Name,Phone,Total Debt (MMK),Created At');

    for (final c in customers) {
      if (c.deletedAt != null) continue;
      final safeName = '"${c.name.replaceAll('"', '""')}"';
      final safePhone = c.phone ?? '';
      customerBuffer.writeln('${c.id},$safeName,$safePhone,${c.totalDebt},${DateFormat('yyyy-MM-dd HH:mm').format(c.createdAt)}');
    }

    final customerFileName = 'customers_excel_$dateStr.csv';
    final customerFile = File('${dir.path}/$customerFileName');
    await customerFile.writeAsString(customerBuffer.toString(), flush: true);
    results.add(BackupExportResult(
      filePath: customerFile.path,
      fileName: customerFileName,
      recordCount: customers.where((c) => c.deletedAt == null).length,
    ));

    // 3. Sales Orders Excel (CSV)
    final orders = await db.select(db.orders).get();
    final orderBuffer = StringBuffer();
    orderBuffer.write('\uFEFF');
    orderBuffer.writeln('Order ID,Order Number,Date,Subtotal (MMK),Discount (MMK),Tax (MMK),Final Total (MMK),Payment Method,Status');

    for (final o in orders) {
      final safeOrderNo = o.orderNumber;
      final dateStrFormatted = DateFormat('yyyy-MM-dd HH:mm').format(o.createdAt);
      orderBuffer.writeln('${o.id},$safeOrderNo,$dateStrFormatted,${o.subtotal},${o.discountAmount},${o.taxAmount},${o.totalAmount},${o.paymentMethod},${o.status}');
    }

    final orderFileName = 'sales_orders_excel_$dateStr.csv';
    final orderFile = File('${dir.path}/$orderFileName');
    await orderFile.writeAsString(orderBuffer.toString(), flush: true);
    results.add(BackupExportResult(
      filePath: orderFile.path,
      fileName: orderFileName,
      recordCount: orders.length,
    ));

    return results;
  }

  /// Restores data from JSON string
  Future<BackupRestoreResult> restoreFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonContent);
      if (!decoded.containsKey('data')) {
        return const BackupRestoreResult(
          success: false,
          message: 'Invalid backup file: missing data root',
          restoredRecords: 0,
        );
      }

      final data = decoded['data'] as Map<String, dynamic>;
      int count = 0;

      await db.transaction(() async {
        // Restore Categories
        if (data['categories'] is List) {
          for (final raw in data['categories']) {
            if (raw is! Map<String, dynamic>) continue;
            final id = raw['id']?.toString() ?? Uuid().v4();
            final shopId = raw['shopId']?.toString() ?? 'default-shop';
            final name = raw['name']?.toString() ?? 'Unnamed Category';
            final colorCode = raw['colorCode']?.toString();
            final sortOrder = (raw['sortOrder'] as num?)?.toInt() ?? 0;
            final createdAt = raw['createdAt'] != null
                ? DateTime.tryParse(raw['createdAt'].toString()) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();
            final updatedAt = raw['updatedAt'] != null
                ? DateTime.tryParse(raw['updatedAt'].toString()) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();
            final deletedAt = raw['deletedAt'] != null
                ? DateTime.tryParse(raw['deletedAt'].toString())
                : null;

            await db.into(db.categories).insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                colorCode: drift.Value(colorCode),
                sortOrder: drift.Value(sortOrder),
                createdAt: drift.Value(createdAt),
                updatedAt: drift.Value(updatedAt),
                deletedAt: drift.Value(deletedAt),
                syncStatus: const drift.Value('synced'),
              ),
            );
            count++;
          }
        }

        // Restore Products
        if (data['products'] is List) {
          for (final raw in data['products']) {
            if (raw is! Map<String, dynamic>) continue;
            final id = raw['id']?.toString() ?? Uuid().v4();
            final shopId = raw['shopId']?.toString() ?? 'default-shop';
            final name = raw['name']?.toString() ?? 'Unnamed Product';
            final costPrice = (raw['costPrice'] as num?)?.toDouble() ?? 0.0;
            final sellingPrice = (raw['sellingPrice'] as num?)?.toDouble() ?? 0.0;
            final stockQuantity = (raw['stockQuantity'] as num?)?.toInt() ?? 0;
            final categoryId = raw['categoryId']?.toString();
            final barcode = raw['barcode']?.toString();
            final imageUrl = raw['imageUrl']?.toString();
            final isActive = raw['isActive'] as bool? ?? true;
            final trackStock = raw['trackStock'] as bool? ?? true;
            final createdAt = raw['createdAt'] != null
                ? DateTime.tryParse(raw['createdAt'].toString()) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();
            final updatedAt = raw['updatedAt'] != null
                ? DateTime.tryParse(raw['updatedAt'].toString()) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();
            final deletedAt = raw['deletedAt'] != null
                ? DateTime.tryParse(raw['deletedAt'].toString())
                : null;

            await db.into(db.products).insertOnConflictUpdate(
              ProductsCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                costPrice: drift.Value(costPrice),
                sellingPrice: sellingPrice,
                stockQuantity: drift.Value(stockQuantity),
                trackStock: drift.Value(trackStock),
                categoryId: drift.Value(categoryId),
                barcode: drift.Value(barcode),
                imageUrl: drift.Value(imageUrl),
                isActive: drift.Value(isActive),
                createdAt: drift.Value(createdAt),
                updatedAt: drift.Value(updatedAt),
                deletedAt: drift.Value(deletedAt),
                syncStatus: const drift.Value('synced'),
              ),
            );
            count++;
          }
        }

        // Restore Customers
        if (data['customers'] is List) {
          for (final raw in data['customers']) {
            if (raw is! Map<String, dynamic>) continue;
            final id = raw['id']?.toString() ?? Uuid().v4();
            final shopId = raw['shopId']?.toString() ?? 'default-shop';
            final name = raw['name']?.toString() ?? 'Unnamed Customer';
            final phone = raw['phone']?.toString();
            final totalDebt = (raw['totalDebt'] as num?)?.toDouble() ?? 0.0;
            final createdAt = raw['createdAt'] != null
                ? DateTime.tryParse(raw['createdAt'].toString()) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();
            final updatedAt = raw['updatedAt'] != null
                ? DateTime.tryParse(raw['updatedAt'].toString()) ?? DateTime.now().toUtc()
                : DateTime.now().toUtc();
            final deletedAt = raw['deletedAt'] != null
                ? DateTime.tryParse(raw['deletedAt'].toString())
                : null;

            await db.into(db.customers).insertOnConflictUpdate(
              CustomersCompanion.insert(
                id: id,
                shopId: shopId,
                name: name,
                phone: drift.Value(phone),
                totalDebt: drift.Value(totalDebt),
                createdAt: drift.Value(createdAt),
                updatedAt: drift.Value(updatedAt),
                deletedAt: drift.Value(deletedAt),
                syncStatus: const drift.Value('synced'),
              ),
            );
            count++;
          }
        }
      });

      return BackupRestoreResult(
        success: true,
        message: 'Successfully restored $count records from backup!',
        restoredRecords: count,
      );
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        message: 'Restore failed: $e',
        restoredRecords: 0,
      );
    }
  }

  Future<Directory> _getBackupDirectory() async {
    if (customBackupDirectory != null) {
      if (!await customBackupDirectory!.exists()) {
        await customBackupDirectory!.create(recursive: true);
      }
      return customBackupDirectory!;
    }
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }
    final backupDir = Directory('${baseDir.path}/dot_pos_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }
}
