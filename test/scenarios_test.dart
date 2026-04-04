// Tests for the scenario setup system.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/scenarios.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/world.dart';
import 'package:se4x/pages/production_page.dart';

// ── Fixtures ──

const baseConfig = GameConfig();

WorldState hw({int value = 30}) =>
    WorldState(name: 'HW', isHomeworld: true, homeworldValue: value);

WorldState colony(int growth, {int pipeline = 0}) =>
    WorldState(name: 'C$growth', growthMarkerLevel: growth, pipelineIncome: pipeline);

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Scenario Data Integrity
  // ═══════════════════════════════════════════════════════════════════════════

  group('Scenario data integrity', () {
    test('all scenarios have unique IDs', () {
      final ids = kScenarios.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'Duplicate scenario IDs');
    });

    test('all scenarios have non-empty name and description', () {
      for (final s in kScenarios) {
        expect(s.name.isNotEmpty, true, reason: '${s.id} has empty name');
        expect(s.description.isNotEmpty, true, reason: '${s.id} has empty description');
      }
    });

    test('Knife Fight has correct starting techs', () {
      final kf = kScenarios.firstWhere((s) => s.id == 'knife_fight');
      expect(kf.startingTechOverrides[TechId.shipSize], 3);
      expect(kf.startingTechOverrides[TechId.move], 2);
    });

    test('Knife Fight has correct starting fleet', () {
      final kf = kScenarios.firstWhere((s) => s.id == 'knife_fight');
      expect(kf.startingFleet![ShipType.scout], 4);
      expect(kf.startingFleet![ShipType.colonyShip], 4);
    });

    test('2v1 Allied has 1.5x cost multipliers', () {
      final s = kScenarios.firstWhere((s) => s.id == '3p_2v1_allied');
      expect(s.shipCostMultiplier, 1.5);
      expect(s.techCostMultiplier, 1.5);
    });

    test('3v1 Solo has 2x colony income', () {
      final s = kScenarios.firstWhere((s) => s.id == '4p_3v1_solo');
      expect(s.colonyIncomeMultiplier, 2.0);
    });

    test('Quick Conquest blocks mines and minesweepers', () {
      final s = kScenarios.firstWhere((s) => s.id == 'quick_conquest');
      expect(s.blockedTechs, contains(TechId.mines));
      expect(s.blockedTechs, contains(TechId.mineSweep));
      expect(s.blockedShipTypes, contains(ShipType.mine));
      expect(s.blockedShipTypes, contains(ShipType.sw));
    });

    test('Handicap has colony growth bonus of 2', () {
      final s = kScenarios.firstWhere((s) => s.id == 'handicap');
      expect(s.colonyGrowthBonus, 2);
    });

    test('Alien VP scenario exposes VP track metadata', () {
      final s = scenarioById('alien_vp_easy');
      expect(s, isNotNull);
      expect(s!.victoryPoints, isNotNull);
      expect(s.victoryPoints!.lossThreshold, 10);
      expect(s.victoryPoints!.label, 'Alien VP');
    });

    test('DM coop scenario exposes VP track metadata', () {
      final s = scenarioById('dm_coop_2p_easy');
      expect(s, isNotNull);
      expect(s!.victoryPoints, isNotNull);
      expect(s.victoryPoints!.label, 'DM VP');
      expect(s.victoryPoints!.lossText, '10 = loss');
    });

    test('Replicator large scenario exposes setup metadata', () {
      final s = scenarioById('replicator_large');
      expect(s, isNotNull);
      expect(s!.replicatorSetup, isNotNull);
      expect(s.replicatorSetup!.mapLabel, 'Large');
      expect(s.blockedShipTypes, contains(ShipType.decoy));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Ship Cost Multiplier
  // ═══════════════════════════════════════════════════════════════════════════

  group('Ship cost multiplier (2v1 allied: 1.5x)', () {
    final config = const GameConfig(shipCostMultiplier: 1.5);

    test('DD costs 9 instead of 6', () {
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [const ShipPurchase(type: ShipType.dd, quantity: 1)],
      );
      // 6 * 1.5 = 9
      expect(ps.shipPurchaseCost(config), 9);
    });

    test('CA costs 18 instead of 12', () {
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [const ShipPurchase(type: ShipType.ca, quantity: 1)],
      );
      // 12 * 1.5 = 18
      expect(ps.shipPurchaseCost(config), 18);
    });

    test('no multiplier when 1.0', () {
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [const ShipPurchase(type: ShipType.dd, quantity: 1)],
      );
      expect(ps.shipPurchaseCost(baseConfig), 6);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Tech Cost Multiplier
  // ═══════════════════════════════════════════════════════════════════════════

  group('Tech cost multiplier (2v1 allied: 1.5x)', () {
    final config = const GameConfig(techCostMultiplier: 1.5);

    test('Attack 1 costs 30 instead of 20', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.attack: 1},
        techPurchaseOrder: [TechId.attack],
      );
      // 20 * 1.5 = 30
      expect(ps.techSpendingCpDerived(config), 30);
    });

    test('odd cost rounds up', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.tactics: 1},
        techPurchaseOrder: [TechId.tactics],
      );
      // 15 * 1.5 = 22.5 -> ceil = 23
      expect(ps.techSpendingCpDerived(config), 23);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Colony Income Multiplier
  // ═══════════════════════════════════════════════════════════════════════════

  group('Colony income multiplier (3v1 solo: 2x non-HW)', () {
    final config = const GameConfig(colonyIncomeMultiplier: 2.0);

    test('homeworld income unchanged', () {
      final ps = ProductionState(worlds: [hw(value: 30)]);
      // HW: 30 (not doubled), no colonies
      expect(ps.colonyCp(config), 30);
    });

    test('colony income doubled', () {
      final ps = ProductionState(worlds: [
        hw(),
        WorldState(name: 'C2', growthMarkerLevel: 2), // 3 CP
      ]);
      // HW: 30 + colony: 3*2 = 6 => 36
      expect(ps.colonyCp(config), 36);
    });

    test('multiple colonies doubled', () {
      final ps = ProductionState(worlds: [
        hw(),
        WorldState(name: 'C1', growthMarkerLevel: 1), // 1 CP
        WorldState(name: 'C3', growthMarkerLevel: 3), // 5 CP
      ]);
      // HW: 30 + (1+5)*2 = 30 + 12 = 42
      expect(ps.colonyCp(config), 42);
    });

    test('no multiplier when 1.0', () {
      final ps = ProductionState(worlds: [
        hw(),
        WorldState(name: 'C2', growthMarkerLevel: 2), // 3 CP
      ]);
      expect(ps.colonyCp(baseConfig), 33);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Colony Growth Bonus (Handicap)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Colony growth bonus (handicap: +2)', () {
    final config = const GameConfig(colonyGrowthBonus: 2);

    test('colony grows 3 steps in one turn (capped at 3)', () {
      final ps = ProductionState(
        cpCarryOver: 10,
        worlds: [
          hw(),
          WorldState(name: 'C0', growthMarkerLevel: 0), // new colony
        ],
      );
      final next = ps.prepareForNextTurn(config, []);
      // Growth: 0 + 1 + 2 = 3 (capped at 3)
      final colony = next.worlds.firstWhere((w) => !w.isHomeworld);
      expect(colony.growthMarkerLevel, 3);
    });

    test('colony at growth 2 caps at 3', () {
      final ps = ProductionState(
        cpCarryOver: 10,
        worlds: [
          hw(),
          WorldState(name: 'C2', growthMarkerLevel: 2),
        ],
      );
      final next = ps.prepareForNextTurn(config, []);
      final colony = next.worlds.firstWhere((w) => !w.isHomeworld);
      expect(colony.growthMarkerLevel, 3); // 2+1+2=5 but capped at 3
    });

    test('no bonus when colonyGrowthBonus is 0', () {
      final ps = ProductionState(
        cpCarryOver: 10,
        worlds: [
          hw(),
          WorldState(name: 'C0', growthMarkerLevel: 0),
        ],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      final colony = next.worlds.firstWhere((w) => !w.isHomeworld);
      expect(colony.growthMarkerLevel, 1); // normal: 0 + 1
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Scenario Blocked Ships/Techs
  // ═══════════════════════════════════════════════════════════════════════════

  group('Scenario blocked ships and techs', () {
    final config = const GameConfig(
      scenarioBlockedShips: [ShipType.mine, ShipType.sw],
      scenarioBlockedTechs: [TechId.mines, TechId.mineSweep],
    );

    test('blocked ships cannot be built', () {
      int fullTech(TechId id) => 7;
      expect(canBuildShip(ShipType.mine, fullTech, config, []), false);
      expect(canBuildShip(ShipType.sw, fullTech, config, []), false);
    });

    test('non-blocked ships still buildable', () {
      int fullTech(TechId id) => 7;
      expect(canBuildShip(ShipType.dd, fullTech, config, []), true);
      expect(canBuildShip(ShipType.scout, fullTech, config, []), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GameConfig Serialization with Scenario Fields
  // ═══════════════════════════════════════════════════════════════════════════

  group('GameConfig scenario serialization', () {
    test('round-trips scenario fields correctly', () {
      final config = GameConfig(
        scenarioId: 'knife_fight',
        replicatorDifficulty: 'Hard',
        shipCostMultiplier: 1.5,
        techCostMultiplier: 1.5,
        colonyIncomeMultiplier: 2.0,
        colonyGrowthBonus: 2,
        scenarioBlockedTechs: [TechId.mines],
        scenarioBlockedShips: [ShipType.mine],
      );
      final json = config.toJson();
      final restored = GameConfig.fromJson(json);
      expect(restored.scenarioId, 'knife_fight');
      expect(restored.replicatorDifficulty, 'Hard');
      expect(restored.shipCostMultiplier, 1.5);
      expect(restored.techCostMultiplier, 1.5);
      expect(restored.colonyIncomeMultiplier, 2.0);
      expect(restored.colonyGrowthBonus, 2);
      expect(restored.scenarioBlockedTechs, [TechId.mines]);
      expect(restored.scenarioBlockedShips, [ShipType.mine]);
    });

    test('defaults when fields absent', () {
      final restored = GameConfig.fromJson({});
      expect(restored.scenarioId, isNull);
      expect(restored.replicatorDifficulty, isNull);
      expect(restored.shipCostMultiplier, 1.0);
      expect(restored.techCostMultiplier, 1.0);
      expect(restored.colonyIncomeMultiplier, 1.0);
      expect(restored.colonyGrowthBonus, 0);
      expect(restored.scenarioBlockedTechs, isEmpty);
      expect(restored.scenarioBlockedShips, isEmpty);
    });
  });
}
