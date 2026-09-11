import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/localization/app_locale.dart';

class CategoryManagementDialog extends ConsumerWidget {
  const CategoryManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final lang = ref.watch(appLanguageProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
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
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category, color: Color(0xFF60A5FA), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.tr('inv_manage_categories', lang),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        AppTranslations.tr('inv_categories', lang),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          lang == AppLanguage.my ? 'အမျိုးအစား မရှိသေးပါ' : 'No categories yet.',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF334155), height: 1),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      Color categoryColor = const Color(0xFF3B82F6);
                      if (cat.colorCode != null && cat.colorCode!.startsWith('#')) {
                        try {
                          categoryColor = Color(int.parse(cat.colorCode!.replaceFirst('#', '0xFF')));
                        } catch (_) {}
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: categoryColor,
                          child: const Icon(Icons.folder, color: Colors.white, size: 14),
                        ),
                        title: Text(
                          cat.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: FutureBuilder<int>(
                          future: ref.read(productDaoProvider).getCategoryProductCount(cat.id),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Text(
                              lang == AppLanguage.my ? '$count ပစ္စည်း' : '$count items',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            );
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 18),
                              tooltip: AppTranslations.tr('btn_edit', lang),
                              onPressed: () => _openCategoryForm(context, ref, categoryToEdit: cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                              tooltip: AppTranslations.tr('btn_delete', lang),
                              onPressed: () => _confirmDeleteCategory(context, ref, cat),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
            const SizedBox(height: 16),

            // Add Category Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppTranslations.tr('inv_add_category', lang)),
              onPressed: () => _openCategoryForm(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategoryForm(BuildContext context, WidgetRef ref, {Category? categoryToEdit}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(categoryToEdit: categoryToEdit),
    );
  }

  void _confirmDeleteCategory(BuildContext context, WidgetRef ref, Category category) async {
    final lang = ref.read(appLanguageProvider);
    final count = await ref.read(productDaoProvider).getCategoryProductCount(category.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          AppTranslations.tr('inv_delete_category', lang),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          lang == AppLanguage.my
              ? '"${category.name}" အမျိုးအစားကို ဖျက်မည်လား? (ပါဝင်သော $count ပစ္စည်းများသည် မပျက်ဘဲ အမည်မရှိအမျိုးအစားအဖြစ် ဆက်လက်ရှိနေမည်ဖြစ်သည်။)'
              : 'Delete category "${category.name}"? ($count products will remain safe and become uncategorized.)',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTranslations.tr('btn_cancel', lang), style: const TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppTranslations.tr('btn_delete', lang), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(productDaoProvider).softDeleteCategory(category.id);
      ref.invalidate(categoriesStreamProvider);
      ref.invalidate(activeProductsStreamProvider);
      ref.invalidate(allInventoryProductsStreamProvider);
    }
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? categoryToEdit;

  const _CategoryFormDialog({this.categoryToEdit});

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _nameController = TextEditingController();
  final _sortController = TextEditingController(text: '0');
  String _selectedColor = '#3B82F6';

  final List<String> _colorPalette = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
    '#F43F5E', // Rose
    '#6366F1', // Indigo
    '#64748B', // Slate
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _sortController.text = widget.categoryToEdit!.sortOrder.toString();
      _selectedColor = widget.categoryToEdit!.colorCode ?? '#3B82F6';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isEdit = widget.categoryToEdit != null;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? AppTranslations.tr('inv_edit_category', lang) : AppTranslations.tr('inv_add_category', lang),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Category Name Field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: AppTranslations.tr('inv_category_name', lang),
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 16),

            // Color Picker Chips
            Text(
              AppTranslations.tr('inv_choose_color', lang),
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorPalette.map((hex) {
                final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedColor == hex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppTranslations.tr('btn_cancel', lang), style: const TextStyle(color: Color(0xFF94A3B8))),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveCategory,
                  child: Text(AppTranslations.tr('btn_save', lang)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final productDao = ref.read(productDaoProvider);
    final shop = ref.read(currentShopProvider).value;
    final shopId = shop?.id ?? 'shop_default';
    final sort = int.tryParse(_sortController.text.trim()) ?? 0;

    if (widget.categoryToEdit != null) {
      await productDao.updateCategory(
        CategoriesCompanion(
          id: drift.Value(widget.categoryToEdit!.id),
          shopId: drift.Value(shopId),
          name: drift.Value(name),
          colorCode: drift.Value(_selectedColor),
          sortOrder: drift.Value(sort),
          updatedAt: drift.Value(DateTime.now().toUtc()),
          syncStatus: const drift.Value('pending'),
        ),
      );
    } else {
      await productDao.insertCategory(
        CategoriesCompanion(
          id: drift.Value(const Uuid().v4()),
          shopId: drift.Value(shopId),
          name: drift.Value(name),
          colorCode: drift.Value(_selectedColor),
          sortOrder: drift.Value(sort),
          createdAt: drift.Value(DateTime.now().toUtc()),
          updatedAt: drift.Value(DateTime.now().toUtc()),
          syncStatus: const drift.Value('pending'),
        ),
      );
    }

    ref.invalidate(categoriesStreamProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
