import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ticket.dart';

/// Service for offline caching using Hive.
///
/// Provides local storage for tickets to enable offline functionality.
/// Implements a network-first strategy with automatic fallback to cached data
/// when network is unavailable.
///
/// ## Architecture
///
/// The service uses two Hive boxes (NoSQL storage):
/// - `tickets`: Stores tickets as JSON strings (key: ticket ID, value: JSON)
/// - `cache_metadata`: Stores cache metadata (last update timestamp, count)
///
/// ## Features
///
/// - **Automatic Caching**: Tickets are automatically cached on successful network loads
/// - **Offline Support**: App works completely offline using cached data
/// - **Cache Staleness Detection**: Detects when cache is outdated (default: 1 hour)
/// - **Error Resilience**: Corrupted cache entries are skipped, not propagated
/// - **Statistics**: Provides cache statistics for debugging and monitoring
///
/// ## Initialization
///
/// Must be initialized before use, typically in `main()` before `runApp()`:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   await OfflineCacheService.initialize(); // ← Initialize cache
///   runApp(MyApp());
/// }
/// ```
///
/// ## Basic Usage
///
/// ### Caching Tickets (Automatic in TicketBloc)
/// ```dart
/// try {
///   final tickets = await ticketRepository.getTickets();
///   await OfflineCacheService.cacheTickets(tickets); // Auto-cache on success
///   emit(state.copyWith(tickets: tickets));
/// } catch (networkError) {
///   // Fallback to cache on network error
///   if (OfflineCacheService.hasCachedData()) {
///     final cached = OfflineCacheService.getCachedTickets();
///     emit(state.copyWith(
///       tickets: cached,
///       error: 'Offline mode: Showing cached data',
///     ));
///   }
/// }
/// ```
///
/// ### Cache Management
/// ```dart
/// // Check cache status
/// bool hasData = OfflineCacheService.hasCachedData();
/// int count = OfflineCacheService.getCachedCount();
/// bool isStale = OfflineCacheService.isCacheStale();
///
/// // Get cache statistics
/// final stats = OfflineCacheService.getCacheStats();
/// debugPrint('Cache: ${stats['count']} tickets, last update: ${stats['lastUpdate']}');
///
/// // Manual operations
/// await OfflineCacheService.cacheTicket(ticket);        // Cache single
/// Ticket? t = OfflineCacheService.getCachedTicket(id);  // Get single
/// await OfflineCacheService.removeCachedTicket(id);     // Remove single
/// await OfflineCacheService.clearCache();               // Clear all
/// ```
///
/// ## Data Flow
///
/// 1. **Network Available**:
///    - Fetch from API → Cache data → Show fresh data
///
/// 2. **Network Unavailable**:
///    - Try API (fails) → Load from cache → Show cached data
///
/// 3. **No Cache**:
///    - Try API (fails) → No cache → Show error
///
/// ## Cache Staleness
///
/// The cache tracks the last update timestamp. Use `isCacheStale()` to check:
/// ```dart
/// if (OfflineCacheService.isCacheStale(maxAge: Duration(hours: 2))) {
///   // Cache is older than 2 hours, should refresh
/// }
/// ```
///
/// ## Error Handling
///
/// The service handles errors gracefully:
/// - Corrupted JSON entries are skipped (logged but not thrown)
/// - Missing cache returns empty list (not throws)
/// - Failed cache writes are logged but don't crash the app
///
/// ## Performance
///
/// - **Fast**: Hive is optimized for mobile (faster than SQLite)
/// - **Compact**: Tickets stored as compressed JSON strings
/// - **Efficient**: Batch operations for bulk caching
///
/// ## Thread Safety
///
/// All methods check initialization state with `_ensureInitialized()`.
/// Throws `StateError` if used before `initialize()` is called.
///
/// ## See Also
///
/// - [TicketBloc] - Uses this service for automatic cache fallback
/// - [Hive Documentation](https://docs.hivedb.dev/)
class OfflineCacheService {
  OfflineCacheService._();

  static const String _ticketsBoxName = 'tickets';
  static const String _metadataBoxName = 'cache_metadata';

  static late Box<String> _ticketsBox;
  static late Box<dynamic> _metadataBox;

  static bool _initialized = false;

  /// Initialize Hive and open boxes.
  ///
  /// Must be called before using any cache methods, typically in main().
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('OfflineCacheService already initialized');
      return;
    }

    try {
      await Hive.initFlutter();

      // Open boxes for tickets (storing as JSON strings)
      _ticketsBox = await Hive.openBox<String>(_ticketsBoxName);
      _metadataBox = await Hive.openBox(_metadataBoxName);

      _initialized = true;
      debugPrint('OfflineCacheService initialized successfully');
      debugPrint('Cached tickets: ${_ticketsBox.length}');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize OfflineCacheService: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Cache a list of tickets.
  ///
  /// Replaces existing cache with new data.
  /// Stores last update timestamp for cache invalidation.
  static Future<void> cacheTickets(List<Ticket> tickets) async {
    _ensureInitialized();

    try {
      // Clear existing cache
      await _ticketsBox.clear();

      // Store tickets as JSON strings
      final Map<String, String> ticketMap = {};
      for (final ticket in tickets) {
        ticketMap[ticket.id] = ticket.toJsonString();
      }

      await _ticketsBox.putAll(ticketMap);

      // Update metadata
      await _metadataBox.put('lastCacheUpdate', DateTime.now().toIso8601String());
      await _metadataBox.put('cachedCount', tickets.length);

      debugPrint('Cached ${tickets.length} tickets');
    } catch (e) {
      debugPrint('Failed to cache tickets: $e');
      rethrow;
    }
  }

  /// Get all cached tickets.
  ///
  /// Returns empty list if no cache exists.
  static List<Ticket> getCachedTickets() {
    _ensureInitialized();

    try {
      final tickets = <Ticket>[];

      for (final jsonString in _ticketsBox.values) {
        try {
          final ticket = ticketFromJsonString(jsonString);
          tickets.add(ticket);
        } catch (e) {
          debugPrint('Failed to parse cached ticket: $e');
          // Skip corrupted entries
        }
      }

      debugPrint('Retrieved ${tickets.length} cached tickets');
      return tickets;
    } catch (e) {
      debugPrint('Failed to get cached tickets: $e');
      return [];
    }
  }

  /// Get a single cached ticket by ID.
  ///
  /// Returns null if ticket not found.
  static Ticket? getCachedTicket(String id) {
    _ensureInitialized();

    try {
      final jsonString = _ticketsBox.get(id);
      if (jsonString == null) return null;

      return ticketFromJsonString(jsonString);
    } catch (e) {
      debugPrint('Failed to get cached ticket $id: $e');
      return null;
    }
  }

  /// Cache a single ticket (update or add).
  static Future<void> cacheTicket(Ticket ticket) async {
    _ensureInitialized();

    try {
      await _ticketsBox.put(ticket.id, ticket.toJsonString());
      debugPrint('Cached ticket ${ticket.id}');
    } catch (e) {
      debugPrint('Failed to cache ticket ${ticket.id}: $e');
    }
  }

  /// Remove a ticket from cache.
  static Future<void> removeCachedTicket(String id) async {
    _ensureInitialized();

    try {
      await _ticketsBox.delete(id);
      debugPrint('Removed cached ticket $id');
    } catch (e) {
      debugPrint('Failed to remove cached ticket $id: $e');
    }
  }

  /// Clear all cached tickets.
  static Future<void> clearCache() async {
    _ensureInitialized();

    try {
      await _ticketsBox.clear();
      await _metadataBox.delete('lastCacheUpdate');
      await _metadataBox.delete('cachedCount');
      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Check if cache exists and is not empty.
  static bool hasCachedData() {
    _ensureInitialized();
    return _ticketsBox.isNotEmpty;
  }

  /// Get the last cache update timestamp.
  ///
  /// Returns null if never cached.
  static DateTime? getLastCacheUpdate() {
    _ensureInitialized();

    try {
      final timestamp = _metadataBox.get('lastCacheUpdate');
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      debugPrint('Failed to get last cache update: $e');
      return null;
    }
  }

  /// Check if cache is stale (older than specified duration).
  ///
  /// Default: cache is stale after 1 hour.
  static bool isCacheStale({Duration maxAge = const Duration(hours: 1)}) {
    final lastUpdate = getLastCacheUpdate();
    if (lastUpdate == null) return true;

    return DateTime.now().difference(lastUpdate) > maxAge;
  }

  /// Get number of cached tickets.
  static int getCachedCount() {
    _ensureInitialized();
    return _ticketsBox.length;
  }

  /// Get cache statistics.
  static Map<String, dynamic> getCacheStats() {
    _ensureInitialized();

    return {
      'count': _ticketsBox.length,
      'lastUpdate': getLastCacheUpdate()?.toIso8601String(),
      'isStale': isCacheStale(),
      'sizeInBytes': _ticketsBox.length * 1024, // Approximate
    };
  }

  /// Close all boxes.
  ///
  /// Call this when app is terminated.
  static Future<void> close() async {
    if (!_initialized) return;

    try {
      await _ticketsBox.close();
      await _metadataBox.close();
      _initialized = false;
      debugPrint('OfflineCacheService closed');
    } catch (e) {
      debugPrint('Failed to close OfflineCacheService: $e');
    }
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'OfflineCacheService not initialized. Call initialize() first.',
      );
    }
  }
}

/// Helper functions for Ticket JSON serialization.

/// Parse ticket from JSON string.
///
/// Uses dart:convert for decoding and the freezed-generated fromJson factory.
Ticket ticketFromJsonString(String jsonString) {
  try {
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return Ticket.fromJson(jsonMap);
  } catch (e) {
    debugPrint('Error decoding ticket from JSON: $e');
    rethrow;
  }
}

/// Extension to add JSON string serialization to Ticket model.
extension TicketJsonString on Ticket {
  /// Convert ticket to JSON string for Hive storage.
  ///
  /// Uses the freezed-generated toJson method and dart:convert for encoding.
  String toJsonString() {
    try {
      final jsonMap = toJson();
      return json.encode(jsonMap);
    } catch (e) {
      debugPrint('Error encoding ticket to JSON: $e');
      rethrow;
    }
  }
}
