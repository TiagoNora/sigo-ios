import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/constants/ticket_constants.dart';
import '../l10n/app_localizations.dart';

part 'ticket.freezed.dart';
part 'ticket.g.dart';

@freezed
class Ticket with _$Ticket {
  const factory Ticket({
    @JsonKey(name: 'id') @Default('') String id,
    @JsonKey(name: 'name') @Default('') String title,
    @JsonKey(name: 'description') @Default('--') String description,
    @JsonKey(name: 'impact') @Default('') String impact,
    @JsonKey(
      name: 'status',
      fromJson: _ticketStatusFromJson,
      toJson: _ticketStatusToJson,
    )
    @Default(TicketStatus.open)
    TicketStatus status,
    @JsonKey(name: 'priority') @Default('P3') String priority,
    @JsonKey(name: 'category') @Default('') String category,
    @JsonKey(
      name: 'creationDate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    required DateTime createdAt,
    @JsonKey(
      name: 'lastUpdate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    required DateTime updatedAt,
    @JsonKey(
      name: 'resolutionDate',
      readValue: _readResolutionDate,
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    DateTime? resolvedAt,
    @JsonKey(name: 'createdBy') @Default('') String requesterName,
    @JsonKey(name: 'requesterEmail') String? requesterEmail,
    @JsonKey(name: 'requesterPhone') String? requesterPhone,
    @JsonKey(name: 'createdByTeam') String? assignedTo,
    @Default(<String>[])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<String> attachments,
    @JsonKey(includeFromJson: false, includeToJson: false) String? notes,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'scope') String? scope,
    @JsonKey(name: 'ciType') String? ciType,
    @JsonKey(name: 'subcategory') String? subcategory,
    @JsonKey(name: 'severity') String? severity,
    @JsonKey(name: 'slaInMinutes') int? slaInMinutes,
    @JsonKey(name: 'slaType') String? slaType,
    @JsonKey(name: 'slaConsumedInMinutes') int? slaConsumedInMinutes,
    @JsonKey(
      name: 'expectedResolutionDate',
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    DateTime? expectedResolutionDate,
    @JsonKey(name: 'tenant') String? tenant,
    @JsonKey(name: 'externalId') String? externalId,
    @JsonKey(
      name: 'cis',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    List<Map<String, dynamic>>? cis,
    @JsonKey(
      name: 'services',
      fromJson: _stringListFromJson,
      toJson: _stringListToJson,
    )
    List<String>? services,
    @JsonKey(
      name: 'serviceTypes',
      fromJson: _stringListFromJson,
      toJson: _stringListToJson,
    )
    List<String>? serviceTypes,
    @JsonKey(
      name: 'closedDate',
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    DateTime? closedDate,
    @JsonKey(
      name: 'notes',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    List<Map<String, dynamic>>? apiNotes,
    @JsonKey(
      name: 'attachments',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    List<Map<String, dynamic>>? apiAttachments,
  }) = _Ticket;

  const Ticket._();

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);

  // Custom API payload (mirrors previous behavior)
  Map<String, dynamic> toApiJson() => {
        'id': id,
        'name': title,
        'impact': impact,
        'status': status.toApiValue(),
        'priority': priority,
        'category': category,
        'creationDate': createdAt.toIso8601String(),
        'lastUpdate': updatedAt.toIso8601String(),
        'expectedResolutionDate': resolvedAt?.toIso8601String(),
        'createdBy': requesterName,
        'createdByTeam': assignedTo,
        'externalId': externalId ?? '',
        'type': type ?? 'REQUEST',
      };
}

TicketStatus _ticketStatusFromJson(Object? value) =>
    TicketStatus.fromApiValue((value as String?) ?? TicketStatusStrings.open);

String _ticketStatusToJson(TicketStatus status) => status.toApiValue();

DateTime _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return DateTime.now();
}

DateTime? _parseOptionalDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}

Object? _readResolutionDate(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['resolvedDate'];

String _dateToIsoString(DateTime value) => value.toIso8601String();

String? _dateToIsoNullable(DateTime? value) => value?.toIso8601String();

List<Map<String, dynamic>>? _mapListFromJson(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  return null;
}

List<Map<String, dynamic>>? _mapListToJson(
        List<Map<String, dynamic>>? value) =>
    value;

List<String>? _stringListFromJson(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return null;
}

List<String>? _stringListToJson(List<String>? value) => value;

enum TicketStatus {
  open,
  acknowledged,
  inProgress,
  resolved,
  closed,
  cancelled,
  pending,
  held;

  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.acknowledged:
        return 'Acknowledged';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.cancelled:
        return 'Cancelled';
      case TicketStatus.pending:
        return 'Pending';
      case TicketStatus.held:
        return 'Held';
    }
  }

  static TicketStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case TicketStatusStrings.open:
        return TicketStatus.open;
      case TicketStatusStrings.acknowledged:
        return TicketStatus.acknowledged;
      case TicketStatusStrings.inProgress:
      case 'ASSIGNED':
        return TicketStatus.inProgress;
      case TicketStatusStrings.resolved:
      case 'COMPLETED':
        return TicketStatus.resolved;
      case TicketStatusStrings.closed:
        return TicketStatus.closed;
      case TicketStatusStrings.cancelled:
        return TicketStatus.cancelled;
      case TicketStatusStrings.pending:
        return TicketStatus.pending;
      case TicketStatusStrings.held:
        return TicketStatus.held;
      default:
        return TicketStatus.open;
    }
  }

  String toApiValue() {
    switch (this) {
      case TicketStatus.open:
        return TicketStatusStrings.open;
      case TicketStatus.acknowledged:
        return TicketStatusStrings.acknowledged;
      case TicketStatus.inProgress:
        return TicketStatusStrings.inProgress;
      case TicketStatus.resolved:
        return TicketStatusStrings.resolved;
      case TicketStatus.closed:
        return TicketStatusStrings.closed;
      case TicketStatus.cancelled:
        return TicketStatusStrings.cancelled;
      case TicketStatus.pending:
        return TicketStatusStrings.pending;
      case TicketStatus.held:
        return TicketStatusStrings.held;
    }
  }

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

enum TicketPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  static TicketPriority fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'P1':
        return TicketPriority.urgent;
      case 'P2':
        return TicketPriority.high;
      case 'P3':
        return TicketPriority.medium;
      case 'P4':
        return TicketPriority.low;
      default:
        return TicketPriority.medium;
    }
  }

  String toApiValue() {
    switch (this) {
      case TicketPriority.low:
        return 'P4';
      case TicketPriority.medium:
        return 'P3';
      case TicketPriority.high:
        return 'P2';
      case TicketPriority.urgent:
        return 'P1';
    }
  }

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
