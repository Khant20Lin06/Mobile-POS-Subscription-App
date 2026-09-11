import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_provider.dart';

class OpenShiftDialog extends ConsumerStatefulWidget {
  const OpenShiftDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const OpenShiftDialog(),
    );
  }

  @override
  ConsumerState<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends ConsumerState<OpenShiftDialog> {
  final _floatController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _currencyFormat = NumberFormat('#,##0', 'en_US');
  final _uuid = const Uuid();

  double get _enteredFloat {
    final clean = _floatController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  void _addFloat(double amount) {
    final current = _enteredFloat;
    final total = current + amount;
    _floatController.text = _currencyFormat.format(total);
    setState(() {});
  }

  @override
  void dispose() {
    _floatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.lock_clock, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Open Cashier Shift (အဆိုင်းဖွင့်ခြင်း)',
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
                  // Cashier Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            activeUser != null && activeUser.name.isNotEmpty
                                ? activeUser.name.substring(0, 1).toUpperCase()
                                : 'C',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeUser?.name ?? 'Unknown Cashier',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Opening Shift at ${DateFormat('hh:mm a, dd MMM yyyy').format(DateTime.now())}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Starting Cash Float (အံဆွဲစတင်ငွေ):',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Amount Input
                  TextFormField(
                    controller: _floatController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
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
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Quick Increment Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickChip('+10,000', 10000),
                      _buildQuickChip('+20,000', 20000),
                      _buildQuickChip('+50,000', 50000),
                      _buildQuickChip('+100,000', 100000),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Optional Notes
                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Opening Note (Optional)',
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
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Start Shift (အဆိုင်းစတင်မည်)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final shop = await ref.read(currentShopProvider.future);
                        if (shop == null || activeUser == null) return;

                        final shiftDao = ref.read(shiftDaoProvider);
                        final now = DateTime.now().toUtc();
                        final startingFloat = _enteredFloat;

                        await shiftDao.openShift(
                          ShiftsCompanion.insert(
                            id: _uuid.v4(),
                            shopId: shop.id,
                            userId: activeUser.id,
                            openedAt: now,
                            openingCashFloat: drift.Value(startingFloat),
                            expectedCash: drift.Value(startingFloat),
                            status: const drift.Value('OPEN'),
                            notes: drift.Value(_notesController.text.trim()),
                            createdAt: drift.Value(now),
                            updatedAt: drift.Value(now),
                            syncStatus: const drift.Value('pending'),
                          ),
                        );

                        navigator.pop(true);
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Shift opened with ${_currencyFormat.format(startingFloat)} MMK starting float!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double amount) {
    return ActionChip(
      backgroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF334155)),
      label: Text(label, style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold)),
      onPressed: () => _addFloat(amount),
    );
  }
}
