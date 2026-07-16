import 'package:flutter_test/flutter_test.dart';
import '../features/events/domains/models/event_filter.dart';

void main() {
  group('EventFilter', () {
    test('isEmpty returns true when no filter is set', () {
      const filter = EventFilter();
      expect(filter.isEmpty, isTrue);
    });

    test('isEmpty returns false when a keyword is set', () {
      const filter = EventFilter(keyword: 'test');
      expect(filter.isEmpty, isFalse);
    });

    test('copyWith updates keyword correctly', () {
      const filter = EventFilter();
      final updated = filter.copyWith(keyword: 'food');
      expect(updated.keyword, 'food');
      expect(updated.location, isNull);
    });

    test('copyWith can set keyword to null', () {
      const filter = EventFilter();
      final cleared = filter.copyWith(keyword: null);
      expect(cleared.keyword, isNull);
    });

    test('copyWith isEmpty returns true after clearing keyword', () {
      const filter = EventFilter();
      final cleared = filter.copyWith(keyword: null);
      expect(cleared.isEmpty, isTrue);
    });
  });
}
