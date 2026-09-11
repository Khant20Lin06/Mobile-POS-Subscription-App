import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/providers/database_provider.dart';
import '../providers/cart_provider.dart';
import 'receipt_dialog.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  final _currencyFormat = NumberFormat('#,##0', 'en_US');
  String _selectedMethod = 'CASH';
  late TextEditingController _tenderController;
  double _tenderAmount = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _tenderAmount = cart.totalAmount;
    _tenderController = TextEditingController(text: cart.totalAmount.toInt().toString());
  }

  @override
  void dispose() {
    _tenderController.dispose();
    super.dispose();
  }

  void _setTender(double amount) {
    setState(() {
      _tenderAmount = amount;
      _tenderController.text = amount.toInt().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final shopAsync = ref.watch(currentShopProvider);
    final total = cart.totalAmount;
    final changeDue = _tenderAmount - total;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              children: [
                const Icon(Icons.point_of_sale, color: Color(0xFF60A5FA), size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Payment & Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grand Total Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Payable Amount',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      Text(
                        '${_currencyFormat.format(total)} MMK',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  if (cart.selectedCustomer != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF60A5FA), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            cart.selectedCustomer!.name,
                            style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods Grid
            const Text(
              'Select Payment Method',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMethodButton('CASH', 'Cash (ငွေသား)', Icons.money),
                _buildMethodButton('KBZ_PAY', 'KBZPay', Icons.phone_android),
                _buildMethodButton('WAVE_PAY', 'WavePay', Icons.account_balance_wallet),
                _buildMethodButton('CREDIT', 'Credit (အကြွေး)', Icons.receipt_long),
              ],
            ),
            const SizedBox(height: 16),

            // Cash Tender & Quick Buttons (Only for CASH)
            if (_selectedMethod == 'CASH') ...[
              const Text(
                'Tendered Amount (ပေးငွေ)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tenderController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: 'MMK',
                  suffixStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _tenderAmount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Quick Tender Denominations
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickTenderChip('Exact', total),
                  if (total < 5000) _buildQuickTenderChip('5,000', 5000),
                  if (total < 10000) _buildQuickTenderChip('10,000', 10000),
                  if (total < 20000) _buildQuickTenderChip('20,000', 20000),
                  if (total < 50000) _buildQuickTenderChip('50,000', 50000),
                  _buildQuickTenderChip('100,000', 100000),
                ],
              ),
              const SizedBox(height: 14),

              // Change Due Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: changeDue >= 0
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: changeDue >= 0 ? const Color(0xFF10B981) : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      changeDue >= 0 ? 'Change Due (ပြန်အမ်းငွေ):' : 'Insufficient Tender (မလုံလောက်ပါ):',
                      style: TextStyle(
                        color: changeDue >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_currencyFormat.format(changeDue.abs())} MMK',
                      style: TextStyle(
                        color: changeDue >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Credit validation warning
            if (_selectedMethod == 'CREDIT' && cart.selectedCustomer == null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'အကြွေးဖြင့် ရောင်းချရန် Customer ရွေးချယ်ပေးရန် လိုအပ်ပါသည်။',
                        style: TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Confirm Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isProcessing ||
                      (_selectedMethod == 'CASH' && changeDue < 0) ||
                      (_selectedMethod == 'CREDIT' && cart.selectedCustomer == null)
                  ? null
                  : () => _completeOrder(context, cart, shopAsync.value),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'COMPLETE TRANSACTION & PRINT SLIP',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton(String method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
          if (method != 'CASH') {
            _tenderAmount = ref.read(cartProvider).totalAmount;
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTenderChip(String label, double amount) {
    return ActionChip(
      backgroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF334155)),
      label: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      onPressed: () => _setTender(amount),
    );
  }

  Future<void> _completeOrder(
    BuildContext context,
    CartState cart,
    Shop? shop,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final orderDao = ref.read(orderDaoProvider);
      final customerDao = ref.read(customerDaoProvider);
      final uuid = const Uuid();
      final orderId = uuid.v4();
      final now = DateTime.now().toUtc();
      final shopId = shop?.id ?? 'default-shop';
      final invoiceNumber = 'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';

      // 1. Prepare Order items
      final itemsCompanion = cart.items.map((ci) {
        return OrderItemsCompanion.insert(
          id: uuid.v4(),
          orderId: orderId,
          productId: ci.product.id,
          productName: ci.product.name,
          quantity: ci.quantity,
          costPrice: ci.product.costPrice,
          unitPrice: ci.unitPrice,
          subtotal: ci.subtotal,
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        );
      }).toList();

      final activeUser = ref.read(currentUserProvider);

      // 2. Insert Order + Decrement Stock in ACID Transaction
      await orderDao.createOrderWithItems(
        orderEntry: OrdersCompanion.insert(
          id: orderId,
          shopId: shopId,
          userId: drift.Value(activeUser?.id),
          customerId: drift.Value(cart.selectedCustomer?.id),
          orderNumber: invoiceNumber,
          subtotal: cart.subtotal,
          discountAmount: drift.Value(cart.discountAmount),
          taxAmount: drift.Value(cart.taxAmount),
          totalAmount: cart.totalAmount,
          paymentMethod: drift.Value(_selectedMethod),
          status: const drift.Value('COMPLETED'),
          notes: drift.Value(cart.notes),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        ),
        items: itemsCompanion,
      );

      // 3. If credit sale, record in customer ledger
      if (_selectedMethod == 'CREDIT' && cart.selectedCustomer != null) {
        await customerDao.recordLedgerEntry(
          ledgerEntry: CustomerLedgersCompanion.insert(
            id: uuid.v4(),
            shopId: shopId,
            customerId: cart.selectedCustomer!.id,
            orderId: drift.Value(orderId),
            type: 'DEBT_INCREASE',
            amount: cart.totalAmount,
            notes: drift.Value('Credit Sale: $invoiceNumber'),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
            syncStatus: const drift.Value('pending'),
          ),
        );
      }

      // 4. Update active shift drawer sales
      final activeShift = await ref.read(shiftDaoProvider).getActiveShift(shopId);
      if (activeShift != null) {
        final isCash = _selectedMethod == 'CASH';
        await ref.read(shiftDaoProvider).recordOrderSale(
          shiftId: activeShift.id,
          cashAmount: isCash ? cart.totalAmount : 0.0,
          nonCashAmount: isCash ? 0.0 : cart.totalAmount,
        );
      }

      // 5. Build Receipt Data Model
      final receipt = ReceiptData(
        shopName: shop?.name ?? 'My POS Store',
        shopPhone: shop?.phone,
        shopAddress: shop?.address,
        currency: shop?.currency ?? 'MMK',
        orderNumber: invoiceNumber,
        orderDate: DateTime.now(),
        cashierName: activeUser?.name ?? 'Cashier',
        customerName: cart.selectedCustomer?.name,
        items: cart.items.map((ci) {
          return ReceiptLineItem(
            name: ci.product.name,
            quantity: ci.quantity,
            unitPrice: ci.unitPrice,
            subtotal: ci.subtotal,
          );
        }).toList(),
        subtotal: cart.subtotal,
        discount: cart.discountAmount,
        tax: cart.taxAmount,
        totalAmount: cart.totalAmount,
        tenderAmount: _tenderAmount,
        changeDue: _selectedMethod == 'CASH' ? (_tenderAmount - cart.totalAmount) : 0.0,
        paymentMethod: _selectedMethod,
        notes: cart.notes,
      );

      // 5. Clear Cart
      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(pendingSyncCountProvider);

      // Auto-print receipt if enabled in settings
      final printerConfig = ref.read(printerConfigProvider);
      if (printerConfig.autoPrint) {
        ref.read(printerServiceProvider).printReceipt(receipt).ignore();
      }

      if (!context.mounted) return;

      Navigator.pop(context); // Close Payment Modal

      // Open Receipt Dialog
      showDialog(
        context: context,
        builder: (ctx) => ReceiptDialog(receipt: receipt),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
