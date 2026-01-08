// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TicketImpl _$$TicketImplFromJson(Map<String, dynamic> json) => _$TicketImpl(
  id: json['id'] as String? ?? '',
  title: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '--',
  impact: json['impact'] as String? ?? '',
  status: json['status'] == null
      ? TicketStatus.open
      : _ticketStatusFromJson(json['status']),
  priority: json['priority'] as String? ?? 'P3',
  category: json['category'] as String? ?? '',
  createdAt: _parseDateTime(json['creationDate']),
  updatedAt: _parseDateTime(json['lastUpdate']),
  resolvedAt: _parseOptionalDateTime(
    _readResolutionDate(json, 'resolutionDate'),
  ),
  requesterName: json['createdBy'] as String? ?? '',
  requesterEmail: json['requesterEmail'] as String?,
  requesterPhone: json['requesterPhone'] as String?,
  assignedTo: json['createdByTeam'] as String?,
  type: json['type'] as String?,
  scope: json['scope'] as String?,
  ciType: json['ciType'] as String?,
  subcategory: json['subcategory'] as String?,
  severity: json['severity'] as String?,
  slaInMinutes: (json['slaInMinutes'] as num?)?.toInt(),
  slaType: json['slaType'] as String?,
  slaConsumedInMinutes: (json['slaConsumedInMinutes'] as num?)?.toInt(),
  expectedResolutionDate: _parseOptionalDateTime(
    json['expectedResolutionDate'],
  ),
  tenant: json['tenant'] as String?,
  externalId: json['externalId'] as String?,
  cis: _mapListFromJson(json['cis']),
  services: _stringListFromJson(json['services']),
  serviceTypes: _stringListFromJson(json['serviceTypes']),
  closedDate: _parseOptionalDateTime(json['closedDate']),
  apiNotes: _mapListFromJson(json['notes']),
  apiAttachments: _mapListFromJson(json['attachments']),
);

Map<String, dynamic> _$$TicketImplToJson(
  _$TicketImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.title,
  'description': instance.description,
  'impact': instance.impact,
  'status': _ticketStatusToJson(instance.status),
  'priority': instance.priority,
  'category': instance.category,
  'creationDate': _dateToIsoString(instance.createdAt),
  'lastUpdate': _dateToIsoString(instance.updatedAt),
  'resolutionDate': _dateToIsoNullable(instance.resolvedAt),
  'createdBy': instance.requesterName,
  'requesterEmail': instance.requesterEmail,
  'requesterPhone': instance.requesterPhone,
  'createdByTeam': instance.assignedTo,
  'type': instance.type,
  'scope': instance.scope,
  'ciType': instance.ciType,
  'subcategory': instance.subcategory,
  'severity': instance.severity,
  'slaInMinutes': instance.slaInMinutes,
  'slaType': instance.slaType,
  'slaConsumedInMinutes': instance.slaConsumedInMinutes,
  'expectedResolutionDate': _dateToIsoNullable(instance.expectedResolutionDate),
  'tenant': instance.tenant,
  'externalId': instance.externalId,
  'cis': _mapListToJson(instance.cis),
  'services': _stringListToJson(instance.services),
  'serviceTypes': _stringListToJson(instance.serviceTypes),
  'closedDate': _dateToIsoNullable(instance.closedDate),
  'notes': _mapListToJson(instance.apiNotes),
  'attachments': _mapListToJson(instance.apiAttachments),
};
