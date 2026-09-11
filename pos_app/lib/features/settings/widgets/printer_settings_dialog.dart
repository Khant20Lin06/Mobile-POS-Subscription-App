import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/hardware/hardware_permission_service.dart';
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
  late String _connectionType;
  late String _paperSize;
  late bool _autoPrint;
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _printerNameController;

  List<Printer> _availablePrinters = [];
  List<BluetoothPrinterDevice> _bluetoothPrinters = [];
  bool _isScanning = false;
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool? _connectionTestSuccess;
  bool _isSendingTestPrint = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(printerConfigProvider);
    _connectionType = config.connectionType;
    _paperSize = config.paperSize;
    _autoPrint = config.autoPrint;
    _ipController = TextEditingController(text: config.ipAddress);
    _portController = TextEditingController(text: config.port.toString());
    _printerNameController = TextEditingController(text: config.selectedPrinterName ?? '');
    _scanPrinters();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _printerNameController.dispose();
    super.dispose();
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isScanning = true;
      _connectionTestResult = null;
      _connectionTestSuccess = null;
    });
    try {
      if (_connectionType == 'bluetooth') {
        final granted = await HardwarePermissionService.requestBluetoothPermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFD97706),
              content: const Text('Bluetooth permission needed to scan for wireless printers.'),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: HardwarePermissionService.openSettings,
              ),
            ),
          );
        }
        final btList = await BluetoothThermalPrinterService.listPairedPrinters();
        if (mounted) {
          setState(() {
            _bluetoothPrinters = btList;
            if (_printerNameController.text.trim().isEmpty && btList.isNotEmpty) {
              _printerNameController.text = btList.first.address;
            }
          });
        }
      } else {
        final list = await SystemThermalPrinterService.listPrinters();
        if (mounted) {
          setState(() {
            _availablePrinters = list;
            if (_printerNameController.text.trim().isEmpty && list.isNotEmpty) {
              final defaultPrinter = list.where((p) => p.isDefault).firstOrNull ?? list.first;
              _printerNameController.text = defaultPrinter.name;
            }
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _testWifiConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
      _connectionTestSuccess = null;
    });

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;
    final result = await NetworkThermalPrinterService.testConnection(ip, port);

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestSuccess = result.success;
        _connectionTestResult = result.message;
      });
    }
  }

  Future<void> _testBluetoothConnection() async {
    final addr = _printerNameController.text.trim();
    if (addr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Please select or enter a paired Bluetooth printer first!'),
        ),
      );
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
      _connectionTestSuccess = null;
    });

    final result = await BluetoothThermalPrinterService.testConnection(addr);

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestSuccess = result.success;
        _connectionTestResult = result.message;
      });
    }
  }

  PrinterConfig _buildCurrentConfig() {
    return PrinterConfig(
      connectionType: _connectionType,
      paperSize: _paperSize,
      ipAddress: _ipController.text.trim().isEmpty ? '192.168.1.100' : _ipController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 9100,
      selectedPrinterName: _printerNameController.text.trim().isNotEmpty
          ? _printerNameController.text.trim()
          : null,
      autoPrint: _autoPrint,
    );
  }

  ReceiptData _generateTestReceipt() {
    final shop = ref.read(currentShopProvider).value;
    final shopName = shop?.name ?? 'DOT POS Store';
    final now = DateTime.now();

    return ReceiptData(
      shopName: shopName,
      shopAddress: shop?.address ?? 'No. 123, Bogyoke Road, Yangon',
      shopPhone: shop?.phone ?? '09-770001122',
      currency: shop?.currency ?? 'MMK',
      orderNumber: 'TEST-001',
      orderDate: now,
      cashierName: 'Admin',
      customerName: 'HARDWARE TEST',
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
      notes: 'Thermal Printer Hardware Connected OK!',
    );
  }

  Future<void> _handleDirectTestPrint() async {
    if (_isSendingTestPrint) return;

    setState(() => _isSendingTestPrint = true);
    final currentConfig = _buildCurrentConfig();

    // Temporarily persist config so printer service picks up current settings
    await ref.read(printerConfigProvider.notifier).updateConfig(currentConfig);

    try {
      final receipt = _generateTestReceipt();
      final result = await ref.read(printerServiceProvider).printReceipt(receipt);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          content: Row(
            children: [
              Icon(result.success ? Icons.check_circle : Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Test Print Failed: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTestPrint = false);
      }
    }
  }

  void _handlePreviewTestSlip() {
    final receipt = _generateTestReceipt();
    ReceiptDialog.show(
      context,
      receipt: receipt,
      title: 'Printer Test Slip (${_paperSize.toUpperCase()})',
      orderNumber: 'TEST-001',
    );
  }

  Future<void> _handleSave() async {
    final config = _buildCurrentConfig();
    await ref.read(printerConfigProvider.notifier).updateConfig(config);

    if (!mounted) return;
    Navigator.pop(context);
    final lang = ref.read(appLanguageProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text(
          lang == AppLanguage.my
              ? 'ပရင်တာ ဆက်တင်များ အောင်မြင်စွာ မှတ်သားပြီးပါပြီ'
              : 'Printer settings saved successfully!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
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
                      lang == AppLanguage.my ? 'ပရင်တာ ချိတ်ဆက်မှု ဆက်တင်' : 'Thermal Printer Hardware Setup',
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
                    onSelected: (_) async {
                      setState(() => _connectionType = 'bluetooth');
                      await HardwarePermissionService.requestBluetoothPermissions();
                      _scanPrinters();
                    },
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
                            const Text('32 Chars (Standard Roll)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
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

              // Interface-specific Configuration Area
              if (_connectionType == 'wifi') ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ipController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Printer IP Address',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          hintText: '192.168.1.100',
                          hintStyle: const TextStyle(color: Color(0xFF475569)),
                          prefixIcon: const Icon(Icons.lan, color: Color(0xFF38BDF8), size: 18),
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
                          labelText: 'Port',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          hintText: '9100',
                          hintStyle: const TextStyle(color: Color(0xFF475569)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ping WiFi Printer Button & Status
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isTestingConnection
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                            )
                          : const Icon(Icons.network_check, size: 16),
                      label: Text(
                        _isTestingConnection ? 'Testing...' : 'Test WiFi Ping',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isTestingConnection ? null : _testWifiConnection,
                    ),
                  ],
                ),
                if (_connectionTestResult != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connectionTestSuccess == true ? Icons.check_circle : Icons.error_outline,
                          size: 16,
                          color: _connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionTestResult!,
                            style: TextStyle(
                              color: _connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFF87171),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ] else ...[
                // System / Bluetooth / USB / Built-in Device Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _connectionType == 'bluetooth'
                          ? (lang == AppLanguage.my ? 'ချိတ်ဆက်ထားသော Bluetooth စက်များ' : 'Paired Bluetooth Printers')
                          : (lang == AppLanguage.my ? 'တွေ့ရှိထားသော စက်ကိရိယာများ' : 'Detected Hardware Devices'),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: _isScanning
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                          : const Icon(Icons.refresh, size: 14),
                      label: Text(_isScanning ? 'Scanning...' : 'Rescan', style: const TextStyle(fontSize: 11)),
                      onPressed: _isScanning ? null : _scanPrinters,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (_connectionType == 'bluetooth') ...[
                  if (_bluetoothPrinters.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F172A),
                          value: _bluetoothPrinters.any((p) => p.address == _printerNameController.text || p.name == _printerNameController.text)
                              ? _printerNameController.text
                              : _bluetoothPrinters.first.address,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                          items: _bluetoothPrinters.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.address,
                              child: Row(
                                children: [
                                  const Icon(Icons.bluetooth, size: 16, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p.name} (${p.address})',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _printerNameController.text = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Test Bluetooth Connection Button
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                                )
                              : const Icon(Icons.bluetooth_searching, size: 16),
                          label: Text(
                            _isTestingConnection ? 'Connecting...' : 'Test Connection',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isTestingConnection ? null : _testBluetoothConnection,
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lang == AppLanguage.my
                                      ? 'Bluetooth ပရင်တာ မတွေ့ရှိသေးပါ'
                                      : 'No Paired Bluetooth Printers Found',
                                  style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lang == AppLanguage.my
                                ? 'ဖုန်း၏ Settings > Bluetooth သို့ သွားရောက်ပြီး ပရင်တာကို အရင် Pair လုပ်ပေးပါ (Password ပုံမှန်အားဖြင့် 0000 သို့မဟုတ် 1234 ဖြစ်ပါသည်)။'
                                : 'Please pair your Bluetooth thermal printer in Android Settings > Bluetooth first (PIN usually 0000 or 1234).',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.settings_bluetooth, size: 14, color: Colors.white),
                            label: Text(
                              lang == AppLanguage.my ? 'Bluetooth Settings ဖွင့်ရန်' : 'Open Bluetooth Settings',
                              style: const TextStyle(fontSize: 11, color: Colors.white),
                            ),
                            onPressed: HardwarePermissionService.openSettings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  if (_availablePrinters.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F172A),
                          value: _availablePrinters.any((p) => p.name == _printerNameController.text)
                              ? _printerNameController.text
                              : _availablePrinters.first.name,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                          items: _availablePrinters.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.name,
                              child: Row(
                                children: [
                                  Icon(
                                    p.isDefault ? Icons.star : Icons.print,
                                    size: 16,
                                    color: p.isDefault ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p.name} ${p.isDefault ? "(Default)" : ""}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _printerNameController.text = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _connectionType == 'builtin'
                                      ? 'Sunmi & iMin built-in thermal printers will print directly via native spooler.'
                                      : 'Please connect your USB printer via USB cable or OTG adapter.',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                if (_connectionTestResult != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connectionTestSuccess == true ? Icons.check_circle : Icons.error_outline,
                          size: 16,
                          color: _connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionTestResult!,
                            style: TextStyle(
                              color: _connectionTestSuccess == true ? const Color(0xFF10B981) : const Color(0xFFF87171),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                TextField(
                  controller: _printerNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: _connectionType == 'bluetooth'
                        ? (lang == AppLanguage.my ? 'Bluetooth လိပ်စာ / MAC Address' : 'Printer Bluetooth Address (e.g. 66:22:33:44:55:66)')
                        : (lang == AppLanguage.my ? 'ပရင်တာ အမည် / Device Name' : 'Target Printer Name (or leave blank for default)'),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    prefixIcon: Icon(_connectionType == 'bluetooth' ? Icons.bluetooth : Icons.devices, color: const Color(0xFF38BDF8), size: 18),
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

              // Test Print Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.preview, size: 16),
                      label: const Text('Preview Slip', style: TextStyle(fontSize: 12)),
                      onPressed: _handlePreviewTestSlip,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSendingTestPrint
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.print, size: 16),
                      label: Text(
                        _isSendingTestPrint
                            ? 'Printing...'
                            : (lang == AppLanguage.my ? 'စမ်းသပ်ပရင့် ထုတ်မည်' : 'Send Test Print'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: _isSendingTestPrint ? null : _handleDirectTestPrint,
                    ),
                  ),
                ],
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
                onPressed: _handleSave,
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
