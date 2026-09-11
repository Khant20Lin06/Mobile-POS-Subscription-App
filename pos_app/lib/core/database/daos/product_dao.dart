import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  /// Watch all active products for real-time POS grid UI
  Stream<List<Product>> watchActiveProducts() {
    return (select(products)
          ..where((tbl) => tbl.deletedAt.isNull() & tbl.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Get active products filtered by category
  Stream<List<Product>> watchProductsByCategory(String? categoryId) {
    final query = select(products)
      ..where((tbl) => tbl.deletedAt.isNull() & tbl.isActive.equals(true));
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch();
  }

  /// Search product by barcode or name
  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((tbl) =>
              tbl.deletedAt.isNull() &
              tbl.isActive.equals(true) &
              (tbl.name.contains(query) | tbl.barcode.equals(query))))
        .get();
  }

  /// Find exact product by barcode (for barcode gun / camera scan)
  Future<Product?> getProductByBarcode(String barcode) {
    return (select(products)
          ..where((tbl) =>
              tbl.deletedAt.isNull() &
              tbl.isActive.equals(true) &
              tbl.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Insert a new product (marks syncStatus as 'pending')
  Future<int> insertProduct(ProductsCompanion entry) {
    return into(products).insert(entry);
  }

  /// Update an existing product and update `updatedAt` timestamp for delta sync
  Future<bool> updateProduct(ProductsCompanion entry) {
    return update(products).replace(entry);
  }

  /// Soft delete a product
  Future<int> softDeleteProduct(String id) {
    return (update(products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Decrement stock quantity after an order is placed
  Future<void> decrementStock(String productId, int quantity) async {
    final product = await (select(products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product != null && product.trackStock) {
      final newQuantity = product.stockQuantity - quantity;
      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(newQuantity),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('pending'),
        ),
      );
    }
  }

  /// Watch all non-deleted products for Inventory management
  Stream<List<Product>> watchAllInventoryProducts() {
    return (select(products)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Adjust stock by delta (+ for Stock In, - for Stock Out/Wastage)
  Future<void> adjustStock(String productId, int quantityDelta) async {
    final product = await (select(products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product != null) {
      final newQuantity = (product.stockQuantity + quantityDelta).clamp(0, 999999);
      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(newQuantity),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('pending'),
        ),
      );
    }
  }

  /// Set exact stock count (Inventory count correction)
  Future<void> setExactStock(String productId, int exactQuantity) async {
    final product = await (select(products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product != null) {
      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          stockQuantity: Value(exactQuantity.clamp(0, 999999)),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('pending'),
        ),
      );
    }
  }

  /// Watch all categories
  Stream<List<Category>> watchCategories() {
    return (select(db.categories)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Insert new category
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(db.categories).insert(entry);
  }

  /// Update existing category
  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(db.categories).replace(entry);
  }

  /// Soft delete category and safely unassign associated products
  Future<int> softDeleteCategory(String id) async {
    // Safely detach products from this category so they are not orphaned
    await (update(products)..where((t) => t.categoryId.equals(id))).write(
      const ProductsCompanion(
        categoryId: Value(null),
      ),
    );

    return (update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Get product count for a given category
  Future<int> getCategoryProductCount(String categoryId) async {
    final countExp = products.id.count();
    final query = selectOnly(products)
      ..addColumns([countExp])
      ..where(products.categoryId.equals(categoryId) & products.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
