import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  /// Authenticate active user by PIN code
  Future<User?> authenticatePin({required String shopId, required String pinCode}) {
    return (select(users)
          ..where((tbl) =>
              tbl.shopId.equals(shopId) &
              tbl.pinCode.equals(pinCode) &
              tbl.isActive.equals(true) &
              tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get single user by ID
  Future<User?> getUserById(String id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Watch all active users for a shop
  Stream<List<User>> watchActiveUsers(String shopId) {
    return (select(users)
          ..where((tbl) => tbl.shopId.equals(shopId) & tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Insert a new staff user
  Future<int> insertUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  /// Update user profile or PIN
  Future<bool> updateUser(UsersCompanion entry) {
    return update(users).replace(entry);
  }

  /// Soft delete user
  Future<int> softDeleteUser(String id) {
    final now = DateTime.now().toUtc();
    return (update(users)..where((t) => t.id.equals(id))).write(
      UsersCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }
}
