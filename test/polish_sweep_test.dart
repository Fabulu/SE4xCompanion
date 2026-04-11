// Tests for the polish sweep changes:
//   - GameConfig.enableNebulaMining: default, copyWith, toJson/fromJson, legacy
//   - totalCp respects enableNebulaMining flag
//   - Card #181 produces shipyardCapacityMod
//   - isShipyardExempt additional coverage (mine, miner, colonyShip, warSun)
//   - TP expenditure tracking (TpExpenditure.cost, derived/effective/remaining TP)

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_modifiers.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/data/temporal_effects.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/world.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. GameConfig.enableNebulaMining
  // ---------------------------------------------------------------------------
  group('GameConfig.enableNebulaMining', () {
    test('default value is true', () {
      const config = GameConfig();
      expect(config.enableNebulaMining, isTrue);
    });

    test('copyWith toggles to false', () {
      const config = GameConfig();
      final toggled = config.copyWith(enableNebulaMining: false);
      expect(toggled.enableNebulaMining, isFalse);
    });

    test('copyWith toggles back to true', () {
      const config = GameConfig(enableNebulaMining: false);
      final toggled = config.copyWith(enableNebulaMining: true);
      expect(toggled.enableNebulaMining, isTrue);
    });

    test('copyWith without argument preserves the value', () {
      const config = GameConfig(enableNebulaMining: false);
      final copy = config.copyWith();
      expect(copy.enableNebulaMining, isFalse);
    });

    test('toJson/fromJson round-trip with true', () {
      const config = GameConfig(enableNebulaMining: true);
      final restored = GameConfig.fromJson(config.toJson());
      expect(restored.enableNebulaMining, isTrue);
    });

    test('toJson/fromJson round-trip with false', () {
      const config = GameConfig(enableNebulaMining: false);
      final restored = GameConfig.fromJson(config.toJson());
      expect(restored.enableNebulaMining, isFalse);
    });

    test('legacy JSON without key defaults to true', () {
      final config = GameConfig.fromJson({});
      expect(config.enableNebulaMining, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. totalCp respects enableNebulaMining flag
  // ---------------------------------------------------------------------------
  group('totalCp respects enableNebulaMining', () {
    // Helpers shared across the group.
    MapHexState nebulaHex() =>
        const MapHexState(coord: HexCoord(1, 0), terrain: HexTerrain.nebula);

    ShipCounter miner(int n) =>
        ShipCounter(type: ShipType.miner, number: n, isBuilt: true);

    FleetStackState friendlyFleet(HexCoord coord, List<String> ships) =>
        FleetStackState(
          id: 'f${coord.q}${coord.r}',
          coord: coord,
          shipCounterIds: ships,
        );

    // Terra 2 is required for nebula mining income.
    final techWithTerra2 = const TechState(
      levels: {TechId.terraforming: 2},
    );

    test('with enableNebulaMining=true, totalCp includes nebula income', () {
      final minerCounter = miner(1);
      final map = GameMapState(
        hexes: [nebulaHex()],
        fleets: [
          friendlyFleet(
            const HexCoord(1, 0),
            [minerCounter.id],
          ),
        ],
      );
      final ps = ProductionState(
        worlds: [
          const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30),
        ],
        techState: techWithTerra2,
      );

      const configOn = GameConfig(enableNebulaMining: true);
      const configOff = GameConfig(enableNebulaMining: false);

      final withNebula = ps.totalCp(configOn, const [], map, [minerCounter]);
      final withoutNebula = ps.totalCp(configOff, const [], map, [minerCounter]);

      // nebulaMiningCp returns 3 for one miner in one nebula hex.
      expect(withNebula - withoutNebula, 3);
    });

    test('with enableNebulaMining=false, totalCp excludes nebula income', () {
      final minerCounter = miner(1);
      final map = GameMapState(
        hexes: [nebulaHex()],
        fleets: [
          friendlyFleet(
            const HexCoord(1, 0),
            [minerCounter.id],
          ),
        ],
      );
      final ps = ProductionState(
        worlds: [
          const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30),
        ],
        techState: techWithTerra2,
      );

      const configOff = GameConfig(enableNebulaMining: false);
      // Baseline: without map (no mining at all).
      final baseNoMap = ps.totalCp(configOff);
      // With map but nebula mining disabled: should equal the no-map baseline.
      final withMapDisabled =
          ps.totalCp(configOff, const [], map, [minerCounter]);
      expect(withMapDisabled, baseNoMap);
    });

    test('disabling nebula mining does not affect asteroid mining', () {
      final minerCounter = miner(1);
      final asteroidHex =
          const MapHexState(coord: HexCoord(0, 0), terrain: HexTerrain.asteroid);
      final map = GameMapState(
        hexes: [asteroidHex],
        fleets: [
          friendlyFleet(const HexCoord(0, 0), [minerCounter.id]),
        ],
      );
      final ps = ProductionState(
        worlds: [
          const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30),
        ],
      );

      const configOn = GameConfig(enableNebulaMining: true);
      const configOff = GameConfig(enableNebulaMining: false);

      // Asteroid mining is unaffected by the flag.
      expect(
        ps.totalCp(configOff, const [], map, [minerCounter]),
        ps.totalCp(configOn, const [], map, [minerCounter]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Card #181 produces shipyardCapacityMod
  // ---------------------------------------------------------------------------
  group('Card #181 Advanced Shipyards', () {
    test('cardModifiersFor(181) returns a binding with modifiers', () {
      final binding = cardModifiersFor(181);
      expect(binding, isNotNull);
      expect(binding!.hasModifiers, isTrue);
    });

    test('binding has exactly one modifier', () {
      final binding = cardModifiersFor(181)!;
      expect(binding.modifiers.length, 1);
    });

    test('modifier type is shipyardCapacityMod', () {
      final modifier = cardModifiersFor(181)!.modifiers.first;
      expect(modifier.type, 'shipyardCapacityMod');
    });

    test('modifier value is 1', () {
      final modifier = cardModifiersFor(181)!.modifiers.first;
      expect(modifier.value, 1);
    });

    test('card #181 is NOT flagged as complex', () {
      final binding = cardModifiersFor(181)!;
      expect(binding.isComplex, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. shipyardCapacityForHex includes modifier bonus
  // ---------------------------------------------------------------------------
  group('shipyardCapacityForHex includes modifier bonus', () {
    // Setup: one hex at (0,0) with 1 shipyard, no world (avoids blockade path).
    const hexCoord = HexCoord(0, 0);
    final map = GameMapState(
      hexes: [
        const MapHexState(
          coord: hexCoord,
          terrain: HexTerrain.deepSpace,
          shipyardCount: 1,
        ),
      ],
    );

    // SY tech level 2 → 2 HP per yard.
    final tech = const TechState(
      levels: {TechId.shipYard: 2},
    );

    final ps = ProductionState(
      worlds: [
        const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30),
      ],
      techState: tech,
    );

    test('without modifiers, capacity is 2 (1 yard × 2 HP at tech 2)', () {
      final cap = ps.shipyardCapacityForHex(hexCoord, map, tech);
      expect(cap, 2);
    });

    test('with shipyardCapacityMod value 1, capacity is 3', () {
      const mod = GameModifier(
        name: 'Advanced Shipyards',
        type: 'shipyardCapacityMod',
        value: 1,
      );
      final cap = ps.shipyardCapacityForHex(
        hexCoord,
        map,
        tech,
        modifiers: [mod],
      );
      expect(cap, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. isShipyardExempt additional coverage
  // ---------------------------------------------------------------------------
  group('isShipyardExempt additional coverage', () {
    test('ShipType.mine is exempt (maxCounters == 0)', () {
      expect(kShipDefinitions[ShipType.mine]!.isShipyardExempt, isTrue);
    });

    test('ShipType.miner is exempt (maxCounters == 0)', () {
      expect(kShipDefinitions[ShipType.miner]!.isShipyardExempt, isTrue);
    });

    test('ShipType.colonyShip is exempt (maxCounters == 0)', () {
      expect(kShipDefinitions[ShipType.colonyShip]!.isShipyardExempt, isTrue);
    });

    test('ShipType.warSun is NOT exempt (maxCounters == 1)', () {
      expect(kShipDefinitions[ShipType.warSun]!.isShipyardExempt, isFalse);
    });

    test('ShipType.warSun maxCounters is 1', () {
      expect(kShipDefinitions[ShipType.warSun]!.maxCounters, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. TP expenditure tracking
  // Index reference (kTemporalEffects):
  //   0 — Crossing the Event Horizon  (perUnit,      baseCost 10)
  //   1 — Redline the Engines         (perUnit,      baseCost 15)
  //   2 — Reroute Targeting Computers (flat,         baseCost 10)
  //   3 — Temporal Maneuver           (perHullPoint, baseCost 10)
  // ---------------------------------------------------------------------------
  group('TP expenditure tracking', () {
    // ── TpExpenditure.cost() ─────────────────────────────────────────────────

    test('TpExpenditure.cost() flat effect returns baseCost', () {
      // Index 2: Reroute Targeting Computers — flat cost 10.
      const exp = TpExpenditure(effectIndex: 2);
      expect(exp.cost(), kTemporalEffects[2].baseCost);
      expect(exp.cost(), 10);
    });

    test('TpExpenditure.cost() perUnit with quantity=3 returns baseCost*3', () {
      // Index 1: Redline the Engines — perUnit, baseCost 15.
      const exp = TpExpenditure(effectIndex: 1, quantity: 3);
      expect(exp.cost(), kTemporalEffects[1].baseCost * 3);
      expect(exp.cost(), 45);
    });

    test('TpExpenditure.cost() perHullPoint with hullPoints=4 returns baseCost*4', () {
      // Index 3: Temporal Maneuver — perHullPoint, baseCost 10.
      const exp = TpExpenditure(effectIndex: 3, hullPoints: 4);
      expect(exp.cost(), kTemporalEffects[3].baseCost * 4);
      expect(exp.cost(), 40);
    });

    test('TpExpenditure.cost() perHullPoint with hullPoints=0 returns baseCost*1 (minimum 1)', () {
      // hullPoints=0 is treated as 1 per the implementation.
      const exp = TpExpenditure(effectIndex: 3, hullPoints: 0);
      expect(exp.cost(), kTemporalEffects[3].baseCost * 1);
      expect(exp.cost(), 10);
    });

    test('TpExpenditure.cost() out-of-range index returns 0', () {
      const expNegative = TpExpenditure(effectIndex: -1);
      const expTooLarge = TpExpenditure(effectIndex: 9999);
      expect(expNegative.cost(), 0);
      expect(expTooLarge.cost(), 0);
    });

    // ── tpSpendingDerived ────────────────────────────────────────────────────

    test('tpSpendingDerived sums multiple expenditures', () {
      // flat(10) + perUnit×3(45) = 55
      final ps = ProductionState(
        tpExpenditures: const [
          TpExpenditure(effectIndex: 2),           // flat 10
          TpExpenditure(effectIndex: 1, quantity: 3), // perUnit 15×3=45
        ],
      );
      expect(ps.tpSpendingDerived(), 55);
    });

    // ── tpSpendingDerived with empty list ───────────────────────────────────

    test('tpSpendingDerived returns 0 with empty expenditures', () {
      const ps = ProductionState(tpExpenditures: []);
      expect(ps.tpSpendingDerived(), 0);
    });

    // ── remainingTp ──────────────────────────────────────────────────────────

    test('remainingTp equals totalTp minus tpSpendingDerived', () {
      // enableFacilities + enableTemporal required for totalTp to be non-zero.
      const config = GameConfig(enableFacilities: true, enableTemporal: true);
      final ps = ProductionState(
        tpCarryOver: 50,
        worlds: [const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30)],
        tpExpenditures: const [
          TpExpenditure(effectIndex: 2), // flat 10
        ],
      );
      // totalTp = tpCarryOver(50) + colonyTp (≥0); we just verify the delta.
      final total = ps.totalTp(config);
      expect(ps.remainingTp(config), total - 10);
    });

    // ── JSON round-trip ──────────────────────────────────────────────────────

    test('TpExpenditure JSON round-trip preserves all fields', () {
      const original = TpExpenditure(effectIndex: 3, quantity: 2, hullPoints: 5);
      final json = original.toJson();
      final restored = TpExpenditure.fromJson(json);
      expect(restored.effectIndex, original.effectIndex);
      expect(restored.quantity, original.quantity);
      expect(restored.hullPoints, original.hullPoints);
    });

    // ── GameConfig.temporalEngineShipType ────────────────────────────────────

    test('GameConfig.temporalEngineShipType JSON round-trip with ShipType.dd', () {
      const config = GameConfig(temporalEngineShipType: ShipType.dd);
      final restored = GameConfig.fromJson(config.toJson());
      expect(restored.temporalEngineShipType, ShipType.dd);
    });

    test('GameConfig.temporalEngineShipType legacy JSON (missing key) yields null', () {
      final config = GameConfig.fromJson(const {});
      expect(config.temporalEngineShipType, isNull);
    });
  });
}
