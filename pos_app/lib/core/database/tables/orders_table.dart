import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('Order')
class Orders extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  
  /// Human readable invoice number e.g. "INV-20260911-0001"
  TextColumn get orderNumber => text()();
  
  RealColumn get subtotal => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  
  /// Payment method: 'CASH', 'KBZ_PAY', 'WAVE_PAY', 'CREDIT'
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))();
  
  /// Order status: 'COMPLETED', 'VOIDED', 'HOLD'
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))();
  
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
