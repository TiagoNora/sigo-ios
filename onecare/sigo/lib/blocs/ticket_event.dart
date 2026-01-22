part of 'ticket_bloc.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialTickets extends TicketEvent {
  const LoadInitialTickets();
}

class RefreshTickets extends TicketEvent {
  const RefreshTickets();
}

class LoadMoreTickets extends TicketEvent {
  const LoadMoreTickets();
}

class ApplyFilter extends TicketEvent {
  const ApplyFilter({
    required this.filterQuery,
    this.filterLabel,
    this.filterLabelKey,
    this.filterSourceId,
  });

  final Map<String, dynamic>? filterQuery;
  final String? filterLabel;
  final String? filterLabelKey;
  final int? filterSourceId;

  @override
  List<Object?> get props => [
    filterQuery,
    filterLabel,
    filterLabelKey,
    filterSourceId,
  ];
}

class ApplySearch extends TicketEvent {
  const ApplySearch(this.term);
  final String term;

  @override
  List<Object?> get props => [term];
}

class ClearTickets extends TicketEvent {
  const ClearTickets();
}
