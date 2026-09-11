import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';
import '../../pos/widgets/receipt_dialog.dart';
import '../widgets/invoice_detail_dialog.dart';

enum InvoiceDateFilter { today, week, month, all }

class SaleInvoiceScreen extends ConsumerStatefulWidget {
  const SaleInvoiceScreen({super.key});

  @override
  ConsumerState<SaleInvoiceScreen> createState() => _SaleInvoiceScreenState();
}

class _SaleInvoiceScreenState extends ConsumerState<SaleInvoiceScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat('#,##0', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  InvoiceDateFilter _selectedFilter = InvoiceDateFilter.today;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  (DateTime?, DateTime?) _calculateDateRange(InvoiceDateFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case InvoiceDateFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return (start, end);
      case InvoiceDateFilter.week:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        return (start, end);
      case InvoiceDateFilter.month:
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
        return (start, nextMonth);
      case InvoiceDateFilter.all:
        return (null, null);
    }
  }

  Future<void> _quickPrintSlip(Order order, String customerName) async {
    final orderDao = ref.read(orderDaoProvider);
    final shop = ref.read(currentShopProvider).value;
    final items = await orderDao.getItemsForOrder(order.id);

    final receipt = ReceiptData(
      shopName: shop?.name ?? 'My POS Store',
      shopPhone: shop?.phone,
      shopAddress: shop?.address,
      currency: shop?.currency ?? 'MMK',
      orderNumber: order.orderNumber,
      orderDate: order.createdAt.toLocal(),
      cashierName: 'Cashier',
      customerName: customerName.isNotEmpty ? customerName : null,
      items: items.map((item) {
        return ReceiptLineItem(
          name: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          subtotal: item.subtotal,
        );
      }).toList(),
      subtotal: order.subtotal,
      discount: order.discountAmount,
      tax: order.taxAmount,
      totalAmount: order.totalAmount,
      tenderAmount: order.totalAmount,
      changeDue: 0.0,
      paymentMethod: order.paymentMethod,
      notes: order.notes,
    );

    if (mounted) {
      ReceiptDialog.show(context, receipt: receipt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final orderDao = ref.watch(orderDaoProvider);
    final shop = ref.watch(currentShopProvider).value;
    final currency = shop?.currency ?? 'MMK';

    // Build customer name lookup map
    final customersList = ref.watch(customersStreamProvider).value ?? [];
    final customerMap = <String, String>{
      for (final c in customersList) c.id: c.name,
    };

    final (startDate, endDate) = _calculateDateRange(_selectedFilter);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: Color(0xFF60A5FA), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.tr('invoice_title', lang),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          lang == AppLanguage.my
                              ? 'အရောင်းပြေစာ မှတ်တမ်းများ ရှာဖွေခြင်းနှင့် ပြန်လည်ထုတ်ယူခြင်း'
                              : 'Order history, audit vouchers & thermal re-print',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filter Bar & Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppTranslations.tr('invoice_search_hint', lang),
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: AppTranslations.tr('invoice_filter_today', lang),
                          filter: InvoiceDateFilter.today,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: AppTranslations.tr('invoice_filter_week', lang),
                          filter: InvoiceDateFilter.week,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: AppTranslations.tr('invoice_filter_month', lang),
                          filter: InvoiceDateFilter.month,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: AppTranslations.tr('invoice_filter_all', lang),
                          filter: InvoiceDateFilter.all,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Invoices List & Summary Stream
            Expanded(
              child: StreamBuilder<List<Order>>(
                stream: orderDao.watchOrdersFiltered(
                  startDate: startDate,
                  endDate: endDate,
                  query: null, // We filter locally to support customer name search as well
                  limit: 400,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                    );
                  }

                  final allOrders = snapshot.data ?? [];

                  // Apply search filter (matches invoice number OR customer name)
                  final orders = allOrders.where((order) {
                    if (_searchQuery.isEmpty) return true;
                    final orderNum = order.orderNumber.toLowerCase();
                    final custName = (order.customerId != null ? customerMap[order.customerId] ?? '' : '').toLowerCase();
                    return orderNum.contains(_searchQuery) || custName.contains(_searchQuery);
                  }).toList();

                  // Calculate aggregate metrics
                  final totalCount = orders.length;
                  final totalRevenue = orders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);

                  return Column(
                    children: [
                      // Mini stats summary banner
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt, size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Text(
                                  '${AppTranslations.tr('invoice_total_count', lang)}: $totalCount',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '${_currencyFormat.format(totalRevenue)} $currency',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Invoices ListView
                      Expanded(
                        child: orders.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF334155)),
                                      ),
                                      child: const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppTranslations.tr('invoice_no_invoices', lang),
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                                itemCount: orders.length,
                                itemBuilder: (context, index) {
                                  final order = orders[index];
                                  final custName = order.customerId != null
                                      ? (customerMap[order.customerId] ?? 'Customer #${order.customerId!.substring(0, 6)}')
                                      : AppTranslations.tr('invoice_walk_in', lang);

                                  return _buildInvoiceCard(
                                    context: context,
                                    order: order,
                                    customerName: custName,
                                    currency: currency,
                                    lang: lang,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required InvoiceDateFilter filter}) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard({
    required BuildContext context,
    required Order order,
    required String customerName,
    required String currency,
    required AppLanguage lang,
  }) {
    final isCredit = order.paymentMethod == 'CREDIT';
    final isCompleted = order.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            InvoiceDetailDialog.show(
              context,
              order: order,
              customerName: customerName,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Invoice Number, Date, Status badge
                Row(
                  children: [
                    const Icon(Icons.receipt_outlined, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _dateFormat.format(order.createdAt.toLocal()),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 8),

                // Bottom row: Customer, Payment Method, Amount, Action Button
                Row(
                  children: [
                    // Customer
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customerName,
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payment Method Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCredit ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        order.paymentMethod,
                        style: TextStyle(
                          color: isCredit ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Total Amount
                    Text(
                      '${_currencyFormat.format(order.totalAmount)} $currency',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Quick print button
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF94A3B8)),
                      tooltip: AppTranslations.tr('invoice_reprint', lang),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => _quickPrintSlip(order, customerName),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
