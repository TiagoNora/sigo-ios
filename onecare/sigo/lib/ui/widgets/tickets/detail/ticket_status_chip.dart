import 'package:flutter/material.dart';
import '../../../../models/ticket.dart';
import '../../../../l10n/app_localizations.dart';

/// Colored chip displaying ticket status with appropriate color coding.
class TicketStatusChip extends StatelessWidget {
  final TicketStatus status;
  final AppLocalizations l10n;

  const TicketStatusChip({
    super.key,
    required this.status,
    required this.l10n,
  });

  Color _getStatusColor() {
    switch (status) {
      case TicketStatus.open:
        return Colors.orange;
      case TicketStatus.acknowledged:
        return Colors.amber;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
      case TicketStatus.cancelled:
        return Colors.red;
      case TicketStatus.pending:
        return Colors.blue;
      case TicketStatus.held:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.getLocalizedName(l10n),
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
