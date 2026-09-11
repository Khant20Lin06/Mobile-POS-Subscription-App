import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class CustomerFormDialog extends ConsumerStatefulWidget {
  final Customer? customerToEdit;

  const CustomerFormDialog({super.key, this.customerToEdit});

  static Future<bool?> show(BuildContext context, {Customer? customerToEdit}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CustomerFormDialog(customerToEdit: customerToEdit),
    );
  }

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _initialDebtController;

  bool _isSaving = false;
  bool get _isEditing => widget.customerToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customerToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _initialDebtController = TextEditingController(text: c != null ? c.totalDebt.toStringAsFixed(0) : '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _initialDebtController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final customerDao = ref.read(customerDaoProvider);
      final shop = await (db.select(db.shops)..limit(1)).getSingleOrNull();
      final shopId = shop?.id ?? 'default_shop';

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      final debt = double.tryParse(_initialDebtController.text.trim()) ?? 0.0;
      final now = DateTime.now().toUtc();

      if (_isEditing) {
        final existing = widget.customerToEdit!;
        await (db.update(db.customers)..where((t) => t.id.equals(existing.id))).write(
          CustomersCompanion(
            name: drift.Value(name),
            phone: drift.Value(phone),
            totalDebt: drift.Value(debt),
            updatedAt: drift.Value(now),
            syncStatus: const drift.Value('pending'),
          ),
        );
      } else {
        final customerId = const Uuid().v4();
        await customerDao.insertCustomer(
          CustomersCompanion.insert(
            id: customerId,
            shopId: shopId,
            name: name,
            phone: drift.Value(phone),
            totalDebt: drift.Value(debt),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
            syncStatus: const drift.Value('pending'),
          ),
        );

        // If there was initial migrated debt, record initial ledger entry
        if (debt > 0) {
          await customerDao.recordLedgerEntry(
            ledgerEntry: CustomerLedgersCompanion.insert(
              id: const Uuid().v4(),
              shopId: shopId,
              customerId: customerId,
              type: 'DEBT_INCREASE',
              amount: debt,
              notes: const drift.Value('Initial Migrated Debt Balance'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
              syncStatus: const drift.Value('pending'),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(_isEditing ? 'Customer "$name" updated!' : 'Customer "$name" added!'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error saving customer: $e')),
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
            child: Icon(_isEditing ? Icons.person_outline : Icons.person_add_alt, color: const Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            _isEditing ? 'Edit Customer' : 'Add New Customer',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              const Text('Customer Name *', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(hint: 'e.g. U Hla Win, Daw Aye Aye'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter customer name';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone
              const Text('Phone Number (Optional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  hint: '09xxxxxxxxx',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 18),
                ),
              ),
              const SizedBox(height: 14),

              // Initial Debt (only in add mode or explicitly adjust)
              Text(
                _isEditing ? 'Total Outstanding Debt' : 'Initial Debt Balance (အကြွေးစာရင်းဟောင်း)',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _initialDebtController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  hint: '0',
                  suffixText: 'MMK',
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val.trim()) == null) return 'Enter valid amount';
                  return null;
                },
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
          onPressed: _isSaving ? null : _saveCustomer,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : _isEditing ? 'Update Profile' : 'Save Customer'),
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
      suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
    );
  }
}
