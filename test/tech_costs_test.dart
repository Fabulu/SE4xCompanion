import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/tech_costs.dart';

void main() {
  group('Base game tech costs', () {
    test('contains 20 techs (14 base + 6 CE)', () {
      expect(kBaseTechCosts.length, 20);
    });

    test('ShipSize starts at 1, costs 10/15/20/25/30', () {
      final e = kBaseTechCosts[TechId.shipSize]!;
      expect(e.startLevel, 1);
      expect(e.levelCosts, {2: 10, 3: 15, 4: 20, 5: 25, 6: 30});
      expect(e.maxLevel, 6);
    });

    test('Attack starts at 0, costs 20/30/40', () {
      final e = kBaseTechCosts[TechId.attack]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 20, 2: 30, 3: 40});
    });

    test('Defense starts at 0, costs 20/30/40', () {
      final e = kBaseTechCosts[TechId.defense]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 20, 2: 30, 3: 40});
    });

    test('Tactics starts at 0, costs 15/20/30', () {
      final e = kBaseTechCosts[TechId.tactics]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 15, 2: 20, 3: 30});
    });

    test('Move starts at 1, costs 20/30/40/50/60', () {
      final e = kBaseTechCosts[TechId.move]!;
      expect(e.startLevel, 1);
      expect(e.levelCosts, {2: 20, 3: 30, 4: 40, 5: 50, 6: 60});
    });

    test('ShipYard starts at 1, costs 20/30', () {
      final e = kBaseTechCosts[TechId.shipYard]!;
      expect(e.startLevel, 1);
      expect(e.levelCosts, {2: 20, 3: 30});
    });

    test('Terraforming starts at 0, costs 25', () {
      final e = kBaseTechCosts[TechId.terraforming]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 25});
    });

    test('Exploration starts at 0, costs 15', () {
      final e = kBaseTechCosts[TechId.exploration]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 15});
    });

    test('Fighters starts at 0, costs 25/30/40', () {
      final e = kBaseTechCosts[TechId.fighters]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 25, 2: 30, 3: 40});
    });

    test('PointDefense starts at 0, costs 20/25/30', () {
      final e = kBaseTechCosts[TechId.pointDefense]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 20, 2: 25, 3: 30});
    });

    test('Cloaking starts at 0, costs 30/40', () {
      final e = kBaseTechCosts[TechId.cloaking]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 30, 2: 40});
    });

    test('Scanners starts at 0, costs 20/30', () {
      final e = kBaseTechCosts[TechId.scanners]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 20, 2: 30});
    });

    test('Mines starts at 0, costs 20', () {
      final e = kBaseTechCosts[TechId.mines]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 20});
    });

    test('MineSweep starts at 0, costs 10/20', () {
      final e = kBaseTechCosts[TechId.mineSweep]!;
      expect(e.startLevel, 0);
      expect(e.levelCosts, {1: 10, 2: 20});
    });

    test('correct start levels: ShipSize=1, Move=1, ShipYard=1, Ground=1, others=0', () {
      for (final entry in kBaseTechCosts.entries) {
        final id = entry.key;
        final e = entry.value;
        if (id == TechId.shipSize || id == TechId.move || id == TechId.shipYard || id == TechId.ground) {
          expect(e.startLevel, 1, reason: '${id.name} should start at 1');
        } else {
          expect(e.startLevel, 0, reason: '${id.name} should start at 0');
        }
      }
    });
  });

  group('Facilities/AGT tech costs', () {
    test('contains exactly 26 techs', () {
      expect(kFacilitiesTechCosts.length, 26);
    });

    test('SupplyRange starts at 1', () {
      final e = kFacilitiesTechCosts[TechId.supplyRange]!;
      expect(e.startLevel, 1);
      expect(e.levelCosts, {2: 10, 3: 15, 4: 15});
    });

    test('Ground starts at 1', () {
      final e = kFacilitiesTechCosts[TechId.ground]!;
      expect(e.startLevel, 1);
      expect(e.levelCosts, {2: 10, 3: 15});
    });

    test('correct start levels in facilities mode', () {
      final startsAtOne = {
        TechId.shipSize, TechId.move, TechId.shipYard,
        TechId.supplyRange, TechId.ground,
      };
      for (final entry in kFacilitiesTechCosts.entries) {
        if (startsAtOne.contains(entry.key)) {
          expect(entry.value.startLevel, 1, reason: '${entry.key.name} should start at 1');
        } else {
          expect(entry.value.startLevel, 0, reason: '${entry.key.name} should start at 0');
        }
      }
    });

    test('Move costs differ between base and AGT', () {
      final base = kBaseTechCosts[TechId.move]!;
      final agt = kFacilitiesTechCosts[TechId.move]!;
      // Base: 20/30/40/50/60 vs AGT: 20/25/25/25/20/20
      expect(base.levelCosts[3], 30);
      expect(agt.levelCosts[3], 25);
      expect(base.levelCosts.length, 5);
      expect(agt.levelCosts.length, 6); // AGT goes to level 7
    });

    test('Mines costs differ between base and AGT', () {
      final base = kBaseTechCosts[TechId.mines]!;
      final agt = kFacilitiesTechCosts[TechId.mines]!;
      expect(base.levelCosts[1], 20);
      expect(agt.levelCosts[1], 30);
    });

    test('AGT-only techs not in base, CE techs in both', () {
      // These are AGT-only (not in base)
      final agtOnly = [
        TechId.supplyRange, TechId.advancedCon,
        TechId.antiReplicator, TechId.jammers,
        TechId.tractorBeamBb, TechId.shieldProjDn,
      ];
      for (final id in agtOnly) {
        expect(kBaseTechCosts.containsKey(id), false, reason: '${id.name} should not be in base');
        expect(kFacilitiesTechCosts.containsKey(id), true, reason: '${id.name} should be in AGT');
      }
      // These are CE techs present in BOTH tables
      final ceTechs = [
        TechId.ground, TechId.boarding, TechId.securityForces,
        TechId.missileBoats, TechId.fastBcAbility, TechId.militaryAcad,
      ];
      for (final id in ceTechs) {
        expect(kBaseTechCosts.containsKey(id), true, reason: '${id.name} should be in base (CE)');
        expect(kFacilitiesTechCosts.containsKey(id), true, reason: '${id.name} should be in AGT');
      }
    });
  });

  group('TechCostEntry', () {
    test('costForNext returns correct cost', () {
      final e = kBaseTechCosts[TechId.attack]!;
      expect(e.costForNext(0), 20);
      expect(e.costForNext(1), 30);
      expect(e.costForNext(2), 40);
    });

    test('costForNext returns null when maxed', () {
      final e = kBaseTechCosts[TechId.attack]!;
      expect(e.costForNext(3), isNull);
    });

    test('maxLevel is correct', () {
      expect(kBaseTechCosts[TechId.shipSize]!.maxLevel, 6);
      expect(kBaseTechCosts[TechId.terraforming]!.maxLevel, 1);
      expect(kBaseTechCosts[TechId.attack]!.maxLevel, 3);
    });
  });

  group('visibleTechs', () {
    test('base mode without CE returns 14 techs', () {
      final techs = visibleTechs(facilitiesMode: false);
      expect(techs.length, 14);
    });

    test('base mode with CE returns 20 techs (14 base + 6 CE)', () {
      final techs = visibleTechs(facilitiesMode: false, closeEncountersOwned: true);
      expect(techs.length, 20);
      expect(techs.contains(TechId.ground), true);
      expect(techs.contains(TechId.boarding), true);
      expect(techs.contains(TechId.securityForces), true);
      expect(techs.contains(TechId.missileBoats), true);
      expect(techs.contains(TechId.fastBcAbility), true);
      expect(techs.contains(TechId.militaryAcad), true);
    });

    test('base mode with CE does not include AGT-only techs', () {
      final techs = visibleTechs(facilitiesMode: false, closeEncountersOwned: true);
      expect(techs.contains(TechId.supplyRange), false);
      expect(techs.contains(TechId.advancedCon), false);
      expect(techs.contains(TechId.jammers), false);
      expect(techs.contains(TechId.tractorBeamBb), false);
      expect(techs.contains(TechId.shieldProjDn), false);
    });

    test('facilities mode returns all 26 techs when all options enabled', () {
      final techs = visibleTechs(
        facilitiesMode: true,
        replicatorsEnabled: true,
        advancedConEnabled: true,
      );
      expect(techs.length, 26);
    });

    test('facilities mode without replicators excludes antiReplicator', () {
      final techs = visibleTechs(
        facilitiesMode: true,
        replicatorsEnabled: false,
        advancedConEnabled: true,
      );
      expect(techs.contains(TechId.antiReplicator), false);
      expect(techs.length, 25);
    });

    test('facilities mode without advancedCon excludes advancedCon', () {
      final techs = visibleTechs(
        facilitiesMode: true,
        replicatorsEnabled: true,
        advancedConEnabled: false,
      );
      expect(techs.contains(TechId.advancedCon), false);
      expect(techs.length, 25);
    });

    test('facilities mode without both optionals excludes both', () {
      final techs = visibleTechs(
        facilitiesMode: true,
        replicatorsEnabled: false,
        advancedConEnabled: false,
      );
      expect(techs.contains(TechId.antiReplicator), false);
      expect(techs.contains(TechId.advancedCon), false);
      expect(techs.length, 24);
    });

    test('CE techs have correct costs in base table', () {
      expect(kBaseTechCosts[TechId.ground]!.startLevel, 1);
      expect(kBaseTechCosts[TechId.ground]!.levelCosts, {2: 10, 3: 15});
      expect(kBaseTechCosts[TechId.boarding]!.levelCosts, {1: 20, 2: 25});
      expect(kBaseTechCosts[TechId.securityForces]!.levelCosts, {1: 15, 2: 15});
      expect(kBaseTechCosts[TechId.missileBoats]!.levelCosts, {1: 15, 2: 15});
      expect(kBaseTechCosts[TechId.fastBcAbility]!.levelCosts, {1: 10, 2: 10});
      expect(kBaseTechCosts[TechId.militaryAcad]!.levelCosts, {1: 10, 2: 20});
    });
  });
}
