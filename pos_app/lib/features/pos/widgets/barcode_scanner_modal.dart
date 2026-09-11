import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/hardware/barcode_scan_service.dart';
import '../providers/cart_provider.dart';

/// Interactive Barcode Scanner Modal supporting Camera Scanner and Hardware Scan Gun
class BarcodeScannerModal extends ConsumerStatefulWidget {
  const BarcodeScannerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const BarcodeScannerModal(),
    );
  }

  @override
  ConsumerState<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends ConsumerState<BarcodeScannerModal> {
  final TextEditingController _manualInputController = TextEditingController();
  final FocusNode _manualInputFocus = FocusNode();
  late BarcodeScanGunListener _scanGunListener;

  MobileScannerController? _cameraController;
  bool _torchEnabled = false;
  bool _isProcessingScan = false;
  String? _errorMessage;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();

    if (_isMobile) {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }

    _scanGunListener = BarcodeScanGunListener();
    _scanGunListener.start(_handleBarcodeDetected);
  }

  @override
  void dispose() {
    _scanGunListener.stop();
    _cameraController?.dispose();
    _manualInputController.dispose();
    _manualInputFocus.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    final barcode = rawCode.trim();
    if (barcode.isEmpty || _isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
      _errorMessage = null;
    });

    try {
      final productDao = ref.read(productDaoProvider);
      final product = await productDao.getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        BarcodeScanGunListener.playSuccessBeep();
        ref.read(cartProvider.notifier).addToCart(product);

        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang == AppLanguage.my
                        ? 'Cart ထဲသို့ "${product.name}" ထည့်သွင်းပြီးပါပြီ'
                        : 'Added "${product.name}" to cart (${product.sellingPrice.toStringAsFixed(0)} MMK)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Auto close scanner on successful match
        Navigator.pop(context);
      } else {
        BarcodeScanGunListener.playErrorBeep();
        final lang = ref.read(appLanguageProvider);
        setState(() {
          _errorMessage = lang == AppLanguage.my
              ? 'ဘားကုဒ် "$barcode" နှင့် ကိုက်ညီသော ပစ္စည်းမရှိပါ'
              : 'No product found with barcode "$barcode"';
          _isProcessingScan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Scan error: $e';
          _isProcessingScan = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        padding: const EdgeInsets.all(20),
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
                  child: const Icon(Icons.qr_code_scanner, color: Color(0xFF38BDF8), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == AppLanguage.my ? 'ဘားကုဒ် စကန်ဖတ်ရန်' : 'Scan Barcode',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        lang == AppLanguage.my ? 'Camera သို့မဟုတ် Scanner Gun ဖြင့် ဖတ်ပါ' : 'Camera or Hardware Scan Gun',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera Viewfinder or Desktop Scanner Graphic
            if (_isMobile && _cameraController != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 240,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _cameraController!,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final b in barcodes) {
                            final val = b.rawValue;
                            if (val != null && val.isNotEmpty) {
                              _handleBarcodeDetected(val);
                              break;
                            }
                          }
                        },
                      ),
                      // Viewfinder Overlay Box
                      Container(
                        width: 220,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Camera Controls (Flash & Flip)
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _torchEnabled ? Icons.flash_on : Icons.flash_off,
                                  color: _torchEnabled ? const Color(0xFFF59E0B) : Colors.white,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  await _cameraController?.toggleTorch();
                                  setState(() => _torchEnabled = !_torchEnabled);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 18),
                                onPressed: () async {
                                  await _cameraController?.switchCamera();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Desktop or Non-mobile Placeholder
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sensors, color: Color(0xFF38BDF8), size: 40),
                      const SizedBox(height: 8),
                      Text(
                        lang == AppLanguage.my
                            ? 'စကန်ဖတ်စက်မှ အချက်ပြ စောင့်ဆိုင်းနေပါသည်'
                            : 'Listening for Hardware Scan Gun',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang == AppLanguage.my
                            ? 'ဘားကုဒ် ဖတ်လိုက်ပါက ပစ္စည်းအလိုအလျောက် ဝင်ပါမည်'
                            : 'Trigger scanner or enter barcode below',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Error or Status Alert
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Manual Barcode Input Fallback
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualInputController,
                    focusNode: _manualInputFocus,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: lang == AppLanguage.my ? 'ဘားကုဒ် ရိုက်ထည့်ရန် (Manual Enter)...' : 'Type barcode number...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      prefixIcon: const Icon(Icons.keyboard, color: Color(0xFF94A3B8), size: 16),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (val) {
                      _handleBarcodeDetected(val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _handleBarcodeDetected(_manualInputController.text);
                  },
                  child: Text(
                    lang == AppLanguage.my ? 'ထည့်မည်' : 'Enter',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
