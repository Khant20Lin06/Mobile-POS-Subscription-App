import 'dart:math';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/seeder.dart';
import '../../core/providers/database_provider.dart';
import '../subscription/widgets/plan_showcase_dialog.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(currentShopProvider);
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final ordersAsync = ref.watch(recentOrdersStreamProvider);
    final customersAsync = ref.watch(customersStreamProvider);
    final pendingSyncAsync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale, color: Color(0xFF60A5FA), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mobile POS Engine',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  shopAsync.when(
                    data: (shop) => Text(
                      shop != null ? '${shop.name} (${shop.currency})' : 'Loading shop...',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const Text('Loading...', style: TextStyle(fontSize: 11)),
                    error: (e, stack) => const Text('Error', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Subscription Plan Pill
          Builder(
            builder: (context) {
              final shop = shopAsync.value;
              final isPro = shop?.planTier == 'pro' || shop?.planTier == 'custom';
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmall = screenWidth < 500;

              return InkWell(
                onTap: () => PlanShowcaseDialog.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPro
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    border: Border.all(
                      color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPro ? Icons.stars : Icons.wifi_off,
                        color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSmall
                            ? (isPro ? 'PRO' : 'FREE')
                            : (isPro ? '${shop?.planTier.toUpperCase()} (Cloud Active)' : 'FREE (Offline Mode)'),
                        style: TextStyle(
                          color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Upgrade Button (Opens Plan Showcase)
          IconButton(
            tooltip: 'View Subscription Plans',
            icon: const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 22),
            onPressed: () => PlanShowcaseDialog.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Top Stats & Sync Banner
          _buildTopBanner(pendingSyncAsync, productsAsync, ordersAsync),

          // Action Toolbar
          _buildActionToolbar(context, productsAsync),

          // Tabs
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B82F6),
              labelColor: const Color(0xFF60A5FA),
              unselectedLabelColor: const Color(0xFF94A3B8),
              tabs: [
                Tab(
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  text: 'Products (${productsAsync.value?.length ?? 0})',
                ),
                Tab(
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  text: 'Recent Orders (${ordersAsync.value?.length ?? 0})',
                ),
                Tab(
                  icon: const Icon(Icons.people_outline, size: 18),
                  text: 'Customers & Debt (${customersAsync.value?.length ?? 0})',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(productsAsync),
                _buildOrdersTab(ordersAsync),
                _buildCustomersTab(customersAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner(
    AsyncValue<int> pendingSync,
    AsyncValue<List<Product>> products,
    AsyncValue<List<Order>> orders,
  ) {
    final totalSales = orders.value?.fold<double>(
          0.0,
          (sum, o) => sum + o.totalAmount,
        ) ??
        0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              title: "Total Revenue",
              value: '${_currencyFormat.format(totalSales)} MMK',
              icon: Icons.payments_outlined,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: "Total Orders",
              value: '${orders.value?.length ?? 0}',
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: "Stock Items",
              value: '${products.value?.length ?? 0}',
              icon: Icons.category_outlined,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: "Offline Sync Queue",
              value: '${pendingSync.value ?? 0} Pending',
              icon: Icons.cloud_queue,
              color: const Color(0xFFA855F7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(
    BuildContext context,
    AsyncValue<List<Product>> productsAsync,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0F172A),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.flash_on, size: 18),
            label: const Text('Execute Quick Test Sale'),
            onPressed: () => _executeTestSale(productsAsync.value ?? []),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.cloud_sync, size: 18),
            label: const Text('Sync to Cloud Now'),
            onPressed: () async {
              final syncService = ref.read(syncServiceProvider);
              final messenger = ScaffoldMessenger.of(context);
              final result = await syncService.pushPendingChanges();
              ref.invalidate(pendingSyncCountProvider);
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: result.success ? const Color(0xFF10B981) : Colors.redAccent,
                  content: Text(result.message),
                ),
              );
            },
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF0284C7)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
            onPressed: () => _showAddProductDialog(context),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8),
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reseed Demo Data'),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final messenger = ScaffoldMessenger.of(context);
              await DatabaseSeeder.seedIfEmpty(db);
              ref.invalidate(currentShopProvider);
              ref.invalidate(activeProductsStreamProvider);
              messenger.showSnackBar(
                const SnackBar(content: Text('Demo Data Checked & Seeded successfully!')),
              );
            },
          ),
          const SizedBox(width: 8),
          const Chip(
            backgroundColor: Color(0xFF1E293B),
            label: Text(
              'Offline SQLite ACID Ready',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(AsyncValue<List<Product>> productsAsync) {
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text('No products available. Click "Reseed Demo Data".',
                style: TextStyle(color: Color(0xFF94A3B8))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B)),
          itemBuilder: (context, index) {
            final p = products[index];
            final profit = p.sellingPrice - p.costPrice;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fastfood, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Barcode: ${p.barcode ?? "N/A"}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            Text(
                              'Cost: ${_currencyFormat.format(p.costPrice)} MMK',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                            Text(
                              '(Margin: +${_currencyFormat.format(profit)})',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_currencyFormat.format(p.sellingPrice)} MMK',
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.stockQuantity <= 10
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stock: ${p.stockQuantity}',
                          style: TextStyle(
                            color: p.stockQuantity <= 10 ? Colors.redAccent : Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildOrdersTab(AsyncValue<List<Order>> ordersAsync) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(
            child: Text('No orders yet. Click "Execute Quick Test Sale" to simulate sales.',
                style: TextStyle(color: Color(0xFF94A3B8))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B)),
          itemBuilder: (context, index) {
            final o = orders[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.orderNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${dateFormat.format(o.createdAt.toLocal())} | Payment: ${o.paymentMethod}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_currencyFormat.format(o.totalAmount)} MMK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            o.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload_outlined,
                            size: 13,
                            color: o.syncStatus == 'synced' ? Colors.green : const Color(0xFFA855F7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            o.syncStatus.toUpperCase(),
                            style: TextStyle(
                              color: o.syncStatus == 'synced' ? Colors.green : const Color(0xFFA855F7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildCustomersTab(AsyncValue<List<Customer>> customersAsync) {
    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return const Center(
            child: Text('No customers registered yet.', style: TextStyle(color: Color(0xFF94A3B8))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B)),
          itemBuilder: (context, index) {
            final c = customers[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF334155),
                    child: Icon(Icons.person, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${c.phone ?? "No phone"}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Debt: ${_currencyFormat.format(c.totalDebt)} MMK',
                        style: TextStyle(
                          color: c.totalDebt > 0 ? Colors.redAccent : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${c.syncStatus.toUpperCase()}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  // Quick Test Sale Action
  Future<void> _executeTestSale(List<Product> products) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please seed products first!')),
      );
      return;
    }

    final orderDao = ref.read(orderDaoProvider);
    final shop = await ref.read(currentShopProvider.future);
    final shopId = shop?.id ?? 'default-shop-id';

    final uuid = const Uuid();
    final orderId = uuid.v4();
    final now = DateTime.now().toUtc();
    final random = Random();

    // Pick 1 to 2 random products
    final sampleProd1 = products[random.nextInt(products.length)];
    final qty1 = 1;
    final subtotal1 = sampleProd1.sellingPrice * qty1;

    final items = <OrderItemsCompanion>[
      OrderItemsCompanion.insert(
        id: uuid.v4(),
        orderId: orderId,
        productId: sampleProd1.id,
        productName: sampleProd1.name,
        quantity: qty1,
        costPrice: sampleProd1.costPrice,
        unitPrice: sampleProd1.sellingPrice,
        subtotal: subtotal1,
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value('pending'),
      ),
    ];

    double totalAmount = subtotal1;

    // Optional second item
    if (products.length > 1) {
      final sampleProd2 = products[(products.indexOf(sampleProd1) + 1) % products.length];
      final qty2 = 1;
      final subtotal2 = sampleProd2.sellingPrice * qty2;
      items.add(
        OrderItemsCompanion.insert(
          id: uuid.v4(),
          orderId: orderId,
          productId: sampleProd2.id,
          productName: sampleProd2.name,
          quantity: qty2,
          costPrice: sampleProd2.costPrice,
          unitPrice: sampleProd2.sellingPrice,
          subtotal: subtotal2,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );
      totalAmount += subtotal2;
    }

    final invoiceNum = 'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';

    await orderDao.createOrderWithItems(
      orderEntry: OrdersCompanion.insert(
        id: orderId,
        shopId: shopId,
        orderNumber: invoiceNum,
        subtotal: totalAmount,
        totalAmount: totalAmount,
        paymentMethod: const drift.Value('CASH'),
        status: const drift.Value('COMPLETED'),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        syncStatus: const drift.Value('pending'),
      ),
      items: items,
    );

    ref.invalidate(pendingSyncCountProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('Order $invoiceNum completed! Inventory updated atomically.'),
        ),
      );
    }
  }

  // Add Product Dialog
  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController(text: '${1000 + Random().nextInt(9000)}');
    final priceCtrl = TextEditingController(text: '3000');
    final costCtrl = TextEditingController(text: '1800');
    final stockCtrl = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Product to SQLite DB', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Product Name', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
              TextField(
                controller: barcodeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Barcode / SKU', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Selling Price (MMK)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Cost Price (MMK)', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Stock Quantity', labelStyle: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final shop = await ref.read(currentShopProvider.future);
              final shopId = shop?.id ?? 'default-shop-id';
              final uuid = const Uuid();
              final now = DateTime.now().toUtc();

              await ref.read(productDaoProvider).insertProduct(
                    ProductsCompanion.insert(
                      id: uuid.v4(),
                      shopId: shopId,
                      name: nameCtrl.text.trim(),
                      barcode: drift.Value(barcodeCtrl.text.trim()),
                      sellingPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                      costPrice: drift.Value(double.tryParse(costCtrl.text) ?? 0.0),
                      stockQuantity: drift.Value(int.tryParse(stockCtrl.text) ?? 0),
                      trackStock: const drift.Value(true),
                      createdAt: drift.Value(now),
                      updatedAt: drift.Value(now),
                      syncStatus: const drift.Value('pending'),
                    ),
                  );

              ref.invalidate(pendingSyncCountProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Product'),
          ),
        ],
      ),
    );
  }
}
