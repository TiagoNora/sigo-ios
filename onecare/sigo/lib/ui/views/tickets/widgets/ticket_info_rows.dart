import 'package:flutter/material.dart';
import '../../../../utils/date_formatter.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 150,
    this.labelGap = 12,
  });

  final String label;
  final String value;
  final double labelWidth;
  final double labelGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class DateRow extends StatelessWidget {
  const DateRow({
    super.key,
    required this.label,
    required this.date,
    this.labelWidth = 150,
    this.labelGap = 12,
  });

  final String label;
  final DateTime? date;
  final double labelWidth;
  final double labelGap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final localDate = date;
    final value = localDate != null
        ? formatDate(localDate, locale.toString(), includeTime: true)
        : '--';
    
    return InfoRow(
      label: label, 
      value: value, 
      labelWidth: labelWidth,
      labelGap: labelGap,
    );
  }
}
