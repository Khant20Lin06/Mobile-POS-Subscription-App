import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/shifts_table.dart';

part 'shift_dao.g.dart';

@DriftAccessor(tables: [Shifts])
class ShiftDao extends DatabaseAccessor<AppDatabase> with _$ShiftDaoMixin {
  ShiftDao(super.db);

  /// Watch the currently active (open) shift for a shop
  Stream<Shift?> watchActiveShift(String shopId) {
    return (select(shifts)
          ..where((tbl) =>
              tbl.shopId.equals(shopId) &
              tbl.status.equals('OPEN') &
              tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.openedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Get the currently active (open) shift for a shop
  Future<Shift?> getActiveShift(String shopId) {
    return (select(shifts)
          ..where((tbl) =>
              tbl.shopId.equals(shopId) &
              tbl.status.equals('OPEN') &
              tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.openedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Open a new shift
  Future<void> openShift(ShiftsCompanion entry) async {
    await into(shifts).insert(entry);
  }

  /// Record cash sales or non-cash sales from completed orders
  Future<void> recordOrderSale({
    required String shiftId,
    required double cashAmount,
    required double nonCashAmount,
  }) async {
    final shift = await (select(shifts)..where((t) => t.id.equals(shiftId))).getSingleOrNull();
    if (shift == null) return;

    final newCashSales = shift.cashSales + cashAmount;
    final newNonCashSales = shift.nonCashSales + nonCashAmount;
    final newExpected = shift.openingCashFloat + newCashSales + shift.cashIn - shift.cashOut;

    await (update(shifts)..where((t) => t.id.equals(shiftId))).write(
      ShiftsCompanion(
        cashSales: Value(newCashSales),
        nonCashSales: Value(newNonCashSales),
        expectedCash: Value(newExpected),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Record Pay In or Pay Out (e.g. debt repayment in cash or cash drawer expense)
  Future<void> recordCashMovement({
    required String shiftId,
    required String type, // 'PAY_IN' or 'PAY_OUT'
    required double amount,
    String? note,
  }) async {
    final shift = await (select(shifts)..where((t) => t.id.equals(shiftId))).getSingleOrNull();
    if (shift == null) return;

    double newCashIn = shift.cashIn;
    double newCashOut = shift.cashOut;

    if (type == 'PAY_IN') {
      newCashIn += amount;
    } else if (type == 'PAY_OUT') {
      newCashOut += amount;
    }

    final newExpected = shift.openingCashFloat + shift.cashSales + newCashIn - newCashOut;

    await (update(shifts)..where((t) => t.id.equals(shiftId))).write(
      ShiftsCompanion(
        cashIn: Value(newCashIn),
        cashOut: Value(newCashOut),
        expectedCash: Value(newExpected),
        notes: note != null ? Value(note) : shift.notes != null ? Value(shift.notes!) : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Close the shift with actual physical cash count
  Future<Shift> closeShift({
    required String shiftId,
    required double actualCash,
    String? closeNotes,
  }) async {
    final now = DateTime.now().toUtc();
    final shift = await (select(shifts)..where((t) => t.id.equals(shiftId))).getSingle();

    final expected = shift.openingCashFloat + shift.cashSales + shift.cashIn - shift.cashOut;
    final difference = actualCash - expected;

    await (update(shifts)..where((t) => t.id.equals(shiftId))).write(
      ShiftsCompanion(
        closedAt: Value(now),
        actualCash: Value(actualCash),
        expectedCash: Value(expected),
        difference: Value(difference),
        status: const Value('CLOSED'),
        notes: closeNotes != null ? Value(closeNotes) : const Value.absent(),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );

    return (select(shifts)..where((t) => t.id.equals(shiftId))).getSingle();
  }

  /// Watch shift history (most recent first)
  Stream<List<Shift>> watchShiftHistory(String shopId) {
    return (select(shifts)
          ..where((tbl) => tbl.shopId.equals(shopId) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.openedAt, mode: OrderingMode.desc)]))
        .watch();
  }
}
