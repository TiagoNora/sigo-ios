import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/app_features.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/ticket_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticket.dart';
import '../../../models/ticket_extensions.dart';
import '../../../models/app_notification.dart';
import '../../../domain/repositories/priority_repository.dart';
import '../../../blocs/locale_cubit.dart';
import '../../../blocs/auth_bloc.dart';
import '../../../styles/app_theme.dart';
import '../../../utils/date_formatter.dart';
import '../../../blocs/ticket_bloc.dart';
import '../../../view_models/home_controller.dart';
import '../../../constants/app_spacing.dart';
import '../../widgets/tickets/ticket_search_bar.dart';
import '../../widgets/tickets/status_chip.dart';
import '../../widgets/common/error_view.dart';
import '../notifications/notifications_screen.dart';
import '../../../services/notification_service.dart';
import '../../../app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with RouteAware, WidgetsBindingObserver {
  HomeController? _controller;
  bool _requestedInitialLoad = false;
  final FocusNode _searchFocusNode = FocusNode();
  DateTime? _lastNotificationReload;
  static const _notificationReloadThrottle = Duration(seconds: 2);

  HomeController get controller =>
      _controller ??= HomeController(ticketBloc: context.read<TicketBloc>())
        ..init();

  void scrollToTop() => controller.scrollToTop();

  void _reloadNotifications() {
    if (!AppFeatures.enableNotifications) return;
    final now = DateTime.now();
    if (_lastNotificationReload != null &&
        now.difference(_lastNotificationReload!) < _notificationReloadThrottle) {
      return;
    }
    _lastNotificationReload = now;
    context.read<NotificationService>().reloadFromStorage();
  }

  @override
  void initState() {
    super.initState();
    controller; // ensure initialization once lifecycle starts

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Load tickets if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketBloc = context.read<TicketBloc>();
      final authState = context.read<AuthBloc>().state;
      if (!ticketBloc.state.hasLoadedOnce && authState is AuthAuthenticated) {
        _requestedInitialLoad = true;
        ticketBloc.add(const LoadInitialTickets());
      }
      // Reload notifications when screen is first shown
      _reloadNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Unfocus immediately when returning to screen to ensure keyboard stays closed
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('Returned to home screen - refreshing data');
      context.read<TicketBloc>().add(const RefreshTickets());
      _reloadNotifications();
      try {
        // Ensure keyboard is closed again after frame
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      } catch (e) {
        debugPrint('Error dismissing keyboard: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh data when app is resumed
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - refreshing home screen data');
      if (mounted) {
        context.read<TicketBloc>().add(const RefreshTickets());
        _reloadNotifications();
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    // Remove observer first to prevent lifecycle callbacks after disposal
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);

    // Unfocus before disposing to prevent errors
    try {
    } catch (e) {
      debugPrint('Error unfocusing nodes: $e');
    }

    // Dispose resources
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticketRepository = getIt<TicketRepository>();
    return BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (!_requestedInitialLoad &&
            authState is AuthAuthenticated &&
            !state.hasLoadedOnce &&
            !state.isLoading) {
          _requestedInitialLoad = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<TicketBloc>().add(const LoadInitialTickets());
            }
          });
        }
        final tickets = state.tickets;
        // Show skeleton during initial load and any active reloads.
        final shouldShowSkeleton = !state.hasLoadedOnce || state.isLoading;

        final showEmpty =
            !shouldShowSkeleton &&
            state.hasLoadedOnce &&
            !state.isLoading &&
            tickets.isEmpty;

        final searchQuery = controller.searchController.text.trim();
        final resultsCount = ticketRepository.totalCount ?? tickets.length;
        final showSearchCount = !shouldShowSkeleton &&
            (ticketRepository.totalCount != null ||
                state.hasLoadedOnce ||
                searchQuery.isNotEmpty);
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: AppFeatures.enableNotifications
                ? Builder(
                    builder: (context) {
                      final notificationService =
                          context.read<NotificationService>();
                      return StreamBuilder<List<AppNotification>>(
                        stream: notificationService.notificationsStream,
                        initialData: notificationService.notifications,
                        builder: (context, snapshot) {
                          final unread = snapshot.data
                                  ?.where((notification) => !notification.read)
                                  .length ??
                              0;

                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 9 ? '9+' : '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  )
                : null,
            title: SvgPicture.asset(
              'lib/resources/logo.svg',
              height: 40,
              fit: BoxFit.contain,
            ),
            centerTitle: true,
            backgroundColor: AppColors.primaryDark,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.filter_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: () => controller.openFilter(context, state),
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                TicketSearchBar(
                  controller: controller.searchController,
                  focusNode: _searchFocusNode,
                  hintText: l10n.searchTickets,
                  onChanged: (value) {
                    controller.onSearchChanged(value);
                  },
                  onClear: () {
                    controller.clearSearch();
                  },
                ),

                if (state.filterLabel != null ||
                    state.filterLabelKey != null ||
                    showSearchCount)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        if (state.filterLabel != null ||
                            state.filterLabelKey != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.filterLabelKey == 'draft_filter'
                                      ? l10n.draftFilter
                                      : (state.filterLabel ?? ''),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (showSearchCount) ...[
                          const Spacer(),
                          Text(
                            l10n.resultsCount(resultsCount),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: _buildContent(
                        state,
                        tickets,
                        shouldShowSkeleton,
                        showEmpty,
                        l10n,
                        controller,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Builder(
            builder: (context) {
              final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
              return isKeyboardOpen
                  ? const SizedBox.shrink()
                  : FloatingActionButton.extended(
                      onPressed: () async {
                        await controller.openCreateTicket(context);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        l10n.newTicket,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(
    TicketState state,
    List<Ticket> tickets,
    bool shouldShowSkeleton,
    bool showEmpty,
    AppLocalizations l10n,
    HomeController controller,
  ) {
    if (!shouldShowSkeleton && state.error != null && tickets.isEmpty) {
      return ErrorView(
        key: const ValueKey('error'),
        message: _translateErrorMessage(state.error!, l10n),
        onRetry: () => context.read<TicketBloc>().add(const RefreshTickets()),
      );
    }

    // Show skeleton, empty, or list
    if (shouldShowSkeleton) {
      return const _SkeletonList(key: ValueKey('skeleton'));
    } else if (showEmpty) {
      return _EmptyState(key: const ValueKey('empty'), l10n: l10n);
    } else {
      return _TicketList(
        key: const ValueKey('list'),
        tickets: tickets,
        state: state,
        controller: controller,
      );
    }
  }

  String _translateErrorMessage(String message, AppLocalizations l10n) {
    if (message.contains('Service not reachable')) {
      return l10n.serviceNotReachable;
    }
    if (message.contains('No internet connection')) {
      return l10n.noInternetConnection;
    }
    if (message.contains('Network connection error')) {
      return l10n.checkYourConnection;
    }
    return message;
  }

  Widget _buildTicketCard(
    BuildContext context,
    Ticket ticket,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          _searchFocusNode.unfocus();
          FocusScope.of(context).unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          await controller.openTicketDetail(context, ticket);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.id,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                  StatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.type}:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _getTypeIcon(ticket.type),
                    size: 14,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.type.getLocalizedType(l10n),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        children: [
                          TextSpan(
                            text: '${l10n.createdBy}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ticket.requesterName),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(
                      ticket.createdAt,
                      locale.toString(),
                      includeTime: true,
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPriorityChip(BuildContext context, String priorityName) {
    final priorityService = getIt<PriorityRepository>();
    final localeCode = context.select(
      (LocaleCubit cubit) => cubit.state.languageCode,
    );
    final priority = priorityService.getPriorityByName(priorityName);

    if (priority == null) {
      // Fallback if priority not found
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          priorityName,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final color = priorityService.parseColor(priority.color);
    final displayText = priority.getTranslation(localeCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'INCIDENT':
        return Icons.warning_amber_rounded;
      case 'PROBLEM':
        return FontAwesomeIcons.circleExclamation;
      case 'REQUEST':
        return FontAwesomeIcons.clipboard;
      default:
        return Icons.category;
    }
  }
}

// Optimized TicketCard widget with const constructor
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.id,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                    StatusChip(status: ticket.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.type}:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _getTypeIcon(ticket.type),
                      size: 14,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.type.getLocalizedType(l10n),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          children: [
                            TextSpan(
                              text: '${l10n.createdBy}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ticket.requesterName),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(
                        ticket.createdAt,
                        locale.toString(),
                        includeTime: true,
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _getTypeIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'INCIDENT':
        return Icons.warning_amber_rounded;
      case 'PROBLEM':
        return FontAwesomeIcons.circleExclamation;
      case 'REQUEST':
        return FontAwesomeIcons.clipboard;
      default:
        return Icons.category;
    }
  }
}


class _SkeletonList extends StatelessWidget {
  const _SkeletonList({super.key, this.physics});

  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const _TicketSkeletonCard(),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    super.key,
    required this.tickets,
    required this.state,
    required this.controller,
  });

  final List<Ticket> tickets;
  final TicketState state;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          tickets.length + (state.isLoadingMore && tickets.isNotEmpty ? 1 : 0),
      cacheExtent: 500, // Cache more items for smoother scrolling
      itemBuilder: (context, index) {
        if (index >= tickets.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LoadingAnimationWidget.threeRotatingDots(
                color: AppColors.primaryDark,
                size: 40,
              ),
            ),
          );
        }
        return TicketCard(
          key: ValueKey(tickets[index].id),
          ticket: tickets[index],
          onTap: () => controller.openTicketDetail(context, tickets[index]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.noTicketsFound,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.pullDownToRefresh,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TicketSkeletonCard extends StatelessWidget {
  const _TicketSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBar(width: 120, height: 12),
            const SizedBox(height: 12),
            _SkeletonBar(width: double.infinity, height: 18),
            const SizedBox(height: 8),
            _SkeletonBar(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 16,
            ),
            const SizedBox(height: 8),
            _SkeletonBar(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
            ),
            const SizedBox(height: 6),
            _SkeletonBar(
              width: MediaQuery.of(context).size.width * 0.5,
              height: 12,
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _SkeletonBar(width: double.infinity, height: 14),
                ),
                SizedBox(width: 12),
                _SkeletonBar(width: 80, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.4, end: 0.8),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      onEnd: () {},
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
