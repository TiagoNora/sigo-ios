/// Mock implementations of repository interfaces for testing.
///
/// These mocks can be used in unit and widget tests to replace real
/// repository implementations with controlled test doubles.
library;

import 'package:sigo/domain/repositories/auth_repository.dart';
import 'package:sigo/domain/repositories/ticket_repository.dart';
import 'package:sigo/models/logout_reason.dart';
import 'package:sigo/models/tenant_config.dart';
import 'package:sigo/models/ticket.dart';
import 'package:sigo/models/ticket_statistics.dart';
import 'package:sigo/models/user.dart';

/// Mock implementation of [AuthRepository] for testing.
///
/// Provides controllable authentication behavior for tests.
class MockAuthRepository implements AuthRepository {
  bool _isAuthenticated = false;
  bool _isInitializing = false;
  bool _isTokenExpired = false;
  LogoutReason _lastLogoutReason = LogoutReason.userRequested;
  String? _accessToken;
  String? _idToken;
  String? _userId;

  @override
  Map<String, String> buildAuthorizationUrl() {
    return {
      'url': 'https://mock.auth.url/authorize',
      'state': 'mock_state_123',
    };
  }

  @override
  Future<bool> exchangeCodeForTokens(String code) async {
    if (code.isNotEmpty) {
      _isAuthenticated = true;
      _accessToken = 'mock_access_token';
      _idToken = 'mock_id_token';
      _userId = 'mock_user_id';
      return true;
    }
    return false;
  }

  @override
  Future<bool> refreshTokens() async {
    if (_isAuthenticated) {
      _accessToken = 'mock_refreshed_token';
      return true;
    }
    return false;
  }

  @override
  Future<void> fetchUserInfo() async {
    // Mock user info fetch
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Map<String, String>? getLogoutUrl() {
    if (_isAuthenticated) {
      return {
        'url': 'https://mock.auth.url/logout',
        'state': 'mock_logout_state',
      };
    }
    return null;
  }

  @override
  Future<void> logout({LogoutReason reason = LogoutReason.userRequested}) async {
    _isAuthenticated = false;
    _lastLogoutReason = reason;
    _accessToken = null;
    _idToken = null;
    _userId = null;
  }

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  bool get isInitializing => _isInitializing;

  @override
  bool get isTokenExpired => _isTokenExpired;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get idToken => _idToken;

  @override
  String? get userId => _userId;

  @override
  User? get currentUser => _isAuthenticated
      ? User(
          username: _userId ?? 'mock_id',
          name: 'Mock User',
          email: 'mock@test.com',
          creationDate: DateTime.now(),
          lastUpdate: DateTime.now(),
        )
      : null;

  @override
  String get redirectUri => 'https://mock.app/callback';

  @override
  TenantConfig? get tenantConfig => null;

  @override
  Stream<User?> get userStream => Stream.value(currentUser);

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic get authService => null;

  @override
  LogoutReason get lastLogoutReason => _lastLogoutReason;

  // Test helpers
  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    if (value) {
      _accessToken = 'mock_access_token';
      _idToken = 'mock_id_token';
      _userId = 'mock_user_id';
    } else {
      _accessToken = null;
      _idToken = null;
      _userId = null;
    }
  }

  void setTokenExpired(bool value) {
    _isTokenExpired = value;
  }

  void setInitializing(bool value) {
    _isInitializing = value;
  }
}

/// Mock implementation of [TicketRepository] for testing.
///
/// Provides controllable ticket data for tests.
class MockTicketRepository implements TicketRepository {
  List<Ticket> _tickets = [];
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  bool get hasMore => _hasMore;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<List<Ticket>> getTickets({
    int page = 0,
    int pageSize = 20,
    Map<String, dynamic>? query,
  }) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    return _tickets;
  }

  @override
  Future<Ticket?> getTicketById(String id) async {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Ticket> createTicket(Map<String, dynamic> ticketData) async {
    final ticket = Ticket.fromJson({
      ...ticketData,
      'id': 'mock_ticket_${_tickets.length + 1}',
    });
    _tickets.add(ticket);
    return ticket;
  }

  @override
  Future<Ticket> updateTicket(String id, Map<String, dynamic> updates) async {
    final index = _tickets.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Ticket not found');
    }
    final ticket = _tickets[index];
    final updated = Ticket.fromJson({
      ...ticket.toJson(),
      ...updates,
    });
    _tickets[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTicket(String id) async {
    _tickets.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Ticket>> searchTickets(String searchTerm) async {
    final term = searchTerm.toLowerCase();
    return _tickets
        .where((t) =>
            t.title.toLowerCase().contains(term) ||
            (t.description?.toLowerCase().contains(term) == true))
        .toList();
  }

  @override
  Stream<List<Ticket>> watchTickets() {
    return Stream.value(List.unmodifiable(_tickets));
  }

  @override
  List<Ticket> getAllTickets() {
    return List.unmodifiable(_tickets);
  }

  @override
  List<Ticket> getTicketsByStatus(TicketStatus status) {
    return _tickets.where((t) => t.status == status).toList();
  }

  @override
  List<Ticket> getTicketsByPriority(TicketPriority priority) {
    return _tickets.where((t) => t.priority == priority.name).toList();
  }

  @override
  TicketStatistics getStatistics() {
    return TicketStatistics(
      total: _tickets.length,
      open: _tickets.where((t) => t.status == TicketStatus.open).length,
      inProgress: _tickets.where((t) => t.status == TicketStatus.inProgress).length,
      resolved: _tickets.where((t) => t.status == TicketStatus.resolved).length,
      closed: _tickets.where((t) => t.status == TicketStatus.closed).length,
    );
  }

  // Test helpers
  void setTickets(List<Ticket> tickets) {
    _tickets = tickets;
  }

  void setHasMore(bool value) {
    _hasMore = value;
  }

  void clear() {
    _tickets.clear();
  }
}
