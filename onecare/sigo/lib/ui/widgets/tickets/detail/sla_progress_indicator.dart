import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Progress bar showing SLA consumption with color-coded indicators.
class SLAProgressIndicator extends StatelessWidget {
  final int slaMinutes;
  final int consumedMinutes;
  final AppLocalizations l10n;

  const SLAProgressIndicator({
    super.key,
    required this.slaMinutes,
    required this.consumedMinutes,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = slaMinutes > 0
        ? (consumedMinutes / slaMinutes * 100).clamp(0, 100).toInt()
        : 0;

    final remaining = (slaMinutes - consumedMinutes).clamp(0, slaMinutes);
    final color = _getColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.sla}: $percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${_formatMinutes(remaining)} ${l10n.remaining}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Color _getColor(int percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 75) return Colors.amber;
    if (percentage < 90) return Colors.orange;
    return Colors.red;
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}
