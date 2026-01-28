import 'package:flutter/material.dart';

/// Section with expandable/collapsible content.
class ExpandableSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final bool isLoading;
  final Widget? emptyState;

  const ExpandableSection({
    super.key,
    required this.title,
    this.trailing,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.isLoading = false,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 8),
                ],
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
            onTap: onToggle,
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : children.isEmpty && emptyState != null
                      ? emptyState!
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
            ),
          ],
        ],
      ),
    );
  }
}
