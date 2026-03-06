import 'package:flutter_test/flutter_test.dart';
import 'package:lifeplan/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    group('normalize', () {
      test('strips time components from DateTime', () {
        final dateWithTime = DateTime(2024, 3, 15, 14, 30, 45, 123);
        final normalized = AppDateUtils.normalize(dateWithTime);

        expect(normalized.year, 2024);
        expect(normalized.month, 3);
        expect(normalized.day, 15);
        expect(normalized.hour, 0);
        expect(normalized.minute, 0);
        expect(normalized.second, 0);
        expect(normalized.millisecond, 0);
      });

      test('returns same date when already at midnight', () {
        final midnight = DateTime(2024, 1, 1);
        expect(AppDateUtils.normalize(midnight), midnight);
      });
    });

    group('formatKey', () {
      test('formats date as YYYY-MM-DD with zero-padded month and day', () {
        expect(AppDateUtils.formatKey(DateTime(2024, 1, 5)), '2024-01-05');
        expect(AppDateUtils.formatKey(DateTime(2024, 12, 25)), '2024-12-25');
        expect(AppDateUtils.formatKey(DateTime(2023, 6, 30)), '2023-06-30');
      });

      test('pads single-digit months and days', () {
        expect(AppDateUtils.formatKey(DateTime(2024, 3, 1)), '2024-03-01');
        expect(AppDateUtils.formatKey(DateTime(2024, 9, 9)), '2024-09-09');
      });
    });

    group('weekKey', () {
      test('returns the Monday of the given week as YYYY-MM-DD', () {
        // Wednesday 2024-01-10 → Monday 2024-01-08
        expect(AppDateUtils.weekKey(DateTime(2024, 1, 10)), '2024-01-08');
      });

      test('returns same date if already Monday', () {
        // Monday 2024-01-08
        expect(AppDateUtils.weekKey(DateTime(2024, 1, 8)), '2024-01-08');
      });

      test('handles Sunday correctly', () {
        // Sunday 2024-01-14 → Monday 2024-01-08
        expect(AppDateUtils.weekKey(DateTime(2024, 1, 14)), '2024-01-08');
      });
    });

    group('monthKey', () {
      test('returns YYYY-MM with zero-padded month', () {
        expect(AppDateUtils.monthKey(DateTime(2024, 1, 15)), '2024-01');
        expect(AppDateUtils.monthKey(DateTime(2024, 12, 1)), '2024-12');
        expect(AppDateUtils.monthKey(DateTime(2023, 6, 30)), '2023-06');
      });
    });

    group('yearKey', () {
      test('returns year as string', () {
        expect(AppDateUtils.yearKey(DateTime(2024, 1, 1)), '2024');
        expect(AppDateUtils.yearKey(DateTime(2023, 12, 31)), '2023');
      });
    });
  });
}
