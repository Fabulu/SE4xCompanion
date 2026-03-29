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
}
