// Regression tests for bug-fix sweep covering:
//   Bug A — shipyard capacity enforcement at purchase time.
//   Bug C — card modifier double-apply guard via sourceCardId.
//   Bug F — multi-turn buildProgressHp accumulation per turn.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('Bug A: canAssignPurchaseTo gates DN at SY-1 hex when multi-turn off',
      () {
    test('DN (5 HP) cannot be queued at 1-yard hex under RAW', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 1),
      ]);
      final tech = const TechState(levels: {TechId.shipYard: 1}); // 1 HP/turn
      final ps = ProductionState(
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
      );
      final dnHull =
          kShipDefinitions[ShipType.dn]!.effectiveHullSize(false);
      expect(dnHull, greaterThanOrEqualTo(2));
      // 1 HP cap, DN needs >=2 HP → cannot assign under RAW.
      expect(ps.canAssignPurchaseTo(hex, dnHull, map, tech), false);
      // DD (1 HP) fits fine.
      expect(ps.canAssignPurchaseTo(hex, 1, map, tech), true);
    });

    test(
        'RAW vs multi-turn: config toggle decides whether UI lets DN through',
        () {
      // The "block" decision is a UI-level composition of canAssignPurchaseTo
      // and config.enableMultiTurnBuilds. Mirror that gate here.
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 1),
      ]);
      final tech = const TechState(levels: {TechId.shipYard: 1});
      final ps = ProductionState(
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
      );
      final dnHull =
          kShipDefinitions[ShipType.dn]!.effectiveHullSize(false);

      bool uiAllowsAdd(GameConfig cfg) =>
          cfg.enableMultiTurnBuilds ||
          ps.canAssignPurchaseTo(hex, dnHull, map, tech);

      const rawCfg = GameConfig(enableMultiTurnBuilds: false);
      const multiCfg = GameConfig(enableMultiTurnBuilds: true);
      expect(uiAllowsAdd(rawCfg), false, reason: 'RAW must block over-capacity');
      expect(uiAllowsAdd(multiCfg), true, reason: 'Multi-turn allows queuing');
    });
  });

  group('Bug C: activeModifier dedup via sourceCardId', () {
    test('GameModifier carries + roundtrips sourceCardId', () {
      const m = GameModifier(
        name: 'Abundant Planet',
        type: 'incomeMod',
        value: 2,
        sourceCardId: 'planetAttribute:1005',
      );
      final json = m.toJson();
      expect(json['sourceCardId'], 'planetAttribute:1005');
      final restored = GameModifier.fromJson(json);
      expect(restored.sourceCardId, 'planetAttribute:1005');
    });

    test('Legacy GameModifier json (no sourceCardId) still parses', () {
      final restored = GameModifier.fromJson({
        'name': 'Legacy',
        'type': 'incomeMod',
        'value': 1,
      });
      expect(restored.sourceCardId, isNull);
    });

    test('withSourceCardId stamps a copy without mutating the original', () {
      const orig = GameModifier(
        name: 'Abundant Planet',
        type: 'incomeMod',
        value: 2,
      );
      final stamped = orig.withSourceCardId('planetAttribute:1005');
      expect(orig.sourceCardId, isNull);
      expect(stamped.sourceCardId, 'planetAttribute:1005');
    });

    test('Applying same card twice yields one active modifier after dedup',
        () {
      // Mirror the de-dup logic in home_page._dedupCardModifiers.
      const id = 'planetAttribute:1005';
      final m1 = const GameModifier(
        name: 'Abundant Planet',
        type: 'incomeMod',
        value: 2,
      ).withSourceCardId(id);
      final active = <GameModifier>[];

      List<GameModifier> dedup(List<GameModifier> incoming) {
        final seen = <String>{
          for (final m in active)
            if (m.sourceCardId != null) m.sourceCardId!,
        };
        final out = <GameModifier>[];
        for (final m in incoming) {
          if (m.sourceCardId != null && seen.contains(m.sourceCardId)) continue;
          out.add(m);
          if (m.sourceCardId != null) seen.add(m.sourceCardId!);
        }
        return out;
      }

      active.addAll(dedup([m1]));
      active.addAll(dedup([m1])); // second application
      expect(active.length, 1);
      expect(active.first.sourceCardId, id);
    });
  });

  group('Bug F: multi-turn buildProgressHp increments each turn', () {
    test('5-HP ship at 1-HP/turn yard takes 5 turns to complete', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 1),
      ]);
      const tech = TechState(levels: {TechId.shipYard: 1}); // 1 HP/turn
      const config = GameConfig(enableMultiTurnBuilds: true);

      var ps = ProductionState(
        techState: tech,
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
        shipPurchases: [
          ShipPurchase(
            type: ShipType.dn,
            shipyardHexId: '0,0',
            totalHpNeeded: 5,
          ),
        ],
      );

      for (int turn = 1; turn <= 5; turn++) {
        ps = ps.applyBuildProgress(config, map);
        expect(ps.shipPurchases.first.buildProgressHp, turn,
            reason: 'turn $turn contribution');
      }
      // After 5 turns, buildProgressHp == totalHpNeeded.
      expect(ps.shipPurchases.first.buildProgressHp, 5);
      expect(ps.shipPurchases.first.totalHpNeeded, 5);
    });

    test('applyBuildProgress is a no-op when multi-turn builds disabled', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 2),
      ]);
      const tech = TechState(levels: {TechId.shipYard: 3});
      const config = GameConfig(enableMultiTurnBuilds: false);

      final ps = ProductionState(
        techState: tech,
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
        shipPurchases: [
          ShipPurchase(
            type: ShipType.dn,
            shipyardHexId: '0,0',
            totalHpNeeded: 5,
          ),
        ],
      );

      final next = ps.applyBuildProgress(config, map);
      expect(next.shipPurchases.first.buildProgressHp, 0);
    });

    test('applyBuildProgress distributes the hex budget across purchases', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 2),
      ]);
      // 2 yards * 2 HP (lvl 3) = 4 HP budget
      const tech = TechState(levels: {TechId.shipYard: 3});
      const config = GameConfig(enableMultiTurnBuilds: true);

      final ps = ProductionState(
        techState: tech,
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
        shipPurchases: [
          ShipPurchase(
            type: ShipType.bb,
            shipyardHexId: '0,0',
            totalHpNeeded: 3,
          ),
          ShipPurchase(
            type: ShipType.dn,
            shipyardHexId: '0,0',
            totalHpNeeded: 5,
          ),
        ],
      );

      final next = ps.applyBuildProgress(config, map);
      // First purchase takes min(3 needed, 4 budget) = 3 → completes.
      expect(next.shipPurchases[0].buildProgressHp, 3);
      // Remaining 1 HP goes to DN.
      expect(next.shipPurchases[1].buildProgressHp, 1);
    });

    test(
        'applyBuildProgress skips purchases with no hex or no totalHpNeeded',
        () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 1),
      ]);
      const tech = TechState(levels: {TechId.shipYard: 1});
      const config = GameConfig(enableMultiTurnBuilds: true);

      final ps = ProductionState(
        techState: tech,
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
        shipPurchases: [
          // No hex assignment.
          ShipPurchase(type: ShipType.dd, totalHpNeeded: 1),
          // No totalHpNeeded (legacy / instant).
          ShipPurchase(type: ShipType.dd, shipyardHexId: '0,0'),
        ],
      );
      final next = ps.applyBuildProgress(config, map);
      expect(next.shipPurchases[0].buildProgressHp, 0);
      expect(next.shipPurchases[1].buildProgressHp, 0);
    });
  });
}
