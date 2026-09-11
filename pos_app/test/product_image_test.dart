import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/widgets/product_image_widget.dart';

void main() {
  group('ProductImageWidget Tests', () {
    testWidgets('renders fallback icon when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageWidget(
              imageUrl: null,
              fallbackIcon: Icons.local_cafe_outlined,
            ),
          ),
        ),
      );

      // Should find the coffee icon
      expect(find.byIcon(Icons.local_cafe_outlined), findsOneWidget);
    });

    testWidgets('renders fallback icon when imageUrl is empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageWidget(
              imageUrl: '   ',
              fallbackIcon: Icons.bakery_dining_outlined,
            ),
          ),
        ),
      );

      // Should find bakery icon
      expect(find.byIcon(Icons.bakery_dining_outlined), findsOneWidget);
    });

    testWidgets('renders default fallback icon when not specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductImageWidget(
              imageUrl: null,
            ),
          ),
        ),
      );

      // Default icon is Icons.inventory_2_outlined
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
