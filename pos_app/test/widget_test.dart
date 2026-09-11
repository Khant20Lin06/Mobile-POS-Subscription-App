import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/seeder.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/main.dart';

void main() {
  testWidgets('POS AppShell & POS Sales Screen loads successfully', (WidgetTester tester) async {
    // Set desktop screen size for widget test
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final inMemoryDb = AppDatabase(NativeDatabase.memory());
    await DatabaseSeeder.seedIfEmpty(inMemoryDb);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
        child: const MobilePosApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify POS Register header and Cashier
    expect(find.textContaining('Cashier:'), findsOneWidget);
    expect(find.text('Current Order (0)'), findsOneWidget);

    await inMemoryDb.close();
  });
}
