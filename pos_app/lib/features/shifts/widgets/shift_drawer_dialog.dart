import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import 'open_shift_dialog.dart';

class ShiftDrawerDialog extends ConsumerStatefulWidget {
  const ShiftDrawerDialog({super.key});

  static Future<Shift?> show(BuildContext context) {
    return showDialog<Shift>(
      context: context,
      builder: (ctx) => const ShiftDrawerDialog(),
    );
  }

  @override
  ConsumerState<ShiftDrawerDialog> createState() => _ShiftDrawerDialogState();
}

class _ShiftDrawerDialogState extends ConsumerState<ShiftDrawerDialog> {
  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  void _showPayInOrOutDialog({required bool isPayIn, required String shiftId}) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isPayIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPayIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            Text(
              isPayIn ? 'Pay In (ငွေသွင်းခြင်း)' : 'Pay Out / Expense (ငွေထုတ်ခြင်း)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount (MMK) *',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Reason / Description (e.g. Ice, Plastic bags)',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPayIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text.replaceAll(',', '').trim()) ?? 0.0;
              if (amount <= 0) return;

              final shiftDao = ref.read(shiftDaoProvider);
              await shiftDao.recordCashMovement(
                shiftId: shiftId,
                type: isPayIn ? 'PAY_IN' : 'PAY_OUT',
                amount: amount,
                note: noteController.text.trim(),
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: isPayIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    content: Text('${isPayIn ? "Pay In" : "Pay Out"} of ${_currencyFormat.format(amount)} MMK recorded!'),
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeShiftAsync = ref.watch(activeShiftStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: activeShiftAsync.when(
          data: (shift) {
            if (shift == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.point_of_sale_outlined, color: Color(0xFF94A3B8), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No Active Shift',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The cash drawer is currently closed. Open a shift to start recording cash sales.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.lock_clock),
                      label: const Text('Open New Shift (အဆိုင်းဖွင့်ရန်)'),
                      onPressed: () {
                        Navigator.pop(context);
                        OpenShiftDialog.show(context);
                      },
                    ),
                  ],
                ),
              );
            }

            final expectedCash = shift.openingCashFloat + shift.cashSales + shift.cashIn - shift.cashOut;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.point_of_sale, color: Color(0xFF60A5FA), size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Cash Drawer Management',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Total in Drawer Highlight Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'CURRENT EXPECTED CASH IN DRAWER',
                              style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_currencyFormat.format(expectedCash)} MMK',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Opened at ${DateFormat('hh:mm a').format(shift.openedAt)}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Breakdown Table
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          children: [
                            _buildDrawerRow('Starting Cash Float:', '${_currencyFormat.format(shift.openingCashFloat)} MMK'),
                            const Divider(color: Color(0xFF334155), height: 14),
                            _buildDrawerRow('Cash Sales (+):', '+${_currencyFormat.format(shift.cashSales)} MMK', color: const Color(0xFF10B981)),
                            const Divider(color: Color(0xFF334155), height: 14),
                            _buildDrawerRow('Digital / Non-Cash Sales:', '${_currencyFormat.format(shift.nonCashSales)} MMK'),
                            const Divider(color: Color(0xFF334155), height: 14),
                            _buildDrawerRow('Pay In / Cash Added (+):', '+${_currencyFormat.format(shift.cashIn)} MMK'),
                            const Divider(color: Color(0xFF334155), height: 14),
                            _buildDrawerRow('Pay Out / Cash Expenses (-):', '-${_currencyFormat.format(shift.cashOut)} MMK', color: Colors.redAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pay In / Pay Out Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10B981),
                                side: const BorderSide(color: Color(0xFF10B981)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.arrow_downward, size: 16),
                              label: const Text('Pay In (+)', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _showPayInOrOutDialog(isPayIn: true, shiftId: shift.id),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.arrow_upward, size: 16),
                              label: const Text('Pay Out (-)', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _showPayInOrOutDialog(isPayIn: false, shiftId: shift.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer with Close Shift Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.fact_check, size: 20),
                      label: const Text('Close Shift & Audit Drawer (အဆိုင်းပိတ်မည်)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context, shift);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading shift: $err', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
