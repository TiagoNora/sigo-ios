import 'package:flutter_test/flutter_test.dart';
import 'package:sigo/services/version_info.dart';

void main() {
  test('stores and exposes provided version label', () {
    const info = VersionInfo('v2.5.1');

    expect(info.label, 'v2.5.1');
  });
}
