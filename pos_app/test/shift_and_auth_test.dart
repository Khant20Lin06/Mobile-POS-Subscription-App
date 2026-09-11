import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/hardware/thermal_receipt_service.dart';
import 'package:pos_app/features/auth/providers/auth_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory SQLite database for test isolation
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Sprint 6 - Cashier PIN & Auth Tests', () {
    test('User PIN authentication succeeds with correct PIN and rejects wrong PIN', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.userDao.insertUser(
        UsersCompanion.insert(
          id: 'user-001',
          shopId: shopId,
          name: 'Ko Cashier',
          role: const drift.Value('cashier'),
          pinCode: '1234',
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      // Correct PIN
      final authenticated = await db.userDao.authenticatePin(
        shopId: shopId,
        pinCode: '1234',
      );
      expect(authenticated, isNotNull);
      expect(authenticated!.name, equals('Ko Cashier'));
      expect(authenticated.role, equals('cashier'));

      // Incorrect PIN
      final wrongPin = await db.userDao.authenticatePin(
        shopId: shopId,
        pinCode: '9999',
      );
      expect(wrongPin, isNull);
    });

    test('watchActiveUsers returns active users and filters soft-deleted users', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.userDao.insertUser(
        UsersCompanion.insert(
          id: 'user-002',
          shopId: shopId,
          name: 'Staff A',
          pinCode: '1111',
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      await db.userDao.insertUser(
        UsersCompanion.insert(
          id: 'user-003',
          shopId: shopId,
          name: 'Staff B',
          pinCode: '2222',
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      var users = await db.userDao.watchActiveUsers(shopId).first;
      expect(users.length, equals(2));

      await db.userDao.softDeleteUser('user-002');

      users = await db.userDao.watchActiveUsers(shopId).first;
      expect(users.length, equals(1));
      expect(users.first.id, equals('user-003'));
    });

    test('RBAC checkPermission correctly distinguishes owner, manager, and cashier', () {
      final now = DateTime.now();

      final owner = User(
        id: '1',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        syncStatus: 'synced',
        shopId: 's1',
        name: 'Owner',
        role: 'owner',
        pinCode: '8888',
        isActive: true,
      );

      final cashier = User(
        id: '2',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        syncStatus: 'synced',
        shopId: 's1',
        name: 'Cashier',
        role: 'cashier',
        pinCode: '1234',
        isActive: true,
      );

      // Owner has full permission
      expect(checkPermission(owner, AppPermission.viewCostPrice), isTrue);
      expect(checkPermission(owner, AppPermission.deleteProduct), isTrue);
      expect(checkPermission(owner, AppPermission.manageDatabase), isTrue);
      expect(checkPermission(owner, AppPermission.viewZReport), isTrue);

      // Cashier is restricted from sensitive actions
      expect(checkPermission(cashier, AppPermission.viewCostPrice), isFalse);
      expect(checkPermission(cashier, AppPermission.deleteProduct), isFalse);
      expect(checkPermission(cashier, AppPermission.manageDatabase), isFalse);
      expect(checkPermission(cashier, AppPermission.viewZReport), isFalse);
    });
  });

  group('Sprint 6 - Shift Management & Cash Drawer Audit Tests', () {
    test('Open shift creates record with starting cash float and OPEN status', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.shiftDao.openShift(
        ShiftsCompanion.insert(
          id: 'shift-001',
          shopId: shopId,
          userId: 'user-001',
          openedAt: now,
          openingCashFloat: const drift.Value(50000.0),
          expectedCash: const drift.Value(50000.0),
          status: const drift.Value('OPEN'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final activeShift = await db.shiftDao.getActiveShift(shopId);
      expect(activeShift, isNotNull);
      expect(activeShift!.id, equals('shift-001'));
      expect(activeShift.openingCashFloat, equals(50000.0));
      expect(activeShift.expectedCash, equals(50000.0));
      expect(activeShift.status, equals('OPEN'));
    });

    test('Recording order sales adjusts cash sales and expected cash balance', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.shiftDao.openShift(
        ShiftsCompanion.insert(
          id: 'shift-002',
          shopId: shopId,
          userId: 'user-001',
          openedAt: now,
          openingCashFloat: const drift.Value(30000.0),
          expectedCash: const drift.Value(30000.0),
          status: const drift.Value('OPEN'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Cash sale of 15,000 MMK and digital sale of 8,000 MMK
      await db.shiftDao.recordOrderSale(
        shiftId: 'shift-002',
        cashAmount: 15000.0,
        nonCashAmount: 8000.0,
      );

      final shift = await db.shiftDao.getActiveShift(shopId);
      expect(shift!.cashSales, equals(15000.0));
      expect(shift.nonCashSales, equals(8000.0));
      expect(shift.expectedCash, equals(45000.0)); // 30,000 float + 15,000 cash
    });

    test('Pay In and Pay Out properly adjust cash drawer amounts', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.shiftDao.openShift(
        ShiftsCompanion.insert(
          id: 'shift-003',
          shopId: shopId,
          userId: 'user-001',
          openedAt: now,
          openingCashFloat: const drift.Value(50000.0),
          expectedCash: const drift.Value(50000.0),
          status: const drift.Value('OPEN'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Pay Out 5,000 MMK for petty cash (ice/plastic bags)
      await db.shiftDao.recordCashMovement(
        shiftId: 'shift-003',
        type: 'PAY_OUT',
        amount: 5000.0,
        note: 'Plastic bags and ice',
      );

      var shift = await db.shiftDao.getActiveShift(shopId);
      expect(shift!.cashOut, equals(5000.0));
      expect(shift.expectedCash, equals(45000.0)); // 50,000 - 5,000

      // Pay In 10,000 MMK (customer repaid debt in cash)
      await db.shiftDao.recordCashMovement(
        shiftId: 'shift-003',
        type: 'PAY_IN',
        amount: 10000.0,
        note: 'Customer debt cash settlement',
      );

      shift = await db.shiftDao.getActiveShift(shopId);
      expect(shift!.cashIn, equals(10000.0));
      expect(shift.expectedCash, equals(55000.0)); // 45,000 + 10,000
    });

    test('Close shift computes discrepancy and marks status as CLOSED', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.shiftDao.openShift(
        ShiftsCompanion.insert(
          id: 'shift-004',
          shopId: shopId,
          userId: 'user-001',
          openedAt: now,
          openingCashFloat: const drift.Value(40000.0),
          expectedCash: const drift.Value(40000.0),
          status: const drift.Value('OPEN'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      await db.shiftDao.recordOrderSale(
        shiftId: 'shift-004',
        cashAmount: 20000.0,
        nonCashAmount: 0.0,
      );
      // Expected cash is 60,000 MMK

      // Actual physical count is 59,500 MMK (500 MMK Short)
      final closed = await db.shiftDao.closeShift(
        shiftId: 'shift-004',
        actualCash: 59500.0,
        closeNotes: '500 MMK coin change rounding short',
      );

      expect(closed.status, equals('CLOSED'));
      expect(closed.actualCash, equals(59500.0));
      expect(closed.expectedCash, equals(60000.0));
      expect(closed.difference, equals(-500.0)); // Short by 500
      expect(closed.closedAt, isNotNull);

      // Confirm no active shift remains open
      final active = await db.shiftDao.getActiveShift(shopId);
      expect(active, isNull);
    });

    test('ThermalReceiptFormatter formats 58mm Shift Closing Slip correctly', () {
      final now = DateTime.now();
      final openedAt = now.subtract(const Duration(hours: 8));

      final slip = ThermalReceiptFormatter.formatShiftClosingSlip(
        shopName: 'DOT POS GROCERY',
        shopPhone: '09777888999',
        shiftId: 'SHIFT-20260911-001',
        cashierName: 'Ko Cashier',
        openedAt: openedAt,
        closedAt: now,
        openingFloat: 50000.0,
        cashSales: 120000.0,
        nonCashSales: 45000.0,
        cashIn: 5000.0,
        cashOut: 3000.0,
        expectedCash: 172000.0,
        actualCash: 172000.0,
        difference: 0.0,
        notes: 'End of afternoon shift',
        lineWidth: 32,
      );

      expect(slip, contains('DOT POS GROCERY'));
      expect(slip, contains('SHIFT CLOSING SLIP'));
      expect(slip, contains('Ko Cashier'));
      expect(slip, contains('50,000 MMK'));
      expect(slip, contains('120,000 MMK'));
      expect(slip, contains('172,000 MMK'));
      expect(slip, contains('BALANCED'));
      expect(slip, contains('Cashier Sign'));
      expect(slip, contains('Manager Sign'));
    });
  });
}
