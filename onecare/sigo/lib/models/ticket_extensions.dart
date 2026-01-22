import 'ticket.dart';
import '../l10n/app_localizations.dart';

extension TicketStatusExtension on TicketStatus {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case TicketStatus.open:
        return l10n.open;
      case TicketStatus.acknowledged:
        return l10n.acknowledged;
      case TicketStatus.inProgress:
        return l10n.inProgress;
      case TicketStatus.resolved:
        return l10n.resolved;
      case TicketStatus.closed:
        return l10n.closed;
      case TicketStatus.cancelled:
        return l10n.cancelled;
      case TicketStatus.pending:
        return l10n.pending;
      case TicketStatus.held:
        return l10n.held;
    }
  }
}

extension TicketPriorityExtension on TicketPriority {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case TicketPriority.low:
        return l10n.low;
      case TicketPriority.medium:
        return l10n.medium;
      case TicketPriority.high:
        return l10n.high;
      case TicketPriority.urgent:
        return l10n.urgent;
    }
  }
}

extension TicketTypeExtension on String? {
  /// Returns a localized label for known ticket types (case-insensitive).
  String getLocalizedType(AppLocalizations l10n) {
    final normalized = (this ?? '').trim().toUpperCase();

    if (normalized.isEmpty) {
      return l10n.na;
    }

    switch (normalized) {
      case 'INCIDENT':
        return l10n.incident;
      case 'PROBLEM':
        return l10n.problem;
      case 'REQUEST':
        return l10n.request;
      default:
        return this!.trim();
    }
  }
}
