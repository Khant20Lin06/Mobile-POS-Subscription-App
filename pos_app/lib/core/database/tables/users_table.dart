import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('User')
class Users extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  /// Role: 'owner', 'manager', 'cashier'
  TextColumn get role => text().withDefault(const Constant('cashier'))();
  
  /// 4 or 6 digit PIN code for rapid POS cashier login/switching
  TextColumn get pinCode => text().withLength(min: 4, max: 10)();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
