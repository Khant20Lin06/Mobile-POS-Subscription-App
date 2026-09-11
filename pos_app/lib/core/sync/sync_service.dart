import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';

class SyncResult {
  final bool success;
  final int itemsPushed;
  final int itemsPulled;
  final String message;

  const SyncResult({
    required this.success,
    this.itemsPushed = 0,
    this.itemsPulled = 0,
    required this.message,
  });
}

class SyncService {
  final AppDatabase db;
  String baseUrl;

  SyncService({
    required this.db,
    this.baseUrl = 'http://localhost:8085',
  });

  /// Push all local changes marked as 'pending' to NestJS Cloud Server
  Future<SyncResult> pushPendingChanges() async {
    final shop = await (db.select(db.shops)..limit(1)).getSingleOrNull();
    if (shop == null) {
      return const SyncResult(success: false, message: 'Shop profile not found in local DB');
    }

    try {
      // 1. Gather all pending records
      final pendingProducts = await (db.select(db.products)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

      final pendingCategories = await (db.select(db.categories)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

      final pendingCustomers = await (db.select(db.customers)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

      final pendingLedgers = await (db.select(db.customerLedgers)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

      final pendingOrders = await (db.select(db.orders)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

      final pendingItems = await (db.select(db.orderItems)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

      final totalPending = pendingProducts.length +
          pendingCategories.length +
          pendingCustomers.length +
          pendingLedgers.length +
          pendingOrders.length +
          pendingItems.length;

      if (totalPending == 0) {
        return const SyncResult(
          success: true,
          itemsPushed: 0,
          message: 'Already up to date. No pending local changes.',
        );
      }

      // 2. Build JSON payload
      final payload = {
        'shopId': shop.id,
        'categories': pendingCategories.map((c) => {
          'id': c.id,
          'name': c.name,
          'colorCode': c.colorCode,
          'sortOrder': c.sortOrder,
          'createdAt': c.createdAt.toIso8601String(),
          'updatedAt': c.updatedAt.toIso8601String(),
          'deletedAt': c.deletedAt?.toIso8601String(),
        }).toList(),
        'products': pendingProducts.map((p) => {
          'id': p.id,
          'categoryId': p.categoryId,
          'name': p.name,
          'barcode': p.barcode,
          'costPrice': p.costPrice,
          'sellingPrice': p.sellingPrice,
          'stockQuantity': p.stockQuantity,
          'trackStock': p.trackStock,
          'imageUrl': p.imageUrl,
          'isActive': p.isActive,
          'createdAt': p.createdAt.toIso8601String(),
          'updatedAt': p.updatedAt.toIso8601String(),
          'deletedAt': p.deletedAt?.toIso8601String(),
        }).toList(),
        'customers': pendingCustomers.map((c) => {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'totalDebt': c.totalDebt,
          'createdAt': c.createdAt.toIso8601String(),
          'updatedAt': c.updatedAt.toIso8601String(),
          'deletedAt': c.deletedAt?.toIso8601String(),
        }).toList(),
        'customerLedgers': pendingLedgers.map((l) => {
          'id': l.id,
          'customerId': l.customerId,
          'orderId': l.orderId,
          'type': l.type,
          'amount': l.amount,
          'notes': l.notes,
          'createdAt': l.createdAt.toIso8601String(),
          'updatedAt': l.updatedAt.toIso8601String(),
          'deletedAt': l.deletedAt?.toIso8601String(),
        }).toList(),
        'orders': pendingOrders.map((o) => {
          'id': o.id,
          'userId': o.userId,
          'customerId': o.customerId,
          'orderNumber': o.orderNumber,
          'subtotal': o.subtotal,
          'discountAmount': o.discountAmount,
          'taxAmount': o.taxAmount,
          'totalAmount': o.totalAmount,
          'paymentMethod': o.paymentMethod,
          'status': o.status,
          'notes': o.notes,
          'createdAt': o.createdAt.toIso8601String(),
          'updatedAt': o.updatedAt.toIso8601String(),
          'deletedAt': o.deletedAt?.toIso8601String(),
        }).toList(),
        'orderItems': pendingItems.map((i) => {
          'id': i.id,
          'orderId': i.orderId,
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'costPrice': i.costPrice,
          'unitPrice': i.unitPrice,
          'subtotal': i.subtotal,
          'createdAt': i.createdAt.toIso8601String(),
          'updatedAt': i.updatedAt.toIso8601String(),
          'deletedAt': i.deletedAt?.toIso8601String(),
        }).toList(),
      };

      // 3. POST to Cloud Sync Endpoint
      final response = await http
          .post(
            Uri.parse('$baseUrl/sync/push'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 4. Mark all pushed items as 'synced' in local database
        await db.transaction(() async {
          for (final p in pendingProducts) {
            await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(
              const ProductsCompanion(syncStatus: Value('synced')),
            );
          }
          for (final c in pendingCategories) {
            await (db.update(db.categories)..where((t) => t.id.equals(c.id))).write(
              const CategoriesCompanion(syncStatus: Value('synced')),
            );
          }
          for (final cu in pendingCustomers) {
            await (db.update(db.customers)..where((t) => t.id.equals(cu.id))).write(
              const CustomersCompanion(syncStatus: Value('synced')),
            );
          }
          for (final l in pendingLedgers) {
            await (db.update(db.customerLedgers)..where((t) => t.id.equals(l.id))).write(
              const CustomerLedgersCompanion(syncStatus: Value('synced')),
            );
          }
          for (final o in pendingOrders) {
            await (db.update(db.orders)..where((t) => t.id.equals(o.id))).write(
              const OrdersCompanion(syncStatus: Value('synced')),
            );
          }
          for (final i in pendingItems) {
            await (db.update(db.orderItems)..where((t) => t.id.equals(i.id))).write(
              const OrderItemsCompanion(syncStatus: Value('synced')),
            );
          }
        });

        return SyncResult(
          success: true,
          itemsPushed: totalPending,
          message: 'Pushed $totalPending changes to cloud server successfully.',
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Sync Push Error: $e');
      return SyncResult(
        success: false,
        message: 'Could not connect to Cloud Server at $baseUrl. Check network or server status.',
      );
    }
  }

  /// Activate License Key from Telegram with Cloud Server
  Future<SyncResult> activateLicense({
    required String licenseKey,
  }) async {
    final shop = await (db.select(db.shops)..limit(1)).getSingleOrNull();
    if (shop == null) {
      return const SyncResult(success: false, message: 'Shop profile not found');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/subscription/activate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'shopId': shop.id,
              'shopName': shop.name,
              'licenseKey': licenseKey.trim().toUpperCase(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final planTier = data['planTier'] as String? ?? 'pro';
        final expiresAtStr = data['expiresAt'] as String?;
        final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

        // Unlock Pro tier locally
        await (db.update(db.shops)..where((t) => t.id.equals(shop.id))).write(
          ShopsCompanion(
            planTier: Value(planTier),
            subscriptionStatus: const Value('active'),
            subscriptionExpiresAt: Value(expiresAt),
            updatedAt: Value(DateTime.now().toUtc()),
            syncStatus: const Value('synced'),
          ),
        );

        // Run initial cloud sync push
        await pushPendingChanges();

        return SyncResult(
          success: true,
          message: data['message'] ?? 'Successfully upgraded to ${planTier.toUpperCase()} Plan!',
        );
      } else {
        return SyncResult(
          success: false,
          message: data['message'] ?? 'Activation failed. Invalid license key.',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Network error connecting to $baseUrl: $e',
      );
    }
  }
}
