import 'package:flutter/material.dart';
import '../utils/phosphor_icons.dart';
import '../../core/theme/journal_colors.dart';

class WaxSealBadge extends StatelessWidget {
  final double size;
  final bool isSmall;

  const WaxSealBadge({
    super.key,
    this.size = 28.0,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = isSmall ? 22.0 : size;

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF9E3838),
            JournalColors.burgundy,
            Color(0xFF571D1D),
          ],
          center: Alignment(-0.2, -0.2),
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFC89A4B).withValues(alpha: 0.6),
          width: isSmall ? 0.8 : 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
          size: dimension * 0.5,
          color: const Color(0xFFF7E6C4),
        ),
      ),
    );
  }
}
