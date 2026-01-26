import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../styles/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// List of selected files with size display and remove buttons.
class FileAttachmentList extends StatelessWidget {
  final List<PlatformFile> files;
  final ValueChanged<int> onRemoveFile;
  final AppLocalizations l10n;

  const FileAttachmentList({
    super.key,
    required this.files,
    required this.onRemoveFile,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.noFilesSelectedMessage,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = file.name;
        final fileSize = file.size;
        final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(
              Icons.insert_drive_file,
              color: AppColors.primary,
            ),
            title: Text(fileName),
            subtitle: Text('$fileSizeKB KB'),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => onRemoveFile(index),
            ),
          ),
        );
      },
    );
  }
}
