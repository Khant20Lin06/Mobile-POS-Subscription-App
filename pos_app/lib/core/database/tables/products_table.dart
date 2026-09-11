import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('Product')
class Products extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  /// Barcode or SKU for camera / hardware scanner
  TextColumn get barcode => text().nullable()();
  
  /// Purchase/Cost price for COGS and gross profit margin calculation
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  
  /// Retail / Selling price
  RealColumn get sellingPrice => real()();
  
  /// Current stock level on hand
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  
  /// Whether to decrement inventory on sale
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
