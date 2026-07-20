import 'package:flutter_test/flutter_test.dart';
import 'package:saccoapp/core/utils/parsing.dart';

void main() {
  group('parseDouble', () {
    test('parses a Django-style stringified decimal', () {
      expect(parseDouble('20000.00'), 20000.0);
    });

    test('parses a raw JSON number', () {
      expect(parseDouble(20000), 20000.0);
      expect(parseDouble(20000.5), 20000.5);
    });

    test('falls back to default on null', () {
      expect(parseDouble(null), 0.0);
      expect(parseDouble(null, 42.0), 42.0);
    });

    test('falls back to default on an unparseable string', () {
      expect(parseDouble('not-a-number', 5.0), 5.0);
    });
  });
}
