import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory SQLite database for test isolation
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Sprint 4 - Inventory & Stock DAO Tests', () {
    test('Insert product persists with cost, selling price and pending syncStatus', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      final companion = ProductsCompanion.insert(
        id: 'test-prod-101',
        shopId: shopId,
        name: 'Special Tea Leaf Salad',
        costPrice: const drift.Value(1200.0),
        sellingPrice: 2500.0,
        stockQuantity: const drift.Value(20),
        trackStock: const drift.Value(true),
        isActive: const drift.Value(true),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value('pending'),
      );

      await db.productDao.insertProduct(companion);

      final products = await db.productDao.watchAllInventoryProducts().first;
      expect(products.length, equals(1));
      expect(products.first.name, equals('Special Tea Leaf Salad'));
      expect(products.first.costPrice, equals(1200.0));
      expect(products.first.sellingPrice, equals(2500.0));
      expect(products.first.stockQuantity, equals(20));
      expect(products.first.syncStatus, equals('pending'));
    });

    test('Stock In adjusts stock quantity upwards and updates syncStatus to pending', () async {
      final now = DateTime.now().toUtc();
      await db.productDao.insertProduct(
        ProductsCompanion.insert(
          id: 'test-prod-102',
          shopId: 'shop-01',
          name: 'Mineral Water 500ml',
          costPrice: const drift.Value(300.0),
          sellingPrice: 600.0,
          stockQuantity: const drift.Value(10),
          trackStock: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('synced'),
        ),
      );

      // Stock In: +25 bottles
      await db.productDao.adjustStock('test-prod-102', 25);

      final updated = await (db.select(db.products)..where((t) => t.id.equals('test-prod-102'))).getSingle();
      expect(updated.stockQuantity, equals(35));
      expect(updated.syncStatus, equals('pending'));
    });

    test('Damage/Wastage adjusts stock quantity downwards and clamps at zero', () async {
      final now = DateTime.now().toUtc();
      await db.productDao.insertProduct(
        ProductsCompanion.insert(
          id: 'test-prod-103',
          shopId: 'shop-01',
          name: 'Fresh Croissant',
          costPrice: const drift.Value(1500.0),
          sellingPrice: 3000.0,
          stockQuantity: const drift.Value(5),
          trackStock: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('synced'),
        ),
      );

      // Stock Out / Damage: -2 croissants
      await db.productDao.adjustStock('test-prod-103', -2);
      var product = await (db.select(db.products)..where((t) => t.id.equals('test-prod-103'))).getSingle();
      expect(product.stockQuantity, equals(3));

      // Excessive write-off should clamp at 0
      await db.productDao.adjustStock('test-prod-103', -10);
      product = await (db.select(db.products)..where((t) => t.id.equals('test-prod-103'))).getSingle();
      expect(product.stockQuantity, equals(0));
    });

    test('setExactStock corrects stock count directly', () async {
      final now = DateTime.now().toUtc();
      await db.productDao.insertProduct(
        ProductsCompanion.insert(
          id: 'test-prod-104',
          shopId: 'shop-01',
          name: 'Energy Drink Can',
          costPrice: const drift.Value(800.0),
          sellingPrice: 1500.0,
          stockQuantity: const drift.Value(12),
          trackStock: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('synced'),
        ),
      );

      // Audit found exactly 50 cans in warehouse
      await db.productDao.setExactStock('test-prod-104', 50);

      final product = await (db.select(db.products)..where((t) => t.id.equals('test-prod-104'))).getSingle();
      expect(product.stockQuantity, equals(50));
      expect(product.syncStatus, equals('pending'));
    });

    test('Insert Category creates category with colorCode and pending syncStatus', () async {
      final now = DateTime.now().toUtc();
      await db.productDao.insertCategory(
        CategoriesCompanion.insert(
          id: 'cat-new-001',
          shopId: 'shop-01',
          name: 'Desserts & Cakes',
          colorCode: const drift.Value('#EC4899'),
          sortOrder: const drift.Value(1),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      final categories = await db.productDao.watchCategories().first;
      expect(categories.any((c) => c.name == 'Desserts & Cakes'), isTrue);
      final added = categories.firstWhere((c) => c.name == 'Desserts & Cakes');
      expect(added.colorCode, equals('#EC4899'));
    });
  });
}
