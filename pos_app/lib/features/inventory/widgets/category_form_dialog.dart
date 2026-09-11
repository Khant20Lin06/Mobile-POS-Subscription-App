import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class CategoryFormDialog extends ConsumerStatefulWidget {
  const CategoryFormDialog({super.key});

  static Future<Category?> show(BuildContext context) {
    return showDialog<Category>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CategoryFormDialog(),
    );
  }

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#3B82F6'; // Default Blue

  final List<String> _colorPalette = [
    '#3B82F6', // Blue
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F97316', // Orange
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final shop = await (db.select(db.shops)..limit(1)).getSingleOrNull();
      final shopId = shop?.id ?? 'default_shop';

      final newCategory = CategoriesCompanion.insert(
        id: const Uuid().v4(),
        shopId: shopId,
        name: _nameController.text.trim(),
        colorCode: drift.Value(_selectedColor),
        sortOrder: const drift.Value(0),
        createdAt: drift.Value(DateTime.now().toUtc()),
        updatedAt: drift.Value(DateTime.now().toUtc()),
        syncStatus: const drift.Value('pending'),
      );

      await ref.read(productDaoProvider).insertCategory(newCategory);
      final created = await (db.select(db.categories)
            ..where((t) => t.id.equals(newCategory.id.value)))
          .getSingleOrNull();

      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error saving category: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category, color: Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('New Category', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category Name *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Hot Drinks, Bakery, Snacks',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter category name';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text('Theme Color', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorPalette.map((hex) {
                  final isSelected = _selectedColor == hex;
                  final color = _parseColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
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
          onPressed: _isSaving ? null : _saveCategory,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : 'Create Category'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
