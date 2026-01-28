import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticket.dart';
import '../common/empty_state.dart';
import '../common/loading_indicator.dart';
import 'ticket_card.dart';

/// A list widget for displaying tickets with pagination support.
class TicketList extends StatelessWidget {
  const TicketList({
    super.key,
    required this.tickets,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onTicketTap,
    this.emptyMessage,
  });

  final List<Ticket> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final Function(Ticket) onTicketTap;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading && tickets.isEmpty) {
      return const LoadingIndicator();
    }

    if (tickets.isEmpty) {
      return EmptyState(
        message: emptyMessage ?? l10n.noTicketsFound,
        icon: Icons.confirmation_number_outlined,
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: tickets.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == tickets.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SmallLoadingIndicator(),
          );
        }

        final ticket = tickets[index];
        return TicketCard(ticket: ticket, onTap: () => onTicketTap(ticket));
      },
    );
  }
}
