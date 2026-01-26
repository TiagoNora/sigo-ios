import 'package:flutter/material.dart';
import '../../../utils/date_formatter.dart';

/// Card representing a saved filter with metadata.
class FilterCard extends StatelessWidget {
  final String name;
  final String owner;
  final DateTime lastUpdate;
  final String visibility;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String ownerLabel;
  final String lastUpdateLabel;
  final String locale;

  const FilterCard({
    super.key,
    required this.name,
    required this.owner,
    required this.lastUpdate,
    required this.visibility,
    required this.isActive,
    required this.onTap,
    this.onDelete,
    required this.ownerLabel,
    required this.lastUpdateLabel,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.blue : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$ownerLabel: $owner',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    Text(
                      '$lastUpdateLabel: ${formatDate(lastUpdate, locale)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
