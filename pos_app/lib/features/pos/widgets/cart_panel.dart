import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import 'customer_select_dialog.dart';
import 'payment_modal.dart';

class CartPanel extends ConsumerWidget {
  final bool isBottomSheet;

  const CartPanel({
    super.key,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Color(0xFF60A5FA), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Order (${cart.totalItemCount})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                    tooltip: 'Clear Cart',
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  ),
                if (isBottomSheet)
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),

          // Customer Selector Bar
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => const CustomerSelectDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cart.selectedCustomer != null
                          ? 'Customer: ${cart.selectedCustomer!.name}'
                          : 'Customer: Walk-in (Tap to change)',
                      style: TextStyle(
                        color: cart.selectedCustomer != null ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: cart.selectedCustomer != null ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),

          // Cart Items List
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 48, color: Color(0xFF475569)),
                        SizedBox(height: 12),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap products from catalog to add',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF334155)),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currencyFormat.format(item.unitPrice)} MMK each',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => ref.read(cartProvider.notifier).decrement(item.product.id),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF334155)),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 32),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => ref.read(cartProvider.notifier).increment(item.product.id),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF334155)),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Item Subtotal
                            SizedBox(
                              width: 80,
                              child: Text(
                                currencyFormat.format(item.subtotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Cart Totals & Checkout Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    Text(
                      '${currencyFormat.format(cart.subtotal)} MMK',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Discount Row with Edit button
                InkWell(
                  onTap: () => _showDiscountDialog(context, ref, cart.discountAmount),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Discount:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: cart.discountAmount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      Text(
                        '-${currencyFormat.format(cart.discountAmount)} MMK',
                        style: TextStyle(
                          color: cart.discountAmount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 10),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${currencyFormat.format(cart.totalAmount)} MMK',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pay Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.payments, size: 20),
                  label: Text(
                    cart.isEmpty
                        ? 'CHARGE'
                        : 'PAY ${currencyFormat.format(cart.totalAmount)} MMK',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: cart.isEmpty
                      ? null
                      : () {
                          if (isBottomSheet) {
                            Navigator.pop(context); // Close bottom sheet
                          }
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => const PaymentModal(),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref, double currentDiscount) {
    final controller = TextEditingController(
      text: currentDiscount > 0 ? currentDiscount.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Apply Order Discount', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'Discount Amount (MMK)',
            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
            suffixText: 'MMK',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).setDiscount(0.0);
              Navigator.pop(ctx);
            },
            child: const Text('Remove Discount', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              ref.read(cartProvider.notifier).setDiscount(val);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
