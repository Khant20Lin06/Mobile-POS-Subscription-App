import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/hardware/thermal_receipt_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory SQLite database for test isolation
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Sprint 5 - Customer CRM & Debt Ledger Tests', () {
    test('Create customer persists with initial debt and pending syncStatus', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      final companion = CustomersCompanion.insert(
        id: 'cust-001',
        shopId: shopId,
        name: 'U Ba (ဦးဘ)',
        phone: const drift.Value('09123456789'),
        totalDebt: const drift.Value(50000.0),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value('pending'),
      );

      await db.customerDao.insertCustomer(companion);

      final customers = await db.customerDao.watchCustomers().first;
      expect(customers.length, equals(1));
      expect(customers.first.name, equals('U Ba (ဦးဘ)'));
      expect(customers.first.phone, equals('09123456789'));
      expect(customers.first.totalDebt, equals(50000.0));
      expect(customers.first.syncStatus, equals('pending'));
    });

    test('Record debt increase via DEBT_INCREASE ledger entry updates customer totalDebt', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust-002',
          shopId: shopId,
          name: 'Daw Hla (ဒေါ်လှ)',
          phone: const drift.Value('09987654321'),
          totalDebt: const drift.Value(10000.0),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      // Record credit purchase (+15,000 MMK)
      await db.customerDao.recordLedgerEntry(
        ledgerEntry: CustomerLedgersCompanion.insert(
          id: 'ledger-001',
          shopId: shopId,
          customerId: 'cust-002',
          type: 'DEBT_INCREASE',
          amount: 15000.0,
          notes: const drift.Value('Credit purchase for grocery items'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      final updated = await db.customerDao.getCustomerById('cust-002');
      expect(updated, isNotNull);
      expect(updated!.totalDebt, equals(25000.0));
      expect(updated.syncStatus, equals('pending'));
    });

    test('Debt repayment decreases debt, logs PAYMENT, and clamps to 0 on overpayment', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust-003',
          shopId: shopId,
          name: 'Ko Aung (ကိုအောင်)',
          phone: const drift.Value('09450001122'),
          totalDebt: const drift.Value(30000.0),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      // Partial repayment (20,000 MMK)
      await db.customerDao.recordLedgerEntry(
        ledgerEntry: CustomerLedgersCompanion.insert(
          id: 'ledger-002',
          shopId: shopId,
          customerId: 'cust-003',
          type: 'PAYMENT',
          amount: 20000.0,
          notes: const drift.Value('Cash repayment #1'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      var cust = await db.customerDao.getCustomerById('cust-003');
      expect(cust!.totalDebt, equals(10000.0));

      // Overpayment repayment test (15,000 MMK when remaining is 10,000 MMK)
      // Zero clamping ensures debt doesn't become negative
      await db.customerDao.recordLedgerEntry(
        ledgerEntry: CustomerLedgersCompanion.insert(
          id: 'ledger-003',
          shopId: shopId,
          customerId: 'cust-003',
          type: 'PAYMENT',
          amount: 15000.0,
          notes: const drift.Value('Cash overpayment test'),
          createdAt: drift.Value(now.add(const Duration(minutes: 5))),
          updatedAt: drift.Value(now.add(const Duration(minutes: 5))),
          syncStatus: const drift.Value('pending'),
        ),
      );

      cust = await db.customerDao.getCustomerById('cust-003');
      expect(cust!.totalDebt, equals(0.0));
    });

    test('watchCustomerHistory retrieves chronological ledger movements', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust-004',
          shopId: shopId,
          name: 'Ma Ni Ni',
          totalDebt: const drift.Value(0.0),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      await db.customerDao.recordLedgerEntry(
        ledgerEntry: CustomerLedgersCompanion.insert(
          id: 'led-1',
          shopId: shopId,
          customerId: 'cust-004',
          type: 'DEBT_INCREASE',
          amount: 5000.0,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      await db.customerDao.recordLedgerEntry(
        ledgerEntry: CustomerLedgersCompanion.insert(
          id: 'led-2',
          shopId: shopId,
          customerId: 'cust-004',
          type: 'PAYMENT',
          amount: 3000.0,
          createdAt: drift.Value(now.add(const Duration(minutes: 1))),
          updatedAt: drift.Value(now.add(const Duration(minutes: 1))),
          syncStatus: const drift.Value('pending'),
        ),
      );

      final history = await db.customerDao.watchCustomerHistory('cust-004').first;
      expect(history.length, equals(2));
      expect(history.first.id, equals('led-2')); // newest first
      expect(history.first.type, equals('PAYMENT'));
      expect(history.last.id, equals('led-1'));
    });

    test('Soft delete customer sets deletedAt and filters from active list', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'test-shop-001';

      await db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust-del',
          shopId: shopId,
          name: 'To Be Deleted',
          totalDebt: const drift.Value(0.0),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      var activeList = await db.customerDao.watchCustomers().first;
      expect(activeList.any((c) => c.id == 'cust-del'), isTrue);

      await db.customerDao.softDeleteCustomer('cust-del');

      activeList = await db.customerDao.watchCustomers().first;
      expect(activeList.any((c) => c.id == 'cust-del'), isFalse);
    });

    test('ThermalReceiptFormatter formats 58mm debt repayment slip correctly', () {
      final slip = ThermalReceiptFormatter.formatDebtRepaymentSlip(
        shopName: 'DOT POS GROCERY',
        shopAddress: 'No. 45, Insein Rd, Yangon',
        shopPhone: '09777888999',
        receiptId: 'RP-20260911-001',
        date: DateTime.now(),
        customerName: 'Ko Kyaw (ကိုကျော်)',
        customerPhone: '09123456789',
        previousDebt: 60000.0,
        amountPaid: 25000.0,
        remainingDebt: 35000.0,
        paymentMethod: 'CASH',
        notes: 'Monthly partial settlement',
        lineWidth: 32,
      );

      expect(slip, contains('DOT POS GROCERY'));
      expect(slip, contains('DEBT REPAYMENT SLIP'));
      expect(slip, contains('Ko Kyaw (ကိုကျော်)'));
      expect(slip, contains('25,000 MMK'));
      expect(slip, contains('60,000 MMK'));
      expect(slip, contains('35,000 MMK'));
      expect(slip, contains('CASH'));
      expect(slip, contains('RP-20260911-'));
    });

    test('ThermalReceiptFormatter formats customer statement slip with history', () {
      final now = DateTime.now();

      final statement = ThermalReceiptFormatter.formatCustomerStatementSlip(
        shopName: 'DOT POS GROCERY',
        customerName: 'Daw Tin Tin',
        customerPhone: '09222333444',
        date: now,
        totalDebt: 45000.0,
        transactions: [
          {
            'type': 'DEBT_INCREASE',
            'amount': 50000.0,
            'notes': 'Credit purchase',
            'date': now.subtract(const Duration(days: 2)),
          },
          {
            'type': 'PAYMENT',
            'amount': 5000.0,
            'notes': 'Partial payment',
            'date': now.subtract(const Duration(days: 1)),
          },
        ],
        lineWidth: 32,
      );

      expect(statement, contains('CUSTOMER ACCOUNT STATEMENT'));
      expect(statement, contains('Daw Tin Tin'));
      expect(statement, contains('45,000 MMK'));
      expect(statement, contains('[CREDIT +]'));
      expect(statement, contains('50,000 MMK'));
      expect(statement, contains('[PAID -]'));
      expect(statement, contains('5,000 MMK'));
    });
  });
}
