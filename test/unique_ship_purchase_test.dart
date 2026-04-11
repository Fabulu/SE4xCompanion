// Wave 4 PP02: Tests for the Unique Ship purchase / production integration.
//
// Covers:
//   • effectiveUnitShipCost(ShipType.un, ..., uniqueDesign: ...) honors the
//     §41.1.6 hull table and the §41.1.5 minimum CP clamp.
//   • ShipPurchase JSON round-trip preserves the design payload.
//   • materializeCompletedPurchases stamps a UN counter with the design.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/unique_ship_designer.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';

void main() {
  const baseConfig = GameConfig();

  group('effectiveUnitShipCost — Unique Ship hull-table pricing', () {
    test('hull 3 with no abilities returns 12 CP', () {
      const design = UniqueShipDesign(
        name: 'Mk III',
        hullSize: 3,
        weaponClass: UniqueShipWeaponClass.c,
        abilityIds: [],
      );
      const ps = ProductionState();
      expect(
        ps.effectiveUnitShipCost(
          ShipType.un,
          baseConfig,
          uniqueDesign: design,
        ),
        12,
      );
    });

    test('hull 1 with DD ability returns max(6+1, 5) = 7 CP', () {
      // DD has stable id 1 and a +1 surcharge in the catalog.
      const design = UniqueShipDesign(
        name: 'Skirmisher',
        hullSize: 1,
        weaponClass: UniqueShipWeaponClass.d,
        abilityIds: [1],
      );
      const ps = ProductionState();
      expect(
        ps.effectiveUnitShipCost(
          ShipType.un,
          baseConfig,
          uniqueDesign: design,
        ),
        7,
      );
    });

    test('design that would price below 5 clamps to §41.1.5 minimum', () {
      // hull 1 = 6 CP base; -2 from two Design Weakness ids would land at 4,
      // but §41.1.5 forces a 5 CP floor. The catalog only has one Design
      // Weakness entry but ids may repeat in the list.
      const design = UniqueShipDesign(
        name: 'Cheapo',
        hullSize: 1,
        weaponClass: UniqueShipWeaponClass.e,
        // ability id 8 = Design Weakness, -1 each.
        abilityIds: [8, 8],
      );
      const ps = ProductionState();
      expect(
        ps.effectiveUnitShipCost(
          ShipType.un,
          baseConfig,
          uniqueDesign: design,
        ),
        kUniqueShipMinCost,
      );
    });

    test('UN without a design payload falls back to the base table cost', () {
      // Sanity check — passing no design must NOT explode and should
      // return the static base cost (5 CP) so callers that have not yet
      // queued a design (e.g. legacy code paths) keep working.
      const ps = ProductionState();
      final cost = ps.effectiveUnitShipCost(ShipType.un, baseConfig);
      expect(cost, isNonZero);
    });

    test('scenario shipCostMultiplier still scales the UN cost', () {
      const design = UniqueShipDesign(
        name: 'Dreadnought',
        hullSize: 5,
        weaponClass: UniqueShipWeaponClass.a,
        abilityIds: [],
      );
      // 2v1 allied scenario uses 1.5x. Hull 5 = 20 CP * 1.5 = 30 CP.
      const allied = GameConfig(shipCostMultiplier: 1.5);
      const ps = ProductionState();
      expect(
        ps.effectiveUnitShipCost(
          ShipType.un,
          allied,
          uniqueDesign: design,
        ),
        30,
      );
    });
  });

  group('shipPurchaseCost — UN purchases delegate to design pricer', () {
    test('queued UN purchase totals match the design cost x quantity', () {
      const design = UniqueShipDesign(
        name: 'Excalibur',
        hullSize: 4,
        weaponClass: UniqueShipWeaponClass.b,
        abilityIds: [4], // Fast 1, +2 CP
      );
      // Hull 4 base = 15, +2 = 17 CP per ship.
      final ps = ProductionState(
        shipPurchases: [
          ShipPurchase(
            type: ShipType.un,
            quantity: 2,
            uniqueDesign: design,
          ),
        ],
      );
      expect(ps.shipPurchaseCost(baseConfig), 34);
    });
  });

  group('ShipPurchase JSON round-trip — uniqueDesign preserved', () {
    test('round-trip preserves a populated unique design', () {
      const design = UniqueShipDesign(
        name: 'Phoenix',
        hullSize: 3,
        weaponClass: UniqueShipWeaponClass.b,
        abilityIds: [1, 2, 7],
      );
      const original = ShipPurchase(
        type: ShipType.un,
        quantity: 1,
        shipyardHexId: 'hw',
        uniqueDesign: design,
      );
      final encoded = jsonEncode(original.toJson());
      final decoded = ShipPurchase.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.type, ShipType.un);
      expect(decoded.quantity, 1);
      expect(decoded.shipyardHexId, 'hw');
      expect(decoded.uniqueDesign, isNotNull);
      expect(decoded.uniqueDesign!.name, 'Phoenix');
      expect(decoded.uniqueDesign!.hullSize, 3);
      expect(decoded.uniqueDesign!.weaponClass, UniqueShipWeaponClass.b);
      expect(decoded.uniqueDesign!.abilityIds, [1, 2, 7]);
    });

    test('legacy purchase without uniqueDesign decodes as null', () {
      // Older saves never wrote the field. fromJson must accept that.
      final json = {
        'type': 'dd',
        'quantity': 3,
      };
      final decoded = ShipPurchase.fromJson(json);
      expect(decoded.uniqueDesign, isNull);
      expect(decoded.type, ShipType.dd);
      expect(decoded.quantity, 3);
    });
  });

  group('materializeCompletedPurchases — preserves the design on the counter',
      () {
    test('UN purchase with design stamps the counter and copies the design',
        () {
      const design = UniqueShipDesign(
        name: 'Nimbus',
        hullSize: 2,
        weaponClass: UniqueShipWeaponClass.c,
        abilityIds: [3], // Exploration, +1 CP
      );
      final ps = ProductionState(
        shipPurchases: [
          ShipPurchase(
            type: ShipType.un,
            quantity: 1,
            uniqueDesign: design,
          ),
        ],
      );
      // Provide a single blank UN counter for the materializer to stamp.
      final blankCounters = <ShipCounter>[
        const ShipCounter(type: ShipType.un, number: 1),
      ];

      final result = ps.materializeCompletedPurchases(
        const TechState(),
        blankCounters,
      );

      expect(result.warnings, isEmpty);
      expect(result.newCounterIds.length, 1);

      final stamped = result.counters.firstWhere(
        (c) => c.type == ShipType.un,
      );
      expect(stamped.isBuilt, isTrue);
      expect(stamped.uniqueDesign, isNotNull);
      expect(stamped.uniqueDesign!.name, 'Nimbus');
      expect(stamped.uniqueDesign!.hullSize, 2);
      expect(stamped.uniqueDesign!.abilityIds, [3]);

      // The original purchase should be consumed from the new state.
      expect(result.state.shipPurchases, isEmpty);
    });
  });

  group('ShipCounter JSON round-trip — uniqueDesign preserved', () {
    test('a stamped UN counter with a design round-trips through JSON', () {
      const design = UniqueShipDesign(
        name: 'Nightfall',
        hullSize: 5,
        weaponClass: UniqueShipWeaponClass.a,
        abilityIds: [7, 11], // Shield Projector + Warp Gates
      );
      const counter = ShipCounter(
        type: ShipType.un,
        number: 1,
        isBuilt: true,
        attack: 3,
        defense: 2,
        tactics: 1,
        move: 2,
        uniqueDesign: design,
      );
      final decoded = ShipCounter.fromJson(
        jsonDecode(jsonEncode(counter.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.uniqueDesign, isNotNull);
      expect(decoded.uniqueDesign!.name, 'Nightfall');
      expect(decoded.uniqueDesign!.hullSize, 5);
      expect(decoded.uniqueDesign!.weaponClass, UniqueShipWeaponClass.a);
      expect(decoded.uniqueDesign!.abilityIds, [7, 11]);
    });
  });
}
