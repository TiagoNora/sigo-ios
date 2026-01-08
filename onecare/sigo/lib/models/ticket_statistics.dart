import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_statistics.freezed.dart';

/// Statistics about tickets grouped by status.
@freezed
class TicketStatistics with _$TicketStatistics {
  const factory TicketStatistics({
    @Default(0) int total,
    @Default(0) int open,
    @Default(0) int inProgress,
    @Default(0) int resolved,
    @Default(0) int closed,
  }) = _TicketStatistics;

  const TicketStatistics._();

  /// Total number of active tickets (not resolved or closed).
  int get active => total - resolved - closed;

  /// Percentage of resolved tickets.
  double get resolvedPercentage => total > 0 ? (resolved / total) * 100 : 0.0;

  /// Percentage of closed tickets.
  double get closedPercentage => total > 0 ? (closed / total) * 100 : 0.0;
}
