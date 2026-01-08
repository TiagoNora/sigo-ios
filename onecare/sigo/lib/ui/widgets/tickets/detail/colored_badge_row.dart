import 'package:flutter/material.dart';

/// InfoRow with a colored badge container.
///
/// Used for displaying priority, impact, and severity with color coding.
class ColoredBadgeRow extends StatelessWidget {
  final String label;
  final String displayText;
  final Color badgeColor;
  final double labelWidth;
  final double labelGap;

  const ColoredBadgeRow({
    super.key,
    required this.label,
    required this.displayText,
    required this.badgeColor,
    this.labelWidth = 150,
    this.labelGap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: labelGap),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              border: Border.all(color: badgeColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: badgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
