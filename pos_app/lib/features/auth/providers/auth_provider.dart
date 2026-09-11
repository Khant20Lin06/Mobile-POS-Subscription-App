import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

enum AppPermission {
  viewCostPrice,
  deleteProduct,
  manageDatabase,
  manageStaff,
  viewZReport,
}

bool checkPermission(User? user, AppPermission permission) {
  if (user == null) return false;
  if (user.role == 'owner') return true;
  if (user.role == 'manager') {
    return permission != AppPermission.manageDatabase;
  }
  // Cashier role
  return false;
}

class CurrentUserNotifier extends StateNotifier<User?> {
  final Ref _ref;

  CurrentUserNotifier(this._ref) : super(null) {
    _initDefaultUser();
  }

  Future<void> _initDefaultUser() async {
    final db = _ref.read(databaseProvider);
    final users = await (db.select(db.users)
          ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();

    if (users.isNotEmpty) {
      // Default to owner or first active user
      final owner = users.firstWhere(
        (u) => u.role == 'owner',
        orElse: () => users.first,
      );
      state = owner;
    }
  }

  void setUser(User user) {
    state = user;
  }

  void logout() {
    state = null;
  }

  Future<bool> loginWithPin(String pinCode) async {
    final shop = await _ref.read(currentShopProvider.future);
    if (shop == null) return false;

    final user = await _ref.read(userDaoProvider).authenticatePin(
          shopId: shop.id,
          pinCode: pinCode,
        );

    if (user != null) {
      state = user;
      _ref.read(isTerminalLockedProvider.notifier).state = false;
      return true;
    }
    return false;
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier(ref);
});

/// Indicates if the POS terminal is locked
final isTerminalLockedProvider = StateProvider<bool>((ref) => false);
