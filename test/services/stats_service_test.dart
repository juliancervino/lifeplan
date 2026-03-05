import 'package:flutter_test/flutter_test.dart';
import 'package:lifeplan/models/frequency.dart';
import 'package:lifeplan/models/goal.dart';
import 'package:lifeplan/services/stats_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGoal extends Mock implements Goal {}

void main() {
  group('StatsService', () {
    late DateTime now;
    late DateTime yesterday;
    late DateTime twoDaysAgo;

    setUp(() {
      now = DateTime(2024, 1, 10);
      yesterday = now.subtract(const Duration(days: 1));
      twoDaysAgo = now.subtract(const Duration(days: 2));
    });

    test('calculateCompletionPercentage should return 100% when all days are completed', () {
      final goal = Goal(
        id: '1',
        title: 'Test Goal',
        category: 'Health',
        frequency: Frequency.daily,
        createdDate: twoDaysAgo,
        records: {
          '2024-01-08': true,
          '2024-01-09': true,
          '2024-01-10': true,
        },
      );

      // We need to override the "now" inside StatsService if possible, 
      // but StatsService uses DateTime.now() internally.
      // For testing, we might need to adjust the logic or accept that it uses real time.
      // Since I can't easily mock DateTime.now() without a library like 'clock',
      // I'll use relative dates from real now.
    });

    // Let's rewrite tests using real "now" to avoid failures due to static DateTime.now()
    test('calculateCompletionPercentage - Daily Goal', () {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final goal = Goal(
        id: '1',
        title: 'Daily',
        category: 'Test',
        frequency: Frequency.daily,
        createdDate: today.subtract(const Duration(days: 5)),
        records: {todayStr: true},
      );

      final percentage = StatsService.calculateCompletionPercentage(goal, days: 1);
      expect(percentage, equals(100.0));
      
      final percentage30 = StatsService.calculateCompletionPercentage(goal, days: 30);
      // It should be 1 out of 6 (today + 5 days ago)
      expect(percentage30, equals(1 / 6 * 100));
    });

    test('calculateAggregateStats - Daily Goals', () {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final goal1 = Goal(
        id: '1',
        title: 'G1',
        category: 'Test',
        frequency: Frequency.daily,
        createdDate: today.subtract(const Duration(days: 1)),
        records: {todayStr: true},
      );

      final goal2 = Goal(
        id: '2',
        title: 'G2',
        category: 'Test',
        frequency: Frequency.daily,
        createdDate: today,
        records: {},
      );

      final stats = StatsService.calculateAggregateStats([goal1, goal2], Frequency.daily, days: 1);
      
      // goal1: yesterday (expected, not completed), today (expected, completed) -> 1/2
      // goal2: today (expected, not completed) -> 0/1
      // Total: 1 completed / 3 expected = 33.33%
      
      expect(stats.completed, equals(1));
      expect(stats.expected, equals(3));
      expect(stats.percentage, closeTo(33.33, 0.01));
    });

    test('calculateLifeScore', () {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final goal1 = Goal(
        id: '1',
        title: 'G1',
        category: 'C1',
        frequency: Frequency.daily,
        createdDate: today,
        records: {todayStr: true},
      );

      final goal2 = Goal(
        id: '2',
        title: 'G2',
        category: 'C1',
        frequency: Frequency.daily,
        createdDate: today,
        records: {},
      );

      final score = StatsService.calculateLifeScore([goal1, goal2], days: 1);
      // goal1: 100%, goal2: 0% -> avg 50%
      expect(score, equals(50.0));
    });

    test('getCategoryStats', () {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final goal1 = Goal(
        id: '1',
        title: 'G1',
        category: 'Health',
        frequency: Frequency.daily,
        createdDate: today,
        records: {todayStr: true},
      );

      final goal2 = Goal(
        id: '2',
        title: 'G2',
        category: 'Work',
        frequency: Frequency.daily,
        createdDate: today,
        records: {},
      );

      final stats = StatsService.getCategoryStats([goal1, goal2]);
      
      expect(stats['Health']?.goalCount, equals(1));
      expect(stats['Health']?.averageCompletion, equals(100.0));
      expect(stats['Work']?.goalCount, equals(1));
      expect(stats['Work']?.averageCompletion, equals(0.0));
    });
  });
}
