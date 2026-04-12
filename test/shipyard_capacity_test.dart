import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('T2-A: per-hex shipyard capacity', () {
    test('hullPointsPerShipyard follows rule 9.6', () {
      expect(ProductionState.hullPointsPerShipyard(1), 1.0);
      expect(ProductionState.hullPointsPerShipyard(2), 2.0);
      expect(ProductionState.hullPointsPerShipyard(3), 3.0);
      expect(ProductionState.hullPointsPerShipyard(4), 3.0);
      expect(ProductionState.hullPointsPerShipyard(0), 1.0);
    });

    test('shipyardCapacityForHex: count * hp per yard', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(
          coord: hex,
          worldId: 'w1',
          shipyardCount: 2,
        ),
      ]);
      final tech = const TechState(levels: {TechId.shipYard: 2});
      final ps = ProductionState(
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
      );
      // 2 yards * 2.0 = 4 HP
      expect(ps.shipyardCapacityForHex(hex, map, tech), 4);
    });

    test('shipyardCapacityForHex returns 0 when hex blocked', () {
      final hex = const HexCoord(1, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 3),
      ]);
      final tech = const TechState(levels: {TechId.shipYard: 3});
      final ps = ProductionState(worlds: [
        WorldState(name: 'HW', id: 'w1', isHomeworld: true, isBlocked: true),
      ]);
      expect(ps.shipyardCapacityForHex(hex, map, tech), 0);
    });

    test('shipyardCapacityForHex returns 0 when no shipyards', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 0),
      ]);
      final tech = const TechState(levels: {TechId.shipYard: 3});
      final ps = ProductionState(worlds: [
        WorldState(name: 'HW', id: 'w1', isHomeworld: true),
      ]);
      expect(ps.shipyardCapacityForHex(hex, map, tech), 0);
    });

    test('hullPointsSpentInHex sums assigned purchases', () {
      final hex = const HexCoord(0, 0);
      // DD has hullSize=1, CA hullSize=2 (from ship_definitions)
      final ps = ProductionState(shipPurchases: [
        ShipPurchase(type: ShipType.dd, quantity: 2, shipyardHexId: '0,0'),
        ShipPurchase(type: ShipType.ca, quantity: 1, shipyardHexId: '0,0'),
        ShipPurchase(type: ShipType.dd, quantity: 1, shipyardHexId: '1,0'),
        ShipPurchase(type: ShipType.dd, quantity: 1), // unassigned
      ]);
      // 2*1 + 1*2 = 4
      expect(ps.hullPointsSpentInHex(hex), 4);
    });

    test('canAssignPurchaseTo respects capacity', () {
      final hex = const HexCoord(0, 0);
      final map = GameMapState(hexes: [
        MapHexState(coord: hex, worldId: 'w1', shipyardCount: 1),
      ]);
      final tech = const TechState(levels: {TechId.shipYard: 3}); // 1*3 = 3 HP
      final ps = ProductionState(
        worlds: [WorldState(name: 'HW', id: 'w1', isHomeworld: true)],
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, shipyardHexId: '0,0'), // 1 HP used
        ],
      );
      // 2 HP free; DD (1 HP) fits, CA (2 HP) fits, BB (3 HP) does not.
      expect(ps.canAssignPurchaseTo(hex, 1, map, tech), true);
      expect(ps.canAssignPurchaseTo(hex, 2, map, tech), true);
      expect(ps.canAssignPurchaseTo(hex, 3, map, tech), false);
    });

    test('inProgressBuilds returns only partially-built purchases', () {
      final ps = ProductionState(shipPurchases: [
        ShipPurchase(type: ShipType.dd), // no progress
        ShipPurchase(
            type: ShipType.ca, buildProgressHp: 2, totalHpNeeded: 3), // in progress
        ShipPurchase(
            type: ShipType.ca, buildProgressHp: 3, totalHpNeeded: 3), // done
      ]);
      expect(ps.inProgressBuilds.length, 1);
      expect(ps.inProgressBuilds.first.type, ShipType.ca);
    });
  });

  group('T2-A: serialization', () {
    test('ShipPurchase roundtrips new fields', () {
      final original = ShipPurchase(
        type: ShipType.bb,
        quantity: 1,
        shipyardHexId: '3,4',
        buildProgressHp: 2,
        totalHpNeeded: 4,
      );
      final json = original.toJson();
      final restored = ShipPurchase.fromJson(json);
      expect(restored.type, ShipType.bb);
      expect(restored.shipyardHexId, '3,4');
      expect(restored.buildProgressHp, 2);
      expect(restored.totalHpNeeded, 4);
    });

    test('ShipPurchase legacy json (no new fields) still parses', () {
      final restored = ShipPurchase.fromJson({'type': 'dd', 'quantity': 2});
      expect(restored.shipyardHexId, isNull);
      expect(restored.buildProgressHp, 0);
      expect(restored.totalHpNeeded, isNull);
    });

    test('MapHexState roundtrips shipyardCount', () {
      final hex = MapHexState(
        coord: const HexCoord(1, 2),
        worldId: 'w1',
        shipyardCount: 3,
      );
      final restored = MapHexState.fromJson(hex.toJson());
      expect(restored.shipyardCount, 3);
    });

    test('MapHexState legacy json defaults shipyardCount to 0', () {
      final restored = MapHexState.fromJson({
        'coord': {'q': 0, 'r': 0},
      });
      expect(restored.shipyardCount, 0);
    });

    test('GameConfig.enableMultiTurnBuilds defaults false and roundtrips', () {
      const c1 = GameConfig();
      expect(c1.enableMultiTurnBuilds, false);
      final c2 = c1.copyWith(enableMultiTurnBuilds: true);
      expect(c2.enableMultiTurnBuilds, true);
      final restored = GameConfig.fromJson(c2.toJson());
      expect(restored.enableMultiTurnBuilds, true);
      // Legacy json without the key
      final legacy = GameConfig.fromJson({});
      expect(legacy.enableMultiTurnBuilds, false);
    });

    test('GameMapState legacy hex migration seeds HW with shipyardCount 1', () {
      // Simulate a legacy save with a hex containing a worldId but no
      // shipyardCount key anywhere.
      final json = {
        'layoutPreset': 'standard4p',
        'hexes': [
          {
            'coord': {'q': 0, 'r': 0},
            'worldId': 'hw-1',
            'label': 'HW',
          },
        ],
      };
      final map = GameMapState.fromJson(json);
      final seeded = map.hexAt(const HexCoord(0, 0));
      expect(seeded, isNotNull);
      expect(seeded!.shipyardCount, 1);
    });

    test('GameMapState modern save (with shipyardCount) is not migrated', () {
      final json = {
        'layoutPreset': 'standard4p',
        'hexes': [
          {
            'coord': {'q': 0, 'r': 0},
            'worldId': 'hw-1',
            'shipyardCount': 0,
          },
        ],
      };
      final map = GameMapState.fromJson(json);
      final h = map.hexAt(const HexCoord(0, 0));
      expect(h!.shipyardCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // EA #34 Giant Race / EA #43 Insectoids hull-size modifier on capacity
  // ---------------------------------------------------------------------------

  group('hullPointsSpentInHex with hullSizeModifier', () {
    test('Giant Race: 1 DD = 2 HP (hull 1+1)', () {
      final hex = const HexCoord(0, 0);
      final ps = ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, shipyardHexId: hex.id),
        ],
      );
      // DD base hull = 1, modifier +1 => effective hull 2
      expect(ps.hullPointsSpentInHex(hex, hullSizeModifier: 1), 2);
    });

    test('Insectoid: 1 DD = 0 HP (hull 1-1=0)', () {
      final hex = const HexCoord(0, 0);
      final ps = ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, shipyardHexId: hex.id),
        ],
      );
      // DD base hull = 1, modifier -1 => effective hull 0
      expect(ps.hullPointsSpentInHex(hex, hullSizeModifier: -1), 0);
    });

    test('Giant Race: 2 CA = 6 HP (hull 2+1=3, x2)', () {
      final hex = const HexCoord(0, 0);
      final ps = ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.ca, quantity: 2, shipyardHexId: hex.id),
        ],
      );
      // CA base hull = 2, modifier +1 => 3, x2 qty = 6
      expect(ps.hullPointsSpentInHex(hex, hullSizeModifier: 1), 6);
    });

    test('Default modifier (0): unchanged', () {
      final hex = const HexCoord(0, 0);
      final ps = ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, shipyardHexId: hex.id),
        ],
      );
      expect(ps.hullPointsSpentInHex(hex), 1);
    });
  });
}
