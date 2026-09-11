import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class DatabaseSeeder {
  static const _uuid = Uuid();

  /// Seed demo data (calls seedIfEmpty)
  static Future<void> seedInitialData(AppDatabase db) => seedIfEmpty(db);

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
      final catMeals = _uuid.v4();
      final catSnacks = _uuid.v4();
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
              name: 'Bakery & Pastries',
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
              id: catMeals,
              shopId: shopId,
              name: 'Food & Meals',
              colorCode: const Value('#E91E63'),
              sortOrder: const Value(4),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: catSnacks,
              shopId: shopId,
              name: 'Packaged Snacks',
              colorCode: const Value('#9C27B0'),
              sortOrder: const Value(5),
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
              sortOrder: const Value(6),
              createdAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );

      // 4. Products (27 authentic items)
      final demoProducts = _getDemoProductList(
        catCoffee: catCoffee,
        catBakery: catBakery,
        catDrinks: catDrinks,
        catMeals: catMeals,
        catSnacks: catSnacks,
        catGeneral: catGeneral,
      );

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

  /// Automatically populates additional rich demo products if the database has 6 or fewer products.
  static Future<void> seedExtraProductsIfFew(AppDatabase db) async {
    try {
      final existingProducts = await (db.select(db.products)..where((t) => t.deletedAt.isNull())).get();
      if (existingProducts.length >= 15) return; // Already has rich inventory

      final shops = await db.select(db.shops).get();
      if (shops.isEmpty) return;
      final shopId = shops.first.id;

      final now = DateTime.now().toUtc();
      final existingCategories = await (db.select(db.categories)..where((t) => t.deletedAt.isNull())).get();

      // Find or create categories
      Future<String> getOrCreateCat(String name, String color, int order) async {
        final found = existingCategories.where((c) => c.name.toLowerCase() == name.toLowerCase());
        if (found.isNotEmpty) return found.first.id;
        final newId = _uuid.v4();
        await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: newId,
            shopId: shopId,
            name: name,
            colorCode: Value(color),
            sortOrder: Value(order),
            createdAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('pending'),
          ),
        );
        return newId;
      }

      final catCoffee = await getOrCreateCat('Coffee & Tea', '#795548', 1);
      final catBakery = await getOrCreateCat('Bakery & Pastries', '#FF9800', 2);
      final catDrinks = await getOrCreateCat('Cold Beverages', '#03A9F4', 3);
      final catMeals = await getOrCreateCat('Food & Meals', '#E91E63', 4);
      final catSnacks = await getOrCreateCat('Packaged Snacks', '#9C27B0', 5);
      final catGeneral = await getOrCreateCat('General Goods', '#4CAF50', 6);

      final demoProducts = _getDemoProductList(
        catCoffee: catCoffee,
        catBakery: catBakery,
        catDrinks: catDrinks,
        catMeals: catMeals,
        catSnacks: catSnacks,
        catGeneral: catGeneral,
      );

      final existingBarcodes = existingProducts.map((p) => p.barcode).toSet();
      final existingNames = existingProducts.map((p) => p.name.toLowerCase()).toSet();

      for (final p in demoProducts) {
        final name = p['name'] as String;
        final barcode = p['barcode'] as String;
        if (existingBarcodes.contains(barcode) || existingNames.contains(name.toLowerCase())) {
          continue; // Avoid duplicating existing items
        }

        await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: _uuid.v4(),
            shopId: shopId,
            name: name,
            categoryId: Value(p['cat'] as String),
            barcode: Value(barcode),
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
    } catch (_) {}
  }

  static List<Map<String, dynamic>> _getDemoProductList({
    required String catCoffee,
    required String catBakery,
    required String catDrinks,
    required String catMeals,
    required String catSnacks,
    required String catGeneral,
  }) {
    return [
      // 1. Coffee & Tea
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
        'name': 'Caramel Macchiato',
        'cat': catCoffee,
        'barcode': '1003',
        'cost': 2500.0,
        'price': 4800.0,
        'stock': 35,
        'imageUrl': 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=400&q=80',
      },
      {
        'name': 'Matcha Green Tea Latte',
        'cat': catCoffee,
        'barcode': '1004',
        'cost': 2600.0,
        'price': 5000.0,
        'stock': 30,
        'imageUrl': 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=400&q=80',
      },
      {
        'name': 'Royal Myanmar Tea (လက်ဖက်ရည်)',
        'cat': catCoffee,
        'barcode': '1005',
        'cost': 1000.0,
        'price': 2200.0,
        'stock': 60,
        'imageUrl': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&q=80',
      },
      {
        'name': 'Iced Lemon Tea',
        'cat': catCoffee,
        'barcode': '1006',
        'cost': 1200.0,
        'price': 2500.0,
        'stock': 45,
        'imageUrl': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&q=80',
      },

      // 2. Bakery & Pastries
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
        'name': 'Blueberry Cheesecake Slice',
        'cat': catBakery,
        'barcode': '2003',
        'cost': 3200.0,
        'price': 6000.0,
        'stock': 15,
        'imageUrl': 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=400&q=80',
      },
      {
        'name': 'Portuguese Egg Tart (2pcs)',
        'cat': catBakery,
        'barcode': '2004',
        'cost': 1800.0,
        'price': 3600.0,
        'stock': 28,
        'imageUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
      },
      {
        'name': 'Almond Danish Pastry',
        'cat': catBakery,
        'barcode': '2005',
        'cost': 2000.0,
        'price': 4000.0,
        'stock': 20,
        'imageUrl': 'https://images.unsplash.com/photo-1589367920969-ab8e050bbb04?w=400&q=80',
      },
      {
        'name': 'Banana Choco Muffin',
        'cat': catBakery,
        'barcode': '2006',
        'cost': 1400.0,
        'price': 2800.0,
        'stock': 35,
        'imageUrl': 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400&q=80',
      },

      // 3. Cold Beverages
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
      {
        'name': 'Sprite 330ml Can',
        'cat': catDrinks,
        'barcode': '3003',
        'cost': 1100.0,
        'price': 1800.0,
        'stock': 65,
        'imageUrl': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400&q=80',
      },
      {
        'name': 'Red Bull Energy 250ml',
        'cat': catDrinks,
        'barcode': '3004',
        'cost': 1600.0,
        'price': 2500.0,
        'stock': 50,
        'imageUrl': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400&q=80',
      },
      {
        'name': 'Fresh Orange Juice 500ml',
        'cat': catDrinks,
        'barcode': '3005',
        'cost': 2200.0,
        'price': 4500.0,
        'stock': 25,
        'imageUrl': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=400&q=80',
      },
      {
        'name': 'Sparkling Passion Soda',
        'cat': catDrinks,
        'barcode': '3006',
        'cost': 1800.0,
        'price': 3800.0,
        'stock': 40,
        'imageUrl': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400&q=80',
      },

      // 4. Food & Meals
      {
        'name': 'Crispy Chicken Burger',
        'cat': catMeals,
        'barcode': '4001',
        'cost': 3500.0,
        'price': 6500.0,
        'stock': 20,
        'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
      },
      {
        'name': 'French Fries (Large)',
        'cat': catMeals,
        'barcode': '4002',
        'cost': 1600.0,
        'price': 3200.0,
        'stock': 40,
        'imageUrl': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&q=80',
      },
      {
        'name': 'Spicy Chicken Drumsticks (3pcs)',
        'cat': catMeals,
        'barcode': '4003',
        'cost': 3800.0,
        'price': 7000.0,
        'stock': 18,
        'imageUrl': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400&q=80',
      },
      {
        'name': 'Club Sandwich with Egg & Ham',
        'cat': catMeals,
        'barcode': '4004',
        'cost': 2800.0,
        'price': 5500.0,
        'stock': 22,
        'imageUrl': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&q=80',
      },

      // 5. Packaged Snacks
      {
        'name': "Lay's Classic Potato Chips 50g",
        'cat': catSnacks,
        'barcode': '5001',
        'cost': 2200.0,
        'price': 3500.0,
        'stock': 45,
        'imageUrl': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&q=80',
      },
      {
        'name': 'Oreo Vanilla Cookies 120g',
        'cat': catSnacks,
        'barcode': '5002',
        'cost': 1500.0,
        'price': 2600.0,
        'stock': 50,
        'imageUrl': 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=400&q=80',
      },
      {
        'name': 'Pringles Sour Cream & Onion 107g',
        'cat': catSnacks,
        'barcode': '5003',
        'cost': 3800.0,
        'price': 5800.0,
        'stock': 30,
        'imageUrl': 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=400&q=80',
      },
      {
        'name': 'KitKat Chocolate 4 Finger',
        'cat': catSnacks,
        'barcode': '5004',
        'cost': 1200.0,
        'price': 2200.0,
        'stock': 60,
        'imageUrl': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400&q=80',
      },
      {
        'name': 'Roasted Salted Cashew Nuts 100g',
        'cat': catSnacks,
        'barcode': '5005',
        'cost': 3000.0,
        'price': 5000.0,
        'stock': 35,
        'imageUrl': 'https://images.unsplash.com/photo-1509912743198-a836881c15f9?w=400&q=80',
      },
    ];
  }
}
