import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../../core/hardware/thermal_receipt_service.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';
import '../../pos/widgets/receipt_dialog.dart';
import '../../subscription/widgets/plan_showcase_dialog.dart';

class InvoiceDetailDialog extends ConsumerStatefulWidget {
  final Order order;
  final String? customerName;

  const InvoiceDetailDialog({
    super.key,
    required this.order,
    this.customerName,
  });

  static Future<void> show(
    BuildContext context, {
    required Order order,
    String? customerName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InvoiceDetailDialog(
        order: order,
        customerName: customerName,
      ),
    );
  }

  @override
  ConsumerState<InvoiceDetailDialog> createState() => _InvoiceDetailDialogState();
}

class _InvoiceDetailDialogState extends ConsumerState<InvoiceDetailDialog> {
  final _currencyFormat = NumberFormat('#,##0', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  bool _isGeneratingPdf = false;

  ReceiptData _buildReceiptData({
    required Shop? shop,
    required String cashierName,
    required List<OrderItem> items,
    required String resolvedCustomerName,
  }) {
    return ReceiptData(
      shopName: shop?.name ?? 'My POS Store',
      shopPhone: shop?.phone,
      shopAddress: shop?.address,
      currency: shop?.currency ?? 'MMK',
      orderNumber: widget.order.orderNumber,
      orderDate: widget.order.createdAt.toLocal(),
      cashierName: cashierName,
      customerName: resolvedCustomerName.isNotEmpty ? resolvedCustomerName : null,
      items: items.map((item) {
        return ReceiptLineItem(
          name: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          subtotal: item.subtotal,
        );
      }).toList(),
      subtotal: widget.order.subtotal,
      discount: widget.order.discountAmount,
      tax: widget.order.taxAmount,
      totalAmount: widget.order.totalAmount,
      tenderAmount: widget.order.totalAmount,
      changeDue: 0.0,
      paymentMethod: widget.order.paymentMethod,
      notes: widget.order.notes,
    );
  }

  void _handlePrintReceipt(
    BuildContext context, {
    required Shop? shop,
    required String cashierName,
    required List<OrderItem> items,
    required String resolvedCustomerName,
  }) {
    final receipt = _buildReceiptData(
      shop: shop,
      cashierName: cashierName,
      items: items,
      resolvedCustomerName: resolvedCustomerName,
    );

    ReceiptDialog.show(context, receipt: receipt);
  }

  Future<void> _handlePdfExport({
    required Shop? shop,
    required String cashierName,
    required List<OrderItem> items,
    required String resolvedCustomerName,
    required bool isPro,
  }) async {
    final lang = ref.read(appLanguageProvider);

    if (!isPro) {
      if (!mounted) return;
      // Show PRO upgrade showcase dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == AppLanguage.my ? 'PRO အင်္ဂါရပ်ဖြစ်ပါသည်' : 'PRO Feature Locked',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            AppTranslations.tr('invoice_pdf_pro_notice', lang),
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.tr('btn_cancel', lang),
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.stars, size: 16),
              label: Text(
                lang == AppLanguage.my ? 'PRO စနစ် ကြည့်ရန်' : 'Upgrade to PRO',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                PlanShowcaseDialog.show(context);
              },
            ),
          ],
        ),
      );
      return;
    }

    // Generate & share PDF
    setState(() => _isGeneratingPdf = true);
    try {
      final doc = pw.Document();
      final currency = shop?.currency ?? 'MMK';

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pwContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shop?.name ?? 'DOT POS STORE',
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                        ),
                        if (shop?.address != null && shop!.address!.isNotEmpty)
                          pw.Text(shop.address!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        if (shop?.phone != null && shop!.phone!.isNotEmpty)
                          pw.Text('Tel: ${shop.phone!}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('SALE INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.Text(widget.order.orderNumber, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ${_dateFormat.format(widget.order.createdAt.toLocal())}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),

                // Customer & Payment Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text(resolvedCustomerName.isNotEmpty ? resolvedCustomerName : 'Walk-in Customer', style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Payment Method: ${widget.order.paymentMethod}', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Cashier: $cashierName', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Status: ${widget.order.status}', style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Items Table
                pw.TableHelper.fromTextArray(
                  headers: ['#', 'Item Description', 'Qty', 'Unit Price ($currency)', 'Total ($currency)'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  data: List<List<dynamic>>.generate(items.length, (index) {
                    final item = items[index];
                    return [
                      (index + 1).toString(),
                      item.productName,
                      item.quantity.toString(),
                      _currencyFormat.format(item.unitPrice),
                      _currencyFormat.format(item.subtotal),
                    ];
                  }),
                ),
                pw.SizedBox(height: 16),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 200,
                      child: pw.Column(
                        children: [
                          _buildPdfRow('Subtotal:', '${_currencyFormat.format(widget.order.subtotal)} $currency'),
                          if (widget.order.discountAmount > 0)
                            _buildPdfRow('Discount:', '-${_currencyFormat.format(widget.order.discountAmount)} $currency'),
                          if (widget.order.taxAmount > 0)
                            _buildPdfRow('Tax:', '+${_currencyFormat.format(widget.order.taxAmount)} $currency'),
                          pw.Divider(thickness: 1),
                          _buildPdfRow('Grand Total:', '${_currencyFormat.format(widget.order.totalAmount)} $currency', isBold: true),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.Center(
                  child: pw.Text('Thank you for your business! • Generated by DOT POS', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'Invoice_${widget.order.orderNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _buildPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final orderDao = ref.watch(orderDaoProvider);
    final shop = ref.watch(currentShopProvider).value;
    final isPro = shop?.planTier == 'pro' || shop?.planTier == 'custom';

    final order = widget.order;
    final currency = shop?.currency ?? 'MMK';
    final resolvedCustomerName = widget.customerName ??
        (order.customerId != null ? 'Customer #${order.customerId!.substring(0, 6)}' : AppTranslations.tr('invoice_walk_in', lang));

    final isCredit = order.paymentMethod == 'CREDIT';
    final isCompleted = order.status == 'COMPLETED';

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_outlined, color: Color(0xFF60A5FA), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                order.orderNumber,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: order.orderNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invoice number copied!'), duration: Duration(seconds: 1)),
                                );
                              },
                              child: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _dateFormat.format(order.createdAt.toLocal()),
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
            ),

            // Main Body: Order details + Line items
            Expanded(
              child: FutureBuilder<List<OrderItem>>(
                future: orderDao.getItemsForOrder(order.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading items: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                    );
                  }

                  final items = snapshot.data ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer & Badges Row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      resolvedCustomerName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(
                                        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Payment method badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCredit
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                          : const Color(0xFF0284C7).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCredit ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                                      ),
                                    ),
                                    child: Text(
                                      order.paymentMethod,
                                      style: TextStyle(
                                        color: isCredit ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.notes != null && order.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Note: ${order.notes!}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Line items section header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${AppTranslations.tr('invoice_items', lang)} (${items.length})',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Qty × Price',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Line items list
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.quantity} × ${_currencyFormat.format(item.unitPrice)} $currency',
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${_currencyFormat.format(item.subtotal)} $currency',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Financial totals breakdown
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('Subtotal', '${_currencyFormat.format(order.subtotal)} $currency'),
                              if (order.discountAmount > 0) ...[
                                const SizedBox(height: 6),
                                _buildSummaryRow('Discount', '-${_currencyFormat.format(order.discountAmount)} $currency', color: const Color(0xFFEF4444)),
                              ],
                              if (order.taxAmount > 0) ...[
                                const SizedBox(height: 6),
                                _buildSummaryRow('Tax', '+${_currencyFormat.format(order.taxAmount)} $currency', color: const Color(0xFFF59E0B)),
                              ],
                              const Divider(color: Color(0xFF334155), height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Grand Total',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    '${_currencyFormat.format(order.totalAmount)} $currency',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFF334155))),
              ),
              child: FutureBuilder<List<OrderItem>>(
                future: orderDao.getItemsForOrder(order.id),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  final isReady = items.isNotEmpty;

                  return Row(
                    children: [
                      // PDF Export Button (PRO Feature)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isPro ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                            side: BorderSide(
                              color: isPro ? const Color(0xFF0284C7) : const Color(0xFFF59E0B).withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                                )
                              : Icon(isPro ? Icons.picture_as_pdf : Icons.lock, size: 16),
                          label: Text(
                            isPro ? 'PDF' : 'PDF (PRO)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: (!isReady || _isGeneratingPdf)
                              ? null
                              : () => _handlePdfExport(
                                    shop: shop,
                                    cashierName: 'Cashier',
                                    items: items,
                                    resolvedCustomerName: resolvedCustomerName,
                                    isPro: isPro,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Re-print Thermal Receipt Button (FREE Feature)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.print, size: 18),
                          label: Text(
                            AppTranslations.tr('invoice_reprint', lang),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: !isReady
                              ? null
                              : () => _handlePrintReceipt(
                                    context,
                                    shop: shop,
                                    cashierName: 'Cashier',
                                    items: items,
                                    resolvedCustomerName: resolvedCustomerName,
                                  ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
