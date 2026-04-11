// Tests for the shipyard enforcement logic introduced in the T4 shipyard
// capacity update:
//   - hullPointsPerShipyard updated values (lvl 2 → 2.0, lvl 3 → 3.0)
//   - ShipDefinition.isShipyardExempt getter
//   - ProductionState.hasShipyardPurchaseInHex
//   - MaterializeResult.shipyardIncrements
//   - hullPointsSpentInHex skips exempt types

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. hullPointsPerShipyard
  // ---------------------------------------------------------------------------
  group('hullPointsPerShipyard', () {
    test('level 1 returns 1.0', () {
      expect(ProductionState.hullPointsPerShipyard(1), 1.0);
    });

    test('level 2 returns 2.0', () {
      expect(ProductionState.hullPointsPerShipyard(2), 2.0);
    });

    test('level 3 returns 3.0', () {
      expect(ProductionState.hullPointsPerShipyard(3), 3.0);
    });

    test('level 0 defaults to 1.0', () {
      expect(ProductionState.hullPointsPerShipyard(0), 1.0);
    });

    test('negative level defaults to 1.0', () {
      expect(ProductionState.hullPointsPerShipyard(-5), 1.0);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. isShipyardExempt
  // ---------------------------------------------------------------------------
  group('isShipyardExempt', () {
    test('ShipType.shipyard is exempt (maxCounters == 0)', () {
      expect(kShipDefinitions[ShipType.shipyard]!.isShipyardExempt, isTrue);
    });

    test('ShipType.base is exempt', () {
      expect(kShipDefinitions[ShipType.base]!.isShipyardExempt, isTrue);
    });

    test('ShipType.dsn is exempt', () {
      expect(kShipDefinitions[ShipType.dsn]!.isShipyardExempt, isTrue);
    });

    test('ShipType.decoy is exempt', () {
      expect(kShipDefinitions[ShipType.decoy]!.isShipyardExempt, isTrue);
    });

    test('ShipType.groundUnit is exempt', () {
      expect(kShipDefinitions[ShipType.groundUnit]!.isShipyardExempt, isTrue);
    });

    test('ShipType.dd is NOT exempt (maxCounters == 6)', () {
      expect(kShipDefinitions[ShipType.dd]!.isShipyardExempt, isFalse);
    });

    test('ShipType.ca is NOT exempt', () {
      expect(kShipDefinitions[ShipType.ca]!.isShipyardExempt, isFalse);
    });

    test('ShipType.fighter is NOT exempt', () {
      expect(kShipDefinitions[ShipType.fighter]!.isShipyardExempt, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. hasShipyardPurchaseInHex
  // ---------------------------------------------------------------------------
  group('hasShipyardPurchaseInHex', () {
    test('returns false when no purchases exist', () {
      final ps = const ProductionState();
      expect(ps.hasShipyardPurchaseInHex('0,0'), isFalse);
    });

    test('returns true when a SY purchase is queued at the given hex', () {
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(type: ShipType.shipyard, shipyardHexId: '0,0'),
      ]);
      expect(ps.hasShipyardPurchaseInHex('0,0'), isTrue);
    });

    test('returns false for non-SY purchase at the same hex', () {
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(type: ShipType.dd, shipyardHexId: '0,0'),
      ]);
      expect(ps.hasShipyardPurchaseInHex('0,0'), isFalse);
    });

    test('returns false for SY purchase at a different hex', () {
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(type: ShipType.shipyard, shipyardHexId: '1,0'),
      ]);
      expect(ps.hasShipyardPurchaseInHex('0,0'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. MaterializeResult.shipyardIncrements
  // ---------------------------------------------------------------------------
  group('MaterializeResult.shipyardIncrements', () {
    final tech = const TechState();

    test('single SY purchase adds hex ID with count 1', () {
      final counters = createAllCounters();
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(
          type: ShipType.shipyard,
          quantity: 1,
          shipyardHexId: '2,3',
        ),
      ]);

      final result = ps.materializeCompletedPurchases(tech, counters);

      expect(result.shipyardIncrements, {'2,3': 1});
    });

    test('two SY purchases at different hexes both appear', () {
      final counters = createAllCounters();
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(
          type: ShipType.shipyard,
          quantity: 1,
          shipyardHexId: '0,0',
        ),
        const ShipPurchase(
          type: ShipType.shipyard,
          quantity: 1,
          shipyardHexId: '1,1',
        ),
      ]);

      final result = ps.materializeCompletedPurchases(tech, counters);

      expect(result.shipyardIncrements, {'0,0': 1, '1,1': 1});
    });

    test('non-SY purchase with maxCounters==0 does NOT appear in increments', () {
      final counters = createAllCounters();
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(
          type: ShipType.base,
          quantity: 1,
          shipyardHexId: '0,0',
        ),
      ]);

      final result = ps.materializeCompletedPurchases(tech, counters);

      expect(result.shipyardIncrements, isEmpty);
    });

    test('SY purchase with null shipyardHexId does NOT appear in increments', () {
      final counters = createAllCounters();
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(
          type: ShipType.shipyard,
          quantity: 1,
          // shipyardHexId intentionally omitted (null)
        ),
      ]);

      final result = ps.materializeCompletedPurchases(tech, counters);

      expect(result.shipyardIncrements, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. hullPointsSpentInHex skips exempt types
  // ---------------------------------------------------------------------------
  group('hullPointsSpentInHex skips exempt types', () {
    test('Base purchase assigned to hex does NOT count toward HP spent', () {
      final hex = const HexCoord(0, 0);
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(type: ShipType.base, quantity: 1, shipyardHexId: '0,0'),
      ]);
      expect(ps.hullPointsSpentInHex(hex), 0);
    });

    test('DD purchase assigned to hex DOES count toward HP spent', () {
      final hex = const HexCoord(0, 0);
      // DD has hullSize 1 per ship_definitions.
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(type: ShipType.dd, quantity: 1, shipyardHexId: '0,0'),
      ]);
      expect(ps.hullPointsSpentInHex(hex), 1);
    });

    test('mixed exempt and non-exempt: only non-exempt counted', () {
      final hex = const HexCoord(0, 0);
      final ps = ProductionState(shipPurchases: [
        const ShipPurchase(type: ShipType.base, quantity: 1, shipyardHexId: '0,0'),
        const ShipPurchase(type: ShipType.dsn, quantity: 2, shipyardHexId: '0,0'),
        const ShipPurchase(type: ShipType.dd, quantity: 2, shipyardHexId: '0,0'),
      ]);
      // Only 2 DDs × 1 HP = 2
      expect(ps.hullPointsSpentInHex(hex), 2);
    });
  });
}
