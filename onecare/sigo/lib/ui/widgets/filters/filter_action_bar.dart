import 'package:flutter/material.dart';

/// Bottom bar with Save and Apply buttons for the quick filters tab.
class FilterActionBar extends StatelessWidget {
  final bool enableSave;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final String saveLabel;
  final String applyLabel;

  const FilterActionBar({
    super.key,
    required this.enableSave,
    required this.onSave,
    required this.onApply,
    required this.saveLabel,
    required this.applyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: enableSave ? onSave : null,
              child: Text(saveLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onApply,
              child: Text(applyLabel),
            ),
          ),
        ],
      ),
    );
  }
}
