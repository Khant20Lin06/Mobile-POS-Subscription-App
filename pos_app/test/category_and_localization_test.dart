import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/localization/app_locale.dart';

void main() {
  group('Localization & Language Provider Tests', () {
    test('AppLanguage switches properly and provides localized strings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default is Myanmar
      expect(container.read(appLanguageProvider), equals(AppLanguage.my));

      // Check key translations
      expect(AppTranslations.tr('nav_register', AppLanguage.en), equals('Register'));
      expect(AppTranslations.tr('nav_register', AppLanguage.my), equals('အရောင်း'));

      expect(AppTranslations.tr('nav_inventory', AppLanguage.en), equals('Inventory'));
      expect(AppTranslations.tr('nav_inventory', AppLanguage.my), equals('စတော့'));

      expect(AppTranslations.tr('nav_settings', AppLanguage.en), equals('Settings'));
      expect(AppTranslations.tr('nav_settings', AppLanguage.my), equals('ဆက်တင်များ'));

      expect(AppTranslations.tr('plan_free', AppLanguage.my), contains('အော့ဖ်လိုင်း'));
      expect(AppTranslations.tr('plan_pro', AppLanguage.my), contains('ကလောက်'));
      expect(AppTranslations.tr('plan_custom', AppLanguage.my), contains('ဆိုင်ခွဲ'));

      // Switch language to English
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en);
      expect(container.read(appLanguageProvider), equals(AppLanguage.en));

      // Toggle back to Myanmar
      container.read(appLanguageProvider.notifier).toggleLanguage();
      expect(container.read(appLanguageProvider), equals(AppLanguage.my));
    });
  });

  group('Category CRUD & Safety Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Insert, update, count products, and soft delete category safely', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'shop-cat-test';

      // 1. Insert category
      final categoryCompanion = CategoriesCompanion.insert(
        id: 'cat-001',
        shopId: shopId,
        name: 'Beverages',
        colorCode: const drift.Value('#3B82F6'),
        sortOrder: const drift.Value(1),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value('pending'),
      );
      await db.productDao.insertCategory(categoryCompanion);

      var categories = await db.productDao.watchCategories().first;
      expect(categories.length, equals(1));
      expect(categories.first.name, equals('Beverages'));
      expect(categories.first.colorCode, equals('#3B82F6'));

      // 2. Add product associated with this category
      final prodCompanion = ProductsCompanion.insert(
        id: 'prod-001',
        shopId: shopId,
        name: 'Espresso',
        categoryId: const drift.Value('cat-001'),
        sellingPrice: 2000.0,
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );
      await db.productDao.insertProduct(prodCompanion);

      // Count products in this category
      final productCount = await db.productDao.getCategoryProductCount('cat-001');
      expect(productCount, equals(1));

      // 3. Update category name and color
      final updatedCompanion = CategoriesCompanion(
        id: const drift.Value('cat-001'),
        shopId: const drift.Value(shopId),
        name: const drift.Value('Hot & Cold Beverages'),
        colorCode: const drift.Value('#10B981'),
        sortOrder: const drift.Value(1),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(DateTime.now().toUtc()),
        syncStatus: const drift.Value('pending'),
      );
      await db.productDao.updateCategory(updatedCompanion);

      categories = await db.productDao.watchCategories().first;
      expect(categories.first.name, equals('Hot & Cold Beverages'));
      expect(categories.first.colorCode, equals('#10B981'));

      // 4. Soft delete category (safe: unassigns products)
      await db.productDao.softDeleteCategory('cat-001');

      // Category list should now exclude soft-deleted category
      categories = await db.productDao.watchCategories().first;
      expect(categories.length, equals(0));

      // Product still exists and categoryId has been safely unassigned to null
      final allProducts = await db.productDao.watchAllInventoryProducts().first;
      expect(allProducts.length, equals(1));
      expect(allProducts.first.name, equals('Espresso'));
      expect(allProducts.first.categoryId, isNull);
    });
  });
}
