import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/product_dao.dart';
import '../database/daos/order_dao.dart';
import '../database/daos/customer_dao.dart';
import '../database/daos/user_dao.dart';
import '../database/daos/shift_dao.dart';
import '../sync/sync_service.dart';

/// Singleton Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// DAO Providers
final productDaoProvider = Provider<ProductDao>((ref) {
  return ref.watch(databaseProvider).productDao;
});

final orderDaoProvider = Provider<OrderDao>((ref) {
  return ref.watch(databaseProvider).orderDao;
});

final customerDaoProvider = Provider<CustomerDao>((ref) {
  return ref.watch(databaseProvider).customerDao;
});

final userDaoProvider = Provider<UserDao>((ref) {
  return ref.watch(databaseProvider).userDao;
});

final shiftDaoProvider = Provider<ShiftDao>((ref) {
  return ref.watch(databaseProvider).shiftDao;
});

/// Reactive Streams for UI
final activeProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productDaoProvider).watchActiveProducts();
});

final recentOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderDaoProvider).watchRecentOrders();
});

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerDaoProvider).watchCustomers();
});

final customerHistoryStreamProvider = StreamProvider.autoDispose.family<List<CustomerLedger>, String>((ref, customerId) {
  return ref.watch(customerDaoProvider).watchCustomerHistory(customerId);
});

final allInventoryProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productDaoProvider).watchAllInventoryProducts();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(productDaoProvider).watchCategories();
});

final activeShiftStreamProvider = StreamProvider<Shift?>((ref) {
  final shop = ref.watch(currentShopProvider).value;
  if (shop == null) return Stream.value(null);
  return ref.watch(shiftDaoProvider).watchActiveShift(shop.id);
});

/// Shop & Subscription Information Provider
final currentShopProvider = FutureProvider<Shop?>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.shops)..limit(1)).getSingleOrNull();
});

/// Pending sync items count (across all tables)
final pendingSyncCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = ref.watch(databaseProvider);
  int count = 0;

  final pCount = await (db.select(db.products)..where((t) => t.syncStatus.equals('pending'))).get();
  final oCount = await (db.select(db.orders)..where((t) => t.syncStatus.equals('pending'))).get();
  final cCount = await (db.select(db.customers)..where((t) => t.syncStatus.equals('pending'))).get();
  final lCount = await (db.select(db.customerLedgers)..where((t) => t.syncStatus.equals('pending'))).get();
  final sCount = await (db.select(db.shifts)..where((t) => t.syncStatus.equals('pending'))).get();
  final uCount = await (db.select(db.users)..where((t) => t.syncStatus.equals('pending'))).get();

  count = pCount.length + oCount.length + cCount.length + lCount.length + sCount.length + uCount.length;
  return count;
});

/// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db: db);
});

