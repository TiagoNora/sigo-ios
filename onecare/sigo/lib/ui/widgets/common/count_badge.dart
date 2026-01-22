import 'package:flutter/material.dart';

/// A small circular badge displaying a count number.
///
/// Used throughout the app to show counts (e.g., number of notes, files, etc.)
class CountBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? borderColor;

  const CountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? Colors.grey.shade400,
        ),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
