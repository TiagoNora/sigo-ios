import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/l10n/app_localizations_en.dart';
import 'package:sigo/models/ticket.dart';
import 'package:sigo/models/ticket_extensions.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('TicketStatusExtension', () {
    test('returns localized names', () {
      expect(TicketStatus.open.getLocalizedName(l10n), l10n.open);
      expect(TicketStatus.acknowledged.getLocalizedName(l10n), l10n.acknowledged);
      expect(TicketStatus.inProgress.getLocalizedName(l10n), l10n.inProgress);
    });
  });

  group('TicketPriorityExtension', () {
    test('returns localized names', () {
      expect(TicketPriority.low.getLocalizedName(l10n), l10n.low);
      expect(TicketPriority.high.getLocalizedName(l10n), l10n.high);
    });
  });

  group('TicketTypeExtension', () {
    test('localizes known types', () {
      expect('INCIDENT'.getLocalizedType(l10n), l10n.incident);
      expect('PROBLEM'.getLocalizedType(l10n), l10n.problem);
      expect('REQUEST'.getLocalizedType(l10n), l10n.request);
    });

    test('handles lowercase and trimmed values', () {
      expect('incident'.getLocalizedType(l10n), l10n.incident);
      expect('  problem  '.getLocalizedType(l10n), l10n.problem);
    });

    test('falls back to original or NA for unknown', () {
      expect('OTHER'.getLocalizedType(l10n), 'OTHER');
      expect((null as String?).getLocalizedType(l10n), l10n.na);
      expect(''.getLocalizedType(l10n), l10n.na);
    });
  });
}
