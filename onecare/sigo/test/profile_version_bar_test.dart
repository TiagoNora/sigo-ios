import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/l10n/app_localizations_en.dart';
import 'package:sigo/ui/views/profile/profile_screen.dart';

void main() {
  testWidgets('version bar shows current year and localized text', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final currentYear = DateTime.now().year.toString();
    const version = 'v1.0.0';
    final expectedCopyright = l10n.copyrightNotice.replaceAll(
      '{year}',
      currentYear,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: buildVersionBar(l10n, versionLabel: version)),
      ),
    );

    expect(
      find.text('${l10n.appVersion} $version - $expectedCopyright'),
      findsOneWidget,
    );
  });
}
