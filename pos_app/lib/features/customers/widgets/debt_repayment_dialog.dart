import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../pos/widgets/receipt_dialog.dart';

class DebtRepaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const DebtRepaymentDialog({super.key, required this.customer});

  static Future<bool?> show(BuildContext context, Customer customer) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DebtRepaymentDialog(customer: customer),
    );
  }

  @override
  ConsumerState<DebtRepaymentDialog> createState() => _DebtRepaymentDialogState();
}

class _DebtRepaymentDialogState extends ConsumerState<DebtRepaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedPaymentMethod = 'CASH';
  bool _isSaving = false;

  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  final List<Map<String, dynamic>> _paymentMethods = [
    {'code': 'CASH', 'label': 'Cash (ငွေသား)', 'icon': Icons.payments_outlined, 'color': Color(0xFF10B981)},
    {'code': 'KBZ_PAY', 'label': 'KBZPay', 'icon': Icons.account_balance_wallet, 'color': Color(0xFF2563EB)},
    {'code': 'WAVE_PAY', 'label': 'WavePay', 'icon': Icons.phone_android, 'color': Color(0xFFF59E0B)},
    {'code': 'AYA_PAY', 'label': 'AYAPay', 'icon': Icons.credit_card, 'color': Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    // Default to full debt amount
    _amountController.text = widget.customer.totalDebt.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _enteredAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  double get _calculatedRemainingDebt {
    final remaining = widget.customer.totalDebt - _enteredAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  void _setFullAmount() {
    setState(() {
      _amountController.text = widget.customer.totalDebt.toStringAsFixed(0);
    });
  }

  Future<void> _processRepayment() async {
    final amount = _enteredAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please enter a valid repayment amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final customerDao = ref.read(customerDaoProvider);
      final shop = await (db.select(db.shops)..limit(1)).getSingleOrNull();
      final shopId = shop?.id ?? 'default_shop';

      final repaymentId = 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final now = DateTime.now().toUtc();
      final note = _noteController.text.trim().isEmpty
          ? 'Debt Settlement via $_selectedPaymentMethod'
          : '${_noteController.text.trim()} ($_selectedPaymentMethod)';

      // Record in customer ledger atomically
      await customerDao.recordLedgerEntry(
        ledgerEntry: CustomerLedgersCompanion.insert(
          id: const Uuid().v4(),
          shopId: shopId,
          customerId: widget.customer.id,
          type: 'PAYMENT',
          amount: amount,
          notes: drift.Value(note),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
      );

      // Generate 58mm Receipt Slip Text
      final slipText = ThermalReceiptFormatter.formatDebtRepaymentSlip(
        shopName: shop?.name ?? 'DOT POS Store',
        shopPhone: shop?.phone,
        shopAddress: shop?.address,
        customerName: widget.customer.name,
        customerPhone: widget.customer.phone,
        receiptId: repaymentId,
        date: DateTime.now(),
        previousDebt: widget.customer.totalDebt,
        amountPaid: amount,
        remainingDebt: _calculatedRemainingDebt,
        paymentMethod: _selectedPaymentMethod,
        notes: note,
        lineWidth: 32,
      );

      if (mounted) {
        Navigator.of(context).pop(true);

        // Open Thermal Receipt Preview Dialog
        ReceiptDialog.show(
          context,
          receiptText: slipText,
          orderNumber: repaymentId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Payment of ${_currencyFormat.format(amount)} MMK received from "${widget.customer.name}"!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Failed to process payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payments, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Debt Repayment', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                Text(
                  widget.customer.name,
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
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Debt Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Outstanding Debt:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      '${_currencyFormat.format(widget.customer.totalDebt)} MMK',
                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Repayment Amount Input + Pay Full Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Repayment Amount *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                  ActionChip(
                    label: const Text('Pay Full Amount', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _setFullAmount,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'MMK',
                  suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Payment Method Grid
              const Text('Payment Mode', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: _paymentMethods.map((m) {
                  final isSelected = _selectedPaymentMethod == m['code'];
                  final color = m['color'] as Color;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPaymentMethod = m['code']),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : const Color(0xFF334155),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(m['icon'] as IconData, size: 18, color: isSelected ? color : const Color(0xFF94A3B8)),
                              const SizedBox(height: 4),
                              Text(
                                m['code'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Reference / Note
              const Text('Reference / Note (Optional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Paid by customer via KPay, Receipt #8812',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 16),

              // Resulting Balance Preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining Debt After Payment:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    Text(
                      '${_currencyFormat.format(_calculatedRemainingDebt)} MMK',
                      style: TextStyle(
                        color: _calculatedRemainingDebt == 0 ? const Color(0xFF10B981) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _processRepayment,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.print, size: 18),
          label: Text(_isSaving ? 'Processing...' : 'Settle & Print Slip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
