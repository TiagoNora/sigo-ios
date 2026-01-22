import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigo/blocs/locale_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to English locale when no preference saved', () async {
    final cubit = LocaleCubit();
    await Future.delayed(Duration.zero);
    expect(cubit.state.languageCode, 'en');
    await cubit.close();
  });

  test('loads saved locale from shared preferences', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'pt'});

    final cubit = LocaleCubit();
    await Future.delayed(Duration.zero);

    expect(cubit.state.languageCode, 'pt');
    await cubit.close();
  });

  test('setLocale updates locale and persists', () async {
    final cubit = LocaleCubit();
    await Future.delayed(Duration.zero);

    var emitted = 0;
    final sub = cubit.stream.listen((_) => emitted++);

    await cubit.setLocale(const Locale('fr'));

    expect(cubit.state.languageCode, 'fr');
    expect(emitted, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'fr');

    await sub.cancel();
    await cubit.close();
  });
}
