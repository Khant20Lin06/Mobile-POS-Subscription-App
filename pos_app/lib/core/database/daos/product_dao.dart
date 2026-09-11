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
}
