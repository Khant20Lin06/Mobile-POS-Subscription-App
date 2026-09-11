import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../pos/widgets/receipt_dialog.dart';

class DailyZReportScreen extends ConsumerStatefulWidget {
  const DailyZReportScreen({super.key});

  @override
  ConsumerState<DailyZReportScreen> createState() => _DailyZReportScreenState();
}

class _DailyZReportScreenState extends ConsumerState<DailyZReportScreen> {
  final _currencyFormat = NumberFormat('#,##0', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd');
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final shopAsync = ref.watch(currentShopProvider);

    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

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
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_outlined, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Z-Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                Text(
                  'End of Day Sales & Profit Audit',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Date Selector Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF38BDF8)),
            label: Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 12)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: (db.select(db.orders)
              ..where((tbl) =>
                  tbl.deletedAt.isNull() &
                  tbl.status.equals('COMPLETED') &
                  tbl.createdAt.isBiggerOrEqualValue(startOfDay) &
                  tbl.createdAt.isSmallerThanValue(endOfDay))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];
          double totalRevenue = 0.0;
          double cashTotal = 0.0;
          double kpayTotal = 0.0;
          double waveTotal = 0.0;
          double creditTotal = 0.0;
          double totalDiscount = 0.0;

          for (final o in orders) {
            totalRevenue += o.totalAmount;
            totalDiscount += o.discountAmount;
            if (o.paymentMethod == 'CASH') {
              cashTotal += o.totalAmount;
            } else if (o.paymentMethod == 'KBZ_PAY') {
              kpayTotal += o.totalAmount;
            } else if (o.paymentMethod == 'WAVE_PAY') {
              waveTotal += o.totalAmount;
            } else if (o.paymentMethod == 'CREDIT') {
              creditTotal += o.totalAmount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Metrics Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMetricCard(
                        title: 'Total Revenue',
                        value: '${_currencyFormat.format(totalRevenue)} MMK',
                        icon: Icons.payments,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Orders Count',
                        value: '${orders.length}',
                        icon: Icons.receipt_long,
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Cash in Drawer',
                        value: '${_currencyFormat.format(cashTotal)} MMK',
                        icon: Icons.point_of_sale,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Digital Wallets',
                        value: '${_currencyFormat.format(kpayTotal + waveTotal)} MMK',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFFA855F7),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        title: 'Credit / Debt Sales',
                        value: '${_currencyFormat.format(creditTotal)} MMK',
                        icon: Icons.pending_actions,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action: Print Z-Report Slip Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.print, size: 20),
                  label: const Text(
                    'PRINT DAILY Z-REPORT SLIP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => _printZReport(
                    context,
                    shopAsync.value,
                    orders,
                    totalRevenue,
                    cashTotal,
                    kpayTotal,
                    waveTotal,
                    creditTotal,
                    totalDiscount,
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Breakdown Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Channels Breakdown',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      _buildChannelRow('💵 Cash (ငွေသား):', cashTotal, totalRevenue),
                      const Divider(color: Color(0xFF334155), height: 16),
                      _buildChannelRow('📱 KBZPay:', kpayTotal, totalRevenue),
                      const Divider(color: Color(0xFF334155), height: 16),
                      _buildChannelRow('🌊 WavePay:', waveTotal, totalRevenue),
                      const Divider(color: Color(0xFF334155), height: 16),
                      _buildChannelRow('📋 Credit (အကြွေးအရောင်း):', creditTotal, totalRevenue),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Transactions of the day
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions for ${_dateFormat.format(_selectedDate)} (${orders.length})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      if (orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('No completed transactions on this date.',
                                style: TextStyle(color: Color(0xFF94A3B8))),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orders.length,
                          separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155)),
                          itemBuilder: (context, index) {
                            final o = orders[index];
                            final timeFormat = DateFormat('HH:mm:ss');
                            return Row(
                              children: [
                                Text(
                                  timeFormat.format(o.createdAt.toLocal()),
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Payment: ${o.paymentMethod}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_currencyFormat.format(o.totalAmount)} MMK',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow(String label, double amount, double totalRevenue) {
    final pct = totalRevenue > 0 ? (amount / totalRevenue * 100).toStringAsFixed(1) : '0.0';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        Row(
          children: [
            Text(
              '${_currencyFormat.format(amount)} MMK',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text('($pct%)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      ],
    );
  }

  void _printZReport(
    BuildContext context,
    Shop? shop,
    List<Order> orders,
    double totalRevenue,
    double cash,
    double kpay,
    double wave,
    double credit,
    double discount,
  ) {
    // Generate Z-Report receipt representation
    final receipt = ReceiptData(
      shopName: '${shop?.name ?? "My POS Store"} [DAILY Z-REPORT]',
      shopPhone: shop?.phone,
      shopAddress: shop?.address,
      currency: shop?.currency ?? 'MMK',
      orderNumber: 'Z-${DateFormat('yyyyMMdd').format(_selectedDate)}',
      orderDate: DateTime.now(),
      cashierName: 'Manager / Audit',
      customerName: 'DAILY SUMMARY',
      items: [
        ReceiptLineItem(name: 'Total Orders Placed', quantity: orders.length, unitPrice: 0, subtotal: 0),
        ReceiptLineItem(name: 'Cash In Drawer', quantity: 1, unitPrice: cash, subtotal: cash),
        ReceiptLineItem(name: 'KBZPay Receipts', quantity: 1, unitPrice: kpay, subtotal: kpay),
        ReceiptLineItem(name: 'WavePay Receipts', quantity: 1, unitPrice: wave, subtotal: wave),
        ReceiptLineItem(name: 'Credit (Debt) Sales', quantity: 1, unitPrice: credit, subtotal: credit),
      ],
      subtotal: totalRevenue + discount,
      discount: discount,
      totalAmount: totalRevenue,
      tenderAmount: cash,
      changeDue: 0.0,
      paymentMethod: 'MULTIPLE CHANNELS',
      notes: 'Official End of Day Z-Report Audit Slip',
    );

    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(receipt: receipt),
    );
  }
}
