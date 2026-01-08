import 'package:flutter/material.dart';

/// ColoredBadgeRow with an edit icon that triggers a callback.
///
/// Used for editable impact/severity fields in ticket detail screens.
class EditableColoredBadgeRow extends StatelessWidget {
  final String label;
  final String displayText;
  final Color badgeColor;
  final VoidCallback onEdit;
  final double labelWidth;
  final double labelGap;

  const EditableColoredBadgeRow({
    super.key,
    required this.label,
    required this.displayText,
    required this.badgeColor,
    required this.onEdit,
    this.labelWidth = 150,
    this.labelGap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              const Spacer(),
              const Icon(Icons.edit, size: 16, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
