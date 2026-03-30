import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/technology.dart';

void main() {
  group('TechState getLevel', () {
    test('returns start level when no levels set (base mode)', () {
      const tech = TechState();
      expect(tech.getLevel(TechId.shipSize), 1);
      expect(tech.getLevel(TechId.move), 1);
      expect(tech.getLevel(TechId.shipYard), 1);
      expect(tech.getLevel(TechId.attack), 0);
      expect(tech.getLevel(TechId.defense), 0);
      expect(tech.getLevel(TechId.tactics), 0);
    });

    test('returns start level in facilities mode', () {
      const tech = TechState();
      expect(tech.getLevel(TechId.supplyRange, facilitiesMode: true), 1);
      expect(tech.getLevel(TechId.ground, facilitiesMode: true), 1);
      expect(tech.getLevel(TechId.advancedCon, facilitiesMode: true), 0);
    });

    test('returns set level when explicitly set', () {
      const tech = TechState(levels: {TechId.attack: 2, TechId.defense: 1});
      expect(tech.getLevel(TechId.attack), 2);
      expect(tech.getLevel(TechId.defense), 1);
    });
  });

  group('TechState setLevel', () {
    test('creates new state with updated level', () {
      const tech = TechState();
      final updated = tech.setLevel(TechId.attack, 2);
      expect(updated.getLevel(TechId.attack), 2);
      // Original unchanged
      expect(tech.getLevel(TechId.attack), 0);
    });

    test('can set multiple levels', () {
      var tech = const TechState();
      tech = tech.setLevel(TechId.attack, 1);
      tech = tech.setLevel(TechId.defense, 2);
      tech = tech.setLevel(TechId.move, 3);
      expect(tech.getLevel(TechId.attack), 1);
      expect(tech.getLevel(TechId.defense), 2);
      expect(tech.getLevel(TechId.move), 3);
    });

    test('overwriting a level replaces old value', () {
      var tech = const TechState(levels: {TechId.attack: 1});
      tech = tech.setLevel(TechId.attack, 3);
      expect(tech.getLevel(TechId.attack), 3);
    });
  });

  group('TechState costForNext', () {
    test('returns correct cost for next level (base mode)', () {
      const tech = TechState();
      expect(tech.costForNext(TechId.attack), 20); // 0->1
      expect(tech.costForNext(TechId.shipSize), 10); // 1->2
    });

    test('returns null when at max level', () {
      const tech = TechState(levels: {TechId.attack: 3});
      expect(tech.costForNext(TechId.attack), isNull);
    });

    test('returns null for unknown tech in base mode', () {
      const tech = TechState();
      // supplyRange is not in base costs
      expect(tech.costForNext(TechId.supplyRange), isNull);
    });

    test('returns correct cost in facilities mode', () {
      const tech = TechState();
      expect(tech.costForNext(TechId.attack, facilitiesMode: true), 20); // 0->1
      expect(tech.costForNext(TechId.supplyRange, facilitiesMode: true), 10); // 1->2
    });

    test('after setting level, cost adjusts', () {
      const tech = TechState(levels: {TechId.attack: 1});
      expect(tech.costForNext(TechId.attack), 30); // 1->2
    });
  });

  group('TechState maxLevel', () {
    test('base mode max levels', () {
      const tech = TechState();
      expect(tech.maxLevel(TechId.attack), 3);
      expect(tech.maxLevel(TechId.shipSize), 6);
      expect(tech.maxLevel(TechId.terraforming), 1);
      expect(tech.maxLevel(TechId.mines), 1);
    });

    test('facilities mode max levels differ', () {
      const tech = TechState();
      expect(tech.maxLevel(TechId.attack, facilitiesMode: true), 4);
      expect(tech.maxLevel(TechId.shipSize, facilitiesMode: true), 7);
      expect(tech.maxLevel(TechId.move, facilitiesMode: true), 7);
    });
  });

  group('TechState JSON round-trip', () {
    test('empty state round-trips', () {
      const tech = TechState();
      final json = tech.toJson();
      final restored = TechState.fromJson(json);
      expect(restored.levels, isEmpty);
    });

    test('populated state round-trips', () {
      const tech = TechState(levels: {
        TechId.attack: 2,
        TechId.defense: 1,
        TechId.move: 3,
        TechId.cloaking: 1,
      });
      final json = tech.toJson();
      final restored = TechState.fromJson(json);
      expect(restored.getLevel(TechId.attack), 2);
      expect(restored.getLevel(TechId.defense), 1);
      expect(restored.getLevel(TechId.move), 3);
      expect(restored.getLevel(TechId.cloaking), 1);
    });

    test('unknown tech names in JSON are ignored', () {
      final json = {
        'levels': {'nonExistentTech': 5, 'attack': 2}
      };
      final restored = TechState.fromJson(json);
      expect(restored.getLevel(TechId.attack), 2);
      expect(restored.levels.length, 1);
    });
  });

  group('Tech cost progression lookup', () {
    test('Attack base: levels 1-3 with costs 20, 30, 40', () {
      final entry = kBaseTechCosts[TechId.attack]!;
      expect(entry.startLevel, 0);
      expect(entry.levelCosts[1], 20);
      expect(entry.levelCosts[2], 30);
      expect(entry.levelCosts[3], 40);
      expect(entry.maxLevel, 3);
    });

    test('ShipSize base: starts at 1, levels 2-6', () {
      final entry = kBaseTechCosts[TechId.shipSize]!;
      expect(entry.startLevel, 1);
      expect(entry.levelCosts[2], 10);
      expect(entry.levelCosts[3], 15);
      expect(entry.levelCosts[4], 20);
      expect(entry.levelCosts[5], 25);
      expect(entry.levelCosts[6], 30);
      expect(entry.maxLevel, 6);
    });

    test('Move base: starts at 1, levels 2-6', () {
      final entry = kBaseTechCosts[TechId.move]!;
      expect(entry.startLevel, 1);
      expect(entry.levelCosts[2], 20);
      expect(entry.levelCosts[3], 30);
      expect(entry.levelCosts[4], 40);
      expect(entry.levelCosts[5], 50);
      expect(entry.levelCosts[6], 60);
      expect(entry.maxLevel, 6);
    });

    test('Tactics base: levels 1-3 with costs 15, 20, 30', () {
      final entry = kBaseTechCosts[TechId.tactics]!;
      expect(entry.startLevel, 0);
      expect(entry.levelCosts[1], 15);
      expect(entry.levelCosts[2], 20);
      expect(entry.levelCosts[3], 30);
      expect(entry.maxLevel, 3);
    });

    test('Terraforming base: single level costing 25', () {
      final entry = kBaseTechCosts[TechId.terraforming]!;
      expect(entry.startLevel, 0);
      expect(entry.levelCosts[1], 25);
      expect(entry.maxLevel, 1);
    });

    test('Attack facilities: levels 1-4 with costs 20, 30, 25, 10', () {
      final entry = kFacilitiesTechCosts[TechId.attack]!;
      expect(entry.startLevel, 0);
      expect(entry.levelCosts[1], 20);
      expect(entry.levelCosts[2], 30);
      expect(entry.levelCosts[3], 25);
      expect(entry.levelCosts[4], 10);
      expect(entry.maxLevel, 4);
    });

    test('ShipSize facilities: starts at 1, levels 2-7', () {
      final entry = kFacilitiesTechCosts[TechId.shipSize]!;
      expect(entry.startLevel, 1);
      expect(entry.levelCosts[7], 30);
      expect(entry.maxLevel, 7);
    });

    test('costForNext returns null past max level', () {
      final entry = kBaseTechCosts[TechId.attack]!;
      expect(entry.costForNext(3), isNull); // max is 3
    });

    test('costForNext returns correct cost for each step', () {
      final entry = kBaseTechCosts[TechId.attack]!;
      expect(entry.costForNext(0), 20); // 0->1
      expect(entry.costForNext(1), 30); // 1->2
      expect(entry.costForNext(2), 40); // 2->3
    });
  });

  group('TechState withPending', () {
    test('merges pending levels correctly', () {
      const tech = TechState(levels: {TechId.attack: 1, TechId.defense: 0});
      final merged = tech.withPending({TechId.tactics: 2, TechId.move: 3});
      expect(merged.levels[TechId.attack], 1);
      expect(merged.levels[TechId.defense], 0);
      expect(merged.levels[TechId.tactics], 2);
      expect(merged.levels[TechId.move], 3);
    });

    test('with empty map returns same instance', () {
      const tech = TechState(levels: {TechId.attack: 1});
      final result = tech.withPending({});
      expect(identical(result, tech), true);
    });

    test('overrides existing levels', () {
      const tech = TechState(levels: {TechId.attack: 1, TechId.defense: 1});
      final merged = tech.withPending({TechId.attack: 3});
      expect(merged.levels[TechId.attack], 3);
      expect(merged.levels[TechId.defense], 1);
    });
  });
}
