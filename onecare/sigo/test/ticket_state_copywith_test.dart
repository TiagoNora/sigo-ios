import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/blocs/ticket_bloc.dart';

void main() {
  test('TicketState.copyWith allows clearing nullable fields', () {
    const state = TicketState(
      filterLabel: 'Draft',
      filterLabelKey: 'draft_filter',
      filterQuery: {'operator': 'AND', 'conditions': []},
    );

    final updated = state.copyWith(
      filterLabel: 'My Saved Filter',
      filterLabelKey: null,
      filterQuery: null,
    );

    expect(updated.filterLabel, 'My Saved Filter');
    expect(updated.filterLabelKey, isNull);
    expect(updated.filterQuery, isNull);
  });
}

