import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Optional text input field with info banner for external reference.
///
/// First step in the ticket creation wizard.
class ExternalReferenceStep extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  const ExternalReferenceStep({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.externalReferenceOptional,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.externalReferenceDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.externalReference,
              hintText: l10n.externalReferenceHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              prefixIcon: const Icon(Icons.link),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.clear(),
                    )
                  : null,
            ),
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.externalReferenceInfo,
                    style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
