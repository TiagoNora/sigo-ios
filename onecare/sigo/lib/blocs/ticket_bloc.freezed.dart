// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TicketState {
  List<Ticket> get tickets => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  bool get hasLoadedOnce => throw _privateConstructorUsedError;
  Map<String, dynamic>? get filterQuery => throw _privateConstructorUsedError;
  String? get filterLabel => throw _privateConstructorUsedError;
  String? get filterLabelKey => throw _privateConstructorUsedError;
  int? get filterSourceId => throw _privateConstructorUsedError;
  String get searchTerm => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of TicketState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketStateCopyWith<TicketState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketStateCopyWith<$Res> {
  factory $TicketStateCopyWith(
    TicketState value,
    $Res Function(TicketState) then,
  ) = _$TicketStateCopyWithImpl<$Res, TicketState>;
  @useResult
  $Res call({
    List<Ticket> tickets,
    bool isLoading,
    bool isLoadingMore,
    bool hasMore,
    bool hasLoadedOnce,
    Map<String, dynamic>? filterQuery,
    String? filterLabel,
    String? filterLabelKey,
    int? filterSourceId,
    String searchTerm,
    String? error,
  });
}

/// @nodoc
class _$TicketStateCopyWithImpl<$Res, $Val extends TicketState>
    implements $TicketStateCopyWith<$Res> {
  _$TicketStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tickets = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasMore = null,
    Object? hasLoadedOnce = null,
    Object? filterQuery = freezed,
    Object? filterLabel = freezed,
    Object? filterLabelKey = freezed,
    Object? filterSourceId = freezed,
    Object? searchTerm = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            tickets: null == tickets
                ? _value.tickets
                : tickets // ignore: cast_nullable_to_non_nullable
                      as List<Ticket>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoadingMore: null == isLoadingMore
                ? _value.isLoadingMore
                : isLoadingMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasLoadedOnce: null == hasLoadedOnce
                ? _value.hasLoadedOnce
                : hasLoadedOnce // ignore: cast_nullable_to_non_nullable
                      as bool,
            filterQuery: freezed == filterQuery
                ? _value.filterQuery
                : filterQuery // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            filterLabel: freezed == filterLabel
                ? _value.filterLabel
                : filterLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterLabelKey: freezed == filterLabelKey
                ? _value.filterLabelKey
                : filterLabelKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            filterSourceId: freezed == filterSourceId
                ? _value.filterSourceId
                : filterSourceId // ignore: cast_nullable_to_non_nullable
                      as int?,
            searchTerm: null == searchTerm
                ? _value.searchTerm
                : searchTerm // ignore: cast_nullable_to_non_nullable
                      as String,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketStateImplCopyWith<$Res>
    implements $TicketStateCopyWith<$Res> {
  factory _$$TicketStateImplCopyWith(
    _$TicketStateImpl value,
    $Res Function(_$TicketStateImpl) then,
  ) = __$$TicketStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Ticket> tickets,
    bool isLoading,
    bool isLoadingMore,
    bool hasMore,
    bool hasLoadedOnce,
    Map<String, dynamic>? filterQuery,
    String? filterLabel,
    String? filterLabelKey,
    int? filterSourceId,
    String searchTerm,
    String? error,
  });
}

/// @nodoc
class __$$TicketStateImplCopyWithImpl<$Res>
    extends _$TicketStateCopyWithImpl<$Res, _$TicketStateImpl>
    implements _$$TicketStateImplCopyWith<$Res> {
  __$$TicketStateImplCopyWithImpl(
    _$TicketStateImpl _value,
    $Res Function(_$TicketStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tickets = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasMore = null,
    Object? hasLoadedOnce = null,
    Object? filterQuery = freezed,
    Object? filterLabel = freezed,
    Object? filterLabelKey = freezed,
    Object? filterSourceId = freezed,
    Object? searchTerm = null,
    Object? error = freezed,
  }) {
    return _then(
      _$TicketStateImpl(
        tickets: null == tickets
            ? _value._tickets
            : tickets // ignore: cast_nullable_to_non_nullable
                  as List<Ticket>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoadingMore: null == isLoadingMore
            ? _value.isLoadingMore
            : isLoadingMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasLoadedOnce: null == hasLoadedOnce
            ? _value.hasLoadedOnce
            : hasLoadedOnce // ignore: cast_nullable_to_non_nullable
                  as bool,
        filterQuery: freezed == filterQuery
            ? _value._filterQuery
            : filterQuery // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        filterLabel: freezed == filterLabel
            ? _value.filterLabel
            : filterLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterLabelKey: freezed == filterLabelKey
            ? _value.filterLabelKey
            : filterLabelKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        filterSourceId: freezed == filterSourceId
            ? _value.filterSourceId
            : filterSourceId // ignore: cast_nullable_to_non_nullable
                  as int?,
        searchTerm: null == searchTerm
            ? _value.searchTerm
            : searchTerm // ignore: cast_nullable_to_non_nullable
                  as String,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$TicketStateImpl extends _TicketState with DiagnosticableTreeMixin {
  const _$TicketStateImpl({
    final List<Ticket> tickets = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.hasLoadedOnce = false,
    final Map<String, dynamic>? filterQuery,
    this.filterLabel,
    this.filterLabelKey,
    this.filterSourceId,
    this.searchTerm = '',
    this.error,
  }) : _tickets = tickets,
       _filterQuery = filterQuery,
       super._();

  final List<Ticket> _tickets;
  @override
  @JsonKey()
  List<Ticket> get tickets {
    if (_tickets is EqualUnmodifiableListView) return _tickets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tickets);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final bool hasLoadedOnce;
  final Map<String, dynamic>? _filterQuery;
  @override
  Map<String, dynamic>? get filterQuery {
    final value = _filterQuery;
    if (value == null) return null;
    if (_filterQuery is EqualUnmodifiableMapView) return _filterQuery;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? filterLabel;
  @override
  final String? filterLabelKey;
  @override
  final int? filterSourceId;
  @override
  @JsonKey()
  final String searchTerm;
  @override
  final String? error;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TicketState(tickets: $tickets, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, hasLoadedOnce: $hasLoadedOnce, filterQuery: $filterQuery, filterLabel: $filterLabel, filterLabelKey: $filterLabelKey, filterSourceId: $filterSourceId, searchTerm: $searchTerm, error: $error)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'TicketState'))
      ..add(DiagnosticsProperty('tickets', tickets))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('isLoadingMore', isLoadingMore))
      ..add(DiagnosticsProperty('hasMore', hasMore))
      ..add(DiagnosticsProperty('hasLoadedOnce', hasLoadedOnce))
      ..add(DiagnosticsProperty('filterQuery', filterQuery))
      ..add(DiagnosticsProperty('filterLabel', filterLabel))
      ..add(DiagnosticsProperty('filterLabelKey', filterLabelKey))
      ..add(DiagnosticsProperty('filterSourceId', filterSourceId))
      ..add(DiagnosticsProperty('searchTerm', searchTerm))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketStateImpl &&
            const DeepCollectionEquality().equals(other._tickets, _tickets) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.hasLoadedOnce, hasLoadedOnce) ||
                other.hasLoadedOnce == hasLoadedOnce) &&
            const DeepCollectionEquality().equals(
              other._filterQuery,
              _filterQuery,
            ) &&
            (identical(other.filterLabel, filterLabel) ||
                other.filterLabel == filterLabel) &&
            (identical(other.filterLabelKey, filterLabelKey) ||
                other.filterLabelKey == filterLabelKey) &&
            (identical(other.filterSourceId, filterSourceId) ||
                other.filterSourceId == filterSourceId) &&
            (identical(other.searchTerm, searchTerm) ||
                other.searchTerm == searchTerm) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_tickets),
    isLoading,
    isLoadingMore,
    hasMore,
    hasLoadedOnce,
    const DeepCollectionEquality().hash(_filterQuery),
    filterLabel,
    filterLabelKey,
    filterSourceId,
    searchTerm,
    error,
  );

  /// Create a copy of TicketState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketStateImplCopyWith<_$TicketStateImpl> get copyWith =>
      __$$TicketStateImplCopyWithImpl<_$TicketStateImpl>(this, _$identity);
}

abstract class _TicketState extends TicketState {
  const factory _TicketState({
    final List<Ticket> tickets,
    final bool isLoading,
    final bool isLoadingMore,
    final bool hasMore,
    final bool hasLoadedOnce,
    final Map<String, dynamic>? filterQuery,
    final String? filterLabel,
    final String? filterLabelKey,
    final int? filterSourceId,
    final String searchTerm,
    final String? error,
  }) = _$TicketStateImpl;
  const _TicketState._() : super._();

  @override
  List<Ticket> get tickets;
  @override
  bool get isLoading;
  @override
  bool get isLoadingMore;
  @override
  bool get hasMore;
  @override
  bool get hasLoadedOnce;
  @override
  Map<String, dynamic>? get filterQuery;
  @override
  String? get filterLabel;
  @override
  String? get filterLabelKey;
  @override
  int? get filterSourceId;
  @override
  String get searchTerm;
  @override
  String? get error;

  /// Create a copy of TicketState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketStateImplCopyWith<_$TicketStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
