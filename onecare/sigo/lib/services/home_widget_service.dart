import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sigo/models/ticket.dart';
import '../firebase_options.dart';
import '../models/widget_ticket_stats.dart';
import '../domain/repositories/auth_repository.dart';
import '../core/di/injection.dart';
import 'api_service.dart';
import 'package:workmanager/workmanager.dart';

/// Service to manage home screen widget updates
class HomeWidgetService {
  static const String _iOSWidgetName = 'SigoWidget';
  static const String _androidProviderName = 'HomeWidgetProvider';
  static const String _widgetUpdateTask = 'widgetUpdateTask';

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the widget service with optional navigator key for navigation
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;

    // Set up callback for widget clicks
    HomeWidget.setAppGroupId('group.com.alticelabs.sigo.onecare');

    // Register background callback for widget interactions
    HomeWidget.registerInteractivityCallback(backgroundCallback);

    // Set up initial data handler for when app launches from widget
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        _handleWidgetClick(uri);
      }
    });

    // Set up ongoing widget click handler
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetClick(uri);
      }
    });
  }

  /// Handle widget click navigation
  static void _handleWidgetClick(Uri uri) {
    debugPrint('Widget clicked with URI: $uri');

    if (uri.host == 'refresh') {
      // Check if HomeWidgetService is registered before accessing it
      if (getIt.isRegistered<HomeWidgetService>()) {
        getIt<HomeWidgetService>().updateWidgetWithTicketStats();
      } else {
        debugPrint('HomeWidgetService not yet registered, skipping refresh');
      }
      return;
    }

    // Navigate to home screen when widget is clicked
    if (_navigatorKey?.currentState != null) {
      // Pop to root (home screen)
      _navigatorKey!.currentState!.popUntil((route) => route.isFirst);
    }
  }

  /// Update the widget with new data
  Future<void> updateWidget({
    String? title,
    String? message,
    int? counter,
  }) async {
    try {
      // Save data to be displayed on the widget
      if (title != null) {
        await HomeWidget.saveWidgetData<String>('widget_title', title);
      }
      if (message != null) {
        await HomeWidget.saveWidgetData<String>('widget_message', message);
      }
      if (counter != null) {
        await HomeWidget.saveWidgetData<int>('widget_counter', counter);
      }

      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Get current widget data
  Future<Map<String, dynamic>> getWidgetData() async {
    try {
      final title = await HomeWidget.getWidgetData<String>('widget_title');
      final message = await HomeWidget.getWidgetData<String>('widget_message');
      final counter = await HomeWidget.getWidgetData<int>('widget_counter');

      return {
        'title': title ?? 'SIGO OneCare',
        'message': message ?? 'No message',
        'counter': counter ?? 0,
      };
    } catch (e) {
      print('Error getting widget data: $e');
      return {
        'title': 'SIGO OneCare',
        'message': 'Error loading data',
        'counter': 0,
      };
    }
  }

  /// Clear all widget data
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_title', 'SIGO OneCare');
      await HomeWidget.saveWidgetData<String>('widget_message', 'Widget cleared');
      await HomeWidget.saveWidgetData<int>('widget_counter', 0);

      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      print('Error clearing widget data: $e');
    }
  }

  /// Fetch ticket statistics and update widget
  /// Returns true if successful, false if network error (to trigger retry)
  Future<bool> updateWidgetWithTicketStats() async {
    try {
      // Set loading state
      await _setWidgetLoading(true);

      debugPrint('Fetching ticket statistics for widget...');

      // Check if user is authenticated first
      List<Ticket> tickets;
      try {
        tickets = await _fetchAllTicketsForWidget();

        debugPrint('Fetched ${tickets.length} tickets for widget');
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();
        final isNetworkError = errorMessage.contains('network') ||
                               errorMessage.contains('connection') ||
                               errorMessage.contains('host lookup') ||
                               errorMessage.contains('socket');

        if (isNetworkError) {
          debugPrint('Network error while fetching tickets: $e');
          debugPrint('Widget will keep last known values and retry later');
          await _setWidgetLoading(false); // Clear loading state
          return false; // Return false to indicate failure for retry
        } else {
          debugPrint('Error fetching tickets (user may not be authenticated): $e');
          await _setWidgetLoading(false); // Clear loading state
          return true; // Return true as this is not a retryable error
        }
      }

      // Count tickets by status
      int acknowledged = 0;
      int held = 0;
      int inProgress = 0;
      int pending = 0;
      int resolved = 0;

      for (var ticket in tickets) {
        switch (ticket.status) {
          case TicketStatus.acknowledged:
            acknowledged++;
            break;
          case TicketStatus.held:
            held++;
            break;
          case TicketStatus.inProgress:
            inProgress++;
            break;
          case TicketStatus.pending:
            pending++;
            break;
          case TicketStatus.resolved:
            resolved++;
            break;
          case TicketStatus.open:
          case TicketStatus.closed:
          case TicketStatus.cancelled:
            // These statuses are not included in the widget
            break;
        }
      }

      final stats = WidgetTicketStats(
        acknowledged: acknowledged,
        held: held,
        inProgress: inProgress,
        pending: pending,
        resolved: resolved,
        lastUpdate: DateTime.now(),
      );

      debugPrint('Widget stats: $stats');

      // Save stats to widget storage
      await HomeWidget.saveWidgetData<int>('ticket_acknowledged', stats.acknowledged);
      await HomeWidget.saveWidgetData<int>('ticket_held', stats.held);
      await HomeWidget.saveWidgetData<int>('ticket_in_progress', stats.inProgress);
      await HomeWidget.saveWidgetData<int>('ticket_pending', stats.pending);
      await HomeWidget.saveWidgetData<int>('ticket_resolved', stats.resolved);
      await HomeWidget.saveWidgetData<int>('ticket_total', stats.total);
      await HomeWidget.saveWidgetData<String>(
        'ticket_last_update',
        stats.lastUpdate.toUtc().toIso8601String(),
      );

      // Clear loading state
      await _setWidgetLoading(false);

      // Update widget
      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );

      debugPrint('Widget updated with ticket stats successfully');
      return true; // Success
    } catch (e, stack) {
      debugPrint('Error updating widget with ticket stats: $e');
      debugPrint('Stack trace: $stack');

      // Clear loading state on error
      await _setWidgetLoading(false);
      return false; // Failure - will trigger retry
    }
  }

  /// Set widget loading state
  Future<void> _setWidgetLoading(bool isLoading) async {
    try {
      await HomeWidget.saveWidgetData<bool>('widget_loading', isLoading);
      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Error setting widget loading state: $e');
    }
  }

  Future<List<Ticket>> _fetchAllTicketsForWidget() async {
    final authRepository = getIt<AuthRepository>();
    if (!authRepository.isAuthenticated || authRepository.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final baseUrl = authRepository.tenantConfig?.baseUrl ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('Missing base URL');
    }

    final apiService = ApiService(
      authRepository.accessToken!,
      baseUrl: baseUrl,
      authService: authRepository,
    );

    const pageSize = 100;
    const maxPages = 500;
    var pageIndex = 0;
    final allTickets = <Ticket>[];
    int? totalExpected;
    final query = {
      "operator": "AND",
      "conditions": [
        {
          "attribute": "status",
          "operator": "in",
          "value": ["ACKNOWLEDGED", "HELD", "IN_PROGRESS", "PENDING"]
        }
      ]
    };

    while (pageIndex < maxPages) {
      final response = await apiService.searchTickets(
        pageIndex: pageIndex,
        pageSize: pageSize,
        query: query,
      );

      final results = (response['results'] as List?) ?? const [];
      totalExpected ??= _extractTotalCount(response);
      debugPrint(
        'Widget tickets page=$pageIndex size=${results.length} totalExpected=${totalExpected ?? 'unknown'}',
      );
      if (results.isEmpty) {
        break;
      }

      for (final json in results) {
        allTickets.add(Ticket.fromJson(json as Map<String, dynamic>));
      }

      if (totalExpected != null && allTickets.length >= totalExpected!) {
        break;
      }

      if (results.length < pageSize) {
        break;
      }

      pageIndex++;
    }

    return allTickets;
  }

  int? _extractTotalCount(Map<String, dynamic> response) {
    final total = response['total'] ?? response['totalCount'] ?? response['count'];
    if (total is int) {
      return total;
    }
    final paging = response['paging'];
    if (paging is Map<String, dynamic>) {
      final pagingTotal = paging['total'] ?? paging['count'];
      if (pagingTotal is int) {
        return pagingTotal;
      }
    }
    return null;
  }

  /// Schedule 15-minute periodic widget updates
  Future<void> schedulePeriodicUpdates() async {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      await Workmanager().registerPeriodicTask(
        _widgetUpdateTask,
        _widgetUpdateTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      debugPrint('Scheduled 15-minute widget updates');
    } catch (e) {
      debugPrint('Error scheduling widget updates: $e');
    }
  }

  /// Cancel scheduled widget updates
  Future<void> cancelScheduledUpdates() async {
    try {
      await Workmanager().cancelByUniqueName(_widgetUpdateTask);
      debugPrint('Cancelled scheduled widget updates');
    } catch (e) {
      debugPrint('Error cancelling widget updates: $e');
    }
  }

  /// Set empty/default widget data
  Future<void> _setEmptyWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<int>('ticket_acknowledged', 0);
      await HomeWidget.saveWidgetData<int>('ticket_held', 0);
      await HomeWidget.saveWidgetData<int>('ticket_in_progress', 0);
      await HomeWidget.saveWidgetData<int>('ticket_pending', 0);
      await HomeWidget.saveWidgetData<int>('ticket_total', 0);
      await HomeWidget.saveWidgetData<String>(
        'ticket_last_update',
        DateTime.now().toUtc().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Error setting empty widget data: $e');
    }
  }

  /// Update widget with test data (for testing)
  Future<void> updateWidgetWithTestData() async {
    try {
      await HomeWidget.saveWidgetData<int>('ticket_acknowledged', 5);
      await HomeWidget.saveWidgetData<int>('ticket_held', 2);
      await HomeWidget.saveWidgetData<int>('ticket_in_progress', 8);
      await HomeWidget.saveWidgetData<int>('ticket_pending', 3);
      await HomeWidget.saveWidgetData<int>('ticket_total', 18);
      await HomeWidget.saveWidgetData<String>(
        'ticket_last_update',
        DateTime.now().toUtc().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );

      debugPrint('Widget updated with test data');
    } catch (e) {
      debugPrint('Error updating widget with test data: $e');
    }
  }
}

const String _androidProviderName = 'HomeWidgetProvider';

/// Background task dispatcher for periodic widget updates
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Widget background task started: $task');

      // Initialize Flutter bindings for background isolate
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase (required for dependency injection)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set app group ID for widget data sharing
      await HomeWidget.setAppGroupId('group.com.alticelabs.sigo.onecare');

      // Initialize dependency injection if not already done
      if (!getIt.isRegistered<AuthRepository>()) {
        await configureDependencies();
      }

      // Wait for auth repository to be ready
      final authRepository = getIt<AuthRepository>();
      await authRepository.ready;

      // Check if user is authenticated
      if (!authRepository.isAuthenticated) {
        debugPrint('Widget background task skipped: user not authenticated');
        return Future.value(true);
      }

      // Update widget with latest ticket stats
      final service = HomeWidgetService();
      final success = await service.updateWidgetWithTicketStats();

      if (success) {
        debugPrint('Widget background task completed successfully');
        return Future.value(true);
      } else {
        debugPrint('Widget background task failed due to network error - will retry');
        return Future.value(false); // Tell WorkManager to retry
      }
    } catch (e, stackTrace) {
      debugPrint('Widget background task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

/// Background callback for widget interactions
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri == null) return;
  debugPrint('Widget clicked with URI: $uri');

  if (uri.host != 'refresh') return;

  WidgetsFlutterBinding.ensureInitialized();

  // Set app group ID first (needed to save loading state)
  await HomeWidget.setAppGroupId('group.com.alticelabs.sigo.onecare');

  // Show loading indicator IMMEDIATELY
  try {
    await HomeWidget.saveWidgetData<bool>('widget_loading', true);
    await HomeWidget.updateWidget(
      androidName: _androidProviderName,
      iOSName: 'SigoWidget',
    );
    debugPrint('Loading indicator shown');
  } catch (e) {
    debugPrint('Error showing loading indicator: $e');
  }

  // Initialize Firebase (required for dependency injection)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!getIt.isRegistered<AuthRepository>()) {
    await configureDependencies();
  }

  final authRepository = getIt<AuthRepository>();
  await authRepository.ready;
  if (!authRepository.isAuthenticated) {
    debugPrint('Widget refresh skipped: not authenticated');
    return;
  }

  debugPrint('Widget refresh: fetching latest ticket stats');
  await HomeWidgetService().updateWidgetWithTicketStats();
}

