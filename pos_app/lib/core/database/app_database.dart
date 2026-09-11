import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables/shops_table.dart';
import 'tables/users_table.dart';
import 'tables/categories_table.dart';
import 'tables/products_table.dart';
import 'tables/customers_table.dart';
import 'tables/customer_ledgers_table.dart';
import 'tables/orders_table.dart';
import 'tables/order_items_table.dart';
import 'tables/shifts_table.dart';

import 'daos/product_dao.dart';
import 'daos/order_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/user_dao.dart';
import 'daos/shift_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Shops,
    Users,
    Categories,
    Products,
    Customers,
    CustomerLedgers,
    Orders,
    OrderItems,
    Shifts,
  ],
  daos: [
    ProductDao,
    OrderDao,
    CustomerDao,
    UserDao,
    ShiftDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(shifts);
        }
      },
    );
  }
}

