import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_panel.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'en_US');
  final _searchController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _onBarcodeSubmitted(String barcode) async {
    final barcodeClean = barcode.trim();
    if (barcodeClean.isEmpty) return;

    final productDao = ref.read(productDaoProvider);
    final product = await productDao.getProductByBarcode(barcodeClean);

    if (product != null) {
      ref.read(cartProvider.notifier).addToCart(product);
      _searchController.clear();
      setState(() => _searchQuery = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text('Scanned & Added "${product.name}" to cart!'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('No product found with barcode "$barcodeClean"'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(currentShopProvider);
    final productsAsync = ref.watch(activeProductsStreamProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront, color: Color(0xFF60A5FA), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shopAsync.when(
                  data: (shop) => Text(
                    shop?.name ?? 'POS Register',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  loading: () => const Text('Loading...', style: TextStyle(fontSize: 16)),
                  error: (e, stack) => const Text('POS Register', style: TextStyle(fontSize: 16)),
                ),
                const Text(
                  'Cashier: Ko Cashier (Online)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Barcode & Fast Search Field
          Container(
            width: 260,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: TextField(
              controller: _searchController,
              focusNode: _barcodeFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search or Scan Barcode...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF38BDF8), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              onSubmitted: _onBarcodeSubmitted,
            ),
          ),
          IconButton(
            tooltip: 'Sync to Cloud',
            icon: const Icon(Icons.cloud_sync, color: Color(0xFF38BDF8), size: 22),
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
          Builder(
            builder: (context) {
              final shop = shopAsync.value;
              final isPro = shop?.planTier == 'pro' || shop?.planTier == 'custom';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  border: Border.all(
                    color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPro ? Icons.stars : Icons.wifi_off,
                      color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPro ? 'PRO' : 'FREE',
                      style: TextStyle(
                        color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 850;

          if (isLargeScreen) {
            // Split-View Landscape (Tablet / POS Terminal / Desktop)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Catalog Section (60% width)
                Expanded(
                  flex: 6,
                  child: _buildCatalogSection(productsAsync),
                ),
                // Live Cart Section (40% width)
                const SizedBox(
                  width: 380,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CartPanel(),
                  ),
                ),
              ],
            );
          } else {
            // Single View Portrait (Smartphones)
            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: cart.isEmpty ? 0 : 70),
                    child: _buildCatalogSection(productsAsync),
                  ),
                ),

                // Floating Bottom Cart Bar for Mobile
                if (!cart.isEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: _buildMobileFloatingCartBar(context, cart),
                  ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCatalogSection(AsyncValue<List<Product>> productsAsync) {
    return Column(
      children: [
        // Category Pills
        _buildCategoryPills(),

        // Products Grid
        Expanded(
          child: productsAsync.when(
            data: (products) {
              // Apply category & search filter
              final filtered = products.where((p) {
                final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
                final matchQuery = _searchQuery.isEmpty ||
                    p.name.toLowerCase().contains(_searchQuery) ||
                    (p.barcode != null && p.barcode!.contains(_searchQuery));
                return matchCat && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Color(0xFF475569)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No products matching "$_searchQuery"'
                            : 'No products in this category',
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, gridConstraints) {
                  // Dynamic column count based on available catalog width
                  int crossAxisCount = 2;
                  if (gridConstraints.maxWidth > 700) {
                    crossAxisCount = 4;
                  } else if (gridConstraints.maxWidth > 480) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildProductTile(filtered[index]);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stack) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPills() {
    // Categories stream could be used, or fixed presets for immediate response
    final categories = [
      {'id': null, 'name': 'All Items', 'icon': Icons.apps},
      {'id': 'cat_coffee', 'name': 'Coffee & Tea', 'icon': Icons.coffee},
      {'id': 'cat_bakery', 'name': 'Bakery & Snacks', 'icon': Icons.bakery_dining},
      {'id': 'cat_drinks', 'name': 'Cold Drinks', 'icon': Icons.local_drink},
      {'id': 'cat_general', 'name': 'General Goods', 'icon': Icons.shopping_basket},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: const Color(0xFF1E293B),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategoryId == cat['id'];

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              cat['icon'] as IconData,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            label: Text(
              cat['name'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            backgroundColor: const Color(0xFF0F172A),
            selectedColor: const Color(0xFF2563EB),
            side: BorderSide(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
            ),
            onSelected: (_) {
              setState(() {
                _selectedCategoryId = isSelected ? null : cat['id'] as String?;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    final isOutOfStock = product.trackStock && product.stockQuantity <= 0;

    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isOutOfStock
            ? null
            : () {
                ref.read(cartProvider.notifier).addToCart(product);
              },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutOfStock ? Colors.red.withValues(alpha: 0.3) : const Color(0xFF334155),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icon & Stock Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fastfood, color: Color(0xFF60A5FA), size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.withValues(alpha: 0.2)
                          : product.stockQuantity <= 10
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out' : '${product.stockQuantity}',
                      style: TextStyle(
                        color: isOutOfStock
                            ? Colors.redAccent
                            : product.stockQuantity <= 10
                                ? Colors.amberAccent
                                : Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Name
              Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Price
              Text(
                '${_currencyFormat.format(product.sellingPrice)} MMK',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFloatingCartBar(BuildContext context, CartState cart) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const FractionallySizedBox(
                heightFactor: 0.85,
                child: CartPanel(isBottomSheet: true),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${cart.totalItemCount} Items',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${_currencyFormat.format(cart.totalAmount)} MMK',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
