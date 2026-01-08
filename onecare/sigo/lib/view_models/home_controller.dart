import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../blocs/ticket_bloc.dart';
import '../constants/app_durations.dart';
import '../models/ticket.dart';
import '../ui/views/tickets/create_edit_ticket_screen.dart';
import '../ui/views/filters/filter_screen.dart';
import '../ui/views/tickets/ticket_detail_screen.dart';

/// Handles Home screen behaviors (search debounce, pagination trigger, navigation).
class HomeController {
  HomeController({required this.ticketBloc});

  final TicketBloc ticketBloc;

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? _searchDebounce;
  Timer? _scrollDebounce;

  void init() {
    scrollController.addListener(_onScroll);
  }

  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    _scrollDebounce?.cancel();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    final state = ticketBloc.state;

    if (position.pixels >= position.maxScrollExtent - 200 &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.hasMore) {
      // Debounce scroll events to prevent multiple rapid load requests
      _scrollDebounce?.cancel();
      _scrollDebounce = Timer(AppDurations.scrollDebounce, () {
        ticketBloc.add(const LoadMoreTickets());
      });
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppDurations.searchDebounce, () {
      ticketBloc.add(ApplySearch(value));
    });
  }

  void clearSearch() {
    searchController.clear();
    _searchDebounce?.cancel();
    ticketBloc.add(const ApplySearch(''));
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: AppDurations.animationNormal,
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> refresh() async {
    ticketBloc.add(const RefreshTickets());
  }

  Future<void> openFilter(BuildContext context, TicketState state) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          initialStatus: null,
          initialPriority: null,
          initialCategory: null,
          initialQuery: state.filterQuery,
          initialSourceFilterId: state.filterSourceId,
          initialFilterLabel: state.filterLabel,
          initialFilterLabelKey: state.filterLabelKey,
        ),
      ),
    );

    if (result != null) {
      ticketBloc.add(
        ApplyFilter(
          filterQuery: result['query'] as Map<String, dynamic>?,
          filterLabel: result['filterName'] as String?,
          filterLabelKey: result['filterNameKey'] as String?,
          filterSourceId: result['sourceFilterId'] as int?,
        ),
      );
    }
  }

  Future<void> openTicketDetail(BuildContext context, Ticket ticket) async {
    // Dismiss keyboard immediately before navigation
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Small delay to ensure keyboard is fully dismissed
    await Future.delayed(const Duration(milliseconds: 150));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );

    if (context.mounted) {
      // Ensure keyboard stays dismissed after returning
      FocusScope.of(context).unfocus();
      ticketBloc.add(const RefreshTickets());
    }
  }

  Future<void> openCreateTicket(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEditTicketScreen()),
    );

    if (result == true && context.mounted) {
      ticketBloc.add(const RefreshTickets());
    }
  }
}
