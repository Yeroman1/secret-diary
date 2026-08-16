import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/utils/phosphor_icons.dart';
import '../../core/theme/text_styles.dart';

class PinPadWidget extends StatelessWidget {
  final String currentPin;
  final int pinLength;
  final Function(String digit) onDigitEntered;
  final VoidCallback onDelete;
  final VoidCallback? onBiometricTap;

  const PinPadWidget({
    super.key,
    required this.currentPin,
    this.pinLength = 4,
    required this.onDigitEntered,
    required this.onDelete,
    this.onBiometricTap,
  });

  Widget _buildDot(BuildContext context, bool isFilled) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      width: isFilled ? 18.0 : 14.0,
      height: isFilled ? 18.0 : 14.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.15),
        border: Border.all(
          color: isFilled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildKeyButton(BuildContext context, {required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pinLength,
            (index) => _buildDot(context, index < currentPin.length),
          ),
        ),
        const SizedBox(height: 36),
        // Keypad 1 - 9
        Column(
          children: [
            for (var row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ]) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((digit) {
                  return _buildKeyButton(
                    context,
                    label: digit,
                    onTap: () => onDigitEntered(digit),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Bottom row: Biometric / Clear / 0 / Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: onBiometricTap != null
                      ? IconButton(
                          icon: Icon(
                            PhosphorIcons.fingerprint(),
                            size: 30,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onBiometricTap!();
                          },
                        )
                      : null,
                ),
                _buildKeyButton(
                  context,
                  label: '0',
                  onTap: () => onDigitEntered('0'),
                ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.backspace(),
                      size: 28,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onDelete();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
