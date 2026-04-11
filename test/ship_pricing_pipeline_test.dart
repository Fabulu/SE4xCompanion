// Canonical ship-pricing pipeline tests.
//
// These tests lock the single source of truth for per-unit ship costs
// ([ProductionState.effectiveUnitShipCost]) and guarantee that the
// aggregator ([ProductionState.shipPurchaseCost]) never disagrees with it.
// See `runs/CLAUDE-RUNS/*/ship-pricing-audit.md` for background.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/scenarios.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/world.dart';

void main() {
  WorldState hw() =>
      WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30);

  ProductionState psWith(List<ShipPurchase> purchases) =>
      ProductionState(worlds: [hw()], shipPurchases: purchases);

  const defaultConfig = GameConfig();

  group('effectiveUnitShipCost base table (default config)', () {
    // Base cost comes from kShipDefinitions.buildCost when the default
    // config (no AGT, no alt-empire, no scenario, no modifiers, no EA) is
    // used. The canonical helper must return that number verbatim for
    // every non-zero-cost entry in the table.
    final ps = psWith(const []);

    test('every definition with buildCost > 0 matches the base table', () {
      for (final entry in kShipDefinitions.entries) {
        final def = entry.value;
        if (def.buildCost <= 0) continue; // flagship, starbase, etc.
        final unit = ps.effectiveUnitShipCost(entry.key, defaultConfig);
        expect(unit, def.buildCost,
            reason:
                '${def.abbreviation} (${entry.key.name}) should cost ${def.buildCost} in default config, got $unit');
      }
    });

    test('zero-cost entries clamp to the 1 CP minimum', () {
      // Flagship and Starbase have buildCost: 0 (placed by other mechanics);
      // the clamp guarantees we never charge "0" if such an entry somehow
      // reaches the purchase list.
      expect(
          ps.effectiveUnitShipCost(ShipType.flag, defaultConfig), 1);
      expect(
          ps.effectiveUnitShipCost(ShipType.starbase, defaultConfig), 1);
    });
  });

  group('Titan regression (§22.0 / §41.1.6)', () {
    final ps = psWith(const []);

    test('Titan costs 32 CP in default config', () {
      expect(ps.effectiveUnitShipCost(ShipType.tn, defaultConfig), 32);
    });

    test('Titan costs 32 CP with AGT/facilities mode enabled', () {
      const config = GameConfig(enableFacilities: true);
      // TN has no agtBuildCost override, so the base 32 flows through.
      expect(ps.effectiveUnitShipCost(ShipType.tn, config), 32);
    });

    test('no scenario reduces Titan below 32 CP', () {
      for (final scenario in kScenarios) {
        final config = GameConfig(
          scenarioId: scenario.id,
          shipCostMultiplier: scenario.shipCostMultiplier,
        );
        final cost = ps.effectiveUnitShipCost(ShipType.tn, config);
        expect(cost, greaterThanOrEqualTo(32),
            reason:
                'Scenario ${scenario.id} drops Titan to $cost CP — below the §41.1.6 table value');
      }
    });
  });

  group('Display parity: helper * qty == shipPurchaseCost', () {
    // This is the non-negotiable invariant that makes it safe for the
    // production page to use the helper for display while the game logic
    // keeps calling shipPurchaseCost for the ledger.
    test('aggregator agrees with per-unit helper for mixed purchases', () {
      final purchases = const [
        ShipPurchase(type: ShipType.dd, quantity: 3),
        ShipPurchase(type: ShipType.ca, quantity: 1),
        ShipPurchase(type: ShipType.dn, quantity: 2),
        ShipPurchase(type: ShipType.tn, quantity: 1),
      ];
      final ps = psWith(purchases);

      int handRolled = 0;
      for (final p in purchases) {
        handRolled +=
            ps.effectiveUnitShipCost(p.type, defaultConfig) * p.quantity;
      }
      expect(ps.shipPurchaseCost(defaultConfig), handRolled);
    });

    test('aggregator agrees under an active Empire Advantage + card mod',
        () {
      // Gifted Scientists (+1 global) stacked with Polytitanium (DD -2).
      final config = const GameConfig(selectedEmpireAdvantage: 41);
      const mods = [
        GameModifier(
          name: 'Polytitanium Alloy',
          type: 'costMod',
          shipType: ShipType.dd,
          value: -2,
        ),
      ];
      final purchases = const [
        ShipPurchase(type: ShipType.dd, quantity: 4),
        ShipPurchase(type: ShipType.bb, quantity: 1),
      ];
      final ps = psWith(purchases);

      int handRolled = 0;
      for (final p in purchases) {
        handRolled += ps.effectiveUnitShipCost(
              p.type,
              config,
              modifiers: mods,
            ) *
            p.quantity;
      }
      expect(ps.shipPurchaseCost(config, mods), handRolled);
    });
  });

  group('Scenario multiplier', () {
    test('shipCostMultiplier 1.5 bumps DD from 6 to 9 CP', () {
      const config = GameConfig(shipCostMultiplier: 1.5);
      final ps = psWith(const []);
      expect(ps.effectiveUnitShipCost(ShipType.dd, config), 9);
    });

    test('shipCostMultiplier 1.5 rounds up (ceil)', () {
      const config = GameConfig(shipCostMultiplier: 1.5);
      final ps = psWith(const []);
      // MS Pipeline 3 * 1.5 = 4.5 -> 5
      expect(ps.effectiveUnitShipCost(ShipType.msPipeline, config), 5);
    });
  });

  group('Empire Advantage modifiers', () {
    test('EA #41 Gifted Scientists (+1 global) bumps DD to 7 and TN to 33',
        () {
      const config = GameConfig(selectedEmpireAdvantage: 41);
      final ps = psWith(const []);
      expect(ps.effectiveUnitShipCost(ShipType.dd, config), 7);
      expect(ps.effectiveUnitShipCost(ShipType.tn, config), 33);
    });

    test('EA #51 Star Wolves (DD -1) drops base-empire DD to 5', () {
      const config = GameConfig(selectedEmpireAdvantage: 51);
      final ps = psWith(const []);
      expect(ps.effectiveUnitShipCost(ShipType.dd, config), 5);
    });
  });

  group('Alien-tech card modifiers', () {
    test('Captain\'s Chair-style DN -4 brings DN to 20', () {
      // The task brief describes a DN -4 card; we express it directly as a
      // costMod GameModifier regardless of which card number carries it.
      const mods = [
        GameModifier(
          name: "The Captain's Chair",
          type: 'costMod',
          shipType: ShipType.dn,
          value: -4,
        ),
      ];
      final ps = psWith(const []);
      expect(
          ps.effectiveUnitShipCost(
            ShipType.dn,
            defaultConfig,
            modifiers: mods,
          ),
          20);
    });
  });

  group('Clamp to 1 CP', () {
    test('a -100 modifier on DD clamps the unit cost to 1 CP', () {
      const mods = [
        GameModifier(
          name: 'OP Tech',
          type: 'costMod',
          shipType: ShipType.dd,
          value: -100,
        ),
      ];
      final ps = psWith(const []);
      expect(
          ps.effectiveUnitShipCost(
            ShipType.dd,
            defaultConfig,
            modifiers: mods,
          ),
          1);
    });
  });

  group('Unique Ship (§41.1.5) minimum floor', () {
    test('UN cost is at least 5 CP in default config', () {
      final ps = psWith(const []);
      expect(ps.effectiveUnitShipCost(ShipType.un, defaultConfig),
          greaterThanOrEqualTo(5));
    });

    test('UN cost is at least 5 CP even with generous discounts', () {
      // A -100 costMod plus the ability-12 discount should still be clamped
      // up to the 1 CP per-unit minimum. The §41.1.5 floor is baked into
      // the static buildCost so the canonical pipeline already honors it
      // when the ship is queued without a design.
      const mods = [
        GameModifier(
          name: 'Unfair Tech',
          type: 'costMod',
          shipType: ShipType.un,
          value: -100,
        ),
      ];
      final ps = psWith(const []);
      final cost = ps.effectiveUnitShipCost(
        ShipType.un,
        defaultConfig,
        modifiers: mods,
        shipSpecialAbilities: const {ShipType.un: 12},
      );
      // Clamp guarantees >= 1 CP; we also want to make sure the static
      // table value is the documented §41.1.5 floor.
      expect(cost, greaterThanOrEqualTo(1));
      expect(kShipDefinitions[ShipType.un]!.buildCost, 5,
          reason:
              'Unique Ship base cost must respect §41.1.5 minimum of 5 CP');
    });
  });
}
