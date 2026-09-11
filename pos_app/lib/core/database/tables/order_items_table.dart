import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('OrderItem')
class OrderItems extends Table with SyncableColumns {
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  
  /// Snapshot of product name at the time of purchase
  TextColumn get productName => text()();
  
  IntColumn get quantity => integer()();
  
  /// Unit cost price snapshot at the time of purchase (for COGS)
  RealColumn get costPrice => real()();
  
  /// Unit selling price snapshot at the time of purchase
  RealColumn get unitPrice => real()();
  
  RealColumn get subtotal => real()();

  @override
  Set<Column> get primaryKey => {id};
}
