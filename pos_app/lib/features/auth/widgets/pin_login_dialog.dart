import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../providers/auth_provider.dart';
import 'pin_pad_widget.dart';

class PinLoginDialog extends ConsumerStatefulWidget {
  final bool isLockScreen;
  const PinLoginDialog({super.key, this.isLockScreen = false});

  static Future<bool?> show(BuildContext context, {bool isLockScreen = false}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isLockScreen,
      builder: (ctx) => PinLoginDialog(isLockScreen: isLockScreen),
    );
  }

  @override
  ConsumerState<PinLoginDialog> createState() => _PinLoginDialogState();
}

class _PinLoginDialogState extends ConsumerState<PinLoginDialog> {
  final GlobalKey<State<PinPadWidget>> _pinPadKey = GlobalKey();
  User? _selectedUser;
  String? _errorMessage;

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: StreamBuilder<List<User>>(
        stream: usersAsync,
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Staff Selector Avatars
                if (users.isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Cashier Profile:',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: users.map((user) {
                              final isSelected = _selectedUser?.id == user.id;
                              final isOwner = user.role == 'owner';

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                                          : const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                          child: Text(
                                            user.name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.name,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              user.role.toUpperCase(),
                                              style: TextStyle(
                                                color: isOwner ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // PIN Pad
                PinPadWidget(
                  key: _pinPadKey,
                  title: _selectedUser != null ? 'PIN for ${_selectedUser!.name}' : 'Cashier Login',
                  subtitle: _errorMessage ?? (_selectedUser != null ? 'Enter 4-digit PIN to switch' : 'Enter your 4-digit PIN code'),
                  maxDigits: 4,
                  onPinComplete: (pin) async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    final shop = shopAsync.value;
                    if (shop == null) return;

                    final userDao = ref.read(userDaoProvider);
                    User? authenticatedUser;

                    if (_selectedUser != null) {
                      if (_selectedUser!.pinCode == pin) {
                        authenticatedUser = _selectedUser;
                      }
                    } else {
                      authenticatedUser = await userDao.authenticatePin(
                        shopId: shop.id,
                        pinCode: pin,
                      );
                    }

                    if (authenticatedUser != null) {
                      ref.read(currentUserProvider.notifier).setUser(authenticatedUser);
                      ref.read(isTerminalLockedProvider.notifier).state = false;
                      if (!mounted) return;
                      navigator.pop(true);
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('Logged in as "${authenticatedUser.name}" (${authenticatedUser.role.toUpperCase()})'),
                        ),
                      );
                    } else {
                      setState(() {
                        _errorMessage = 'Incorrect PIN code. Please try again.';
                      });
                      final pinPadState = _pinPadKey.currentState;
                      if (pinPadState != null) {
                        (pinPadState as dynamic).triggerError();
                      }
                    }
                  },
                  onCancel: widget.isLockScreen ? null : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
