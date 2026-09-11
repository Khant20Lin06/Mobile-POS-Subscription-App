import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../providers/cart_provider.dart';

class CustomerSelectDialog extends ConsumerWidget {
  const CustomerSelectDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersStreamProvider);
    final selectedCustomer = ref.watch(cartProvider).selectedCustomer;
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 550),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: Color(0xFF60A5FA), size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Select Customer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Walk-in / Guest Option
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: selectedCustomer == null ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                ),
              ),
              tileColor: selectedCustomer == null
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                  : const Color(0xFF0F172A),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF334155),
                child: Icon(
                  Icons.person_outline,
                  color: selectedCustomer == null ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                ),
              ),
              title: const Text('Walk-in Customer (ဧည့်သည်)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('No debt tracking', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              trailing: selectedCustomer == null
                  ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 20)
                  : null,
              onTap: () {
                ref.read(cartProvider.notifier).setCustomer(null);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registered Customers',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add, size: 16, color: Color(0xFF38BDF8)),
                  label: const Text('New Customer', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                  onPressed: () => _showAddCustomerDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return const Center(
                      child: Text('No customers registered.', style: TextStyle(color: Color(0xFF94A3B8))),
                    );
                  }
                  return ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      final isSelected = selectedCustomer?.id == c.id;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                          ),
                        ),
                        tileColor: isSelected
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                            : const Color(0xFF0F172A),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF334155),
                          child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          c.phone ?? 'No phone',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Debt: ${currencyFormat.format(c.totalDebt)}',
                              style: TextStyle(
                                color: c.totalDebt > 0 ? Colors.redAccent : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 16),
                          ],
                        ),
                        onTap: () {
                          ref.read(cartProvider.notifier).setCustomer(c);
                          Navigator.pop(context);
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
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Customer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            TextField(
              controller: phoneCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final shop = await ref.read(currentShopProvider.future);
              final shopId = shop?.id ?? 'default-shop';
              final uuid = const Uuid();
              final customerId = uuid.v4();
              final now = DateTime.now().toUtc();

              await ref.read(customerDaoProvider).insertCustomer(
                    CustomersCompanion.insert(
                      id: customerId,
                      shopId: shopId,
                      name: nameCtrl.text.trim(),
                      phone: drift.Value(phoneCtrl.text.trim()),
                      totalDebt: const drift.Value(0.0),
                      createdAt: drift.Value(now),
                      updatedAt: drift.Value(now),
                      syncStatus: const drift.Value('pending'),
                    ),
                  );

              final newCust = Customer(
                id: customerId,
                shopId: shopId,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                totalDebt: 0.0,
                createdAt: now,
                updatedAt: now,
                syncStatus: 'pending',
              );

              ref.read(cartProvider.notifier).setCustomer(newCust);
              if (context.mounted) {
                Navigator.pop(ctx); // Close add dialog
                Navigator.pop(context); // Close customer select dialog
              }
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }
}
