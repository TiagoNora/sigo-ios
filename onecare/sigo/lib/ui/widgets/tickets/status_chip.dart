import 'package:flutter/material.dart';
import '../../../constants/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticket.dart';

/// A reusable chip widget that displays a ticket status with color coding.
///
/// The chip automatically styles itself based on the [TicketStatus]:
/// - Open: Orange
/// - Acknowledged: Amber
/// - In Progress: Blue
/// - Resolved: Green
/// - Closed: Grey
/// - Cancelled: Red
/// - Pending: Blue
/// - Held: Blue Grey
class StatusChip extends StatelessWidget {
  final TicketStatus status;

  const StatusChip({
    super.key,
    required this.status,
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
    final l10n = AppLocalizations.of(context);
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status.getLocalizedName(l10n),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
