import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/hardware/thermal_receipt_service.dart';

class ReceiptDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final formattedText = receiptText ??
        (receipt != null ? ThermalReceiptFormatter.format58mm(receipt!) : '');
    final displayTitle = title ?? (receipt != null ? 'Order Completed!' : 'Receipt Preview');
    final slipRef = orderNumber ?? receipt?.orderNumber ?? 'Slip';
    final screenHeight = MediaQuery.of(context).size.height;

    final is80mm = formattedText.contains('=' * 40);
    final paperWidth = is80mm ? 370.0 : 260.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
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
              child: Row(
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
                      width: paperWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Warm thermal paper tint
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SelectableText(
                        formattedText.trim(),
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
                      icon: const Icon(Icons.print, size: 17),
                      label: const Text('Print Slip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Row(
                              children: [
                                const Icon(Icons.print, color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Printed $slipRef to Thermal Printer!')),
                              ],
                            ),
                          ),
                        );
                        Navigator.pop(context);
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
}
