import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/date_formatter.dart';

/// Blue-tinted card displaying a note with username, timestamp, content, and edit button.
class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onEdit;
  final AppLocalizations l10n;
  final String locale;

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.l10n,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final username = note['username'] as String? ?? l10n.unknown;
    final content = note['note'] as String? ?? '';
    final createdAt = note['createdAt'] as DateTime?;

    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    formatDate(createdAt, locale, includeTime: true),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(l10n.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
