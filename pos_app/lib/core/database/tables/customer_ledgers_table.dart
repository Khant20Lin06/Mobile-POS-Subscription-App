import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('CustomerLedger')
class CustomerLedgers extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get customerId => text()();
  
  /// Associated order/invoice id if generated from a sale
  TextColumn get orderId => text().nullable()();
  
  /// Type: 'DEBT_INCREASE' (credit purchase), 'PAYMENT' (debt payoff)
  TextColumn get type => text()();
  
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
