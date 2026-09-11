import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import 'pin_pad_widget.dart';

class AdminOverrideDialog extends ConsumerStatefulWidget {
  final String actionTitle;
  const AdminOverrideDialog({super.key, required this.actionTitle});

  static Future<bool> requestApproval(BuildContext context, {required String actionTitle}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminOverrideDialog(actionTitle: actionTitle),
    );
    return result == true;
  }

  @override
  ConsumerState<AdminOverrideDialog> createState() => _AdminOverrideDialogState();
}

class _AdminOverrideDialogState extends ConsumerState<AdminOverrideDialog> {
  final GlobalKey<State<PinPadWidget>> _pinPadKey = GlobalKey();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: PinPadWidget(
        key: _pinPadKey,
        title: 'Manager / Admin PIN Required',
        subtitle: _errorMessage ?? 'Action: "${widget.actionTitle}"\nEnter Manager or Owner PIN to authorize',
        maxDigits: 4,
        onPinComplete: (pin) async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);

          final shop = await ref.read(currentShopProvider.future);
          if (shop == null) return;

          final userDao = ref.read(userDaoProvider);
          final user = await userDao.authenticatePin(
            shopId: shop.id,
            pinCode: pin,
          );

          if (!mounted) return;

          if (user != null && (user.role == 'owner' || user.role == 'manager')) {
            navigator.pop(true);
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF10B981),
                content: Text('Authorized by ${user.name} (${user.role.toUpperCase()})'),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'Invalid Admin/Manager PIN. Authorization denied.';
            });
            final pinPadState = _pinPadKey.currentState;
            if (pinPadState != null) {
              (pinPadState as dynamic).triggerError();
            }
          }
        },
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}
