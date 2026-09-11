import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/backup/backup_service.dart';
import 'package:pos_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late BackupService backupService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('pos_backup_test_');
    backupService = BackupService(db, customBackupDirectory: tempDir);

    // Seed dummy shop and product
    await db.into(db.shops).insert(
      ShopsCompanion.insert(
        id: 'test-shop-1',
        name: 'Test Coffee Store',
      ),
    );

    await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        id: 'cat-1',
        shopId: 'test-shop-1',
        name: 'Beverages',
      ),
    );

    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: 'prod-1',
        shopId: 'test-shop-1',
        name: 'Cold Brew Coffee',
        costPrice: const drift.Value(1500.0),
        sellingPrice: 3500.0,
        barcode: const drift.Value('88500112233'),
        stockQuantity: const drift.Value(50),
      ),
    );

    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        id: 'cust-1',
        shopId: 'test-shop-1',
        name: 'Ko Thant',
        phone: const drift.Value('0912345678'),
        totalDebt: const drift.Value(15000.0),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService Excel & JSON Tests', () {
    test('exportDatabaseToJson creates valid JSON backup file with correct data and stats', () async {
      final result = await backupService.exportDatabaseToJson();

      expect(result.recordCount, greaterThan(0));
      expect(result.fileName.startsWith('dot_pos_backup_'), isTrue);
      expect(result.fileName.endsWith('.json'), isTrue);

      final file = File(result.filePath);
      expect(await file.exists(), isTrue);

      final rawContent = await file.readAsString();
      final decoded = jsonDecode(rawContent) as Map<String, dynamic>;

      expect(decoded['version'], '1.0.0');
      expect(decoded['stats']['products'], 1);
      expect(decoded['stats']['customers'], 1);
      expect(decoded['data']['products'][0]['name'], 'Cold Brew Coffee');
      expect(decoded['data']['customers'][0]['name'], 'Ko Thant');
    });

    test('exportExcelCsv generates UTF-8 BOM CSV files for products, customers, and orders', () async {
      final results = await backupService.exportExcelCsv();

      expect(results.length, 3);
      final productResult = results.firstWhere((r) => r.fileName.startsWith('products_excel_'));
      final customerResult = results.firstWhere((r) => r.fileName.startsWith('customers_excel_'));
      final orderResult = results.firstWhere((r) => r.fileName.startsWith('sales_orders_excel_'));

      expect(productResult.recordCount, 1);
      expect(customerResult.recordCount, 1);
      expect(orderResult.recordCount, 0);

      final prodFile = File(productResult.filePath);
      final prodBytes = await prodFile.readAsBytes();
      // Verifies UTF-8 BOM [0xEF, 0xBB, 0xBF] is prepended for Microsoft Excel
      expect(prodBytes.length >= 3, isTrue);
      expect(prodBytes[0] == 0xEF && prodBytes[1] == 0xBB && prodBytes[2] == 0xBF, isTrue);
      final prodContent = await prodFile.readAsString();
      expect(prodContent.contains('Cold Brew Coffee'), isTrue);
      expect(prodContent.contains('88500112233'), isTrue);

      final custFile = File(customerResult.filePath);
      final custBytes = await custFile.readAsBytes();
      expect(custBytes[0] == 0xEF && custBytes[1] == 0xBB && custBytes[2] == 0xBF, isTrue);
      final custContent = await custFile.readAsString();
      expect(custContent.contains('Ko Thant'), isTrue);
    });

    test('restoreFromJson restores categories, products and customers into database', () async {
      final newPayload = {
        'version': '1.0.0',
        'data': {
          'categories': [
            {
              'id': 'cat-restored-1',
              'shopId': 'test-shop-1',
              'name': 'Bakery Pastries',
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
              'syncStatus': 'synced',
            }
          ],
          'products': [
            {
              'id': 'prod-restored-1',
              'shopId': 'test-shop-1',
              'name': 'Almond Croissant',
              'costPrice': 2000.0,
              'sellingPrice': 4000.0,
              'stockQuantity': 15,
              'isActive': true,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
              'syncStatus': 'synced',
            }
          ],
          'customers': [
            {
              'id': 'cust-restored-1',
              'shopId': 'test-shop-1',
              'name': 'Daw Hla',
              'phone': '09987654321',
              'totalDebt': 5000.0,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
              'updatedAt': DateTime.now().toUtc().toIso8601String(),
              'syncStatus': 'synced',
            }
          ]
        }
      };

      final result = await backupService.restoreFromJson(jsonEncode(newPayload));
      expect(result.success, isTrue);
      expect(result.restoredRecords, 3);

      final allCats = await db.select(db.categories).get();
      expect(allCats.any((c) => c.name == 'Bakery Pastries'), isTrue);

      final allProds = await db.select(db.products).get();
      expect(allProds.any((p) => p.name == 'Almond Croissant'), isTrue);
    });
  });
}
