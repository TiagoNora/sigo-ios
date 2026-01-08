import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/ticket_constants.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/ticket.dart';
import '../../models/ticket_statistics.dart';
import '../../services/api_service.dart';
import '../../services/network_exception.dart';
import '../../services/not_found_exception.dart';
import '../../services/connectivity_service.dart';

// Helper function to parse tickets in isolate
List<Ticket> _parseTickets(List<dynamic> jsonList) {
  return jsonList
      .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
      .toList();
}

/// Implementation of TicketRepository.
///
/// Manages ticket data with in-memory caching, stream support, and pagination.
@Singleton(as: TicketRepository)
class TicketRepositoryImpl implements TicketRepository {
  final AuthRepository _authRepository;

  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 20;
  Map<String, dynamic>? _currentQuery;
  Map<String, dynamic>? _baseFilterQuery;
  String _searchTerm = '';

  final StreamController<List<Ticket>> _ticketsController =
      StreamController<List<Ticket>>.broadcast();

  TicketRepositoryImpl(this._authRepository);

  ApiService get _apiService {
    if (_authRepository.accessToken == null) {
      throw Exception('Not authenticated');
    }
    final baseUrl = _authRepository.tenantConfig?.baseUrl ?? '';
    return ApiService(
      _authRepository.accessToken!,
      baseUrl: baseUrl,
      authService: _authRepository,
    );
  }

  // Load tickets from API (internal method)
  Future<void> _loadTickets({Map<String, dynamic>? query}) async {
    if (_isLoading) return;

    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot load tickets: user not authenticated - triggering logout');
      await _authRepository.logout();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    _currentQuery = query;

    try {
      final response = await _apiService.searchTickets(
        pageIndex: 0,
        pageSize: _pageSize,
        query: _currentQuery,
      );

      final results = response['results'] as List;
      // Parse tickets in background isolate to prevent UI blocking
      _tickets = await compute(_parseTickets, results);
      _hasMore = results.length >= _pageSize;
      _error = null;
      _isLoading = false;

      // Update stream
      _ticketsController.add(getAllTickets());
    } on NetworkException catch (e) {
      _isLoading = false;
      // Only mark offline for actual connectivity issues, not service unavailability
      if (e.message != 'Service not reachable') {
        ConnectivityService.instance?.markOffline();
      }
      _error = e.message;
      debugPrint('Network error: ${e.message}');
      rethrow; // Propagate error to BLoC
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load tickets: $e';
      debugPrint(_error);
      rethrow; // Propagate error to BLoC
    }
  }

  // Load more tickets (for infinite scroll)
  Future<void> _loadMoreTickets() async {
    if (!_authRepository.isAuthenticated || _isLoading || !_hasMore) {
      debugPrint(
          'loadMoreTickets skipped: authenticated=${_authRepository.isAuthenticated}, isLoading=$_isLoading, hasMore=$_hasMore');
      return;
    }

    debugPrint(
        'Loading more tickets - current page: $_currentPage, total tickets: ${_tickets.length}');

    _isLoading = true;

    try {
      _currentPage++;
      final response = await _apiService.searchTickets(
        pageIndex: _currentPage,
        pageSize: _pageSize,
        query: _currentQuery,
      );

      final results = response['results'] as List;
      // Parse tickets in background isolate to prevent UI blocking
      final newTickets = await compute(_parseTickets, results);

      debugPrint('Loaded ${newTickets.length} new tickets');

      _tickets.addAll(newTickets);
      _hasMore = newTickets.length >= _pageSize;

      debugPrint('Total tickets now: ${_tickets.length}, hasMore: $_hasMore');

      // Update stream
      _ticketsController.add(getAllTickets());
    } on NetworkException catch (e) {
      // Only mark offline for actual connectivity issues, not service unavailability
      if (e.message != 'Service not reachable') {
        ConnectivityService.instance?.markOffline();
      }
      _currentPage--;
    } catch (e) {
      _error = 'Failed to load more tickets: $e';
      debugPrint(_error);
      _currentPage--;
    } finally {
      _isLoading = false;
    }
  }

  Map<String, dynamic>? _mergeSearchWithBase(
      Map<String, dynamic>? baseQuery, String searchValue) {
    final trimmedValue = searchValue.trim();

    if (trimmedValue.isEmpty) {
      return baseQuery;
    }

    final searchCondition = {
      'name': '',
      'operator': 'OR',
      'conditions': [
        {
          'attribute': 'id',
          'operator': 'containsIgnoreCase',
          'value': trimmedValue,
        },
        {
          'attribute': 'name',
          'operator': 'containsIgnoreCase',
          'value': trimmedValue,
        },
      ],
    };

    if (baseQuery == null) {
      return searchCondition;
    }

    final existingConditions = <dynamic>[
      ...(baseQuery['conditions'] as List? ?? []),
    ];

    return {
      ...baseQuery,
      'name': baseQuery['name'] ?? '',
      'operator': baseQuery['operator'] ?? 'AND',
      'conditions': [
        ...existingConditions,
        searchCondition,
      ],
    };
  }

  @override
  Future<List<Ticket>> getTickets({
    int page = 0,
    int pageSize = 20,
    Map<String, dynamic>? query,
  }) async {
    if (page == 0) {
      _baseFilterQuery = query;
      final combinedQuery = _mergeSearchWithBase(_baseFilterQuery, _searchTerm);
      await _loadTickets(query: combinedQuery);
    } else {
      await _loadMoreTickets();
    }

    return getAllTickets();
  }

  @override
  Future<Ticket?> getTicketById(String id) async {
    // Try to get from cache first
    final cached = _tickets.firstWhere(
      (ticket) => ticket.id == id,
      orElse: () => throw StateError('Not found'),
    );

    try {
      return cached;
    } on StateError {
      // Fetch from API if not in cache
      return await _fetchTicketById(id);
    }
  }

  // Get ticket by ID from API (internal)
  Future<Ticket?> _fetchTicketById(String id) async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot fetch ticket: user not authenticated - triggering logout');
      await _authRepository.logout();
      return null;
    }

    try {
      final json = await _apiService.getTicketById(id);
      return Ticket.fromJson(json);
    } on NetworkException catch (e) {
      // Only mark offline for actual connectivity issues, not service unavailability
      if (e.message != 'Service not reachable') {
        ConnectivityService.instance?.markOffline();
      }
      return null;
    } on NotFoundException {
      return null;
    } catch (e) {
      debugPrint('Error fetching ticket: $e');
      return null;
    }
  }

  @override
  Future<Ticket> createTicket(Map<String, dynamic> ticketData) async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot create ticket: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      final now = DateTime.now();
      final requestData = {
        'name': ticketData['name'],
        'impact': ticketData['impact'],
        'priority': ticketData['priority'],
        'category': ticketData['category'],
        'createdBy': ticketData['createdBy'],
        'createdByTeam': ticketData['createdByTeam'],
        'status': 'OPEN',
        'creationDate': now.toIso8601String(),
        'lastUpdate': now.toIso8601String(),
        'externalId': ticketData['externalId'] ?? '',
      };

      final response = await _apiService.createTicket(requestData);
      final ticket = Ticket.fromJson(response);

      _tickets.add(ticket);

      // Update stream
      _ticketsController.add(getAllTickets());

      return ticket;
    } on NetworkException catch (e) {
      // Only mark offline for actual connectivity issues, not service unavailability
      if (e.message != 'Service not reachable') {
        ConnectivityService.instance?.markOffline();
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      throw Exception('Failed to create ticket: $e');
    }
  }

  @override
  Future<Ticket> updateTicket(String id, Map<String, dynamic> updates) async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot update ticket: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      final ticket = _tickets.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Ticket not found'),
      );

      final ticketData = {
        'name': updates['name'] ?? ticket.title,
        'impact': updates['impact'] ?? ticket.description,
        'status': updates['status'] != null
            ? _parseTicketStatusToString(
                _parseTicketStatus(updates['status'] as String))
            : ticket.status.toApiValue(),
        'priority': updates['priority'] ?? ticket.priority,
        'category': updates['category'] ?? ticket.category,
        'createdBy': updates['createdBy'] ?? ticket.requesterName,
        'createdByTeam': updates['createdByTeam'] ?? ticket.assignedTo,
        'lastUpdate': DateTime.now().toIso8601String(),
        'externalId': updates['externalId'] ?? ticket.notes ?? '',
      };

      final response = await _apiService.updateTicket(id, ticketData);
      final updatedTicket = Ticket.fromJson(response);

      final index = _tickets.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }

      // Update stream
      _ticketsController.add(getAllTickets());

      return updatedTicket;
    } on NetworkException catch (e) {
      // Only mark offline for actual connectivity issues, not service unavailability
      if (e.message != 'Service not reachable') {
        ConnectivityService.instance?.markOffline();
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error updating ticket: $e');
      throw Exception('Failed to update ticket: $e');
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    if (!_authRepository.isAuthenticated) {
      debugPrint(
          'Cannot delete ticket: user not authenticated - triggering logout');
      await _authRepository.logout();
      throw Exception('Not authenticated');
    }

    try {
      await _apiService.deleteTicket(id);
      _tickets.removeWhere((ticket) => ticket.id == id);

      // Update stream
      _ticketsController.add(getAllTickets());
    } on NetworkException catch (e) {
      // Only mark offline for actual connectivity issues, not service unavailability
      if (e.message != 'Service not reachable') {
        ConnectivityService.instance?.markOffline();
      }
      throw Exception('Network error while deleting ticket');
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
      throw Exception('Failed to delete ticket: $e');
    }
  }

  @override
  Future<List<Ticket>> searchTickets(String searchTerm) async {
    _searchTerm = searchTerm.trim();
    final combinedQuery = _mergeSearchWithBase(_baseFilterQuery, _searchTerm);
    await _loadTickets(query: combinedQuery);
    return getAllTickets();
  }

  @override
  Stream<List<Ticket>> watchTickets() => _ticketsController.stream;

  @override
  bool get hasMore => _hasMore;

  @override
  bool get isLoading => _isLoading;

  @override
  List<Ticket> getAllTickets() {
    return List.from(_tickets)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<Ticket> getTicketsByStatus(TicketStatus status) {
    return _tickets
        .where((ticket) => ticket.status == status)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<Ticket> getTicketsByPriority(TicketPriority priority) {
    return _tickets
        .where((ticket) => ticket.priority == priority)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  TicketStatistics getStatistics() {
    final tickets = getAllTickets();
    return TicketStatistics(
      total: tickets.length,
      open: tickets.where((t) => t.status == TicketStatus.open).length,
      inProgress:
          tickets.where((t) => t.status == TicketStatus.inProgress).length,
      resolved: tickets.where((t) => t.status == TicketStatus.resolved).length,
      closed: tickets.where((t) => t.status == TicketStatus.closed).length,
    );
  }

  TicketStatus _parseTicketStatus(String status) {
    switch (status.toUpperCase()) {
      case TicketStatusStrings.pending:
        return TicketStatus.pending;
      case TicketStatusStrings.open:
        return TicketStatus.open;
      case TicketStatusStrings.acknowledged:
        return TicketStatus.acknowledged;
      case TicketStatusStrings.inProgress:
      case 'INPROGRESS':
        return TicketStatus.inProgress;
      case TicketStatusStrings.resolved:
        return TicketStatus.resolved;
      case TicketStatusStrings.closed:
        return TicketStatus.closed;
      case TicketStatusStrings.cancelled:
      case TicketStatusStrings.canceled:
        return TicketStatus.cancelled;
      case TicketStatusStrings.held:
        return TicketStatus.held;
      default:
        return TicketStatus.open;
    }
  }

  String _parseTicketStatusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return TicketStatusStrings.pending;
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
      case TicketStatus.held:
        return TicketStatusStrings.held;
    }
  }


  void dispose() {
    _ticketsController.close();
  }
}
