import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/hardware/thermal_receipt_service.dart';
import 'package:pos_app/features/pos/providers/cart_provider.dart';

void main() {
  group('CartNotifier & CartState Tests', () {
    late CartNotifier notifier;

    final dummyProduct1 = Product(
      id: 'prod-1',
      shopId: 'shop-1',
      name: 'Iced Latte',
      costPrice: 2000,
      sellingPrice: 3500,
      stockQuantity: 50,
      trackStock: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: 'synced',
    );

    final dummyProduct2 = Product(
      id: 'prod-2',
      shopId: 'shop-1',
      name: 'Croissant',
      costPrice: 1500,
      sellingPrice: 2500,
      stockQuantity: 20,
      trackStock: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: 'synced',
    );

    setUp(() {
      notifier = CartNotifier();
    });

    test('Initial cart is empty', () {
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.totalAmount, 0.0);
      expect(notifier.state.totalItemCount, 0);
    });

    test('Adding products updates item count and subtotal', () {
      notifier.addToCart(dummyProduct1);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.totalItemCount, 1);
      expect(notifier.state.subtotal, 3500.0);

      // Add same product increments quantity
      notifier.addToCart(dummyProduct1, 2);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.totalItemCount, 3);
      expect(notifier.state.subtotal, 10500.0);

      // Add second product
      notifier.addToCart(dummyProduct2);
      expect(notifier.state.items.length, 2);
      expect(notifier.state.totalItemCount, 4);
      expect(notifier.state.subtotal, 13000.0);
    });

    test('Quantity increment and decrement works properly', () {
      notifier.addToCart(dummyProduct1, 2);
      notifier.increment(dummyProduct1.id);
      expect(notifier.state.totalItemCount, 3);

      notifier.decrement(dummyProduct1.id);
      expect(notifier.state.totalItemCount, 2);

      // Decrementing to 0 removes the item
      notifier.decrement(dummyProduct1.id);
      notifier.decrement(dummyProduct1.id);
      expect(notifier.state.isEmpty, isTrue);
    });

    test('Discounts correctly adjust total amount', () {
      notifier.addToCart(dummyProduct1, 2); // 7000 MMK
      notifier.setDiscount(1000.0);
      expect(notifier.state.subtotal, 7000.0);
      expect(notifier.state.discountAmount, 1000.0);
      expect(notifier.state.totalAmount, 6000.0);
    });

    test('Clearing cart resets all state', () {
      notifier.addToCart(dummyProduct1);
      notifier.setDiscount(500.0);
      notifier.clearCart();
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.discountAmount, 0.0);
    });
  });

  group('ThermalReceiptFormatter Tests', () {
    test('Formats 58mm ASCII receipt string correctly', () {
      final receipt = ReceiptData(
        shopName: 'City Mart Cafe',
        shopPhone: '09-770001122',
        orderNumber: 'INV-20260911-001',
        orderDate: DateTime(2026, 9, 11, 15, 30),
        cashierName: 'Cashier 1',
        items: const [
          ReceiptLineItem(name: 'Iced Americano', quantity: 2, unitPrice: 3500, subtotal: 7000),
          ReceiptLineItem(name: 'Croissant', quantity: 1, unitPrice: 2500, subtotal: 2500),
        ],
        subtotal: 9500,
        discount: 500,
        totalAmount: 9000,
        tenderAmount: 10000,
        changeDue: 1000,
        paymentMethod: 'CASH',
      );

      final formatted = ThermalReceiptFormatter.format58mm(receipt);
      expect(formatted, contains('CITY MART CAFE'));
      expect(formatted, contains('INV-20260911-001'));
      expect(formatted, contains('Iced Americano'));
      expect(formatted, contains('Croissant'));
      expect(formatted, contains('9,000 MMK'));
      expect(formatted, contains('Change Due:'));
    });
  });
}
