import 'package:flutter/material.dart';

/// A row displaying a label-value pair with consistent spacing.
///
/// Used throughout ticket detail screens to display information.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;
  final double labelGap;
  final Widget? leadingIcon;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 150,
    this.labelGap = 12,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            SizedBox(width: labelGap),
          ],
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
