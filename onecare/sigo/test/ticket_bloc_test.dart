import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/blocs/ticket_bloc.dart';
import 'package:sigo/domain/repositories/auth_repository.dart';
import 'package:sigo/domain/repositories/priority_repository.dart';
import 'package:sigo/domain/repositories/ticket_repository.dart';
import 'package:sigo/domain/repositories/user_repository.dart';
import 'package:sigo/models/logout_reason.dart';
import 'package:sigo/models/priority.dart';
import 'package:sigo/models/tenant_config.dart';
import 'package:sigo/models/ticket.dart';
import 'package:sigo/models/ticket_statistics.dart';
import 'package:sigo/models/user.dart';

class _FakeTicketRepository implements TicketRepository {
  _FakeTicketRepository({
    List<Ticket>? ticketsToReturn,
    List<Ticket>? searchResults,
    bool hasMore = true,
  })  : _ticketsToReturn = ticketsToReturn ?? <Ticket>[],
        _searchResults = searchResults ?? <Ticket>[],
        _hasMore = hasMore;

  List<Ticket> _ticketsToReturn;
  List<Ticket> _searchResults;
  bool _hasMore;

  int? lastPage;
  Map<String, dynamic>? lastQuery;
  String? lastSearchTerm;

  set ticketsToReturn(List<Ticket> value) => _ticketsToReturn = value;
  set searchResults(List<Ticket> value) => _searchResults = value;
  set hasMore(bool value) => _hasMore = value;

  @override
  bool get hasMore => _hasMore;

  @override
  bool get isLoading => false;

  @override
  Future<List<Ticket>> getTickets({
    int page = 0,
    int pageSize = 20,
    Map<String, dynamic>? query,
  }) async {
    lastPage = page;
    lastQuery = query;
    return _ticketsToReturn;
  }

  @override
  Future<Ticket?> getTicketById(String id) async {
    for (final ticket in _ticketsToReturn) {
      if (ticket.id == id) return ticket;
    }
    return null;
  }

  @override
  Future<Ticket> createTicket(Map<String, dynamic> ticketData) async {
    return _ticketsToReturn.isNotEmpty
        ? _ticketsToReturn.first
        : _makeTicket('created', DateTime(2024, 1, 1));
  }

  @override
  Future<Ticket> updateTicket(String id, Map<String, dynamic> updates) async {
    return _ticketsToReturn.isNotEmpty
        ? _ticketsToReturn.first
        : _makeTicket('updated', DateTime(2024, 1, 1));
  }

  @override
  Future<void> deleteTicket(String id) async {}

  @override
  Future<List<Ticket>> searchTickets(String searchTerm) async {
    lastSearchTerm = searchTerm;
    return _searchResults;
  }

  @override
  Stream<List<Ticket>> watchTickets() => const Stream.empty();

  @override
  List<Ticket> getAllTickets() => _ticketsToReturn;

  @override
  List<Ticket> getTicketsByStatus(TicketStatus status) =>
      _ticketsToReturn.where((ticket) => ticket.status == status).toList();

  @override
  List<Ticket> getTicketsByPriority(TicketPriority priority) =>
      _ticketsToReturn.where((ticket) => ticket.priority == priority.toApiValue()).toList();

  @override
  TicketStatistics getStatistics() => TicketStatistics(total: _ticketsToReturn.length);
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Map<String, String> buildAuthorizationUrl() => const {'url': '', 'state': ''};

  @override
  Future<bool> exchangeCodeForTokens(String code) async => false;

  @override
  Future<bool> refreshTokens() async => false;

  @override
  Future<void> fetchUserInfo() async {}

  @override
  Map<String, String>? getLogoutUrl() => null;

  @override
  Future<void> logout({LogoutReason reason = LogoutReason.userRequested}) async {}

  @override
  bool get isAuthenticated => true;

  @override
  bool get isInitializing => false;

  @override
  bool get isTokenExpired => false;

  @override
  String? get accessToken => null;

  @override
  String? get idToken => null;

  @override
  String? get userId => null;

  @override
  User? get currentUser => null;

  @override
  String get redirectUri => '';

  @override
  TenantConfig? get tenantConfig => null;

  @override
  Stream<User?> get userStream => const Stream.empty();

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic get authService => null;

  @override
  LogoutReason get lastLogoutReason => LogoutReason.userRequested;
}

class _FakePriorityRepository implements PriorityRepository {
  @override
  Future<void> loadPriorities() async {}

  @override
  Priority? getPriorityByName(String name) => null;

  @override
  Color parseColor(String? colorString) => Colors.grey;

  @override
  List<Priority> get priorities => const [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<Map<String, dynamic>> getUserInfo() async => {};

  @override
  Future<Map<String, dynamic>> getWorkbenchById(int workbenchId) async => {};

  @override
  Future<Map<String, dynamic>?> getDefaultFilter() async => null;

  @override
  Future<List<dynamic>> getUserTeams() async => [];

  @override
  Future<void> updateDefaultTeam(String teamName) async {}
}

Ticket _makeTicket(String id, DateTime createdAt) {
  return Ticket(
    id: id,
    title: 'Ticket $id',
    description: 'Desc $id',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  group('TicketBloc', () {
    test('initial state has isLoading=true and empty tickets', () {
      final bloc = TicketBloc(
        _FakeTicketRepository(),
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      expect(bloc.state.isLoading, true);
      expect(bloc.state.tickets, isEmpty);
      expect(bloc.state.hasMore, true);
      expect(bloc.state.hasLoadedOnce, false);
      bloc.close();
    });

    test('LoadInitialTickets emits loading then results', () async {
      final tickets = [
        _makeTicket('1', DateTime(2024, 1, 1)),
        _makeTicket('2', DateTime(2024, 1, 2)),
      ];
      final ticketRepository = _FakeTicketRepository(ticketsToReturn: tickets);
      final bloc = TicketBloc(
        ticketRepository,
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', true)
              .having((state) => state.hasLoadedOnce, 'hasLoadedOnce', false),
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', false)
              .having((state) => state.tickets, 'tickets', tickets)
              .having((state) => state.hasLoadedOnce, 'hasLoadedOnce', true),
        ]),
      );

      bloc.add(const LoadInitialTickets());
      await future;
      await bloc.close();
    });

    test('LoadInitialTickets with empty results sets hasMore=false', () async {
      final ticketRepository = _FakeTicketRepository(
        ticketsToReturn: [],
        hasMore: false,
      );
      final bloc = TicketBloc(
        ticketRepository,
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TicketState>().having((state) => state.isLoading, 'isLoading', true),
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', false)
              .having((state) => state.tickets, 'tickets', isEmpty)
              .having((state) => state.hasMore, 'hasMore', false),
        ]),
      );

      bloc.add(const LoadInitialTickets());
      await future;
      await bloc.close();
    });

    test('RefreshTickets reloads from page 0', () async {
      final initialTickets = [_makeTicket('old', DateTime(2024, 1, 1))];
      final refreshedTickets = [
        _makeTicket('new1', DateTime(2024, 1, 2)),
        _makeTicket('new2', DateTime(2024, 1, 3)),
      ];

      final ticketRepository = _FakeTicketRepository(ticketsToReturn: initialTickets);
      final bloc = TicketBloc(
        ticketRepository,
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      // Load initial tickets
      bloc.add(const LoadInitialTickets());
      await bloc.stream.firstWhere((state) => !state.isLoading);

      // Change the repository to return different tickets
      ticketRepository.ticketsToReturn = refreshedTickets;

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TicketState>().having((state) => state.isLoading, 'isLoading', true),
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', false)
              .having((state) => state.tickets, 'tickets', refreshedTickets),
        ]),
      );

      bloc.add(const RefreshTickets());
      await future;
      expect(ticketRepository.lastPage, 0);
      await bloc.close();
    });

    test('ApplySearch emits loading then results', () async {
      final tickets = [
        _makeTicket('1', DateTime(2024, 1, 1)),
        _makeTicket('2', DateTime(2024, 1, 2)),
      ];
      final ticketRepository = _FakeTicketRepository(searchResults: tickets, hasMore: false);
      final bloc = TicketBloc(
        ticketRepository,
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', true)
              .having((state) => state.searchTerm, 'searchTerm', 'abc'),
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', false)
              .having((state) => state.tickets, 'tickets', tickets)
              .having((state) => state.hasMore, 'hasMore', false),
        ]),
      );

      bloc.add(const ApplySearch('abc'));
      await future;
      expect(ticketRepository.lastSearchTerm, 'abc');
      await bloc.close();
    });

    test('ApplyFilter normalizes query and updates filter metadata', () async {
      final tickets = [_makeTicket('10', DateTime(2024, 2, 1))];
      final ticketRepository = _FakeTicketRepository(ticketsToReturn: tickets);
      final bloc = TicketBloc(
        ticketRepository,
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      final baseQuery = {
        'name': 'base',
        'operator': 'AND',
        'conditions': [
          {'attribute': 'status', 'operator': 'eq', 'value': 'OPEN'},
        ],
      };

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', true)
              .having((state) => state.filterLabel, 'filterLabel', 'My Filter')
              .having((state) => state.filterLabelKey, 'filterLabelKey', 'filter.key')
              .having((state) => state.filterSourceId, 'filterSourceId', 7),
          isA<TicketState>()
              .having((state) => state.isLoading, 'isLoading', false)
              .having((state) => state.tickets, 'tickets', tickets),
        ]),
      );

      bloc.add(
        ApplyFilter(
          filterQuery: baseQuery,
          filterLabel: 'My Filter',
          filterLabelKey: 'filter.key',
          filterSourceId: 7,
        ),
      );

      await future;
      expect(ticketRepository.lastQuery, isNotNull);
      expect(ticketRepository.lastQuery, isNot(same(baseQuery)));
      await bloc.close();
    });

    test('LoadMore requests next page based on current ticket count', () async {
      final initialTickets = List.generate(
        40,
        (index) => _makeTicket('seed-$index', DateTime(2024, 3, 1, 0, index)),
      );
      final combinedTickets = List.generate(
        60,
        (index) => _makeTicket('all-$index', DateTime(2024, 3, 1, 0, index)),
      );

      final ticketRepository = _FakeTicketRepository(
        searchResults: initialTickets,
        ticketsToReturn: combinedTickets,
        hasMore: true,
      );
      final bloc = TicketBloc(
        ticketRepository,
        _FakeAuthRepository(),
        _FakePriorityRepository(),
        _FakeUserRepository(),
      );

      bloc.add(const ApplySearch('seed'));
      await bloc.stream.firstWhere((state) => !state.isLoading);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TicketState>()
              .having((state) => state.isLoadingMore, 'isLoadingMore', true),
          isA<TicketState>()
              .having((state) => state.isLoadingMore, 'isLoadingMore', false),
        ]),
      );

      bloc.add(const LoadMoreTickets());
      await future;
      expect(ticketRepository.lastPage, 2);
      await bloc.close();
    });
  });
}
