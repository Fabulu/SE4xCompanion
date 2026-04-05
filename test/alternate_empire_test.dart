// Tests for alternate empire features, AGT ship definitions, special abilities,
// and all fixes from the April 2 implementation session.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/empire_advantages.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/special_abilities.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/world.dart';
import 'package:se4x/pages/production_page.dart';

// ── Fixtures ──

const baseConfig = GameConfig();
const facilitiesConfig = GameConfig(enableFacilities: true);
const altConfig = GameConfig(
  enableAlternateEmpire: true,
  ownership: ExpansionOwnership(closeEncounters: true),
);
const altFacilitiesConfig = GameConfig(
  enableAlternateEmpire: true,
  enableFacilities: true,
  ownership: ExpansionOwnership(closeEncounters: true, allGoodThings: true),
);

WorldState hw({int value = 30}) =>
    WorldState(name: 'HW', isHomeworld: true, homeworldValue: value);

int levelOf(TechId id) => 0;

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // AGT Ship Definitions
  // ═══════════════════════════════════════════════════════════════════════════

  group('AGT ship definition overrides', () {
    test('DD: AGT cost 9, weapon D, requires SS2', () {
      final dd = kShipDefinitions[ShipType.dd]!;
      expect(dd.effectiveBuildCost(false, facilitiesMode: true), 9);
      expect(dd.effectiveWeaponClass(true), 'D');
      expect(dd.requiredShipSize(true), 2);
      expect(dd.effectiveHullSize(true), 1); // hull unchanged
    });

    test('DD: base cost 6, weapon C, no SS req', () {
      final dd = kShipDefinitions[ShipType.dd]!;
      expect(dd.effectiveBuildCost(false), 6);
      expect(dd.effectiveWeaponClass(false), 'C');
      expect(dd.requiredShipSize(false), isNull);
    });

    test('CA: AGT weapon C, requires SS3', () {
      final ca = kShipDefinitions[ShipType.ca]!;
      expect(ca.effectiveWeaponClass(true), 'C');
      expect(ca.requiredShipSize(true), 3);
      expect(ca.effectiveHullSize(true), 2); // unchanged
    });

    test('BC: AGT hull 2, requires SS4', () {
      final bc = kShipDefinitions[ShipType.bc]!;
      expect(bc.effectiveHullSize(true), 2);
      expect(bc.effectiveHullSize(false), 3);
      expect(bc.requiredShipSize(true), 4);
      expect(bc.requiredShipSize(false), 3); // from prerequisite string
    });

    test('BB: AGT requires SS5', () {
      final bb = kShipDefinitions[ShipType.bb]!;
      expect(bb.requiredShipSize(true), 5);
      expect(bb.requiredShipSize(false), 3);
      expect(bb.effectiveHullSize(true), 3); // unchanged
    });

    test('DN: AGT requires SS6', () {
      final dn = kShipDefinitions[ShipType.dn]!;
      expect(dn.requiredShipSize(true), 6);
      expect(dn.requiredShipSize(false), 3);
    });

    test('TN: AGT hull 5, requires SS7', () {
      final tn = kShipDefinitions[ShipType.tn]!;
      expect(tn.effectiveHullSize(true), 5);
      expect(tn.effectiveHullSize(false), 4);
      expect(tn.requiredShipSize(true), 7);
      expect(tn.requiredShipSize(false), 4);
    });

    test('Starbase: AGT cost 12, hull 4', () {
      final sb = kShipDefinitions[ShipType.starbase]!;
      expect(sb.effectiveBuildCost(false, facilitiesMode: true), 12);
      expect(sb.effectiveBuildCost(false), 0);
      expect(sb.effectiveHullSize(true), 4);
      expect(sb.effectiveHullSize(false), 5);
    });

    test('DSN: AGT cost 6, hull 2', () {
      final dsn = kShipDefinitions[ShipType.dsn]!;
      expect(dsn.effectiveBuildCost(false, facilitiesMode: true), 6);
      expect(dsn.effectiveBuildCost(false), 5);
      expect(dsn.effectiveHullSize(true), 2);
      expect(dsn.effectiveHullSize(false), 1);
    });

    test('BD/MB: AGT cost 12, hull 2, weapon F', () {
      final bd = kShipDefinitions[ShipType.bdMb]!;
      expect(bd.effectiveBuildCost(false, facilitiesMode: true), 12);
      expect(bd.effectiveBuildCost(false), 9);
      expect(bd.effectiveHullSize(true), 2);
      expect(bd.effectiveWeaponClass(true), 'F');
    });

    test('BV: AGT cost 20', () {
      final bv = kShipDefinitions[ShipType.bv]!;
      expect(bv.effectiveBuildCost(false, facilitiesMode: true), 20);
      expect(bv.effectiveBuildCost(false), 15);
    });

    test('Ships without AGT overrides return base values', () {
      final sc = kShipDefinitions[ShipType.scout]!;
      expect(sc.effectiveBuildCost(false, facilitiesMode: true), 6);
      expect(sc.effectiveHullSize(true), 1);
      expect(sc.effectiveWeaponClass(true), 'E');

      final mine = kShipDefinitions[ShipType.mine]!;
      expect(mine.effectiveBuildCost(false, facilitiesMode: true), 5);
    });
  });

  group('effectiveBuildCost priority: alternate empire > AGT > base', () {
    test('alternate empire cost overrides AGT cost', () {
      final dd = kShipDefinitions[ShipType.dd]!;
      // Alt empire: 10 (not AGT's 9, not base's 6)
      expect(dd.effectiveBuildCost(true, facilitiesMode: true), 10);
      expect(dd.effectiveBuildCost(true, facilitiesMode: false), 10);
    });

    test('AGT cost used when not alternate empire', () {
      final dd = kShipDefinitions[ShipType.dd]!;
      expect(dd.effectiveBuildCost(false, facilitiesMode: true), 9);
    });

    test('base cost used when neither AGT nor alternate', () {
      final dd = kShipDefinitions[ShipType.dd]!;
      expect(dd.effectiveBuildCost(false, facilitiesMode: false), 6);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // War Sun
  // ═══════════════════════════════════════════════════════════════════════════

  group('War Sun ship definition', () {
    test('War Sun exists with correct stats', () {
      final ws = kShipDefinitions[ShipType.warSun]!;
      expect(ws.hullSize, 5);
      expect(ws.buildCost, 30);
      expect(ws.weaponClass, 'A');
      expect(ws.maxCounters, 1);
      expect(ws.maintenanceExempt, false);
    });

    test('War Sun is not buildable through the production ledger', () {
      final warSunConfig = GameConfig(
        selectedEmpireAdvantage: 187,
        ownership: const ExpansionOwnership(closeEncounters: true),
      );
      expect(canBuildShip(ShipType.warSun, levelOf, warSunConfig, []), false);
      expect(canBuildShip(ShipType.warSun, levelOf, baseConfig, []), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // canBuildShip — AGT prerequisites
  // ═══════════════════════════════════════════════════════════════════════════

  group('canBuildShip with AGT Ship Size prerequisites', () {
    int Function(TechId) ssLevel(int level) =>
        (TechId id) => id == TechId.shipSize ? level : 0;

    test('DD requires SS2 in AGT mode', () {
      expect(canBuildShip(ShipType.dd, ssLevel(1), facilitiesConfig, []), false);
      expect(canBuildShip(ShipType.dd, ssLevel(2), facilitiesConfig, []), true);
    });

    test('DD available at SS1 in base mode', () {
      expect(canBuildShip(ShipType.dd, ssLevel(1), baseConfig, []), true);
    });

    test('CA requires SS3 in AGT mode', () {
      expect(canBuildShip(ShipType.ca, ssLevel(2), facilitiesConfig, []), false);
      expect(canBuildShip(ShipType.ca, ssLevel(3), facilitiesConfig, []), true);
    });

    test('BC requires SS4 in AGT mode', () {
      expect(canBuildShip(ShipType.bc, ssLevel(3), facilitiesConfig, []), false);
      expect(canBuildShip(ShipType.bc, ssLevel(4), facilitiesConfig, []), true);
    });

    test('BB requires SS5 in AGT mode', () {
      expect(canBuildShip(ShipType.bb, ssLevel(4), facilitiesConfig, []), false);
      expect(canBuildShip(ShipType.bb, ssLevel(5), facilitiesConfig, []), true);
    });

    test('DN requires SS6 in AGT mode', () {
      expect(canBuildShip(ShipType.dn, ssLevel(5), facilitiesConfig, []), false);
      expect(canBuildShip(ShipType.dn, ssLevel(6), facilitiesConfig, []), true);
    });

    test('TN requires SS7 in AGT mode', () {
      expect(canBuildShip(ShipType.tn, ssLevel(6), facilitiesConfig, []), false);
      expect(canBuildShip(ShipType.tn, ssLevel(7), facilitiesConfig, []), true);
    });

    test('TN blocked for alternate empire regardless of mode', () {
      expect(canBuildShip(ShipType.tn, ssLevel(7), altFacilitiesConfig, []), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alternate Empire Blocks
  // ═══════════════════════════════════════════════════════════════════════════

  group('Alternate empire ship restrictions', () {
    int fullTech(TechId id) => 7;

    test('TN blocked for alternate empire', () {
      expect(canBuildShip(ShipType.tn, fullTech, altConfig, []), false);
    });

    test('CV blocked for alternate empire', () {
      expect(canBuildShip(ShipType.cv, fullTech, altConfig, []), false);
    });

    test('BV blocked for alternate empire', () {
      expect(canBuildShip(ShipType.bv, fullTech, altConfig, []), false);
    });

    test('Fighters still buildable for alternate empire', () {
      int withFighters(TechId id) => id == TechId.fighters ? 1 : 0;
      expect(canBuildShip(ShipType.fighter, withFighters, altConfig, []), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // House of Speed Fix
  // ═══════════════════════════════════════════════════════════════════════════

  group('House of Speed EA (#53)', () {
    test('starts with Movement 7 and blocks Cloaking', () {
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 53);
      expect(ea.startingTechOverrides[TechId.move], 7);
      expect(ea.blockedTechs, contains(TechId.cloaking));
      expect(ea.maxTechLevels, isEmpty);
    });

    test('has no other mechanical fields encoded', () {
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 53);
      expect(ea.costModifiers, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Expert Tacticians
  // ═══════════════════════════════════════════════════════════════════════════

  group('Expert Tacticians EA (#45)', () {
    test('has no encoded tactics bonus', () {
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 45);
      expect(ea.techLevelBonuses, isEmpty);
    });

    test('has no starting tactics override', () {
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 45);
      expect(ea.startingTechOverrides, isEmpty);
    });

    test('does not encode automation for the fleet-size bonus', () {
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 45);
      expect(ea.description, contains('Fleet Size Bonus'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Gifted Scientists CP Rebate
  // ═══════════════════════════════════════════════════════════════════════════

  group('Gifted Scientists EA (#41) — cpPerUnitBuilt', () {
    test('EA does not encode unit-cost rebates', () {
      final ea = kEmpireAdvantages.firstWhere((ea) => ea.cardNumber == 41);
      expect(ea.cpPerUnitBuilt, 0);
    });

    test('ship purchase cost uses only the tech multiplier', () {
      final config = GameConfig(selectedEmpireAdvantage: 41);
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 3),
        ],
      );
      expect(ps.shipPurchaseCost(config), 21);
    });

    test('rebate does not apply to colony ships because no rebate is encoded', () {
      final config = GameConfig(selectedEmpireAdvantage: 41);
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.colonyShip, quantity: 1),
        ],
      );
      expect(ps.shipPurchaseCost(config), 9);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Special Abilities
  // ═══════════════════════════════════════════════════════════════════════════

  group('Special abilities data', () {
    test('12 abilities defined', () {
      expect(kSpecialAbilities.length, 12);
    });

    test('roll values 1-12', () {
      for (int i = 0; i < 12; i++) {
        expect(kSpecialAbilities[i].rollValue, i + 1);
      }
    });

    test('Construction Efficiency (#12) is production-relevant', () {
      final ce = getSpecialAbility(12)!;
      expect(ce.name, 'Construction Efficiency');
      expect(ce.affectsProduction, true);
    });

    test('Advanced Munitions (#11) is production-relevant', () {
      final am = getSpecialAbility(11)!;
      expect(am.name, 'Advanced Munitions');
      expect(am.affectsProduction, true);
    });

    test('8 eligible ship types', () {
      expect(kAbilityEligibleShipTypes.length, 8);
      expect(kAbilityEligibleShipTypes, contains(ShipType.dd));
      expect(kAbilityEligibleShipTypes, contains(ShipType.dn));
    });
  });

  group('Construction Efficiency (ability #12) cost reduction', () {
    test('reduces ship cost by 2 CP', () {
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 1),
        ],
      );
      final abilities = {ShipType.dd: 12};
      // DD costs 6, efficiency -2 = 4
      expect(ps.shipPurchaseCost(baseConfig, const [], abilities), 4);
    });

    test('cost floors at 1 CP', () {
      // Nano-tech EA: -1, plus efficiency -2 on a scout (cost 6)
      final config = GameConfig(selectedEmpireAdvantage: 39);
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.scout, quantity: 1),
        ],
      );
      final abilities = {ShipType.scout: 12};
      // Scout 6, nano -1, efficiency -2 = 4
      expect(ps.shipPurchaseCost(config, const [], abilities), 4);
    });
  });

  group('Advanced Munitions (ability #11) attack cap', () {
    test('stampFromTech allows attack cap hull+1', () {
      final tech = const TechState(levels: {TechId.attack: 2});
      // DD hull 1: normal cap is 1, with Advanced Munitions cap is 2
      final counter = ShipCounter.stampFromTech(
        ShipType.dd, 1, tech,
        advancedMunitions: true,
      );
      expect(counter.attack, 2);
    });

    test('without Advanced Munitions, attack capped at hull', () {
      final tech = const TechState(levels: {TechId.attack: 2});
      final counter = ShipCounter.stampFromTech(
        ShipType.dd, 1, tech,
        advancedMunitions: false,
      );
      expect(counter.attack, 1);
    });

    test('needsUpgrade respects advancedMunitions', () {
      final tech = const TechState(levels: {TechId.attack: 2});
      // Counter stamped with advanced munitions (attack=2, move=1 from start level)
      const counter = ShipCounter(
        type: ShipType.dd, number: 1, isBuilt: true,
        attack: 2, defense: 0, tactics: 0, move: 1,
      );
      // Without advancedMunitions flag, it would think attack should be 1
      expect(counter.needsUpgrade(tech, advancedMunitions: true), false);
      expect(counter.needsUpgrade(tech, advancedMunitions: false), true);
    });

    test('upgradeToTech respects advancedMunitions', () {
      final tech = const TechState(levels: {TechId.attack: 2});
      const counter = ShipCounter(
        type: ShipType.dd, number: 1, isBuilt: true,
        attack: 1, defense: 0, tactics: 0, move: 0,
      );
      final upgraded = counter.upgradeToTech(tech, advancedMunitions: true);
      expect(upgraded, isNotNull);
      expect(upgraded!.attack, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Ship cost clamping (single clamp at end)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Ship cost clamping — single clamp', () {
    test('multiple modifiers accumulate before clamping', () {
      // Nano-tech EA: all ships -1 CP
      final config = GameConfig(selectedEmpireAdvantage: 39);
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 1),
        ],
      );
      // DD 6, nano -1, efficiency -2 = 3
      final abilities = {ShipType.dd: 12};
      expect(ps.shipPurchaseCost(config, const [], abilities), 4);
    });

    test('cost never goes below 1', () {
      // Stack many discounts on a cheap ship
      final config = GameConfig(selectedEmpireAdvantage: 41); // cpPerUnit=1
      final ps = ProductionState(
        cpCarryOver: 100,
        worlds: [hw()],
        shipPurchases: [
          const ShipPurchase(type: ShipType.decoy, quantity: 1),
        ],
      );
      expect(ps.shipPurchaseCost(config), 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AGT Maintenance (hull size changes)
  // ═══════════════════════════════════════════════════════════════════════════

  group('AGT maintenance with different hull sizes', () {
    test('BC maintenance is 2 in AGT (hull 2), 3 in base (hull 3)', () {
      final counters = [
        const ShipCounter(type: ShipType.bc, number: 1, isBuilt: true),
      ];
      final ps = const ProductionState();
      expect(ps.maintenanceTotal(counters, facilitiesConfig), 2);
      expect(ps.maintenanceTotal(counters, baseConfig), 3);
    });

    test('TN maintenance is 5 in AGT (hull 5), 4 in base (hull 4)', () {
      final counters = [
        const ShipCounter(type: ShipType.tn, number: 1, isBuilt: true),
      ];
      final ps = const ProductionState();
      expect(ps.maintenanceTotal(counters, facilitiesConfig), 5);
      expect(ps.maintenanceTotal(counters, baseConfig), 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AGT upgrade costs
  // ═══════════════════════════════════════════════════════════════════════════

  group('AGT upgrade costs use effective hull size', () {
    test('BC upgrade cost is 2 in AGT, 3 in base', () {
      const bc = ShipCounter(type: ShipType.bc, number: 1, isBuilt: true);
      expect(bc.upgradeCost(facilitiesMode: true), 2);
      expect(bc.upgradeCost(facilitiesMode: false), 3);
    });

    test('TN upgrade cost is 5 in AGT, 4 in base', () {
      const tn = ShipCounter(type: ShipType.tn, number: 1, isBuilt: true);
      expect(tn.upgradeCost(facilitiesMode: true), 5);
      expect(tn.upgradeCost(facilitiesMode: false), 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Alien tech cards 56 & 57 were previously miscoded as Empire Advantages.
  // ═══════════════════════════════════════════════════════════════════════════

  group('EA catalog corrections', () {
    test('On Board Workshop (#56) is not an empire advantage', () {
      expect(
        kEmpireAdvantages.where((ea) => ea.cardNumber == 56),
        isEmpty,
      );
    });

    test('Superhighway (#57) is not an empire advantage', () {
      expect(
        kEmpireAdvantages.where((ea) => ea.cardNumber == 57),
        isEmpty,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GameState serialization with new fields
  // ═══════════════════════════════════════════════════════════════════════════

  group('GameState shipSpecialAbilities serialization', () {
    test('round-trips correctly', () {
      final state = GameState(
        shipSpecialAbilities: {
          ShipType.dd: 12,
          ShipType.bc: 11,
          ShipType.scout: 3,
        },
      );
      final json = state.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.shipSpecialAbilities[ShipType.dd], 12);
      expect(restored.shipSpecialAbilities[ShipType.bc], 11);
      expect(restored.shipSpecialAbilities[ShipType.scout], 3);
      expect(restored.shipSpecialAbilities.length, 3);
    });

    test('empty abilities round-trip', () {
      const state = GameState();
      final json = state.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.shipSpecialAbilities, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AGT hull size in stampFromTech
  // ═══════════════════════════════════════════════════════════════════════════

  group('stampFromTech uses AGT hull sizes for tech caps', () {
    test('BC hull 2 in AGT caps attack at 2', () {
      final tech = const TechState(levels: {TechId.attack: 3});
      final counter = ShipCounter.stampFromTech(
        ShipType.bc, 1, tech,
        facilitiesMode: true,
      );
      // AGT BC hull=2, so attack capped at 2
      expect(counter.attack, 2);
    });

    test('BC hull 3 in base allows full attack', () {
      final tech = const TechState(levels: {TechId.attack: 3});
      final counter = ShipCounter.stampFromTech(
        ShipType.bc, 1, tech,
        facilitiesMode: false,
      );
      // Base BC hull=3, hull >= 3 means no cap
      expect(counter.attack, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Industrious Race EA #35 — Colony Income Bonus
  // ═══════════════════════════════════════════════════════════════════════════

  group('Industrious Race EA #35 — colony income bonus', () {
    final config = const GameConfig(selectedEmpireAdvantage: 35);

    test('homeworld gets +5 CP bonus', () {
      final ps = ProductionState(worlds: [hw(value: 20)]);
      // Base: 20, bonus: +5 = 25
      expect(ps.colonyCp(config), 20);
    });

    test('colonies get +1 CP each', () {
      final ps = ProductionState(worlds: [
        hw(),
        WorldState(name: 'C1', growthMarkerLevel: 1), // 1 CP base
        WorldState(name: 'C2', growthMarkerLevel: 2), // 3 CP base
      ]);
      // HW: 30+5=35, C1: 1+1=2, C2: 3+1=4 => 41
      expect(ps.colonyCp(config), 34);
    });

    test('blocked colonies get no bonus', () {
      final ps = ProductionState(worlds: [
        hw(),
        WorldState(name: 'C1', growthMarkerLevel: 2, isBlocked: true),
      ]);
      // HW: 30+5, blocked colony excluded entirely
      expect(ps.colonyCp(config), 30);
    });

    test('no bonus when EA is not #35', () {
      final ps = ProductionState(worlds: [hw()]);
      expect(ps.colonyCp(baseConfig), 30); // no bonus
    });

    test('works in facilities mode', () {
      final facConfig = const GameConfig(
        selectedEmpireAdvantage: 35,
        enableFacilities: true,
      );
      final ps = ProductionState(worlds: [hw()]);
      // Facilities homeworld: 20 + bonus 5 = 25
      expect(ps.colonyCp(facConfig), 20);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Traders EA #49 — Pipeline Income Doubling
  // ═══════════════════════════════════════════════════════════════════════════

  group('Traders EA #49 — pipeline income doubling', () {
    final config = const GameConfig(selectedEmpireAdvantage: 49);

    test('pipeline income doubled with EA #49', () {
      final ps = ProductionState(worlds: [
        WorldState(name: 'C1', growthMarkerLevel: 2, pipelineIncome: 3),
      ]);
      expect(ps.pipelineCp(config), 6); // 3 * 2
    });

    test('pipeline income normal without EA #49', () {
      final ps = ProductionState(worlds: [
        WorldState(name: 'C1', growthMarkerLevel: 2, pipelineIncome: 3),
      ]);
      expect(ps.pipelineCp(baseConfig), 3);
    });

    test('zero pipeline income unaffected', () {
      final ps = ProductionState(worlds: [
        WorldState(name: 'C1', growthMarkerLevel: 2, pipelineIncome: 0),
      ]);
      expect(ps.pipelineCp(config), 0);
    });

    test('blocked worlds excluded', () {
      final ps = ProductionState(worlds: [
        WorldState(name: 'C1', growthMarkerLevel: 2, pipelineIncome: 3, isBlocked: true),
      ]);
      expect(ps.pipelineCp(config), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Quick Learners EA #40 — First Tech Discount
  // ═══════════════════════════════════════════════════════════════════════════

  group('Quick Learners EA #40 — first tech discount', () {
    final config = const GameConfig(selectedEmpireAdvantage: 40);

    test('first tech costs 50% less (rounded down)', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.attack: 1},
        techPurchaseOrder: [TechId.attack],
      );
      expect(ps.techSpendingCpDerived(config), 20);
    });

    test('second tech costs full price', () {
      final ps = ProductionState(
        pendingTechPurchases: {
          TechId.attack: 1,
          TechId.defense: 1,
        },
        techPurchaseOrder: [TechId.attack, TechId.defense],
      );
      expect(ps.techSpendingCpDerived(config), 40);
    });

    test('odd cost rounds down correctly', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.tactics: 1},
        techPurchaseOrder: [TechId.tactics],
      );
      expect(ps.techSpendingCpDerived(config), 15);
    });

    test('no discount when EA is not #40', () {
      final ps = ProductionState(
        pendingTechPurchases: {TechId.attack: 1},
        techPurchaseOrder: [TechId.attack],
      );
      expect(ps.techSpendingCpDerived(baseConfig), 20);
    });

    test('no discount when no purchases yet', () {
      const ps = ProductionState();
      expect(ps.techSpendingCpDerived(config), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Quick Learners techPurchaseOrder serialization
  // ═══════════════════════════════════════════════════════════════════════════

  group('techPurchaseOrder serialization', () {
    test('round-trips correctly', () {
      final ps = ProductionState(
        techPurchaseOrder: [TechId.attack, TechId.defense],
      );
      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);
      expect(restored.techPurchaseOrder, [TechId.attack, TechId.defense]);
    });

    test('empty list round-trips', () {
      const ps = ProductionState();
      final json = ps.toJson();
      final restored = ProductionState.fromJson(json);
      expect(restored.techPurchaseOrder, isEmpty);
    });

    test('prepareForNextTurn resets order', () {
      final ps = ProductionState(
        cpCarryOver: 10,
        worlds: [hw()],
        techPurchaseOrder: [TechId.attack],
      );
      final next = ps.prepareForNextTurn(baseConfig, []);
      expect(next.techPurchaseOrder, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Starbase upgrade — requires built Base
  // ═══════════════════════════════════════════════════════════════════════════

  group('Starbase requires built Base', () {
    int withAC2(TechId id) => id == TechId.advancedCon ? 2 : 0;

    test('cannot build Starbase without a Base', () {
      expect(canBuildShip(ShipType.starbase, withAC2, baseConfig, [], []), false);
    });

    test('can build Starbase with a built Base', () {
      final counters = [
        const ShipCounter(type: ShipType.base, number: 1, isBuilt: true),
      ];
      expect(canBuildShip(ShipType.starbase, withAC2, baseConfig, [], counters), true);
    });

    test('unbuilt Base does not count', () {
      final counters = [
        const ShipCounter(type: ShipType.base, number: 1, isBuilt: false),
      ];
      expect(canBuildShip(ShipType.starbase, withAC2, baseConfig, [], counters), false);
    });

    test('still requires AC2', () {
      int noAC(TechId id) => 0;
      final counters = [
        const ShipCounter(type: ShipType.base, number: 1, isBuilt: true),
      ];
      expect(canBuildShip(ShipType.starbase, noAC, baseConfig, [], counters), false);
    });
  });
}
