import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('Shop')
class Shops extends Table with SyncableColumns {
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('MMK'))();
  
  /// Subscription tier: 'free', 'pro', 'custom'
  TextColumn get planTier => text().withDefault(const Constant('free'))();
  
  /// Status: 'active', 'expired', 'trial'
  TextColumn get subscriptionStatus => text().withDefault(const Constant('active'))();
  
  /// Timestamp when paid subscription expires
  DateTimeColumn get subscriptionExpiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
