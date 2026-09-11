import 'package:drift/drift.dart';

/// Common columns for sync-ready offline-first entities.
/// Every table includes a client-generated UUID, timestamps for delta syncing,
/// soft deletion support, and local sync tracking status.
mixin SyncableColumns on Table {
  /// UUID v4 generated on the client
  TextColumn get id => text()();

  /// Creation timestamp in UTC
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last updated timestamp in UTC (used for incremental delta sync)
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft deletion timestamp. If not null, the item is deleted.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Sync status: 'pending' (needs upload to NestJS) or 'synced' (in sync with cloud)
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}
