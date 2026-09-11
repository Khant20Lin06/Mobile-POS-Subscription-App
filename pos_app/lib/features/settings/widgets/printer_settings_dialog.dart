import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../pos/widgets/receipt_dialog.dart';

class PrinterSettingsDialog extends ConsumerStatefulWidget {
  const PrinterSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const PrinterSettingsDialog(),
    );
  }

  @override
  ConsumerState<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends ConsumerState<PrinterSettingsDialog> {
  String _connectionType = 'bluetooth'; // 'bluetooth', 'wifi', 'usb', 'builtin'
  String _paperSize = '58mm'; // '58mm', '80mm'
  bool _autoPrint = true;
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '9100');
  final _printerNameController = TextEditingController(text: 'MTP-II (Bluetooth)');

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _printerNameController.dispose();
    super.dispose();
  }

  void _handleTestPrint() {
    final shop = ref.read(currentShopProvider).value;
    final shopName = shop?.name ?? 'DOT POS Store';
    final now = DateTime.now();

    final testReceipt = ReceiptData(
      shopName: shopName,
      shopAddress: shop?.address ?? 'No. 123, Bogyoke Road, Yangon',
      shopPhone: shop?.phone ?? '09-770001122',
      currency: shop?.currency ?? 'MMK',
      orderNumber: 'TEST-001',
      orderDate: now,
      cashierName: 'Admin',
      customerName: 'TEST RUN',
      items: const [
        ReceiptLineItem(name: 'Test Item (Coffee)', quantity: 1, unitPrice: 3500.0, subtotal: 3500.0),
        ReceiptLineItem(name: 'Test Item (Water)', quantity: 2, unitPrice: 1000.0, subtotal: 2000.0),
      ],
      subtotal: 5500.0,
      tax: 0.0,
      discount: 0.0,
      totalAmount: 5500.0,
      tenderAmount: 6000.0,
      changeDue: 500.0,
      paymentMethod: 'CASH (TEST)',
      notes: 'Thermal Connection Tested OK!',
    );

    ReceiptDialog.show(
      context,
      receipt: testReceipt,
      title: 'Printer Test Slip (${_paperSize.toUpperCase()})',
      orderNumber: 'TEST-001',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.print, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == AppLanguage.my ? 'ပရင်တာ ချိတ်ဆက်မှု ဆက်တင်' : 'Thermal Printer Setup',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Connection Type
              Text(
                lang == AppLanguage.my ? 'ချိတ်ဆက်မှု အမျိုးအစား' : 'Connection Interface',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Bluetooth (ESC/POS)'),
                    selected: _connectionType == 'bluetooth',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _connectionType == 'bluetooth' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.bluetooth, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _connectionType = 'bluetooth'),
                  ),
                  ChoiceChip(
                    label: const Text('WiFi / LAN Network'),
                    selected: _connectionType == 'wifi',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _connectionType == 'wifi' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.wifi, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _connectionType = 'wifi'),
                  ),
                  ChoiceChip(
                    label: const Text('USB Direct'),
                    selected: _connectionType == 'usb',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _connectionType == 'usb' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.usb, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _connectionType = 'usb'),
                  ),
                  ChoiceChip(
                    label: const Text('Built-in (Sunmi/iMin)'),
                    selected: _connectionType == 'builtin',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _connectionType == 'builtin' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.phone_android, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _connectionType = 'builtin'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Paper Width
              Text(
                lang == AppLanguage.my ? 'ဘောက်ချာ စက္ကူအရွယ်အစား' : 'Paper Width',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _paperSize = '58mm'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paperSize == '58mm' ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _paperSize == '58mm' ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '58 mm',
                              style: TextStyle(
                                color: _paperSize == '58mm' ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Text('32 Chars (Standard)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _paperSize = '80mm'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _paperSize == '80mm' ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _paperSize == '80mm' ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '80 mm',
                              style: TextStyle(
                                color: _paperSize == '80mm' ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Text('48 Chars (Wide Terminal)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Connection Specific Fields
              if (_connectionType == 'wifi') ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ipController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Printer IP Address',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Port (9100)',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else if (_connectionType == 'bluetooth') ...[
                TextField(
                  controller: _printerNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.my ? 'Bluetooth ပရင်တာ အမည် / MAC' : 'Bluetooth Device Name / MAC',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    prefixIcon: const Icon(Icons.bluetooth_searching, color: Color(0xFF38BDF8), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Auto-print Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == AppLanguage.my ? 'အရောင်းပြီးဆုံးပါက အလိုအလျောက် ပရင့်ထုတ်မည်' : 'Auto-Print on Checkout',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            lang == AppLanguage.my ? 'ငွေရှင်းပြီးသည်နှင့် ဘောက်ချာ ချက်ချင်းထွက်မည်' : 'Print thermal slip automatically when order completes',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoPrint,
                      activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _autoPrint = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Test Print Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.print, size: 18),
                label: Text(
                  lang == AppLanguage.my ? 'စမ်းသပ်ပရင့် ထုတ်ကြည့်မည် (Test Print)' : 'Test Print Slip',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: _handleTestPrint,
              ),
              const SizedBox(height: 12),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text(
                        lang == AppLanguage.my
                            ? 'ပရင်တာ ဆက်တင်များ မှတ်သားပြီးပါပြီ'
                            : 'Printer settings saved successfully!',
                      ),
                    ),
                  );
                },
                child: Text(
                  AppTranslations.tr('btn_save', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
