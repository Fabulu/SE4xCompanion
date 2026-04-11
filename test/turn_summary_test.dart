import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/turn_summary.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('TurnSummary JSON round-trip', () {
    test('round-trip with all flat fields populated', () {
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
      expect(restored.committedAt, DateTime.utc(2025, 7, 10, 14, 30, 45));
      expect(restored.techsGained, ['Attack-1', 'Defense-2']);
      expect(restored.shipsBuilt, ['DD x3', 'CA x1']);
      expect(restored.coloniesGrown, 2);
      expect(restored.cpLostToCap, 5);
      expect(restored.rpLostToCap, 3);
      expect(restored.cpCarryOver, 20);
      expect(restored.cpAtTurnEnd, 20);
      expect(restored.rpCarryOver, 15);
      expect(restored.rpAtTurnEnd, 15);
      expect(restored.maintenancePaid, 8);
      expect(restored.productionSnapshot, isNull);
    });

    test('round-trip with empty lists', () {
      final ts = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime.utc(2025, 1, 1),
        techsGained: [],
        shipsBuilt: [],
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
      expect(restored.completedAt.isUtc, true);
      expect(restored.completedAt.year, 2025);
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
      expect(restored.cpCarryOver, 0);
      expect(restored.maintenancePaid, 0);
      expect(restored.productionSnapshot, isNull);
    });

    test('round-trip with full ProductionState snapshot', () {
      const snapshot = ProductionState(
        cpCarryOver: 12,
        turnOrderBid: 3,
        upgradesCp: 2,
        maintenanceIncrease: 1,
        rpCarryOver: 4,
        pipelineConnectedColonies: 2,
        worlds: [
          WorldState(
            id: 'world-1',
            name: 'HW',
            isHomeworld: true,
            homeworldValue: 20,
          ),
          WorldState(
            id: 'world-2',
            name: 'Colony A',
            growthMarkerLevel: 2,
            stagedMineralCp: 3,
          ),
        ],
        techState: TechState(),
      );

      final ts = TurnSummary(
        turnNumber: 4,
        completedAt: DateTime.utc(2026, 2, 1, 12, 0, 0),
        productionSnapshot: snapshot,
        techsGained: ['Move-2'],
        shipsBuilt: ['DD x2'],
        coloniesGrown: 1,
        cpCarryOver: 12,
        rpCarryOver: 4,
        maintenancePaid: 5,
      );

      final json = ts.toJson();
      expect(json['productionSnapshot'], isA<Map<String, dynamic>>());

      final restored = TurnSummary.fromJson(json);
      expect(restored.productionSnapshot, isNotNull);
      final snap = restored.productionSnapshot!;
      expect(snap.cpCarryOver, 12);
      expect(snap.turnOrderBid, 3);
      expect(snap.upgradesCp, 2);
      expect(snap.maintenanceIncrease, 1);
      expect(snap.rpCarryOver, 4);
      expect(snap.pipelineConnectedColonies, 2);
      expect(snap.worlds.length, 2);
      expect(snap.worlds[0].id, 'world-1');
      expect(snap.worlds[0].isHomeworld, isTrue);
      expect(snap.worlds[1].growthMarkerLevel, 2);
      expect(snap.worlds[1].stagedMineralCp, 3);
    });

    test('legacy save without productionSnapshot loads with null snapshot',
        () {
      // Shape matches pre-snapshot TurnSummary format.
      final legacyJson = <String, dynamic>{
        'turnNumber': 7,
        'completedAt': '2025-03-01T08:00:00.000Z',
        'techsGained': ['Attack-1'],
        'shipsBuilt': ['SC x1'],
        'coloniesGrown': 2,
        'cpLostToCap': 4,
        'rpLostToCap': 0,
        'cpCarryOver': 22,
        'rpCarryOver': 0,
        'maintenancePaid': 6,
      };

      final restored = TurnSummary.fromJson(legacyJson);
      expect(restored.productionSnapshot, isNull);
      expect(restored.turnNumber, 7);
      expect(restored.techsGained, ['Attack-1']);
      expect(restored.shipsBuilt, ['SC x1']);
      expect(restored.coloniesGrown, 2);
      expect(restored.cpLostToCap, 4);
      expect(restored.cpCarryOver, 22);
      expect(restored.maintenancePaid, 6);
    });

    test('toJson omits productionSnapshot key when snapshot is null', () {
      final ts = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime.utc(2025, 1, 1),
      );
      final json = ts.toJson();
      expect(json.containsKey('productionSnapshot'), isFalse);
    });
  });
}
