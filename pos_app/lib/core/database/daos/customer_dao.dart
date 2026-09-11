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
          newDebt -= ledgerEntry.amount.value;
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
}
