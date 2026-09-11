import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CloseShiftDialog extends ConsumerStatefulWidget {
  final Shift shift;
  const CloseShiftDialog({super.key, required this.shift});

  static Future<String?> show(BuildContext context, Shift shift) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => CloseShiftDialog(shift: shift),
    );
  }

  @override
  ConsumerState<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<CloseShiftDialog> {
  final _countController = TextEditingController();
  final _notesController = TextEditingController();
  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  double get _expectedCash {
    return widget.shift.openingCashFloat + widget.shift.cashSales + widget.shift.cashIn - widget.shift.cashOut;
  }

  double get _actualCounted {
    final clean = _countController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  double get _difference => _actualCounted - _expectedCash;

  @override
  void initState() {
    super.initState();
    _countController.text = _currencyFormat.format(_expectedCash);
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = _difference;
    final activeUser = ref.watch(currentUserProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
                    const Icon(Icons.fact_check, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Close Shift (အဆိုင်းပိတ် ငွေစစ်ခြင်း)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shift Summary Metric Cards
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Starting Float (စတင်ဖွင့်ငွေ):', '${_currencyFormat.format(widget.shift.openingCashFloat)} MMK'),
                          const SizedBox(height: 6),
                          _buildSummaryRow('Cash Sales (ငွေသားအရောင်း):', '+${_currencyFormat.format(widget.shift.cashSales)} MMK', color: const Color(0xFF10B981)),
                          const SizedBox(height: 6),
                          _buildSummaryRow('Pay In / Repayments (+):', '+${_currencyFormat.format(widget.shift.cashIn)} MMK'),
                          const SizedBox(height: 6),
                          _buildSummaryRow('Pay Out / Expenses (-):', '-${_currencyFormat.format(widget.shift.cashOut)} MMK', color: Colors.redAccent),
                          const Divider(color: Color(0xFF334155), height: 16),
                          _buildSummaryRow(
                            'EXPECTED IN DRAWER (ခန့်မှန်းလက်ကျန်):',
                            '${_currencyFormat.format(_expectedCash)} MMK',
                            isBold: true,
                            color: const Color(0xFF60A5FA),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Actual Counted Cash (ရေတွက်ရရှိသော ငွေသား):',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        suffixText: 'MMK',
                        suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Discrepancy Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: diff == 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : diff > 0
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: diff == 0
                              ? const Color(0xFF10B981)
                              : diff > 0
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            diff == 0
                                ? Icons.check_circle
                                : diff > 0
                                    ? Icons.add_circle
                                    : Icons.warning_amber_rounded,
                            color: diff == 0
                                ? const Color(0xFF10B981)
                                : diff > 0
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              diff == 0
                                  ? 'BALANCED: Cash drawer is 100% exact!'
                                  : diff > 0
                                      ? 'CASH OVER: +${_currencyFormat.format(diff)} MMK (ပိုငွေ)'
                                      : 'CASH SHORT: ${_currencyFormat.format(diff)} MMK (လိုငွေ)',
                              style: TextStyle(
                                color: diff == 0
                                    ? const Color(0xFF10B981)
                                    : diff > 0
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optional Notes
                    TextFormField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Closing Note (e.g. Discrepancy reason)',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.lock, size: 18),
                        label: const Text('Confirm & Close Shift', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final shiftDao = ref.read(shiftDaoProvider);
                          final actualCount = _actualCounted;
                          final closeNote = _notesController.text.trim();

                          final closedShift = await shiftDao.closeShift(
                            shiftId: widget.shift.id,
                            actualCash: actualCount,
                            closeNotes: closeNote.isNotEmpty ? closeNote : null,
                          );

                          final shop = await ref.read(currentShopProvider.future);

                          final slipText = ThermalReceiptFormatter.formatShiftClosingSlip(
                            shopName: shop?.name ?? 'DOT POS Store',
                            shopPhone: shop?.phone,
                            shopAddress: shop?.address,
                            shiftId: closedShift.id,
                            cashierName: activeUser?.name ?? 'Cashier',
                            openedAt: closedShift.openedAt,
                            closedAt: closedShift.closedAt ?? DateTime.now(),
                            openingFloat: closedShift.openingCashFloat,
                            cashSales: closedShift.cashSales,
                            nonCashSales: closedShift.nonCashSales,
                            cashIn: closedShift.cashIn,
                            cashOut: closedShift.cashOut,
                            expectedCash: closedShift.expectedCash,
                            actualCash: actualCount,
                            difference: closedShift.difference ?? 0.0,
                            notes: closeNote,
                            lineWidth: 32,
                          );

                          navigator.pop(slipText);
                        },
                      ),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : const Color(0xFF94A3B8),
            fontSize: isBold ? 12 : 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isBold ? Colors.white : const Color(0xFFE2E8F0)),
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
