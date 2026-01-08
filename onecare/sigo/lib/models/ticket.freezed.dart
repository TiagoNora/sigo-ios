// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Ticket _$TicketFromJson(Map<String, dynamic> json) {
  return _Ticket.fromJson(json);
}

/// @nodoc
mixin _$Ticket {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'description')
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'impact')
  String get impact => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'status',
    fromJson: _ticketStatusFromJson,
    toJson: _ticketStatusToJson,
  )
  TicketStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'priority')
  String get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'category')
  String get category => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'creationDate',
    fromJson: _parseDateTime,
    toJson: _dateToIsoString,
  )
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'lastUpdate',
    fromJson: _parseDateTime,
    toJson: _dateToIsoString,
  )
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'resolutionDate',
    readValue: _readResolutionDate,
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdBy')
  String get requesterName => throw _privateConstructorUsedError;
  @JsonKey(name: 'requesterEmail')
  String? get requesterEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'requesterPhone')
  String? get requesterPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'createdByTeam')
  String? get assignedTo => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String> get attachments => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'type')
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'scope')
  String? get scope => throw _privateConstructorUsedError;
  @JsonKey(name: 'ciType')
  String? get ciType => throw _privateConstructorUsedError;
  @JsonKey(name: 'subcategory')
  String? get subcategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'severity')
  String? get severity => throw _privateConstructorUsedError;
  @JsonKey(name: 'slaInMinutes')
  int? get slaInMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'slaType')
  String? get slaType => throw _privateConstructorUsedError;
  @JsonKey(name: 'slaConsumedInMinutes')
  int? get slaConsumedInMinutes => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'expectedResolutionDate',
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  DateTime? get expectedResolutionDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant')
  String? get tenant => throw _privateConstructorUsedError;
  @JsonKey(name: 'externalId')
  String? get externalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
  List<Map<String, dynamic>>? get cis => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'services',
    fromJson: _stringListFromJson,
    toJson: _stringListToJson,
  )
  List<String>? get services => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'serviceTypes',
    fromJson: _stringListFromJson,
    toJson: _stringListToJson,
  )
  List<String>? get serviceTypes => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'closedDate',
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  DateTime? get closedDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
  List<Map<String, dynamic>>? get apiNotes =>
      throw _privateConstructorUsedError;
  @JsonKey(
    name: 'attachments',
    fromJson: _mapListFromJson,
    toJson: _mapListToJson,
  )
  List<Map<String, dynamic>>? get apiAttachments =>
      throw _privateConstructorUsedError;

  /// Serializes this Ticket to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketCopyWith<Ticket> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketCopyWith<$Res> {
  factory $TicketCopyWith(Ticket value, $Res Function(Ticket) then) =
      _$TicketCopyWithImpl<$Res, Ticket>;
  @useResult
  $Res call({
    @JsonKey(name: 'id') String id,
    @JsonKey(name: 'name') String title,
    @JsonKey(name: 'description') String description,
    @JsonKey(name: 'impact') String impact,
    @JsonKey(
      name: 'status',
      fromJson: _ticketStatusFromJson,
      toJson: _ticketStatusToJson,
    )
    TicketStatus status,
    @JsonKey(name: 'priority') String priority,
    @JsonKey(name: 'category') String category,
    @JsonKey(
      name: 'creationDate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    DateTime createdAt,
    @JsonKey(
      name: 'lastUpdate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    DateTime updatedAt,
    @JsonKey(
      name: 'resolutionDate',
      readValue: _readResolutionDate,
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    DateTime? resolvedAt,
    @JsonKey(name: 'createdBy') String requesterName,
    @JsonKey(name: 'requesterEmail') String? requesterEmail,
    @JsonKey(name: 'requesterPhone') String? requesterPhone,
    @JsonKey(name: 'createdByTeam') String? assignedTo,
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
    @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
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
    @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
    List<Map<String, dynamic>>? apiNotes,
    @JsonKey(
      name: 'attachments',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    List<Map<String, dynamic>>? apiAttachments,
  });
}

/// @nodoc
class _$TicketCopyWithImpl<$Res, $Val extends Ticket>
    implements $TicketCopyWith<$Res> {
  _$TicketCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? impact = null,
    Object? status = null,
    Object? priority = null,
    Object? category = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? resolvedAt = freezed,
    Object? requesterName = null,
    Object? requesterEmail = freezed,
    Object? requesterPhone = freezed,
    Object? assignedTo = freezed,
    Object? attachments = null,
    Object? notes = freezed,
    Object? type = freezed,
    Object? scope = freezed,
    Object? ciType = freezed,
    Object? subcategory = freezed,
    Object? severity = freezed,
    Object? slaInMinutes = freezed,
    Object? slaType = freezed,
    Object? slaConsumedInMinutes = freezed,
    Object? expectedResolutionDate = freezed,
    Object? tenant = freezed,
    Object? externalId = freezed,
    Object? cis = freezed,
    Object? services = freezed,
    Object? serviceTypes = freezed,
    Object? closedDate = freezed,
    Object? apiNotes = freezed,
    Object? apiAttachments = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            impact: null == impact
                ? _value.impact
                : impact // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TicketStatus,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            requesterName: null == requesterName
                ? _value.requesterName
                : requesterName // ignore: cast_nullable_to_non_nullable
                      as String,
            requesterEmail: freezed == requesterEmail
                ? _value.requesterEmail
                : requesterEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            requesterPhone: freezed == requesterPhone
                ? _value.requesterPhone
                : requesterPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedTo: freezed == assignedTo
                ? _value.assignedTo
                : assignedTo // ignore: cast_nullable_to_non_nullable
                      as String?,
            attachments: null == attachments
                ? _value.attachments
                : attachments // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            scope: freezed == scope
                ? _value.scope
                : scope // ignore: cast_nullable_to_non_nullable
                      as String?,
            ciType: freezed == ciType
                ? _value.ciType
                : ciType // ignore: cast_nullable_to_non_nullable
                      as String?,
            subcategory: freezed == subcategory
                ? _value.subcategory
                : subcategory // ignore: cast_nullable_to_non_nullable
                      as String?,
            severity: freezed == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String?,
            slaInMinutes: freezed == slaInMinutes
                ? _value.slaInMinutes
                : slaInMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            slaType: freezed == slaType
                ? _value.slaType
                : slaType // ignore: cast_nullable_to_non_nullable
                      as String?,
            slaConsumedInMinutes: freezed == slaConsumedInMinutes
                ? _value.slaConsumedInMinutes
                : slaConsumedInMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            expectedResolutionDate: freezed == expectedResolutionDate
                ? _value.expectedResolutionDate
                : expectedResolutionDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            tenant: freezed == tenant
                ? _value.tenant
                : tenant // ignore: cast_nullable_to_non_nullable
                      as String?,
            externalId: freezed == externalId
                ? _value.externalId
                : externalId // ignore: cast_nullable_to_non_nullable
                      as String?,
            cis: freezed == cis
                ? _value.cis
                : cis // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            services: freezed == services
                ? _value.services
                : services // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            serviceTypes: freezed == serviceTypes
                ? _value.serviceTypes
                : serviceTypes // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            closedDate: freezed == closedDate
                ? _value.closedDate
                : closedDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            apiNotes: freezed == apiNotes
                ? _value.apiNotes
                : apiNotes // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            apiAttachments: freezed == apiAttachments
                ? _value.apiAttachments
                : apiAttachments // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketImplCopyWith<$Res> implements $TicketCopyWith<$Res> {
  factory _$$TicketImplCopyWith(
    _$TicketImpl value,
    $Res Function(_$TicketImpl) then,
  ) = __$$TicketImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'id') String id,
    @JsonKey(name: 'name') String title,
    @JsonKey(name: 'description') String description,
    @JsonKey(name: 'impact') String impact,
    @JsonKey(
      name: 'status',
      fromJson: _ticketStatusFromJson,
      toJson: _ticketStatusToJson,
    )
    TicketStatus status,
    @JsonKey(name: 'priority') String priority,
    @JsonKey(name: 'category') String category,
    @JsonKey(
      name: 'creationDate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    DateTime createdAt,
    @JsonKey(
      name: 'lastUpdate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    DateTime updatedAt,
    @JsonKey(
      name: 'resolutionDate',
      readValue: _readResolutionDate,
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    DateTime? resolvedAt,
    @JsonKey(name: 'createdBy') String requesterName,
    @JsonKey(name: 'requesterEmail') String? requesterEmail,
    @JsonKey(name: 'requesterPhone') String? requesterPhone,
    @JsonKey(name: 'createdByTeam') String? assignedTo,
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
    @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
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
    @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
    List<Map<String, dynamic>>? apiNotes,
    @JsonKey(
      name: 'attachments',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    List<Map<String, dynamic>>? apiAttachments,
  });
}

/// @nodoc
class __$$TicketImplCopyWithImpl<$Res>
    extends _$TicketCopyWithImpl<$Res, _$TicketImpl>
    implements _$$TicketImplCopyWith<$Res> {
  __$$TicketImplCopyWithImpl(
    _$TicketImpl _value,
    $Res Function(_$TicketImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? impact = null,
    Object? status = null,
    Object? priority = null,
    Object? category = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? resolvedAt = freezed,
    Object? requesterName = null,
    Object? requesterEmail = freezed,
    Object? requesterPhone = freezed,
    Object? assignedTo = freezed,
    Object? attachments = null,
    Object? notes = freezed,
    Object? type = freezed,
    Object? scope = freezed,
    Object? ciType = freezed,
    Object? subcategory = freezed,
    Object? severity = freezed,
    Object? slaInMinutes = freezed,
    Object? slaType = freezed,
    Object? slaConsumedInMinutes = freezed,
    Object? expectedResolutionDate = freezed,
    Object? tenant = freezed,
    Object? externalId = freezed,
    Object? cis = freezed,
    Object? services = freezed,
    Object? serviceTypes = freezed,
    Object? closedDate = freezed,
    Object? apiNotes = freezed,
    Object? apiAttachments = freezed,
  }) {
    return _then(
      _$TicketImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        impact: null == impact
            ? _value.impact
            : impact // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TicketStatus,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        requesterName: null == requesterName
            ? _value.requesterName
            : requesterName // ignore: cast_nullable_to_non_nullable
                  as String,
        requesterEmail: freezed == requesterEmail
            ? _value.requesterEmail
            : requesterEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        requesterPhone: freezed == requesterPhone
            ? _value.requesterPhone
            : requesterPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedTo: freezed == assignedTo
            ? _value.assignedTo
            : assignedTo // ignore: cast_nullable_to_non_nullable
                  as String?,
        attachments: null == attachments
            ? _value._attachments
            : attachments // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        scope: freezed == scope
            ? _value.scope
            : scope // ignore: cast_nullable_to_non_nullable
                  as String?,
        ciType: freezed == ciType
            ? _value.ciType
            : ciType // ignore: cast_nullable_to_non_nullable
                  as String?,
        subcategory: freezed == subcategory
            ? _value.subcategory
            : subcategory // ignore: cast_nullable_to_non_nullable
                  as String?,
        severity: freezed == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String?,
        slaInMinutes: freezed == slaInMinutes
            ? _value.slaInMinutes
            : slaInMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        slaType: freezed == slaType
            ? _value.slaType
            : slaType // ignore: cast_nullable_to_non_nullable
                  as String?,
        slaConsumedInMinutes: freezed == slaConsumedInMinutes
            ? _value.slaConsumedInMinutes
            : slaConsumedInMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        expectedResolutionDate: freezed == expectedResolutionDate
            ? _value.expectedResolutionDate
            : expectedResolutionDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        tenant: freezed == tenant
            ? _value.tenant
            : tenant // ignore: cast_nullable_to_non_nullable
                  as String?,
        externalId: freezed == externalId
            ? _value.externalId
            : externalId // ignore: cast_nullable_to_non_nullable
                  as String?,
        cis: freezed == cis
            ? _value._cis
            : cis // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        services: freezed == services
            ? _value._services
            : services // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        serviceTypes: freezed == serviceTypes
            ? _value._serviceTypes
            : serviceTypes // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        closedDate: freezed == closedDate
            ? _value.closedDate
            : closedDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        apiNotes: freezed == apiNotes
            ? _value._apiNotes
            : apiNotes // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        apiAttachments: freezed == apiAttachments
            ? _value._apiAttachments
            : apiAttachments // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TicketImpl extends _Ticket {
  const _$TicketImpl({
    @JsonKey(name: 'id') this.id = '',
    @JsonKey(name: 'name') this.title = '',
    @JsonKey(name: 'description') this.description = '--',
    @JsonKey(name: 'impact') this.impact = '',
    @JsonKey(
      name: 'status',
      fromJson: _ticketStatusFromJson,
      toJson: _ticketStatusToJson,
    )
    this.status = TicketStatus.open,
    @JsonKey(name: 'priority') this.priority = 'P3',
    @JsonKey(name: 'category') this.category = '',
    @JsonKey(
      name: 'creationDate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    required this.createdAt,
    @JsonKey(
      name: 'lastUpdate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    required this.updatedAt,
    @JsonKey(
      name: 'resolutionDate',
      readValue: _readResolutionDate,
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    this.resolvedAt,
    @JsonKey(name: 'createdBy') this.requesterName = '',
    @JsonKey(name: 'requesterEmail') this.requesterEmail,
    @JsonKey(name: 'requesterPhone') this.requesterPhone,
    @JsonKey(name: 'createdByTeam') this.assignedTo,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final List<String> attachments = const <String>[],
    @JsonKey(includeFromJson: false, includeToJson: false) this.notes,
    @JsonKey(name: 'type') this.type,
    @JsonKey(name: 'scope') this.scope,
    @JsonKey(name: 'ciType') this.ciType,
    @JsonKey(name: 'subcategory') this.subcategory,
    @JsonKey(name: 'severity') this.severity,
    @JsonKey(name: 'slaInMinutes') this.slaInMinutes,
    @JsonKey(name: 'slaType') this.slaType,
    @JsonKey(name: 'slaConsumedInMinutes') this.slaConsumedInMinutes,
    @JsonKey(
      name: 'expectedResolutionDate',
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    this.expectedResolutionDate,
    @JsonKey(name: 'tenant') this.tenant,
    @JsonKey(name: 'externalId') this.externalId,
    @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
    final List<Map<String, dynamic>>? cis,
    @JsonKey(
      name: 'services',
      fromJson: _stringListFromJson,
      toJson: _stringListToJson,
    )
    final List<String>? services,
    @JsonKey(
      name: 'serviceTypes',
      fromJson: _stringListFromJson,
      toJson: _stringListToJson,
    )
    final List<String>? serviceTypes,
    @JsonKey(
      name: 'closedDate',
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    this.closedDate,
    @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
    final List<Map<String, dynamic>>? apiNotes,
    @JsonKey(
      name: 'attachments',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    final List<Map<String, dynamic>>? apiAttachments,
  }) : _attachments = attachments,
       _cis = cis,
       _services = services,
       _serviceTypes = serviceTypes,
       _apiNotes = apiNotes,
       _apiAttachments = apiAttachments,
       super._();

  factory _$TicketImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'name')
  final String title;
  @override
  @JsonKey(name: 'description')
  final String description;
  @override
  @JsonKey(name: 'impact')
  final String impact;
  @override
  @JsonKey(
    name: 'status',
    fromJson: _ticketStatusFromJson,
    toJson: _ticketStatusToJson,
  )
  final TicketStatus status;
  @override
  @JsonKey(name: 'priority')
  final String priority;
  @override
  @JsonKey(name: 'category')
  final String category;
  @override
  @JsonKey(
    name: 'creationDate',
    fromJson: _parseDateTime,
    toJson: _dateToIsoString,
  )
  final DateTime createdAt;
  @override
  @JsonKey(
    name: 'lastUpdate',
    fromJson: _parseDateTime,
    toJson: _dateToIsoString,
  )
  final DateTime updatedAt;
  @override
  @JsonKey(
    name: 'resolutionDate',
    readValue: _readResolutionDate,
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  final DateTime? resolvedAt;
  @override
  @JsonKey(name: 'createdBy')
  final String requesterName;
  @override
  @JsonKey(name: 'requesterEmail')
  final String? requesterEmail;
  @override
  @JsonKey(name: 'requesterPhone')
  final String? requesterPhone;
  @override
  @JsonKey(name: 'createdByTeam')
  final String? assignedTo;
  final List<String> _attachments;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? notes;
  @override
  @JsonKey(name: 'type')
  final String? type;
  @override
  @JsonKey(name: 'scope')
  final String? scope;
  @override
  @JsonKey(name: 'ciType')
  final String? ciType;
  @override
  @JsonKey(name: 'subcategory')
  final String? subcategory;
  @override
  @JsonKey(name: 'severity')
  final String? severity;
  @override
  @JsonKey(name: 'slaInMinutes')
  final int? slaInMinutes;
  @override
  @JsonKey(name: 'slaType')
  final String? slaType;
  @override
  @JsonKey(name: 'slaConsumedInMinutes')
  final int? slaConsumedInMinutes;
  @override
  @JsonKey(
    name: 'expectedResolutionDate',
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  final DateTime? expectedResolutionDate;
  @override
  @JsonKey(name: 'tenant')
  final String? tenant;
  @override
  @JsonKey(name: 'externalId')
  final String? externalId;
  final List<Map<String, dynamic>>? _cis;
  @override
  @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
  List<Map<String, dynamic>>? get cis {
    final value = _cis;
    if (value == null) return null;
    if (_cis is EqualUnmodifiableListView) return _cis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _services;
  @override
  @JsonKey(
    name: 'services',
    fromJson: _stringListFromJson,
    toJson: _stringListToJson,
  )
  List<String>? get services {
    final value = _services;
    if (value == null) return null;
    if (_services is EqualUnmodifiableListView) return _services;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _serviceTypes;
  @override
  @JsonKey(
    name: 'serviceTypes',
    fromJson: _stringListFromJson,
    toJson: _stringListToJson,
  )
  List<String>? get serviceTypes {
    final value = _serviceTypes;
    if (value == null) return null;
    if (_serviceTypes is EqualUnmodifiableListView) return _serviceTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(
    name: 'closedDate',
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  final DateTime? closedDate;
  final List<Map<String, dynamic>>? _apiNotes;
  @override
  @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
  List<Map<String, dynamic>>? get apiNotes {
    final value = _apiNotes;
    if (value == null) return null;
    if (_apiNotes is EqualUnmodifiableListView) return _apiNotes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Map<String, dynamic>>? _apiAttachments;
  @override
  @JsonKey(
    name: 'attachments',
    fromJson: _mapListFromJson,
    toJson: _mapListToJson,
  )
  List<Map<String, dynamic>>? get apiAttachments {
    final value = _apiAttachments;
    if (value == null) return null;
    if (_apiAttachments is EqualUnmodifiableListView) return _apiAttachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Ticket(id: $id, title: $title, description: $description, impact: $impact, status: $status, priority: $priority, category: $category, createdAt: $createdAt, updatedAt: $updatedAt, resolvedAt: $resolvedAt, requesterName: $requesterName, requesterEmail: $requesterEmail, requesterPhone: $requesterPhone, assignedTo: $assignedTo, attachments: $attachments, notes: $notes, type: $type, scope: $scope, ciType: $ciType, subcategory: $subcategory, severity: $severity, slaInMinutes: $slaInMinutes, slaType: $slaType, slaConsumedInMinutes: $slaConsumedInMinutes, expectedResolutionDate: $expectedResolutionDate, tenant: $tenant, externalId: $externalId, cis: $cis, services: $services, serviceTypes: $serviceTypes, closedDate: $closedDate, apiNotes: $apiNotes, apiAttachments: $apiAttachments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.impact, impact) || other.impact == impact) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.requesterName, requesterName) ||
                other.requesterName == requesterName) &&
            (identical(other.requesterEmail, requesterEmail) ||
                other.requesterEmail == requesterEmail) &&
            (identical(other.requesterPhone, requesterPhone) ||
                other.requesterPhone == requesterPhone) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            const DeepCollectionEquality().equals(
              other._attachments,
              _attachments,
            ) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.ciType, ciType) || other.ciType == ciType) &&
            (identical(other.subcategory, subcategory) ||
                other.subcategory == subcategory) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.slaInMinutes, slaInMinutes) ||
                other.slaInMinutes == slaInMinutes) &&
            (identical(other.slaType, slaType) || other.slaType == slaType) &&
            (identical(other.slaConsumedInMinutes, slaConsumedInMinutes) ||
                other.slaConsumedInMinutes == slaConsumedInMinutes) &&
            (identical(other.expectedResolutionDate, expectedResolutionDate) ||
                other.expectedResolutionDate == expectedResolutionDate) &&
            (identical(other.tenant, tenant) || other.tenant == tenant) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId) &&
            const DeepCollectionEquality().equals(other._cis, _cis) &&
            const DeepCollectionEquality().equals(other._services, _services) &&
            const DeepCollectionEquality().equals(
              other._serviceTypes,
              _serviceTypes,
            ) &&
            (identical(other.closedDate, closedDate) ||
                other.closedDate == closedDate) &&
            const DeepCollectionEquality().equals(other._apiNotes, _apiNotes) &&
            const DeepCollectionEquality().equals(
              other._apiAttachments,
              _apiAttachments,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    description,
    impact,
    status,
    priority,
    category,
    createdAt,
    updatedAt,
    resolvedAt,
    requesterName,
    requesterEmail,
    requesterPhone,
    assignedTo,
    const DeepCollectionEquality().hash(_attachments),
    notes,
    type,
    scope,
    ciType,
    subcategory,
    severity,
    slaInMinutes,
    slaType,
    slaConsumedInMinutes,
    expectedResolutionDate,
    tenant,
    externalId,
    const DeepCollectionEquality().hash(_cis),
    const DeepCollectionEquality().hash(_services),
    const DeepCollectionEquality().hash(_serviceTypes),
    closedDate,
    const DeepCollectionEquality().hash(_apiNotes),
    const DeepCollectionEquality().hash(_apiAttachments),
  ]);

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      __$$TicketImplCopyWithImpl<_$TicketImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketImplToJson(this);
  }
}

abstract class _Ticket extends Ticket {
  const factory _Ticket({
    @JsonKey(name: 'id') final String id,
    @JsonKey(name: 'name') final String title,
    @JsonKey(name: 'description') final String description,
    @JsonKey(name: 'impact') final String impact,
    @JsonKey(
      name: 'status',
      fromJson: _ticketStatusFromJson,
      toJson: _ticketStatusToJson,
    )
    final TicketStatus status,
    @JsonKey(name: 'priority') final String priority,
    @JsonKey(name: 'category') final String category,
    @JsonKey(
      name: 'creationDate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    required final DateTime createdAt,
    @JsonKey(
      name: 'lastUpdate',
      fromJson: _parseDateTime,
      toJson: _dateToIsoString,
    )
    required final DateTime updatedAt,
    @JsonKey(
      name: 'resolutionDate',
      readValue: _readResolutionDate,
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    final DateTime? resolvedAt,
    @JsonKey(name: 'createdBy') final String requesterName,
    @JsonKey(name: 'requesterEmail') final String? requesterEmail,
    @JsonKey(name: 'requesterPhone') final String? requesterPhone,
    @JsonKey(name: 'createdByTeam') final String? assignedTo,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final List<String> attachments,
    @JsonKey(includeFromJson: false, includeToJson: false) final String? notes,
    @JsonKey(name: 'type') final String? type,
    @JsonKey(name: 'scope') final String? scope,
    @JsonKey(name: 'ciType') final String? ciType,
    @JsonKey(name: 'subcategory') final String? subcategory,
    @JsonKey(name: 'severity') final String? severity,
    @JsonKey(name: 'slaInMinutes') final int? slaInMinutes,
    @JsonKey(name: 'slaType') final String? slaType,
    @JsonKey(name: 'slaConsumedInMinutes') final int? slaConsumedInMinutes,
    @JsonKey(
      name: 'expectedResolutionDate',
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    final DateTime? expectedResolutionDate,
    @JsonKey(name: 'tenant') final String? tenant,
    @JsonKey(name: 'externalId') final String? externalId,
    @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
    final List<Map<String, dynamic>>? cis,
    @JsonKey(
      name: 'services',
      fromJson: _stringListFromJson,
      toJson: _stringListToJson,
    )
    final List<String>? services,
    @JsonKey(
      name: 'serviceTypes',
      fromJson: _stringListFromJson,
      toJson: _stringListToJson,
    )
    final List<String>? serviceTypes,
    @JsonKey(
      name: 'closedDate',
      fromJson: _parseOptionalDateTime,
      toJson: _dateToIsoNullable,
    )
    final DateTime? closedDate,
    @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
    final List<Map<String, dynamic>>? apiNotes,
    @JsonKey(
      name: 'attachments',
      fromJson: _mapListFromJson,
      toJson: _mapListToJson,
    )
    final List<Map<String, dynamic>>? apiAttachments,
  }) = _$TicketImpl;
  const _Ticket._() : super._();

  factory _Ticket.fromJson(Map<String, dynamic> json) = _$TicketImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'name')
  String get title;
  @override
  @JsonKey(name: 'description')
  String get description;
  @override
  @JsonKey(name: 'impact')
  String get impact;
  @override
  @JsonKey(
    name: 'status',
    fromJson: _ticketStatusFromJson,
    toJson: _ticketStatusToJson,
  )
  TicketStatus get status;
  @override
  @JsonKey(name: 'priority')
  String get priority;
  @override
  @JsonKey(name: 'category')
  String get category;
  @override
  @JsonKey(
    name: 'creationDate',
    fromJson: _parseDateTime,
    toJson: _dateToIsoString,
  )
  DateTime get createdAt;
  @override
  @JsonKey(
    name: 'lastUpdate',
    fromJson: _parseDateTime,
    toJson: _dateToIsoString,
  )
  DateTime get updatedAt;
  @override
  @JsonKey(
    name: 'resolutionDate',
    readValue: _readResolutionDate,
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  DateTime? get resolvedAt;
  @override
  @JsonKey(name: 'createdBy')
  String get requesterName;
  @override
  @JsonKey(name: 'requesterEmail')
  String? get requesterEmail;
  @override
  @JsonKey(name: 'requesterPhone')
  String? get requesterPhone;
  @override
  @JsonKey(name: 'createdByTeam')
  String? get assignedTo;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String> get attachments;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get notes;
  @override
  @JsonKey(name: 'type')
  String? get type;
  @override
  @JsonKey(name: 'scope')
  String? get scope;
  @override
  @JsonKey(name: 'ciType')
  String? get ciType;
  @override
  @JsonKey(name: 'subcategory')
  String? get subcategory;
  @override
  @JsonKey(name: 'severity')
  String? get severity;
  @override
  @JsonKey(name: 'slaInMinutes')
  int? get slaInMinutes;
  @override
  @JsonKey(name: 'slaType')
  String? get slaType;
  @override
  @JsonKey(name: 'slaConsumedInMinutes')
  int? get slaConsumedInMinutes;
  @override
  @JsonKey(
    name: 'expectedResolutionDate',
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  DateTime? get expectedResolutionDate;
  @override
  @JsonKey(name: 'tenant')
  String? get tenant;
  @override
  @JsonKey(name: 'externalId')
  String? get externalId;
  @override
  @JsonKey(name: 'cis', fromJson: _mapListFromJson, toJson: _mapListToJson)
  List<Map<String, dynamic>>? get cis;
  @override
  @JsonKey(
    name: 'services',
    fromJson: _stringListFromJson,
    toJson: _stringListToJson,
  )
  List<String>? get services;
  @override
  @JsonKey(
    name: 'serviceTypes',
    fromJson: _stringListFromJson,
    toJson: _stringListToJson,
  )
  List<String>? get serviceTypes;
  @override
  @JsonKey(
    name: 'closedDate',
    fromJson: _parseOptionalDateTime,
    toJson: _dateToIsoNullable,
  )
  DateTime? get closedDate;
  @override
  @JsonKey(name: 'notes', fromJson: _mapListFromJson, toJson: _mapListToJson)
  List<Map<String, dynamic>>? get apiNotes;
  @override
  @JsonKey(
    name: 'attachments',
    fromJson: _mapListFromJson,
    toJson: _mapListToJson,
  )
  List<Map<String, dynamic>>? get apiAttachments;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
