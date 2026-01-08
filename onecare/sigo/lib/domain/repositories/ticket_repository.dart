import '../../models/ticket.dart';
import '../../models/ticket_statistics.dart';

/// Abstract repository for ticket operations.
/// Defines the contract for ticket data access and management.
abstract class TicketRepository {
  /// Get tickets with pagination and optional query filter.
  ///
  /// [page] - The page number (0-indexed)
  /// [pageSize] - Number of tickets per page
  /// [query] - Optional query filter for advanced filtering
  ///
  /// Returns a list of tickets matching the criteria.
  Future<List<Ticket>> getTickets({
    int page = 0,
    int pageSize = 20,
    Map<String, dynamic>? query,
  });

  /// Get a single ticket by its ID.
  ///
  /// [id] - The ticket ID
  ///
  /// Returns the ticket if found, null otherwise.
  Future<Ticket?> getTicketById(String id);

  /// Create a new ticket.
  ///
  /// [ticketData] - The ticket data as a map
  ///
  /// Returns the created ticket.
  Future<Ticket> createTicket(Map<String, dynamic> ticketData);

  /// Update an existing ticket.
  ///
  /// [id] - The ticket ID to update
  /// [updates] - The fields to update
  ///
  /// Returns the updated ticket.
  Future<Ticket> updateTicket(String id, Map<String, dynamic> updates);

  /// Delete a ticket.
  ///
  /// [id] - The ticket ID to delete
  Future<void> deleteTicket(String id);

  /// Search tickets by search term.
  ///
  /// [searchTerm] - The search term to filter tickets
  ///
  /// Returns a list of matching tickets.
  Future<List<Ticket>> searchTickets(String searchTerm);

  /// Watch for ticket updates in real-time.
  ///
  /// Returns a stream of ticket lists that updates when data changes.
  Stream<List<Ticket>> watchTickets();

  /// Check if there are more tickets to load (for pagination).
  bool get hasMore;

  /// Check if tickets are currently being loaded.
  bool get isLoading;

  /// Get the current list of tickets from cache.
  List<Ticket> getAllTickets();

  /// Get tickets filtered by status.
  List<Ticket> getTicketsByStatus(TicketStatus status);

  /// Get tickets filtered by priority.
  List<Ticket> getTicketsByPriority(TicketPriority priority);

  /// Get statistics about tickets (counts by status).
  TicketStatistics getStatistics();
}
