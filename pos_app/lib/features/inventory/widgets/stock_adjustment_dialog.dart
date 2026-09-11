import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

enum StockAdjustmentType {
  stockIn,
  stockOut,
  setExact,
}

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final Product product;

  const StockAdjustmentDialog({super.key, required this.product});

  static Future<bool?> show(BuildContext context, Product product) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StockAdjustmentDialog(product: product),
    );
  }

  @override
  ConsumerState<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  StockAdjustmentType _type = StockAdjustmentType.stockIn;
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _parsedQty => int.tryParse(_quantityController.text.trim()) ?? 0;

  int get _calculatedNewStock {
    switch (_type) {
      case StockAdjustmentType.stockIn:
        return widget.product.stockQuantity + _parsedQty;
      case StockAdjustmentType.stockOut:
        return (widget.product.stockQuantity - _parsedQty).clamp(0, 999999);
      case StockAdjustmentType.setExact:
        return _parsedQty.clamp(0, 999999);
    }
  }

  void _addQuickQuantity(int amount) {
    final current = _parsedQty;
    final next = (current + amount).clamp(1, 99999);
    setState(() {
      _quantityController.text = next.toString();
    });
  }

  Future<void> _applyAdjustment() async {
    final qty = _parsedQty;
    if (qty <= 0 && _type != StockAdjustmentType.setExact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please enter a valid quantity greater than 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final productDao = ref.read(productDaoProvider);

      if (_type == StockAdjustmentType.stockIn) {
        await productDao.adjustStock(widget.product.id, qty);
      } else if (_type == StockAdjustmentType.stockOut) {
        await productDao.adjustStock(widget.product.id, -qty);
      } else {
        await productDao.setExactStock(widget.product.id, qty);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Stock for "${widget.product.name}" updated to $_calculatedNewStock units.'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Failed to adjust stock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _type == StockAdjustmentType.stockIn
        ? const Color(0xFF10B981) // Green
        : _type == StockAdjustmentType.stockOut
            ? const Color(0xFFEF4444) // Red
            : const Color(0xFF3B82F6); // Blue

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _type == StockAdjustmentType.stockIn
                  ? Icons.add_box_outlined
                  : _type == StockAdjustmentType.stockOut
                      ? Icons.indeterminate_check_box_outlined
                      : Icons.edit_note,
              color: themeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stock Movement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  widget.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Stock Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current On-Hand Stock:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    Text(
                      '${widget.product.stockQuantity} units',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Type Selector Segmented
              const Text('Movement Type', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      type: StockAdjustmentType.stockIn,
                      label: 'Stock In (+)',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeButton(
                      type: StockAdjustmentType.stockOut,
                      label: 'Damage (-)',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeButton(
                      type: StockAdjustmentType.setExact,
                      label: 'Set Exact (=)',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity Input
              Text(
                _type == StockAdjustmentType.setExact ? 'New Exact Quantity *' : 'Adjustment Quantity *',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: () {
                      final curr = _parsedQty;
                      if (curr > 1) {
                        setState(() => _quantityController.text = (curr - 1).toString());
                      }
                    },
                    icon: const Icon(Icons.remove, size: 18),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final curr = _parsedQty;
                      setState(() => _quantityController.text = (curr + 1).toString());
                    },
                    icon: const Icon(Icons.add, size: 18),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick Increments
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickPill('+5', 5),
                  const SizedBox(width: 8),
                  _buildQuickPill('+10', 10),
                  const SizedBox(width: 8),
                  _buildQuickPill('+25', 25),
                  const SizedBox(width: 8),
                  _buildQuickPill('+50', 50),
                ],
              ),
              const SizedBox(height: 16),

              // Reason / Note
              const Text('Reason / Reference Note (Optional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Supplier PO #901, Broken bottle, Stock count audit',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                ),
              ),
              const SizedBox(height: 16),

              // Resulting Stock Preview Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: themeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resulting Stock on Hand:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    Text(
                      '$_calculatedNewStock units',
                      style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _applyAdjustment,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: Text(_isSaving ? 'Applying...' : 'Apply Movement'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required StockAdjustmentType type,
    required String label,
    required Color color,
  }) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () => setState(() => _type = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPill(String label, int amount) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      backgroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF334155)),
      onPressed: () => _addQuickQuantity(amount),
    );
  }
}
