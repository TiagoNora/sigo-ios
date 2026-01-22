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

  // Cache status colors to avoid recomputing on every build
  static const Map<TicketStatus, Color> _statusColors = {
    TicketStatus.open: Colors.orange,
    TicketStatus.acknowledged: Colors.amber,
    TicketStatus.inProgress: Colors.blue,
    TicketStatus.resolved: Colors.green,
    TicketStatus.closed: Colors.grey,
    TicketStatus.cancelled: Colors.red,
    TicketStatus.pending: Colors.blue,
    TicketStatus.held: Colors.blueGrey,
  };

  Color get _statusColor => _statusColors[status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _statusColor;

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
