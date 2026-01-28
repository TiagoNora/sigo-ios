import 'dart:convert';

/// Model for ticket statistics displayed in widget
class WidgetTicketStats {
  final int acknowledged;
  final int held;
  final int inProgress;
  final int pending;
  final int resolved;
  final int total;
  final DateTime lastUpdate;

  WidgetTicketStats({
    required this.acknowledged,
    required this.held,
    required this.inProgress,
    required this.pending,
    required this.resolved,
    required this.lastUpdate,
  }) : total = acknowledged + held + inProgress + pending + resolved;

  /// Create stats from API response
  factory WidgetTicketStats.fromApiResponse(Map<String, dynamic> response) {
    final results = response['results'] as List<dynamic>? ?? [];

    int acknowledged = 0;
    int held = 0;
    int inProgress = 0;
    int pending = 0;
    int resolved = 0;

    for (var ticket in results) {
      final status = ticket['status'] as String?;
      switch (status) {
        case 'ACKNOWLEDGED':
          acknowledged++;
          break;
        case 'HELD':
          held++;
          break;
        case 'IN_PROGRESS':
          inProgress++;
          break;
        case 'PENDING':
          pending++;
          break;
        case 'RESOLVED':
          resolved++;
          break;
      }
    }

    return WidgetTicketStats(
      acknowledged: acknowledged,
      held: held,
      inProgress: inProgress,
      pending: pending,
      resolved: resolved,
      lastUpdate: DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'acknowledged': acknowledged,
      'held': held,
      'inProgress': inProgress,
      'pending': pending,
      'resolved': resolved,
      'total': total,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  /// Create from stored JSON
  factory WidgetTicketStats.fromJson(Map<String, dynamic> json) {
    return WidgetTicketStats(
      acknowledged: json['acknowledged'] as int? ?? 0,
      held: json['held'] as int? ?? 0,
      inProgress: json['inProgress'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      resolved: json['resolved'] as int? ?? 0,
      lastUpdate: DateTime.tryParse(json['lastUpdate'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Get color for each status (as hex string for Android)
  static String getColorForStatus(String status) {
    switch (status) {
      case 'ACKNOWLEDGED':
        return '#2196F3'; // Blue
      case 'HELD':
        return '#FF9800'; // Orange
      case 'IN_PROGRESS':
        return '#4CAF50'; // Green
      case 'PENDING':
        return '#F44336'; // Red
      case 'RESOLVED':
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Gray
    }
  }

  @override
  String toString() {
    return 'WidgetTicketStats(acknowledged: $acknowledged, held: $held, '
        'inProgress: $inProgress, pending: $pending, resolved: $resolved, total: $total)';
  }
}
