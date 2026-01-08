part of 'ticket_bloc.dart';

@freezed
class TicketState with _$TicketState {
  const factory TicketState({
    @Default([]) List<Ticket> tickets,
    @Default(true) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    @Default(false) bool hasLoadedOnce,
    Map<String, dynamic>? filterQuery,
    String? filterLabel,
    String? filterLabelKey,
    int? filterSourceId,
    @Default('') String searchTerm,
    String? error,
  }) = _TicketState;

  const TicketState._();

  /// Computed getter: whether initial loading has finished
  bool get hasFinishedLoading => hasLoadedOnce && !isLoading;

  /// Computed getter: whether ticket list is empty
  bool get isEmpty => tickets.isEmpty;

  /// Computed getter: whether to show empty state
  bool get shouldShowEmpty => hasFinishedLoading && isEmpty && error == null;

  /// Computed getter: whether an active filter is applied
  bool get hasActiveFilter => filterQuery != null || searchTerm.isNotEmpty;
}
