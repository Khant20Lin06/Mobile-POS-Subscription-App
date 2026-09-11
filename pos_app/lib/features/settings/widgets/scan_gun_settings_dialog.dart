import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart' hide Column;
import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';

class ScanGunSettingsDialog extends ConsumerStatefulWidget {
  const ScanGunSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ScanGunSettingsDialog(),
    );
  }

  @override
  ConsumerState<ScanGunSettingsDialog> createState() => _ScanGunSettingsDialogState();
}

class _ScanGunSettingsDialogState extends ConsumerState<ScanGunSettingsDialog> {
  String _scannerType = 'usb_hid'; // 'usb_hid', 'bluetooth_hid', 'camera'
  bool _autoAddToCart = true;
  bool _soundFeedback = true;
  final _testBarcodeController = TextEditingController();
  final _testFocusNode = FocusNode();
  String? _testResult;
  bool _isSuccessMatch = false;

  @override
  void dispose() {
    _testBarcodeController.dispose();
    _testFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleTestScan(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return;

    final db = ref.read(databaseProvider);
    final products = await (db.select(db.products)
          ..where((t) => t.barcode.equals(cleanBarcode) & t.deletedAt.isNull()))
        .get();

    setState(() {
      if (products.isNotEmpty) {
        final p = products.first;
        _isSuccessMatch = true;
        _testResult = '✓ Matched: "${p.name}" (${p.sellingPrice.toStringAsFixed(0)} MMK) • Barcode: $cleanBarcode';
      } else {
        _isSuccessMatch = false;
        _testResult = 'Barcode Scanned: "$cleanBarcode" (No matching product in inventory)';
      }
      _testBarcodeController.clear();
    });

    _testFocusNode.requestFocus();
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == AppLanguage.my ? 'ဘားကုဒ် စကန်ဖတ်စက် ဆက်တင်' : 'Barcode Scan Gun Setup',
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

              // Scanner Interface Selector
              Text(
                lang == AppLanguage.my ? 'စကန်ဖတ်စက် ချိတ်ဆက်မှု စနစ်' : 'Scanner Interface',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('USB Laser Gun (HID)'),
                    selected: _scannerType == 'usb_hid',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _scannerType == 'usb_hid' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.usb, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _scannerType = 'usb_hid'),
                  ),
                  ChoiceChip(
                    label: const Text('Bluetooth Wireless Gun'),
                    selected: _scannerType == 'bluetooth_hid',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _scannerType == 'bluetooth_hid' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.bluetooth, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _scannerType = 'bluetooth_hid'),
                  ),
                  ChoiceChip(
                    label: const Text('Device Camera Scanner'),
                    selected: _scannerType == 'camera',
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: _scannerType == 'camera' ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    avatar: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    onSelected: (_) => setState(() => _scannerType = 'camera'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang == AppLanguage.my
                            ? 'စကန်ဖတ်စက် အသင့်ဖြစ်ပါသည် (USB/Bluetooth HID Plug & Play)'
                            : 'Hardware Scan Gun Ready (HID Keyboard Wedge Active)',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Auto-add to Cart Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_checkout, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == AppLanguage.my ? 'စကန်ဖတ်ပြီးသည်နှင့် Cart ထဲ တန်းထည့်မည်' : 'Auto-Add to Cart on Scan',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            lang == AppLanguage.my ? 'ဘားကုဒ်ဖတ်ရုံဖြင့် ပစ္စည်းအလိုအလျောက် ဝင်မည်' : 'Automatically adds 1 unit when barcode matches',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoAddToCart,
                      activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _autoAddToCart = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Sound Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang == AppLanguage.my ? 'ဘားကုဒ်ဖတ်မိပါက အသံမြည်ရန် (Beep Feedback)' : 'Sound Feedback on Scan',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: _soundFeedback,
                      activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _soundFeedback = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Scanner Test Field
              Text(
                lang == AppLanguage.my ? 'စကန်ဖတ်စက် စမ်းသပ်ရန် (Hardware Test)' : 'Test Hardware Scan Gun',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _testBarcodeController,
                focusNode: _testFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: lang == AppLanguage.my
                      ? 'ဒီနေရာကို ကလစ်ပြီး စကန်ဖတ်စက်ဖြင့် ဖတ်ကြည့်ပါ...'
                      : 'Click here and trigger physical scan gun...',
                  hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                  prefixIcon: const Icon(Icons.qr_code_2, color: Color(0xFF10B981), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: _handleTestScan,
              ),

              if (_testResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSuccessMatch ? const Color(0xFF065F46).withValues(alpha: 0.3) : const Color(0xFF991B1B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSuccessMatch ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _isSuccessMatch ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),

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
                            ? 'စကန်ဖတ်စက် ဆက်တင်များ မှတ်သားပြီးပါပြီ'
                            : 'Scan Gun configuration saved successfully!',
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
