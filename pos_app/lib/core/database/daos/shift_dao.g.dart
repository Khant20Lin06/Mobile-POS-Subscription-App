// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_dao.dart';

// ignore_for_file: type=lint
mixin _$ShiftDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShiftsTable get shifts => attachedDatabase.shifts;
  ShiftDaoManager get managers => ShiftDaoManager(this);
}

class ShiftDaoManager {
  final _$ShiftDaoMixin _db;
  ShiftDaoManager(this._db);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db.attachedDatabase, _db.shifts);
}
