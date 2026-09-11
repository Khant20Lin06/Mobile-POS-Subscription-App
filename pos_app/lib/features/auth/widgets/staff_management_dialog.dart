import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class StaffManagementDialog extends ConsumerStatefulWidget {
  const StaffManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const StaffManagementDialog(),
    );
  }

  @override
  ConsumerState<StaffManagementDialog> createState() => _StaffManagementDialogState();
}

class _StaffManagementDialogState extends ConsumerState<StaffManagementDialog> {
  final _uuid = const Uuid();

  void _showAddOrEditStaffDialog({User? existingUser}) {
    final nameController = TextEditingController(text: existingUser?.name ?? '');
    final pinController = TextEditingController(text: existingUser?.pinCode ?? '');
    String role = existingUser?.role ?? 'cashier';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existingUser != null ? 'Edit Staff Profile' : 'Add New Cashier / Staff',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Staff Name *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Security PIN (4-6 digits) *',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 4) {
                      return 'PIN must be at least 4 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role Permission',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier (Standard POS)')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager (Elevated POS)')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner (Full Admin)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => role = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final shop = await ref.read(currentShopProvider.future);
                  if (shop == null) return;

                  final userDao = ref.read(userDaoProvider);
                  final now = DateTime.now().toUtc();

                  if (existingUser != null) {
                    await userDao.updateUser(
                      UsersCompanion(
                        id: drift.Value(existingUser.id),
                        shopId: drift.Value(shop.id),
                        name: drift.Value(nameController.text.trim()),
                        pinCode: drift.Value(pinController.text.trim()),
                        role: drift.Value(role),
                        updatedAt: drift.Value(now),
                        syncStatus: const drift.Value('pending'),
                      ),
                    );
                  } else {
                    await userDao.insertUser(
                      UsersCompanion.insert(
                        id: _uuid.v4(),
                        shopId: shop.id,
                        name: nameController.text.trim(),
                        pinCode: pinController.text.trim(),
                        role: drift.Value(role),
                        createdAt: drift.Value(now),
                        updatedAt: drift.Value(now),
                        syncStatus: const drift.Value('pending'),
                      ),
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Text(existingUser != null ? 'Staff profile updated!' : 'New staff member added!'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStaff(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Staff Member', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "${user.name}"? They will no longer be able to log in with their PIN.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userDaoProvider).softDeleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFEF4444),
                    content: Text('Staff member "${user.name}" removed.'),
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(currentShopProvider);
    final usersAsync = shopAsync.when(
      data: (shop) => shop != null
          ? ref.watch(userDaoProvider).watchActiveUsers(shop.id)
          : Stream.value(<User>[]),
      loading: () => Stream.value(<User>[]),
      error: (_, error) => Stream.value(<User>[]),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts, color: Color(0xFF60A5FA), size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Staff & Cashier Directory',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Staff List
            Expanded(
              child: StreamBuilder<List<User>>(
                stream: usersAsync,
                builder: (context, snapshot) {
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('No staff members registered.', style: TextStyle(color: Color(0xFF94A3B8))),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, index) => const Divider(color: Color(0xFF334155), height: 16),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isOwner = user.role == 'owner';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          'Role: ${user.role.toUpperCase()} • PIN: ****${user.pinCode.length >= 2 ? user.pinCode.substring(user.pinCode.length - 2) : user.pinCode}',
                          style: TextStyle(
                            color: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF60A5FA), size: 18),
                              onPressed: () => _showAddOrEditStaffDialog(existingUser: user),
                            ),
                            if (!isOwner)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                onPressed: () => _confirmDeleteStaff(user),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Dialog Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('+ Add New Cashier / Staff', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddOrEditStaffDialog(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
