import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/customers_table.dart';
import '../tables/customer_ledgers_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers, CustomerLedgers])
class CustomerDao extends DatabaseAccessor<AppDatabase> with _$CustomerDaoMixin {
  CustomerDao(super.db);

  /// Watch all active customers
  Stream<List<Customer>> watchCustomers() {
    return (select(customers)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Alias for watchCustomers
  Stream<List<Customer>> watchAllActiveCustomers() => watchCustomers();

  /// Retrieve single customer by ID
  Future<Customer?> getCustomerById(String id) {
    return (select(customers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new customer
  Future<int> insertCustomer(CustomersCompanion entry) {
    return into(customers).insert(entry);
  }

  /// Record a credit purchase or a debt payment, adjusting the total debt atomically
  Future<void> recordLedgerEntry({
    required CustomerLedgersCompanion ledgerEntry,
  }) async {
    await transaction(() async {
      await into(customerLedgers).insert(ledgerEntry);

      final customer = await (select(customers)
            ..where((t) => t.id.equals(ledgerEntry.customerId.value)))
          .getSingleOrNull();

      if (customer != null) {
        double newDebt = customer.totalDebt;
        if (ledgerEntry.type.value == 'DEBT_INCREASE') {
          newDebt += ledgerEntry.amount.value;
        } else if (ledgerEntry.type.value == 'PAYMENT') {
          newDebt = (newDebt - ledgerEntry.amount.value).clamp(0.0, 999999999.0);
        }

        await (update(customers)..where((t) => t.id.equals(customer.id))).write(
          CustomersCompanion(
            totalDebt: Value(newDebt),
            updatedAt: Value(DateTime.now().toUtc()),
            syncStatus: const Value('pending'),
          ),
        );
      }
    });
  }

  /// Get ledger history for a specific customer
  Future<List<CustomerLedger>> getCustomerHistory(String customerId) {
    return (select(customerLedgers)
          ..where((tbl) => tbl.customerId.equals(customerId) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Watch live ledger history stream for a specific customer
  Stream<List<CustomerLedger>> watchCustomerHistory(String customerId) {
    return (select(customerLedgers)
          ..where((tbl) => tbl.customerId.equals(customerId) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Update an existing customer profile
  Future<bool> updateCustomer(CustomersCompanion entry) {
    return update(customers).replace(entry);
  }

  /// Soft delete a customer
  Future<int> softDeleteCustomer(String id) {
    final now = DateTime.now().toUtc();
    return (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Search customer by name or phone
  Future<List<Customer>> searchCustomers(String query) {
    return (select(customers)
          ..where((tbl) =>
              tbl.deletedAt.isNull() &
              (tbl.name.contains(query) | (tbl.phone.isNotNull() & tbl.phone.contains(query)))))
        .get();
  }
}
