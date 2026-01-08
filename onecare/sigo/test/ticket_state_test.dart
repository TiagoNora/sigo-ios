import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/blocs/ticket_bloc.dart';

void main() {
  group('TicketState', () {
    test('defaults start in loading until first fetch completes', () {
      const state = TicketState();

      expect(state.isLoading, isTrue);
      expect(state.hasLoadedOnce, isFalse);
      expect(state.tickets, isEmpty);
    });

    test('copyWith updates hasLoadedOnce and tickets', () {
      const initial = TicketState();
      final updated = initial.copyWith(
        hasLoadedOnce: true,
        tickets: const [],
        isLoading: false,
      );

      expect(updated.hasLoadedOnce, isTrue);
      expect(updated.isLoading, isFalse);
      expect(updated.tickets, isEmpty);
    });
  });
}
