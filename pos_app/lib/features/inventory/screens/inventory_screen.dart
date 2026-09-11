import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/stock_adjustment_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/admin_override_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _filterLowStockOnly = false;
  static const int _lowStockThreshold = 5;

  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductForm({Product? productToEdit}) async {
    final activeUser = ref.read(currentUserProvider);
    if (activeUser?.role == 'cashier') {
      final approved = await AdminOverrideDialog.requestApproval(
        context,
        actionTitle: productToEdit != null ? 'Edit Product "${productToEdit.name}"' : 'Add New Product',
      );
      if (!approved) return;
    }
    if (mounted) {
      ProductFormDialog.show(context, productToEdit: productToEdit);
    }
  }

  void _confirmDeleteProduct(Product product) async {
    final activeUser = ref.read(currentUserProvider);
    if (activeUser?.role == 'cashier') {
      final approved = await AdminOverrideDialog.requestApproval(
        context,
        actionTitle: 'Delete Product "${product.name}"',
      );
      if (!approved) return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Product', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "${product.name}" from your catalog?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(productDaoProvider).softDeleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFEF4444),
                    content: Text('Product "${product.name}" deleted.'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allInventoryProductsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Stock & Inventory',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Add Category Button
          IconButton.filledTonal(
            tooltip: 'Add Category',
            onPressed: () => CategoryFormDialog.show(context),
            icon: const Icon(Icons.create_new_folder_outlined, size: 18, color: Color(0xFF38BDF8)),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
          ),
          const SizedBox(width: 6),

          // Add Product Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Product', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (allProducts) {
          final categories = categoriesAsync.value ?? [];
          final categoryMap = {for (var c in categories) c.id: c};

          // Filter Products
          final filteredProducts = allProducts.where((p) {
            final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
            final matchesSearch = _searchQuery.isEmpty ||
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            final matchesLowStock = !_filterLowStockOnly || (p.trackStock && p.stockQuantity <= _lowStockThreshold);

            return matchesCategory && matchesSearch && matchesLowStock;
          }).toList();

          // Compute Inventory Valuation & Metrics
          int totalUnits = 0;
          double totalCostValuation = 0.0;
          double totalRetailValuation = 0.0;
          int lowStockAlerts = 0;

          for (final p in allProducts) {
            if (p.trackStock) {
              totalUnits += p.stockQuantity;
              totalCostValuation += p.stockQuantity * p.costPrice;
              totalRetailValuation += p.stockQuantity * p.sellingPrice;
              if (p.stockQuantity <= _lowStockThreshold) {
                lowStockAlerts++;
              }
            }
          }

          return Column(
            children: [
              // Top KPI Summary Cards (Horizontally Scrollable for Mobile)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildKpiCard(
                        title: 'Total Items',
                        value: '${allProducts.length}',
                        subtitle: 'Active products',
                        icon: Icons.grid_view_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        title: 'Total Units',
                        value: _currencyFormat.format(totalUnits),
                        subtitle: 'In stock',
                        icon: Icons.all_inbox_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        title: 'Low Stock',
                        value: '$lowStockAlerts',
                        subtitle: '<= $_lowStockThreshold units',
                        icon: Icons.warning_amber_rounded,
                        color: lowStockAlerts > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        title: 'Inventory Value',
                        value: '${_currencyFormat.format(totalRetailValuation)} MMK',
                        subtitle: 'Cost: ${_currencyFormat.format(totalCostValuation)} MMK',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ),

              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search product by name, SKU or barcode...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Low Stock Filter Toggle
                    FilterChip(
                      selected: _filterLowStockOnly,
                      label: Text(
                        'Low Stock ($lowStockAlerts)',
                        style: TextStyle(
                          color: _filterLowStockOnly ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: _filterLowStockOnly ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      side: BorderSide(
                        color: _filterLowStockOnly ? const Color(0xFFEF4444) : const Color(0xFF334155),
                      ),
                      onSelected: (val) => setState(() => _filterLowStockOnly = val),
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ChoiceChip(
                      label: const Text('All Categories', style: TextStyle(fontSize: 11)),
                      selected: _selectedCategoryId == null,
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: const BorderSide(color: Color(0xFF334155)),
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((c) {
                      final isSelected = _selectedCategoryId == c.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.name, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          backgroundColor: const Color(0xFF1E293B),
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: const BorderSide(color: Color(0xFF334155)),
                          onSelected: (_) => setState(() => _selectedCategoryId = isSelected ? null : c.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Product Table / List
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final product = filteredProducts[index];
                          final category = product.categoryId != null ? categoryMap[product.categoryId] : null;
                          return _buildProductCard(product, category);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
        error: (err, _) => Center(child: Text('Error loading inventory: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            subtitle,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, Category? category) {
    final marginPct = product.sellingPrice > 0
        ? ((product.sellingPrice - product.costPrice) / product.sellingPrice) * 100.0
        : 0.0;

    final isLowStock = product.trackStock && product.stockQuantity <= _lowStockThreshold;
    final isOutOfStock = product.trackStock && product.stockQuantity <= 0;

    final stockBadgeColor = isOutOfStock
        ? const Color(0xFFEF4444)
        : isLowStock
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 550;

        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOutOfStock
                    ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                    : isLowStock
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : const Color(0xFF334155),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Product Image + Name/Category + Retail Price & Stock Badge
                Row(
                  children: [
                    ProductImageWidget(
                      imageUrl: product.imageUrl,
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category != null) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Text(
                                category.name,
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_currencyFormat.format(product.sellingPrice)} MMK',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: stockBadgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: stockBadgeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            product.trackStock
                                ? (isOutOfStock ? 'Out' : '${product.stockQuantity} left')
                                : '∞ Stock',
                            style: TextStyle(color: stockBadgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Middle Row: Barcode + Cost + Margin
                Row(
                  children: [
                    if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                      const Icon(Icons.qr_code, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Text(
                        product.barcode!,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Cost: ${_currencyFormat.format(product.costPrice)} MMK',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${marginPct.toStringAsFixed(0)}% Margin)',
                      style: TextStyle(
                        color: marginPct >= 20 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 4),

                // Bottom Row: Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF38BDF8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.swap_vert_circle_outlined, size: 15),
                      label: const Text('Stock (+/-)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => StockAdjustmentDialog.show(context, product),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit Product',
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 18),
                      onPressed: () => _openProductForm(productToEdit: product),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                      onPressed: () => _confirmDeleteProduct(product),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Wide desktop layout
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutOfStock
                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                  : isLowStock
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                      : const Color(0xFF334155),
            ),
          ),
          child: Row(
            children: [
              ProductImageWidget(
                imageUrl: product.imageUrl,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),

              // Name, Category, Barcode
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              category.name,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                          const Icon(Icons.qr_code, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            product.barcode!,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          'Cost: ${_currencyFormat.format(product.costPrice)} MMK',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${marginPct.toStringAsFixed(0)}% Margin)',
                          style: TextStyle(
                            color: marginPct >= 20 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Retail Price
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currencyFormat.format(product.sellingPrice)} MMK',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'Retail Price',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Stock Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: stockBadgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stockBadgeColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      product.trackStock ? '${product.stockQuantity}' : '∞',
                      style: TextStyle(color: stockBadgeColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      isOutOfStock
                          ? 'Out of Stock'
                          : isLowStock
                              ? 'Low Stock'
                              : 'In Stock',
                      style: TextStyle(color: stockBadgeColor, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Adjust Stock Button
                  IconButton(
                    tooltip: 'Stock Movement (+/-)',
                    icon: const Icon(Icons.swap_vert_circle_outlined, color: Color(0xFF38BDF8), size: 22),
                    onPressed: () => StockAdjustmentDialog.show(context, product),
                  ),

                  // Edit Product Button
                  IconButton(
                    tooltip: 'Edit Product',
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => _openProductForm(productToEdit: product),
                  ),

                  // Delete Product Button
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                    onPressed: () => _confirmDeleteProduct(product),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Products Found',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first item or clear your search filters.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openProductForm(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
