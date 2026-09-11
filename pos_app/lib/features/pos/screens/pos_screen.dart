import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/admin_override_dialog.dart';
import '../../auth/widgets/pin_login_dialog.dart';
import '../../auth/widgets/staff_management_dialog.dart';
import '../../shifts/widgets/open_shift_dialog.dart';
import '../../shifts/widgets/shift_drawer_dialog.dart';
import '../../shifts/widgets/close_shift_dialog.dart';
import '../widgets/receipt_dialog.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../core/localization/app_locale.dart';
import '../../subscription/widgets/plan_showcase_dialog.dart';
import '../../inventory/widgets/category_management_dialog.dart';

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
    final activeUser = ref.watch(currentUserProvider);

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  shopAsync.when(
                    data: (shop) => Text(
                      shop?.name ?? 'POS Register',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    loading: () => const Text('Loading...', style: TextStyle(fontSize: 16)),
                    error: (e, stack) => const Text('POS Register', style: TextStyle(fontSize: 16)),
                  ),
                  Text(
                    'Cashier: ${activeUser?.name ?? "Cashier"} (${activeUser?.role ?? "Active"})',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // On Desktop/Tablet (>=750px), show search field in AppBar
          Builder(
            builder: (context) {
              final isWide = MediaQuery.of(context).size.width >= 750;
              if (!isWide) return const SizedBox.shrink();
              return Container(
                width: 220,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: _buildSearchBar(),
              );
            },
          ),
          IconButton(
            tooltip: 'Sync to Cloud',
            icon: const Icon(Icons.cloud_sync, color: Color(0xFF38BDF8), size: 20),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
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

              return InkWell(
                onTap: () => PlanShowcaseDialog.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPro
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    border: Border.all(
                      color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPro ? Icons.stars : Icons.wifi_off,
                        color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isPro ? 'PRO' : 'FREE',
                        style: TextStyle(
                          color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Shift Status Chip
          Consumer(
            builder: (context, ref, _) {
              final shiftAsync = ref.watch(activeShiftStreamProvider);
              final shift = shiftAsync.value;
              final isOpen = shift != null;
              final screenWidth = MediaQuery.of(context).size.width;
              final isCompact = screenWidth < 500;

              return InkWell(
                onTap: () async {
                  if (isOpen) {
                    final toClose = await ShiftDrawerDialog.show(context);
                    if (toClose != null && context.mounted) {
                      final slip = await CloseShiftDialog.show(context, toClose);
                      if (slip != null && context.mounted) {
                        ReceiptDialog.show(
                          context,
                          receiptText: slip,
                          title: 'Shift Closed & Audited!',
                          orderNumber: 'SHIFT-${toClose.id.substring(0, 8)}',
                        );
                      }
                    }
                  } else {
                    OpenShiftDialog.show(context);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    border: Border.all(
                      color: isOpen ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOpen ? Icons.point_of_sale : Icons.lock_clock,
                        color: isOpen ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompact
                            ? (isOpen ? 'Shift' : 'Open')
                            : (isOpen ? 'Drawer: ${_currencyFormat.format(shift.expectedCash)}' : 'Open Shift'),
                        style: TextStyle(
                          color: isOpen ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Cashier Profile & Lock Dropdown
          Consumer(
            builder: (context, ref, _) {
              final activeUser = ref.watch(currentUserProvider);
              final isOwner = activeUser?.role == 'owner';
              final screenWidth = MediaQuery.of(context).size.width;
              final isCompact = screenWidth < 500;

              return PopupMenuButton<String>(
                tooltip: 'Cashier Profile & Security',
                offset: const Offset(0, 45),
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) async {
                  if (value == 'lock') {
                    ref.read(isTerminalLockedProvider.notifier).state = true;
                    PinLoginDialog.show(context, isLockScreen: true);
                  } else if (value == 'switch') {
                    PinLoginDialog.show(context);
                  } else if (value == 'staff') {
                    if (activeUser?.role == 'cashier') {
                      final approved = await AdminOverrideDialog.requestApproval(
                        context,
                        actionTitle: 'Manage Staff Directory',
                      );
                      if (!approved) return;
                    }
                    if (context.mounted) {
                      StaffManagementDialog.show(context);
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'header',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeUser?.name ?? 'Unknown Cashier',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          activeUser?.role.toUpperCase() ?? 'CASHIER',
                          style: TextStyle(
                            color: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem(
                    value: 'lock',
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 8),
                        Text('Lock Terminal (သော့ခတ်မည်)', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'switch',
                    child: Row(
                      children: [
                        Icon(Icons.switch_account_outlined, color: Color(0xFF60A5FA), size: 18),
                        SizedBox(width: 8),
                        Text('Switch Cashier (ကက်ရှာပြောင်းမည်)', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'staff',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text('Staff Management (ဝန်ထမ်းစာရင်း)', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                        child: Text(
                          activeUser != null && activeUser.name.isNotEmpty
                              ? activeUser.name.substring(0, 1).toUpperCase()
                              : 'C',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 6),
                        Text(
                          activeUser?.name ?? 'Cashier',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8), size: 16),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 850;
          final isWide = constraints.maxWidth >= 750;

          if (isLargeScreen) {
            // Split-View Landscape (Tablet / POS Terminal / Desktop)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Catalog Section (60% width)
                Expanded(
                  flex: 6,
                  child: _buildCatalogSection(productsAsync, showSearchBar: !isWide),
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
                    child: _buildCatalogSection(productsAsync, showSearchBar: true),
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

  Widget _buildSearchBar() {
    return TextField(
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
    );
  }

  Widget _buildCatalogSection(AsyncValue<List<Product>> productsAsync, {bool showSearchBar = false}) {
    return Column(
      children: [
        if (showSearchBar)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            color: const Color(0xFF1E293B),
            child: _buildSearchBar(),
          ),

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
                  // Dynamic column count and compact aspect ratio based on available catalog width
                  int crossAxisCount = 2;
                  double childAspectRatio = 1.10;
                  if (gridConstraints.maxWidth > 800) {
                    crossAxisCount = 4;
                    childAspectRatio = 1.15;
                  } else if (gridConstraints.maxWidth > 500) {
                    crossAxisCount = 3;
                    childAspectRatio = 1.12;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
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
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final lang = ref.watch(appLanguageProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: const Color(0xFF1E293B),
      child: categoriesAsync.when(
        data: (categories) {
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 1. All Items Chip
              FilterChip(
                selected: _selectedCategoryId == null,
                showCheckmark: false,
                avatar: Icon(
                  Icons.apps,
                  size: 16,
                  color: _selectedCategoryId == null ? Colors.white : const Color(0xFF94A3B8),
                ),
                label: Text(
                  AppTranslations.tr('pos_all_items', lang),
                  style: TextStyle(
                    color: _selectedCategoryId == null ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor: const Color(0xFF0F172A),
                selectedColor: const Color(0xFF2563EB),
                side: BorderSide(
                  color: _selectedCategoryId == null ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                ),
                onSelected: (_) => setState(() => _selectedCategoryId = null),
              ),
              const SizedBox(width: 8),

              // Dynamic Category Chips from Database
              ...categories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                Color catColor = const Color(0xFF3B82F6);
                if (cat.colorCode != null && cat.colorCode!.startsWith('#')) {
                  try {
                    catColor = Color(int.parse(cat.colorCode!.replaceFirst('#', '0xFF')));
                  } catch (_) {}
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: CircleAvatar(
                      radius: 6,
                      backgroundColor: catColor,
                    ),
                    label: Text(
                      cat.name,
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
                        _selectedCategoryId = isSelected ? null : cat.id;
                      });
                    },
                  ),
                );
              }),

              // Manage Categories Shortcut Chip
              ActionChip(
                avatar: const Icon(Icons.tune, size: 14, color: Color(0xFF38BDF8)),
                label: Text(
                  lang == AppLanguage.my ? '+ အမျိုးအစားများ' : '+ Manage',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFF38BDF8), width: 0.8),
                onPressed: () => CategoryManagementDialog.show(context),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => const SizedBox.shrink(),
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutOfStock ? Colors.red.withValues(alpha: 0.3) : const Color(0xFF334155),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Product Image with Stock Badge overlay (Expands to fill available top space)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImageWidget(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? const Color(0xFFEF4444).withValues(alpha: 0.9)
                              : product.stockQuantity <= 10
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.9)
                                  : const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isOutOfStock
                                ? Colors.redAccent
                                : product.stockQuantity <= 10
                                    ? Colors.amberAccent
                                    : const Color(0xFF10B981),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isOutOfStock ? 'Out' : '${product.stockQuantity}',
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.white
                                : product.stockQuantity <= 10
                                    ? Colors.white
                                    : const Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Details (Snug & tight at the bottom with zero dangling empty void!)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_currencyFormat.format(product.sellingPrice)} MMK',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
