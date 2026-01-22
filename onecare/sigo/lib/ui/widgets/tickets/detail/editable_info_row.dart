import 'package:flutter/material.dart';

/// An info row with an edit icon that triggers a callback.
///
/// Used for editable fields in ticket detail screens.
class EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final double labelWidth;
  final double labelGap;
  final Widget? leadingIcon;

  const EditableInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
    this.labelWidth = 150,
    this.labelGap = 12,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.edit, size: 16, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
