import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sigo/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    // Initialize locale data for all supported locales
    await initializeDateFormatting('en');
    await initializeDateFormatting('pt');
    await initializeDateFormatting('fr');
    await initializeDateFormatting('de');
  });

  group('formatDate', () {
    group('with time (default)', () {
      test('formats date with English locale', () {
        final date = DateTime(2025, 12, 19, 14, 30);
        final result = formatDate(date, 'en');

        expect(result, '19 Dec 2025 - 14:30');
      });

      test('formats date with Portuguese locale', () {
        final date = DateTime(2025, 12, 19, 14, 30);
        final result = formatDate(date, 'pt');

        expect(result, '19 Dez 2025 - 14:30');
      });

      test('formats date with French locale', () {
        final date = DateTime(2025, 1, 15, 9, 45);
        final result = formatDate(date, 'fr');

        expect(result, contains('Janv')); // French abbreviation
        expect(result, contains('2025'));
        expect(result, contains('09:45'));
      });

      test('formats date with German locale', () {
        final date = DateTime(2025, 3, 20, 16, 15);
        final result = formatDate(date, 'de');

        expect(result, contains('Mär')); // German abbreviation for March
        expect(result, contains('2025'));
        expect(result, contains('16:15'));
      });

      test('capitalizes month abbreviation', () {
        final date = DateTime(2025, 6, 10, 12, 0);
        final result = formatDate(date, 'en');

        // Should start with capital letter
        expect(result, contains('Jun')); // Not 'jun'
        expect(result, isNot(contains('jun')));
      });

      test('removes periods from abbreviations', () {
        final date = DateTime(2025, 1, 1, 10, 30);
        final result = formatDate(date, 'de');

        // German often uses periods like "Jan." but they should be removed
        expect(result, isNot(contains('.')));
      });

      test('handles single-digit days', () {
        final date = DateTime(2025, 5, 5, 8, 15);
        final result = formatDate(date, 'en');

        expect(result, startsWith('05')); // Day should be zero-padded
      });

      test('handles single-digit hours', () {
        final date = DateTime(2025, 5, 15, 9, 5);
        final result = formatDate(date, 'en');

        expect(result, contains('09:05')); // Time should be zero-padded
      });

      test('handles midnight', () {
        final date = DateTime(2025, 1, 1, 0, 0);
        final result = formatDate(date, 'en');

        expect(result, contains('00:00'));
      });

      test('handles end of day', () {
        final date = DateTime(2025, 12, 31, 23, 59);
        final result = formatDate(date, 'en');

        expect(result, contains('23:59'));
      });
    });

    group('without time', () {
      test('formats date only with English locale', () {
        final date = DateTime(2025, 12, 19, 14, 30);
        final result = formatDate(date, 'en', includeTime: false);

        expect(result, '19 Dec 2025');
        expect(result, isNot(contains('14:30')));
        expect(result, isNot(contains('-')));
      });

      test('formats date only with Portuguese locale', () {
        final date = DateTime(2025, 8, 25, 10, 0);
        final result = formatDate(date, 'pt', includeTime: false);

        expect(result, contains('Ago')); // Portuguese abbreviation for August
        expect(result, contains('2025'));
        expect(result, isNot(contains('10:00')));
      });

      test('formats date only with French locale', () {
        final date = DateTime(2025, 2, 14, 18, 30);
        final result = formatDate(date, 'fr', includeTime: false);

        expect(result, contains('Févr')); // French abbreviation
        expect(result, contains('2025'));
        expect(result, isNot(contains('18:30')));
      });

      test('capitalizes all parts correctly', () {
        final date = DateTime(2025, 11, 30, 12, 0);
        final result = formatDate(date, 'en', includeTime: false);

        // Each part should be capitalized
        expect(result, matches(RegExp(r'^\d+ [A-Z][a-z]+ \d+$')));
      });
    });

    group('edge cases', () {
      test('handles leap year date', () {
        final date = DateTime(2024, 2, 29, 12, 0); // Leap year
        final result = formatDate(date, 'en');

        expect(result, contains('29 Feb 2024'));
      });

      test('handles first day of year', () {
        final date = DateTime(2025, 1, 1, 0, 0);
        final result = formatDate(date, 'en');

        expect(result, contains('01 Jan 2025'));
      });

      test('handles last day of year', () {
        final date = DateTime(2025, 12, 31, 23, 59);
        final result = formatDate(date, 'en');

        expect(result, contains('31 Dec 2025'));
      });

      test('handles distant past date', () {
        final date = DateTime(1900, 1, 1, 12, 0);
        final result = formatDate(date, 'en');

        expect(result, contains('1900'));
      });

      test('handles distant future date', () {
        final date = DateTime(2099, 12, 31, 23, 59);
        final result = formatDate(date, 'en');

        expect(result, contains('2099'));
      });
    });

    group('consistency across locales', () {
      test('all locales format the same date with consistent structure', () {
        final date = DateTime(2025, 6, 15, 14, 30);
        final locales = ['en', 'pt', 'fr', 'de'];

        for (final locale in locales) {
          final result = formatDate(date, locale);

          // All should have the same structure
          expect(result, matches(RegExp(r'^\d+ \w+ \d+ - \d+:\d+$')));
          // All should contain the year
          expect(result, contains('2025'));
          // All should contain the day
          expect(result, contains('15'));
          // All should contain the time
          expect(result, contains('14:30'));
          // None should contain periods
          expect(result, isNot(contains('.')));
        }
      });

      test('all locales format date-only with consistent structure', () {
        final date = DateTime(2025, 6, 15, 14, 30);
        final locales = ['en', 'pt', 'fr', 'de'];

        for (final locale in locales) {
          final result = formatDate(date, locale, includeTime: false);

          // All should have the same structure
          expect(result, matches(RegExp(r'^\d+ \w+ \d+$')));
          // All should contain the year
          expect(result, contains('2025'));
          // All should contain the day
          expect(result, contains('15'));
          // None should contain time
          expect(result, isNot(contains(':')));
          expect(result, isNot(contains('-')));
        }
      });
    });

    group('month abbreviations', () {
      test('capitalizes English month abbreviations', () {
        final months = [
          DateTime(2025, 1, 1), // Jan
          DateTime(2025, 2, 1), // Feb
          DateTime(2025, 3, 1), // Mar
          DateTime(2025, 4, 1), // Apr
          DateTime(2025, 5, 1), // May
          DateTime(2025, 6, 1), // Jun
          DateTime(2025, 7, 1), // Jul
          DateTime(2025, 8, 1), // Aug
          DateTime(2025, 9, 1), // Sep
          DateTime(2025, 10, 1), // Oct
          DateTime(2025, 11, 1), // Nov
          DateTime(2025, 12, 1), // Dec
        ];

        final expectedAbbreviations = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];

        for (var i = 0; i < months.length; i++) {
          final result = formatDate(months[i], 'en', includeTime: false);
          expect(result, contains(expectedAbbreviations[i]));
        }
      });

      test('capitalizes Portuguese month abbreviations', () {
        final date = DateTime(2025, 1, 1);
        final result = formatDate(date, 'pt', includeTime: false);

        // Portuguese January abbreviation should be capitalized
        expect(result, matches(RegExp(r'[A-Z][a-z]+')));
      });
    });

    group('zero-padding', () {
      test('pads single-digit days with zero', () {
        for (var day = 1; day <= 9; day++) {
          final date = DateTime(2025, 1, day, 12, 0);
          final result = formatDate(date, 'en');

          expect(result, startsWith('0$day '));
        }
      });

      test('pads single-digit hours with zero', () {
        for (var hour = 0; hour <= 9; hour++) {
          final date = DateTime(2025, 1, 1, hour, 30);
          final result = formatDate(date, 'en');

          expect(result, contains('0$hour:30'));
        }
      });

      test('pads single-digit minutes with zero', () {
        for (var minute = 0; minute <= 9; minute++) {
          final date = DateTime(2025, 1, 1, 12, minute);
          final result = formatDate(date, 'en');

          expect(result, contains('12:0$minute'));
        }
      });
    });
  });
}
