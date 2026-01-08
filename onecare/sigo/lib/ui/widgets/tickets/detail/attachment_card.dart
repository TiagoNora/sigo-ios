import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/date_formatter.dart';

/// Card showing file attachment with name, size, timestamp, and download/delete actions.
class AttachmentCard extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final AppLocalizations l10n;
  final String locale;

  const AttachmentCard({
    super.key,
    required this.attachment,
    required this.onDownload,
    required this.onDelete,
    required this.l10n,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final name = attachment['name'] as String? ?? l10n.unknown;
    final size = attachment['size'] as int? ?? 0;
    final createdAt = attachment['createdAt'] as DateTime?;
    final sizeKB = (size / 1024).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.attach_file, color: Colors.blue),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$sizeKB KB'),
            if (createdAt != null)
              Text(
                formatDate(createdAt, locale, includeTime: true),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: onDownload,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
