import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../pos/widgets/receipt_dialog.dart';

class CustomerStatementDialog extends ConsumerWidget {
  final Customer customer;

  const CustomerStatementDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => CustomerStatementDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(customerHistoryStreamProvider(customer.id));
    final shopAsync = ref.watch(currentShopProvider);
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: Color(0xFF38BDF8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Statement', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                Text(
                  customer.name,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 460,
        child: Column(
          children: [
            // Top Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Outstanding Balance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '${currencyFormat.format(customer.totalDebt)} MMK',
                        style: TextStyle(
                          color: customer.totalDebt > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (customer.phone != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Text(customer.phone!, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Timeline Header
            const Row(
              children: [
                Icon(Icons.history, size: 16, color: Color(0xFF94A3B8)),
                SizedBox(width: 6),
                Text('Ledger Movements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),

            // Timeline Entries
            Expanded(
              child: historyAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text('No transaction history recorded yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    );
                  }

                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1, color: Color(0xFF334155)),
                    itemBuilder: (ctx, index) {
                      final item = entries[index];
                      final isIncrease = item.type == 'DEBT_INCREASE';
                      final color = isIncrease ? const Color(0xFFEF4444) : const Color(0xFF10B981);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                                color: color,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isIncrease ? 'Credit Purchase' : 'Debt Repayment',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (item.notes != null && item.notes!.isNotEmpty)
                                    Text(
                                      item.notes!,
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    dateFormat.format(item.createdAt),
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncrease ? '+' : '-'}${currencyFormat.format(item.amount)} MMK',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final shop = shopAsync.value;
            final entries = historyAsync.value ?? [];

            final transactions = entries.map((e) {
              return {
                'date': e.createdAt,
                'type': e.type,
                'amount': e.amount,
              };
            }).toList();

            final slipText = ThermalReceiptFormatter.formatCustomerStatementSlip(
              shopName: shop?.name ?? 'DOT POS Store',
              shopPhone: shop?.phone,
              customerName: customer.name,
              customerPhone: customer.phone,
              date: DateTime.now(),
              totalDebt: customer.totalDebt,
              transactions: transactions,
              lineWidth: 32,
            );

            Navigator.of(context).pop();

            ReceiptDialog.show(
              context,
              receiptText: slipText,
              orderNumber: 'STMT-${customer.name}',
            );
          },
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Print Statement Slip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
