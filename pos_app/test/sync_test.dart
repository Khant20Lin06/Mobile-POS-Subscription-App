import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/sync/sync_service.dart';

void main() {
  group('SyncResult Model Tests', () {
    test('Constructs success SyncResult correctly', () {
      const result = SyncResult(
        success: true,
        itemsPushed: 12,
        itemsPulled: 5,
        message: 'Sync completed successfully',
      );

      expect(result.success, isTrue);
      expect(result.itemsPushed, equals(12));
      expect(result.itemsPulled, equals(5));
      expect(result.message, equals('Sync completed successfully'));
    });

    test('Constructs failure SyncResult correctly', () {
      const result = SyncResult(
        success: false,
        message: 'License activation failed: invalid key',
      );

      expect(result.success, isFalse);
      expect(result.itemsPushed, equals(0));
      expect(result.itemsPulled, equals(0));
      expect(result.message, contains('invalid key'));
    });
  });
}
