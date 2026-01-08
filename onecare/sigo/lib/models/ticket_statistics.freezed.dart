// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TicketStatistics {
  int get total => throw _privateConstructorUsedError;
  int get open => throw _privateConstructorUsedError;
  int get inProgress => throw _privateConstructorUsedError;
  int get resolved => throw _privateConstructorUsedError;
  int get closed => throw _privateConstructorUsedError;

  /// Create a copy of TicketStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketStatisticsCopyWith<TicketStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketStatisticsCopyWith<$Res> {
  factory $TicketStatisticsCopyWith(
    TicketStatistics value,
    $Res Function(TicketStatistics) then,
  ) = _$TicketStatisticsCopyWithImpl<$Res, TicketStatistics>;
  @useResult
  $Res call({int total, int open, int inProgress, int resolved, int closed});
}

/// @nodoc
class _$TicketStatisticsCopyWithImpl<$Res, $Val extends TicketStatistics>
    implements $TicketStatisticsCopyWith<$Res> {
  _$TicketStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TicketStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? open = null,
    Object? inProgress = null,
    Object? resolved = null,
    Object? closed = null,
  }) {
    return _then(
      _value.copyWith(
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            open: null == open
                ? _value.open
                : open // ignore: cast_nullable_to_non_nullable
                      as int,
            inProgress: null == inProgress
                ? _value.inProgress
                : inProgress // ignore: cast_nullable_to_non_nullable
                      as int,
            resolved: null == resolved
                ? _value.resolved
                : resolved // ignore: cast_nullable_to_non_nullable
                      as int,
            closed: null == closed
                ? _value.closed
                : closed // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TicketStatisticsImplCopyWith<$Res>
    implements $TicketStatisticsCopyWith<$Res> {
  factory _$$TicketStatisticsImplCopyWith(
    _$TicketStatisticsImpl value,
    $Res Function(_$TicketStatisticsImpl) then,
  ) = __$$TicketStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, int open, int inProgress, int resolved, int closed});
}

/// @nodoc
class __$$TicketStatisticsImplCopyWithImpl<$Res>
    extends _$TicketStatisticsCopyWithImpl<$Res, _$TicketStatisticsImpl>
    implements _$$TicketStatisticsImplCopyWith<$Res> {
  __$$TicketStatisticsImplCopyWithImpl(
    _$TicketStatisticsImpl _value,
    $Res Function(_$TicketStatisticsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TicketStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? open = null,
    Object? inProgress = null,
    Object? resolved = null,
    Object? closed = null,
  }) {
    return _then(
      _$TicketStatisticsImpl(
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        open: null == open
            ? _value.open
            : open // ignore: cast_nullable_to_non_nullable
                  as int,
        inProgress: null == inProgress
            ? _value.inProgress
            : inProgress // ignore: cast_nullable_to_non_nullable
                  as int,
        resolved: null == resolved
            ? _value.resolved
            : resolved // ignore: cast_nullable_to_non_nullable
                  as int,
        closed: null == closed
            ? _value.closed
            : closed // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$TicketStatisticsImpl extends _TicketStatistics {
  const _$TicketStatisticsImpl({
    this.total = 0,
    this.open = 0,
    this.inProgress = 0,
    this.resolved = 0,
    this.closed = 0,
  }) : super._();

  @override
  @JsonKey()
  final int total;
  @override
  @JsonKey()
  final int open;
  @override
  @JsonKey()
  final int inProgress;
  @override
  @JsonKey()
  final int resolved;
  @override
  @JsonKey()
  final int closed;

  @override
  String toString() {
    return 'TicketStatistics(total: $total, open: $open, inProgress: $inProgress, resolved: $resolved, closed: $closed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketStatisticsImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.inProgress, inProgress) ||
                other.inProgress == inProgress) &&
            (identical(other.resolved, resolved) ||
                other.resolved == resolved) &&
            (identical(other.closed, closed) || other.closed == closed));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, total, open, inProgress, resolved, closed);

  /// Create a copy of TicketStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketStatisticsImplCopyWith<_$TicketStatisticsImpl> get copyWith =>
      __$$TicketStatisticsImplCopyWithImpl<_$TicketStatisticsImpl>(
        this,
        _$identity,
      );
}

abstract class _TicketStatistics extends TicketStatistics {
  const factory _TicketStatistics({
    final int total,
    final int open,
    final int inProgress,
    final int resolved,
    final int closed,
  }) = _$TicketStatisticsImpl;
  const _TicketStatistics._() : super._();

  @override
  int get total;
  @override
  int get open;
  @override
  int get inProgress;
  @override
  int get resolved;
  @override
  int get closed;

  /// Create a copy of TicketStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketStatisticsImplCopyWith<_$TicketStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
