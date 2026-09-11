import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('Customer')
class Customers extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  
  /// Total outstanding debt balance
  RealColumn get totalDebt => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
