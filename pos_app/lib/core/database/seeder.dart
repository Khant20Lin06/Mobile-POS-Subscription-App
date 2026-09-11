import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class DatabaseSeeder {
  static const _uuid = Uuid();

  /// Seed demo data if the database is completely fresh
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final existingShops = await db.select(db.shops).get();
    if (existingShops.isNotEmpty) {
      return; // Already initialized
    }

    final now = DateTime.now().toUtc();
    final shopId = _uuid.v4();

    await db.transaction(() async {
      // 1. Default Shop
      await db.into(db.shops).insert(
            ShopsCompanion.insert(
              id: shopId,
              name: 'DOT POS Store',
              phone: const Value('09-770001122'),
              address: const Value('No. 123, Bogyoke Road, Yangon'),
              currency: const Value('MMK'),
              planTier: const Value('free'),
              subscriptionStatus: const Value('active'),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      // 2. Default Cashier & Owner
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: _uuid.v4(),
              shopId: shopId,
              name: 'Owner (Admin)',
              role: const Value('owner'),
              pinCode: '8888',
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      final cashierId = _uuid.v4();
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: cashierId,
              shopId: shopId,
              name: 'Ko Cashier',
              role: const Value('cashier'),
              pinCode: '1234',
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      // 3. Categories
      final catCoffee = _uuid.v4();
      final catBakery = _uuid.v4();
      final catDrinks = _uuid.v4();
      final catGeneral = _uuid.v4();

      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: catCoffee,
              shopId: shopId,
              name: 'Coffee & Tea',
              colorCode: const Value('#795548'),
              sortOrder: const Value(1),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: catBakery,
              shopId: shopId,
              name: 'Bakery & Snacks',
              colorCode: const Value('#FF9800'),
              sortOrder: const Value(2),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: catDrinks,
              shopId: shopId,
              name: 'Cold Beverages',
              colorCode: const Value('#03A9F4'),
              sortOrder: const Value(3),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: catGeneral,
              shopId: shopId,
              name: 'General Goods',
              colorCode: const Value('#4CAF50'),
              sortOrder: const Value(4),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      // 4. Products
      final demoProducts = [
        {
          'name': 'Iced Americano',
          'cat': catCoffee,
          'barcode': '1001',
          'cost': 2000.0,
          'price': 3800.0,
          'stock': 50,
          'imageUrl': 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=400&q=80',
        },
        {
          'name': 'Hot Cappuccino',
          'cat': catCoffee,
          'barcode': '1002',
          'cost': 2200.0,
          'price': 4200.0,
          'stock': 40,
          'imageUrl': 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&q=80',
        },
        {
          'name': 'Butter Croissant',
          'cat': catBakery,
          'barcode': '2001',
          'cost': 1500.0,
          'price': 3000.0,
          'stock': 25,
          'imageUrl': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&q=80',
        },
        {
          'name': 'Chocolate Brownie',
          'cat': catBakery,
          'barcode': '2002',
          'cost': 1800.0,
          'price': 3500.0,
          'stock': 30,
          'imageUrl': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400&q=80',
        },
        {
          'name': 'Mineral Water 1L',
          'cat': catDrinks,
          'barcode': '3001',
          'cost': 500.0,
          'price': 1000.0,
          'stock': 120,
          'imageUrl': 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=400&q=80',
        },
        {
          'name': 'Coca Cola 330ml Can',
          'cat': catDrinks,
          'barcode': '3002',
          'cost': 1100.0,
          'price': 1800.0,
          'stock': 75,
          'imageUrl': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&q=80',
        },
      ];

      for (final p in demoProducts) {
        await db.into(db.products).insert(
              ProductsCompanion.insert(
                id: _uuid.v4(),
                shopId: shopId,
                name: p['name'] as String,
                categoryId: Value(p['cat'] as String),
                barcode: Value(p['barcode'] as String),
                costPrice: Value(p['cost'] as double),
                sellingPrice: p['price'] as double,
                stockQuantity: Value(p['stock'] as int),
                trackStock: const Value(true),
                imageUrl: Value(p['imageUrl'] as String?),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value('pending'),
              ),
            );
      }

      // 5. Default Regular Customer
      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              id: _uuid.v4(),
              shopId: shopId,
              name: 'Daw Hla Hla (Regular)',
              phone: const Value('09-450011223'),
              totalDebt: const Value(0.0),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );
    });
  }
}
