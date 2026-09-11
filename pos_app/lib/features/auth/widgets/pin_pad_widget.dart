import 'package:flutter/material.dart';

class PinPadWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int maxDigits;
  final void Function(String pin) onPinComplete;
  final VoidCallback? onCancel;

  const PinPadWidget({
    super.key,
    this.title = 'Enter Security PIN',
    this.subtitle,
    this.maxDigits = 4,
    required this.onPinComplete,
    this.onCancel,
  });

  @override
  State<PinPadWidget> createState() => _PinPadWidgetState();
}

class _PinPadWidgetState extends State<PinPadWidget> {
  String _enteredPin = '';
  bool _isError = false;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < widget.maxDigits) {
      final newPin = _enteredPin + digit;
      setState(() {
        _enteredPin = newPin;
        _isError = false;
      });

      if (newPin.length == widget.maxDigits) {
        widget.onPinComplete(newPin);
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _isError = false;
    });
  }

  /// Called externally by parent if PIN failed
  void triggerError() {
    setState(() {
      _isError = true;
      _enteredPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Icon & Title
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isError
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : const Color(0xFF2563EB).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isError ? Icons.lock_open : Icons.lock_outline,
              color: _isError ? const Color(0xFFEF4444) : const Color(0xFF60A5FA),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isError ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Masked PIN indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.maxDigits, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isError
                      ? const Color(0xFFEF4444)
                      : isFilled
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF334155),
                  border: Border.all(
                    color: _isError
                        ? const Color(0xFFEF4444)
                        : isFilled
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF475569),
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Keypad 3x4 grid
          Column(
            children: [
              _buildKeypadRow(['1', '2', '3']),
              const SizedBox(height: 12),
              _buildKeypadRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildKeypadRow(['7', '8', '9']),
              const SizedBox(height: 12),
              _buildKeypadRow(['C', '0', 'DEL']),
            ],
          ),

          if (widget.onCancel != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) {
        if (k == 'C') {
          return _buildKeyButton(
            child: const Text('C', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: _onClear,
          );
        } else if (k == 'DEL') {
          return _buildKeyButton(
            child: const Icon(Icons.backspace_outlined, color: Color(0xFF94A3B8), size: 20),
            onTap: _onBackspace,
          );
        } else {
          return _buildKeyButton(
            child: Text(
              k,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _onDigitPressed(k),
          );
        }
      }).toList(),
    );
  }

  Widget _buildKeyButton({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 68,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
