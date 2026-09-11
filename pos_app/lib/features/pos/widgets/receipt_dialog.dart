import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/hardware/thermal_receipt_service.dart';

class ReceiptDialog extends ConsumerStatefulWidget {
  final ReceiptData? receipt;
  final String? receiptText;
  final String? title;
  final String? orderNumber;

  const ReceiptDialog({
    super.key,
    this.receipt,
    this.receiptText,
    this.title,
    this.orderNumber,
  });

  /// Static helper to quickly display receipt dialog from anywhere
  static Future<void> show(
    BuildContext context, {
    ReceiptData? receipt,
    String? receiptText,
    String? title,
    String? orderNumber,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(
        receipt: receipt,
        receiptText: receiptText,
        title: title,
        orderNumber: orderNumber,
      ),
    );
  }

  @override
  ConsumerState<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<ReceiptDialog> {
  bool _isPrinting = false;

  Future<void> _handlePrint(String formattedText, String slipRef) async {
    if (_isPrinting) return;

    setState(() => _isPrinting = true);
    try {
      final printerService = ref.read(printerServiceProvider);
      PrintResult result;

      if (widget.receipt != null) {
        result = await printerService.printReceipt(widget.receipt!);
      } else {
        result = await printerService.printRawText(formattedText, jobName: 'Slip_$slipRef');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: result.success ? 3 : 5),
        ),
      );

      if (result.success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Print Failed: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerConfig = ref.watch(printerConfigProvider);
    final formattedText = widget.receiptText ??
        (widget.receipt != null ? ThermalReceiptFormatter.format58mm(widget.receipt!) : '');
    final displayTitle = widget.title ?? (widget.receipt != null ? 'Order Completed!' : 'Receipt Preview');
    final slipRef = widget.orderNumber ?? widget.receipt?.orderNumber ?? 'Slip';
    final screenHeight = MediaQuery.of(context).size.height;

    // Printer connection badge string
    String connectionInfo;
    IconData connectionIcon;
    switch (printerConfig.connectionType) {
      case 'wifi':
        connectionInfo = 'WiFi (${printerConfig.ipAddress}:${printerConfig.port})';
        connectionIcon = Icons.wifi;
        break;
      case 'builtin':
        connectionInfo = 'Built-in (Sunmi/iMin)';
        connectionIcon = Icons.phone_android;
        break;
      case 'usb':
        connectionInfo = 'USB Direct';
        connectionIcon = Icons.usb;
        break;
      default:
        connectionInfo = printerConfig.selectedPrinterName ?? 'Bluetooth ESC/POS';
        connectionIcon = Icons.bluetooth;
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  // Printer Route Indicator Badge
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(connectionIcon, size: 12, color: const Color(0xFF38BDF8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Target: $connectionInfo • ${printerConfig.paperSize.toUpperCase()}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Realistic Thermal Paper Slip Container (Fitted & Responsive)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Warm thermal paper tint
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SelectableText(
                        _sanitizeReceiptText(formattedText),
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: ['Courier', 'Consolas', 'Courier New'],
                          fontSize: 11.5,
                          height: 1.35,
                          letterSpacing: 0.1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B), // Dark thermal ink color
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('Copy', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: formattedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receipt copied to clipboard!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print, size: 17),
                      label: Text(
                        _isPrinting ? 'Printing...' : 'Print Slip',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: _isPrinting ? null : () => _handlePrint(formattedText, slipRef),
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

  String _sanitizeReceiptText(String text) {
    final lines = text.split('\n');
    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    return lines.map((l) => l.trimRight()).join('\n');
  }
}
