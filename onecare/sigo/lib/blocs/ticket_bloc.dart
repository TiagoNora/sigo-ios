import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../models/ticket.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/ticket_repository.dart';
import '../domain/repositories/priority_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../constants/api_constants.dart';

part 'ticket_event.dart';
part 'ticket_state.dart';
part 'ticket_bloc.freezed.dart';

/// Business Logic Component for managing ticket state and operations.
///
/// This BLoC handles all ticket-related operations including:
/// - Loading and paginating tickets
/// - Applying filters and search
/// - Refreshing ticket lists
/// - Loading default user filters
/// - Managing ticket state (loading, loaded, error)
///
/// The TicketBloc uses the Repository pattern to interact with data sources
/// and emits immutable [TicketState] objects through a stream.
///
/// ## Events Handled:
/// - [LoadInitialTickets]: Loads the first page of tickets
/// - [RefreshTickets]: Refreshes the current ticket list
/// - [LoadMoreTickets]: Loads the next page (infinite scroll pagination)
/// - [ApplyFilter]: Applies a filter query to tickets
/// - [ApplySearch]: Searches tickets by search term
///
/// ## Dependencies:
/// - [TicketRepository]: Handles ticket data operations
/// - [AuthRepository]: Provides authentication state and user info
/// - [PriorityRepository]: Manages priority data for ticket filtering
/// - [UserRepository]: Handles user-specific operations like default filters
///
/// ## Usage Example:
/// ```dart
/// final ticketBloc = context.read<TicketBloc>();
/// ticketBloc.add(const LoadInitialTickets());
///
/// // In a widget:
/// BlocBuilder<TicketBloc, TicketState>(
///   builder: (context, state) {
///     if (state.isLoading) return CircularProgressIndicator();
///     return ListView(children: state.tickets.map(...));
///   },
/// )
/// ```
@injectable
class TicketBloc extends Bloc<TicketEvent, TicketState> {
  TicketBloc(
    this.ticketRepository,
    this.authRepository,
    this.priorityRepository,
    this.userRepository,
  ) : super(const TicketState()) {
    on<LoadInitialTickets>(_onLoadInitial);
    on<RefreshTickets>(_onRefresh);
    on<LoadMoreTickets>(_onLoadMore);
    on<ApplyFilter>(_onApplyFilter);
    on<ApplySearch>(_onApplySearch);
    on<ClearTickets>(_onClearTickets);

    _authSubscription = authRepository.userStream.listen((user) {
      if (user == null) {
        _lastUserKey = null;
        add(const ClearTickets());
        return;
      }

      final currentKey = user.username.trim();
      if (_lastUserKey != null && _lastUserKey != currentKey) {
        add(const ClearTickets());
        add(const LoadInitialTickets());
      }
      _lastUserKey = currentKey;
    });
  }

  final TicketRepository ticketRepository;
  final AuthRepository authRepository;
  final PriorityRepository priorityRepository;
  final UserRepository userRepository;
  StreamSubscription? _authSubscription;
  String? _lastUserKey;

  Future<void> _onLoadInitial(
    LoadInitialTickets event,
    Emitter<TicketState> emit,
  ) async {
    if (state.isLoading) {
      return;
    }
    try {
      await authRepository.ready;
      if (!authRepository.isAuthenticated) return;
      emit(state.copyWith(isLoading: true, error: null));
      // Priorities are loaded by PriorityRepository when needed
      await _loadDefaultFilterIfAny(emit);

      // Always load from network - no caching
      final tickets = await ticketRepository.getTickets(query: state.filterQuery);

      emit(
        state.copyWith(
          tickets: tickets,
          hasMore: ticketRepository.hasMore,
          isLoading: false,
          hasLoadedOnce: true,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          tickets: [],
          hasMore: false,
          isLoading: false,
          hasLoadedOnce: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefresh(
    RefreshTickets event,
    Emitter<TicketState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      if (state.filterQuery == null) {
        await _loadDefaultFilterIfAny(emit);
      }

      // Always load from network - no caching
      final tickets = await ticketRepository.getTickets(query: state.filterQuery);

      emit(
        state.copyWith(
          tickets: tickets,
          hasMore: ticketRepository.hasMore,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          tickets: [],
          hasMore: false,
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreTickets event,
    Emitter<TicketState> emit,
  ) async {
    if (state.isLoading || !state.hasLoadedOnce) return;
    if (ticketRepository.isLoading || !ticketRepository.hasMore) return;
    try {
      emit(state.copyWith(isLoadingMore: true, error: null));

      // Calculate current page based on tickets loaded
      final pageSize = ApiConstants.defaultPageSize;
      final currentPage = (state.tickets.length / pageSize).floor();
      final tickets = await ticketRepository.getTickets(
        page: currentPage,
        pageSize: pageSize,
        query: state.filterQuery,
      );

      emit(
        state.copyWith(
          tickets: tickets,
          hasMore: ticketRepository.hasMore,
          isLoadingMore: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<TicketState> emit,
  ) async {
    try {
      final normalizedQuery = _normalizeQuery(event.filterQuery);
      emit(
        state.copyWith(
          isLoading: true,
          filterQuery: normalizedQuery,
          filterLabel: event.filterLabel,
          filterLabelKey: event.filterLabelKey,
          filterSourceId: event.filterSourceId,
          error: null,
        ),
      );

      final tickets = await ticketRepository.getTickets(query: normalizedQuery);
      emit(
        state.copyWith(
          tickets: tickets,
          hasMore: ticketRepository.hasMore,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onApplySearch(
    ApplySearch event,
    Emitter<TicketState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, searchTerm: event.term, error: null));
      final tickets = await ticketRepository.searchTickets(event.term);
      emit(
        state.copyWith(
          tickets: tickets,
          hasMore: ticketRepository.hasMore,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onClearTickets(
    ClearTickets event,
    Emitter<TicketState> emit,
  ) async {
    await ticketRepository.clearCache();
    emit(
      state.copyWith(
        tickets: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        hasLoadedOnce: false,
        filterQuery: null,
        filterLabel: null,
        filterLabelKey: null,
        filterSourceId: null,
        searchTerm: '',
        error: null,
      ),
    );
  }

  Future<void> _loadDefaultFilterIfAny(Emitter<TicketState> emit) async{
    try {
      if (!authRepository.isAuthenticated) return;

      final defaultFilter = await userRepository.getDefaultFilter();
      if (defaultFilter == null) return;

      final filterQuery = defaultFilter['filterQuery'] as Map<String, dynamic>?;
      final filterName = defaultFilter['filterName'] as String?;
      final filterId = defaultFilter['filterId'] as int?;

      if (filterQuery != null) {
        emit(
          state.copyWith(
            filterQuery: _normalizeQuery(filterQuery),
            filterLabel: filterName,
            filterLabelKey: null,
            filterSourceId: filterId,
          ),
        );
      }
    } catch (e) {
      // Default filter is optional, log but don't fail
      debugPrint('Failed to load default filter: $e');
    }
  }

  Map<String, dynamic>? _normalizeQuery(Map<String, dynamic>? query) {
    if (query == null) return null;
    try {
      return json.decode(json.encode(query)) as Map<String, dynamic>;
    } catch (_) {
      return query;
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
