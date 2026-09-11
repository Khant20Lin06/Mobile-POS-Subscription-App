import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/localization/app_locale.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Sale Invoice Feature & DAO Tests', () {
    test('Create order with items, query via watchOrdersFiltered, and getOrderWithDetails', () async {
      final now = DateTime.now().toUtc();
      const shopId = 'shop-inv-001';

      // 1. Create a customer
      await db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust-inv-001',
          shopId: shopId,
          name: 'Ko Min (ကိုမင်း)',
          phone: const drift.Value('09777123456'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      // 2. Create a product
      await db.productDao.insertProduct(
        ProductsCompanion.insert(
          id: 'prod-001',
          shopId: shopId,
          name: 'Red Bull Energy Drink',
          sellingPrice: 2500.0,
          costPrice: const drift.Value(1800.0),
          stockQuantity: const drift.Value(50),
          trackStock: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      // 3. Create an order with items
      final orderEntry = OrdersCompanion.insert(
        id: 'order-001',
        shopId: shopId,
        orderNumber: 'INV-20260912-0001',
        customerId: const drift.Value('cust-inv-001'),
        subtotal: 5000.0,
        discountAmount: const drift.Value(0.0),
        taxAmount: const drift.Value(0.0),
        totalAmount: 5000.0,
        paymentMethod: const drift.Value('CASH'),
        status: const drift.Value('COMPLETED'),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value('pending'),
      );

      final items = [
        OrderItemsCompanion.insert(
          id: 'item-001',
          orderId: 'order-001',
          productId: 'prod-001',
          productName: 'Red Bull Energy Drink',
          quantity: 2,
          costPrice: 1800.0,
          unitPrice: 2500.0,
          subtotal: 5000.0,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      ];

      await db.orderDao.createOrderWithItems(
        orderEntry: orderEntry,
        items: items,
      );

      // 4. Test watchOrdersFiltered without filter
      final allOrders = await db.orderDao.watchOrdersFiltered().first;
      expect(allOrders.length, equals(1));
      expect(allOrders.first.orderNumber, equals('INV-20260912-0001'));
      expect(allOrders.first.totalAmount, equals(5000.0));

      // 5. Test watchOrdersFiltered with query filter
      final matched = await db.orderDao.watchOrdersFiltered(query: '0001').first;
      expect(matched.length, equals(1));

      final notMatched = await db.orderDao.watchOrdersFiltered(query: '9999').first;
      expect(notMatched.isEmpty, isTrue);

      // 6. Test getOrderWithDetails
      final details = await db.orderDao.getOrderWithDetails('order-001');
      expect(details, isNotNull);
      expect(details!.order.orderNumber, equals('INV-20260912-0001'));
      expect(details.items.length, equals(1));
      expect(details.items.first.productName, equals('Red Bull Energy Drink'));
      expect(details.customer, isNotNull);
      expect(details.customer!.name, equals('Ko Min (ကိုမင်း)'));
    });

    test('Sale Invoice localization translations exist for English and Myanmar', () {
      expect(AppTranslations.tr('nav_invoices', AppLanguage.en), equals('Invoices'));
      expect(AppTranslations.tr('nav_invoices', AppLanguage.my), equals('ဘောက်ချာ'));

      expect(AppTranslations.tr('invoice_title', AppLanguage.en), equals('Sale Invoices'));
      expect(AppTranslations.tr('invoice_title', AppLanguage.my), equals('အရောင်းဘောက်ချာ မှတ်တမ်း'));

      expect(AppTranslations.tr('invoice_filter_today', AppLanguage.en), equals('Today'));
      expect(AppTranslations.tr('invoice_filter_today', AppLanguage.my), equals('ယနေ့'));

      expect(AppTranslations.tr('invoice_reprint', AppLanguage.en), equals('Print Thermal Slip'));
      expect(AppTranslations.tr('invoice_reprint', AppLanguage.my), equals('ပြေစာ ပြန်ထုတ်မည်'));
    });
  });
}
