import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/turn_summary.dart';

void main() {
  group('TurnSummary JSON round-trip', () {
    test('round-trip with all fields populated', () {
      final ts = TurnSummary(
        turnNumber: 3,
        completedAt: DateTime.utc(2025, 7, 10, 14, 30, 45),
        techsGained: ['Attack-1', 'Defense-2'],
        shipsBuilt: ['DD x3', 'CA x1'],
        coloniesGrown: 2,
        cpLostToCap: 5,
        rpLostToCap: 3,
        cpCarryOver: 20,
        rpCarryOver: 15,
        maintenancePaid: 8,
      );

      final json = ts.toJson();
      final restored = TurnSummary.fromJson(json);

      expect(restored.turnNumber, 3);
      expect(restored.completedAt, DateTime.utc(2025, 7, 10, 14, 30, 45));
      expect(restored.techsGained, ['Attack-1', 'Defense-2']);
      expect(restored.shipsBuilt, ['DD x3', 'CA x1']);
      expect(restored.coloniesGrown, 2);
      expect(restored.cpLostToCap, 5);
      expect(restored.rpLostToCap, 3);
      expect(restored.cpCarryOver, 20);
      expect(restored.rpCarryOver, 15);
      expect(restored.maintenancePaid, 8);
    });

    test('round-trip with empty lists', () {
      final ts = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime.utc(2025, 1, 1),
        techsGained: [],
        shipsBuilt: [],
        coloniesGrown: 0,
        cpLostToCap: 0,
        rpLostToCap: 0,
        cpCarryOver: 0,
        rpCarryOver: 0,
        maintenancePaid: 0,
      );

      final json = ts.toJson();
      final restored = TurnSummary.fromJson(json);

      expect(restored.turnNumber, 1);
      expect(restored.techsGained, isEmpty);
      expect(restored.shipsBuilt, isEmpty);
      expect(restored.coloniesGrown, 0);
      expect(restored.cpLostToCap, 0);
      expect(restored.rpLostToCap, 0);
    });

    test('DateTime serialization uses ISO 8601', () {
      final ts = TurnSummary(
        turnNumber: 5,
        completedAt: DateTime.utc(2025, 12, 31, 23, 59, 59),
      );

      final json = ts.toJson();
      expect(json['completedAt'], '2025-12-31T23:59:59.000Z');

      final restored = TurnSummary.fromJson(json);
      expect(restored.completedAt.year, 2025);
      expect(restored.completedAt.month, 12);
      expect(restored.completedAt.day, 31);
      expect(restored.completedAt.hour, 23);
      expect(restored.completedAt.minute, 59);
      expect(restored.completedAt.second, 59);
      expect(restored.completedAt.isUtc, true);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = <String, dynamic>{
        'turnNumber': 2,
        'completedAt': '2025-06-15T10:00:00.000Z',
      };
      final restored = TurnSummary.fromJson(json);

      expect(restored.turnNumber, 2);
      expect(restored.techsGained, isEmpty);
      expect(restored.shipsBuilt, isEmpty);
      expect(restored.coloniesGrown, 0);
      expect(restored.cpLostToCap, 0);
      expect(restored.rpLostToCap, 0);
      expect(restored.cpCarryOver, 0);
      expect(restored.rpCarryOver, 0);
      expect(restored.maintenancePaid, 0);
    });
  });
}
