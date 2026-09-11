import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/product_image_widget.dart';
import 'category_form_dialog.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? productToEdit;
  final String? initialBarcode;

  const ProductFormDialog({super.key, this.productToEdit, this.initialBarcode});

  static Future<bool?> show(BuildContext context, {Product? productToEdit, String? initialBarcode}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProductFormDialog(productToEdit: productToEdit, initialBarcode: initialBarcode),
    );
  }

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  bool _trackStock = true;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(0) : '0');
    _sellingPriceController = TextEditingController(text: p != null ? p.sellingPrice.toStringAsFixed(0) : '0');
    _stockController = TextEditingController(text: p != null ? p.stockQuantity.toString() : '0');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _selectedCategoryId = p?.categoryId;
    _trackStock = p?.trackStock ?? true;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  double get _costPrice => double.tryParse(_costPriceController.text.trim()) ?? 0.0;
  double get _sellingPrice => double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;

  double get _marginPercent {
    if (_sellingPrice <= 0) return 0.0;
    return ((_sellingPrice - _costPrice) / _sellingPrice) * 100.0;
  }

  void _generateRandomBarcode() {
    final random = Random();
    final prefix = '885'; // Demo country/store prefix
    final suffix = List.generate(9, (_) => random.nextInt(10)).join();
    setState(() {
      _barcodeController.text = '$prefix$suffix';
    });
  }

  Future<void> _addNewCategory() async {
    final newCategory = await CategoryFormDialog.show(context);
    if (newCategory != null && mounted) {
      setState(() {
        _selectedCategoryId = newCategory.id;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = path.extension(picked.path);
      final filename = '${const Uuid().v4()}$ext';
      final localFile = await File(picked.path).copy('${imagesDir.path}/$filename');

      if (mounted) {
        setState(() {
          _imageUrlController.text = localFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Widget _buildPresetChip(String label, String url) {
    return InkWell(
      onTap: () => setState(() => _imageUrlController.text = url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Text(label, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final productDao = ref.read(productDaoProvider);
      final shop = await (db.select(db.shops)..limit(1)).getSingleOrNull();
      final shopId = shop?.id ?? 'default_shop';

      final name = _nameController.text.trim();
      final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();
      final cost = _costPrice;
      final selling = _sellingPrice;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      final now = DateTime.now().toUtc();

      if (_isEditing) {
        final existing = widget.productToEdit!;
        await (db.update(db.products)..where((t) => t.id.equals(existing.id))).write(
          ProductsCompanion(
            name: drift.Value(name),
            categoryId: drift.Value(_selectedCategoryId),
            barcode: drift.Value(barcode),
            costPrice: drift.Value(cost),
            sellingPrice: drift.Value(selling),
            stockQuantity: drift.Value(stock),
            trackStock: drift.Value(_trackStock),
            imageUrl: drift.Value(imageUrl),
            isActive: drift.Value(_isActive),
            updatedAt: drift.Value(now),
            syncStatus: const drift.Value('pending'),
          ),
        );
      } else {
        final newEntry = ProductsCompanion.insert(
          id: const Uuid().v4(),
          shopId: shopId,
          categoryId: drift.Value(_selectedCategoryId),
          name: name,
          barcode: drift.Value(barcode),
          costPrice: drift.Value(cost),
          sellingPrice: selling,
          stockQuantity: drift.Value(stock),
          trackStock: drift.Value(_trackStock),
          imageUrl: drift.Value(imageUrl),
          isActive: drift.Value(_isActive),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
          syncStatus: const drift.Value('pending'),
        );
        await productDao.insertProduct(newEntry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(_isEditing ? 'Product "$name" updated successfully!' : 'Product "$name" created successfully!'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Failed to save product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_isEditing ? Icons.edit : Icons.add_box, color: const Color(0xFF60A5FA), size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            _isEditing ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Selector Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.image_outlined, size: 16, color: Color(0xFF38BDF8)),
                          SizedBox(width: 6),
                          Text('Product Image (ဓာတ်ပုံ)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview Box
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ProductImageWidget(
                                imageUrl: _imageUrlController.text,
                                width: 70,
                                height: 70,
                                borderRadius: BorderRadius.circular(10),
                                fallbackIcon: Icons.add_photo_alternate_outlined,
                              ),
                              if (_imageUrlController.text.isNotEmpty)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _imageUrlController.clear()),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Image Action Buttons & URL input
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF38BDF8),
                                          side: const BorderSide(color: Color(0xFF334155)),
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                        ),
                                        icon: const Icon(Icons.photo_library, size: 14),
                                        label: const Text('Gallery', style: TextStyle(fontSize: 11)),
                                        onPressed: () => _pickImage(ImageSource.gallery),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF10B981),
                                          side: const BorderSide(color: Color(0xFF334155)),
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                        ),
                                        icon: const Icon(Icons.camera_alt, size: 14),
                                        label: const Text('Camera', style: TextStyle(fontSize: 11)),
                                        onPressed: () => _pickImage(ImageSource.camera),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _imageUrlController,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Or paste image URL (https://...)',
                                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: const Color(0xFF1E293B),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Preset Samples
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Presets: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                            _buildPresetChip('Coffee', 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=400&q=80'),
                            const SizedBox(width: 4),
                            _buildPresetChip('Bakery', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&q=80'),
                            const SizedBox(width: 4),
                            _buildPresetChip('Beverage', 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=400&q=80'),
                            const SizedBox(width: 4),
                            _buildPresetChip('Snack', 'https://images.unsplash.com/photo-1621996346565-e3d5d6281290?w=400&q=80'),
                            const SizedBox(width: 4),
                            _buildPresetChip('Food', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Product Name
                const Text('Product Name *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(hint: 'e.g. Myanmar Beer Can, Latte, Fried Rice'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter product name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Category Dropdown with inline "+ New" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Category', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                    InkWell(
                      onTap: _addNewCategory,
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF38BDF8)),
                          SizedBox(width: 4),
                          Text('New Category', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                categoriesAsync.when(
                  data: (categories) {
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedCategoryId,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _buildInputDecoration(hint: 'Select Category'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Category (General)', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                        ...categories.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: c.colorCode != null
                                        ? Color(int.parse('FF${c.colorCode!.replaceAll('#', '')}', radix: 16))
                                        : const Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(c.name, style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => const Text('Error loading categories', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 14),

                // Barcode / SKU with 1-Tap Generator
                const Text('Barcode / SKU (Optional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _buildInputDecoration(
                          hint: 'Scan or Enter Barcode',
                          prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF38BDF8), size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Generate Random Barcode',
                      onPressed: _generateRandomBarcode,
                      icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF60A5FA)),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pricing Row (Cost Price vs Selling Price)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cost Price (ဝယ်စျေး) *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _buildInputDecoration(hint: '0', suffixText: 'MMK'),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (val == null || double.tryParse(val.trim()) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selling Price (ရောင်းစျေး) *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: _buildInputDecoration(hint: '0', suffixText: 'MMK'),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              final p = double.tryParse(val?.trim() ?? '');
                              if (p == null || p < 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Profit & Margin Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Gross Profit: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          Text(
                            '${(_sellingPrice - _costPrice).toStringAsFixed(0)} MMK',
                            style: TextStyle(
                              color: (_sellingPrice >= _costPrice) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _marginPercent >= 20
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : _marginPercent >= 0
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_marginPercent.toStringAsFixed(1)}% Margin',
                          style: TextStyle(
                            color: _marginPercent >= 20
                                ? const Color(0xFF10B981)
                                : _marginPercent >= 0
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Initial / Current Stock & Track Stock
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Current Stock (လက်ကျန်)' : 'Initial Stock (အစပျိုးစတော့)',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _buildInputDecoration(hint: '0', suffixText: 'units'),
                            validator: (val) {
                              if (val == null || int.tryParse(val.trim()) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Track Inventory', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_trackStock ? 'Auto Deduct' : 'Unlimited', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            value: _trackStock,
                            activeThumbColor: const Color(0xFF3B82F6),
                            onChanged: (val) => setState(() => _trackStock = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveProduct,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : _isEditing ? 'Update Product' : 'Create Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
    );
  }
}
