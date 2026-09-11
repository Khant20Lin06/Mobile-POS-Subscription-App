import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('Shift')
class Shifts extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get userId => text()();

  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  RealColumn get openingCashFloat => real().withDefault(const Constant(0.0))();
  RealColumn get cashSales => real().withDefault(const Constant(0.0))();
  RealColumn get nonCashSales => real().withDefault(const Constant(0.0))();
  RealColumn get cashIn => real().withDefault(const Constant(0.0))();
  RealColumn get cashOut => real().withDefault(const Constant(0.0))();
  RealColumn get expectedCash => real().withDefault(const Constant(0.0))();
  RealColumn get actualCash => real().nullable()();
  RealColumn get difference => real().nullable()();

  /// Status: 'OPEN', 'CLOSED'
  TextColumn get status => text().withDefault(const Constant('OPEN'))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
