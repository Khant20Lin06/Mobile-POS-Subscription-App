import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/orders_table.dart';
import '../tables/order_items_table.dart';
import '../tables/products_table.dart';

part 'order_dao.g.dart';

class SalesSummary {
  final double totalSales;
  final int totalOrders;
  final double cashTotal;
  final double digitalTotal;

  SalesSummary({
    required this.totalSales,
    required this.totalOrders,
    required this.cashTotal,
    required this.digitalTotal,
  });
}

class OrderWithDetails {
  final Order order;
  final List<OrderItem> items;
  final Customer? customer;

  OrderWithDetails({
    required this.order,
    required this.items,
    this.customer,
  });
}

@DriftAccessor(tables: [Orders, OrderItems, Products])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  /// Watch recent completed orders
  Stream<List<Order>> watchRecentOrders({int limit = 50}) {
    return (select(orders)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  /// Watch orders with optional date range and search filter
  Stream<List<Order>> watchOrdersFiltered({
    DateTime? startDate,
    DateTime? endDate,
    String? query,
    int limit = 300,
  }) {
    return (select(orders)
          ..where((tbl) {
            Expression<bool> predicate = tbl.deletedAt.isNull();
            if (startDate != null) {
              predicate = predicate & tbl.createdAt.isBiggerOrEqualValue(startDate);
            }
            if (endDate != null) {
              predicate = predicate & tbl.createdAt.isSmallerOrEqualValue(endDate);
            }
            if (query != null && query.trim().isNotEmpty) {
              final q = '%${query.trim()}%';
              predicate = predicate & tbl.orderNumber.like(q);
            }
            return predicate;
          })
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  /// Get order with its line items and customer
  Future<OrderWithDetails?> getOrderWithDetails(String orderId) async {
    final order = await (select(orders)..where((tbl) => tbl.id.equals(orderId))).getSingleOrNull();
    if (order == null) return null;

    final items = await getItemsForOrder(orderId);

    Customer? customer;
    if (order.customerId != null && order.customerId!.isNotEmpty) {
      customer = await (attachedDatabase.select(attachedDatabase.customers)
            ..where((tbl) => tbl.id.equals(order.customerId!)))
          .getSingleOrNull();
    }

    return OrderWithDetails(
      order: order,
      items: items,
      customer: customer,
    );
  }

  /// Get order items for a specific order
  Future<List<OrderItem>> getItemsForOrder(String orderId) {
    return (select(orderItems)
          ..where((tbl) => tbl.orderId.equals(orderId) & tbl.deletedAt.isNull()))
        .get();
  }

  /// Create an order along with its line items inside an ACID SQLite transaction,
  /// and automatically update product stock levels.
  Future<void> createOrderWithItems({
    required OrdersCompanion orderEntry,
    required List<OrderItemsCompanion> items,
  }) async {
    await transaction(() async {
      // 1. Insert order
      await into(orders).insert(orderEntry);

      // 2. Insert items and decrement stock
      for (final item in items) {
        await into(orderItems).insert(item);

        // Decrement product inventory
        final prod = await (select(products)..where((t) => t.id.equals(item.productId.value)))
            .getSingleOrNull();
        if (prod != null && prod.trackStock) {
          final newStock = prod.stockQuantity - item.quantity.value;
          await (update(products)..where((t) => t.id.equals(prod.id))).write(
            ProductsCompanion(
              stockQuantity: Value(newStock),
              updatedAt: Value(DateTime.now().toUtc()),
              syncStatus: const Value('pending'),
            ),
          );
        }
      }
    });
  }

  /// Calculate sales statistics for a given day (defaults to today)
  Future<SalesSummary> getDailySalesSummary([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final dayOrders = await (select(orders)
          ..where((tbl) =>
              tbl.deletedAt.isNull() &
              tbl.status.equals('COMPLETED') &
              tbl.createdAt.isBiggerOrEqualValue(startOfDay) &
              tbl.createdAt.isSmallerThanValue(endOfDay)))
        .get();

    double total = 0.0;
    double cash = 0.0;
    double digital = 0.0;

    for (final o in dayOrders) {
      total += o.totalAmount;
      if (o.paymentMethod == 'CASH') {
        cash += o.totalAmount;
      } else {
        digital += o.totalAmount;
      }
    }

    return SalesSummary(
      totalSales: total,
      totalOrders: dayOrders.length,
      cashTotal: cash,
      digitalTotal: digital,
    );
  }
}
