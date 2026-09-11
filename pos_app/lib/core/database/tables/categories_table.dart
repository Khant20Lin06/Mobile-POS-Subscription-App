import 'package:drift/drift.dart';
import 'sync_mixins.dart';

@DataClassName('Category')
class Categories extends Table with SyncableColumns {
  TextColumn get shopId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  /// Hex color code for POS UI button styling (e.g. '#FF5722')
  TextColumn get colorCode => text().nullable()();
  
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
