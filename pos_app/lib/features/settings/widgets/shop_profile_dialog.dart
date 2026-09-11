import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/localization/app_locale.dart';

class ShopProfileDialog extends ConsumerStatefulWidget {
  final Shop shop;

  const ShopProfileDialog({super.key, required this.shop});

  static Future<void> show(BuildContext context, Shop shop) {
    return showDialog(
      context: context,
      builder: (ctx) => ShopProfileDialog(shop: shop),
    );
  }

  @override
  ConsumerState<ShopProfileDialog> createState() => _ShopProfileDialogState();
}

class _ShopProfileDialogState extends ConsumerState<ShopProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _selectedCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _phoneController = TextEditingController(text: widget.shop.phone ?? '');
    _addressController = TextEditingController(text: widget.shop.address ?? '');
    _selectedCurrency = widget.shop.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      await (db.update(db.shops)..where((t) => t.id.equals(widget.shop.id))).write(
        ShopsCompanion(
          name: drift.Value(_nameController.text.trim()),
          phone: drift.Value(_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim()),
          address: drift.Value(_addressController.text.trim().isEmpty ? null : _addressController.text.trim()),
          currency: drift.Value(_selectedCurrency),
          updatedAt: drift.Value(DateTime.now().toUtc()),
          syncStatus: const drift.Value('pending'),
        ),
      );

      ref.invalidate(currentShopProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Shop profile updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Failed to update shop: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store, color: Color(0xFFA855F7), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == AppLanguage.my ? 'ဆိုင်အချက်အလက် ပြင်ဆင်ရန်' : 'Edit Shop Profile',
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

              // Shop Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: lang == AppLanguage.my ? 'ဆိုင်အမည်' : 'Shop Name',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  prefixIcon: const Icon(Icons.business, color: Color(0xFF38BDF8), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return lang == AppLanguage.my ? 'ဆိုင်အမည် ထည့်ပေးပါ' : 'Please enter shop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: lang == AppLanguage.my ? 'ဖုန်းနံပါတ်' : 'Phone Number',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF10B981), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: lang == AppLanguage.my ? 'ဆိုင်လိပ်စာ' : 'Shop Address',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFFF59E0B), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Currency Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: lang == AppLanguage.my ? 'အသုံးပြုငွေကြေး' : 'Store Currency',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFFA855F7), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'MMK', child: Text('MMK (Myanmar Kyats)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (US Dollars)')),
                  DropdownMenuItem(value: 'THB', child: Text('THB (Thai Baht)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppTranslations.tr('btn_cancel', lang)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              AppTranslations.tr('btn_save', lang),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
