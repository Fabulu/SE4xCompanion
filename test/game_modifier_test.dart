import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('GameModifier JSON round-trip', () {
    test('costMod with shipType round-trips', () {
      const mod = GameModifier(
        name: 'Polytitanium Alloy',
        type: 'costMod',
        shipType: ShipType.dd,
        value: -2,
      );
      final json = mod.toJson();
      final restored = GameModifier.fromJson(json);
      expect(restored.name, 'Polytitanium Alloy');
      expect(restored.type, 'costMod');
      expect(restored.shipType, ShipType.dd);
      expect(restored.value, -2);
      expect(restored.isPercent, false);
    });

    test('maintenanceMod with percent round-trips', () {
      const mod = GameModifier(
        name: 'Soylent Purple',
        type: 'maintenanceMod',
        shipType: ShipType.scout,
        value: 50,
        isPercent: true,
      );
      final json = mod.toJson();
      final restored = GameModifier.fromJson(json);
      expect(restored.name, 'Soylent Purple');
      expect(restored.type, 'maintenanceMod');
      expect(restored.shipType, ShipType.scout);
      expect(restored.value, 50);
      expect(restored.isPercent, true);
    });

    test('incomeMod without shipType round-trips', () {
      const mod = GameModifier(
        name: 'Abundant Planet',
        type: 'incomeMod',
        value: 2,
      );
      final json = mod.toJson();
      final restored = GameModifier.fromJson(json);
      expect(restored.name, 'Abundant Planet');
      expect(restored.type, 'incomeMod');
      expect(restored.shipType, isNull);
      expect(restored.value, 2);
    });

    test('techCostMod round-trips', () {
      const mod = GameModifier(
        name: 'Quantum Computing',
        type: 'techCostMod',
        value: -10,
      );
      final json = mod.toJson();
      final restored = GameModifier.fromJson(json);
      expect(restored.name, 'Quantum Computing');
      expect(restored.type, 'techCostMod');
      expect(restored.value, -10);
    });
  });

  group('GameModifier effectDescription', () {
    test('costMod shows ship abbreviation and CP change', () {
      const mod = GameModifier(
        name: 'Test', type: 'costMod', shipType: ShipType.dd, value: -2,
      );
      expect(mod.effectDescription, 'DD build cost -2 CP');
    });

    test('maintenanceMod percent shows percentage', () {
      const mod = GameModifier(
        name: 'Test', type: 'maintenanceMod', shipType: ShipType.scout,
        value: 50, isPercent: true,
      );
      expect(mod.effectDescription, 'SC maintenance 50%');
    });

    test('incomeMod shows signed CP', () {
      const mod = GameModifier(name: 'Test', type: 'incomeMod', value: 2);
      expect(mod.effectDescription, '+2 CP income/turn');
    });

    test('techCostMod shows signed CP', () {
      const mod = GameModifier(name: 'Test', type: 'techCostMod', value: -10);
      expect(mod.effectDescription, 'Tech costs -10 CP');
    });
  });

  group('GameState with activeModifiers', () {
    test('round-trips with modifiers', () {
      final gs = GameState(
        turnNumber: 3,
        activeModifiers: const [
          GameModifier(name: 'Test', type: 'incomeMod', value: 5),
          GameModifier(
            name: 'Poly', type: 'costMod', shipType: ShipType.dd, value: -2,
          ),
        ],
      );
      final json = gs.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.activeModifiers.length, 2);
      expect(restored.activeModifiers[0].name, 'Test');
      expect(restored.activeModifiers[0].value, 5);
      expect(restored.activeModifiers[1].shipType, ShipType.dd);
    });

    test('defaults to empty list when missing from JSON', () {
      final json = <String, dynamic>{'turnNumber': 2};
      final restored = GameState.fromJson(json);
      expect(restored.activeModifiers, isEmpty);
    });

    test('copyWith replaces modifiers', () {
      const gs = GameState();
      final updated = gs.copyWith(activeModifiers: const [
        GameModifier(name: 'X', type: 'incomeMod', value: 1),
      ]);
      expect(updated.activeModifiers.length, 1);
      expect(updated.activeModifiers[0].name, 'X');
    });
  });

  group('Production calculations with modifiers', () {
    const baseConfig = GameConfig();

    WorldState hw({int value = 30}) =>
        WorldState(name: 'HW', isHomeworld: true, homeworldValue: value);

    test('incomeMod adds to totalCp', () {
      final ps = ProductionState(worlds: [hw()]);
      const mods = [GameModifier(name: 'X', type: 'incomeMod', value: 3)];
      expect(ps.totalCp(baseConfig, mods), ps.totalCp(baseConfig) + 3);
    });

    test('negative incomeMod subtracts from totalCp', () {
      final ps = ProductionState(worlds: [hw()]);
      const mods = [GameModifier(name: 'X', type: 'incomeMod', value: -5)];
      expect(ps.totalCp(baseConfig, mods), ps.totalCp(baseConfig) - 5);
    });

    test('costMod reduces ship purchase cost', () {
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: const [ShipPurchase(type: ShipType.dd, quantity: 2)],
      );
      // DD base cost is 6, so 2x = 12
      expect(ps.shipPurchaseCost(baseConfig), 12);
      // With -2 modifier, each DD costs 4, so 2x = 8
      const mods = [
        GameModifier(name: 'Poly', type: 'costMod', shipType: ShipType.dd, value: -2),
      ];
      expect(ps.shipPurchaseCost(baseConfig, mods), 8);
    });

    test('costMod does not reduce below 1', () {
      final ps = ProductionState(
        worlds: [hw()],
        shipPurchases: const [ShipPurchase(type: ShipType.dd, quantity: 1)],
      );
      // DD costs 6, modifier -100 should clamp to 1
      const mods = [
        GameModifier(name: 'OP', type: 'costMod', shipType: ShipType.dd, value: -100),
      ];
      expect(ps.shipPurchaseCost(baseConfig, mods), 1);
    });

    test('maintenanceMod percent reduces per-ship maintenance', () {
      const counters = [
        ShipCounter(type: ShipType.scout, number: 1, isBuilt: true),
        ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
        ShipCounter(type: ShipType.ca, number: 1, isBuilt: true),
      ];
      final ps = ProductionState(worlds: [hw()]);

      // Without modifiers: SC(1) + DD(1) + CA(2) = 4
      expect(ps.maintenanceTotal(counters, baseConfig), 4);

      // With SC at 50%: ceil(1*0.5)=1, DD still 1, CA still 2 -> total 4
      // Actually SC hull=1, 50% of 1 = 0.5, ceil=1 -- same!
      // Let's use DD at 50% instead: DD hull=1, 50%=0.5, ceil=1 -- also same
      // Use CA at 50%: CA hull=2, 50%=1 -> SC(1)+DD(1)+CA(1) = 3
      const mods = [
        GameModifier(
          name: 'Half CA', type: 'maintenanceMod',
          shipType: ShipType.ca, value: 50, isPercent: true,
        ),
      ];
      expect(ps.maintenanceTotal(counters, baseConfig, mods), 3);
    });

    test('global maintenanceMod applies to total', () {
      const counters = [
        ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
        ShipCounter(type: ShipType.dd, number: 2, isBuilt: true),
      ];
      final ps = ProductionState(worlds: [hw()]);
      // 2 DDs, hull 1 each = 2 maintenance
      expect(ps.maintenanceTotal(counters, baseConfig), 2);
      // Global 50% -> ceil(2*0.5) = 1
      const mods = [
        GameModifier(
          name: 'Half all', type: 'maintenanceMod', value: 50, isPercent: true,
        ),
      ];
      expect(ps.maintenanceTotal(counters, baseConfig, mods), 1);
    });

    test('modifierIncome sums all incomeMod values', () {
      const mods = [
        GameModifier(name: 'A', type: 'incomeMod', value: 2),
        GameModifier(name: 'B', type: 'incomeMod', value: -1),
        GameModifier(name: 'C', type: 'costMod', shipType: ShipType.dd, value: -2),
      ];
      expect(ProductionState.modifierIncome(mods), 1);
    });

    test('modifiers flow through to remainingCp', () {
      final ps = ProductionState(worlds: [hw()]);
      const counters = <ShipCounter>[];
      const mods = [GameModifier(name: 'X', type: 'incomeMod', value: 5)];
      final withMods = ps.remainingCp(baseConfig, counters, mods);
      final withoutMods = ps.remainingCp(baseConfig, counters);
      expect(withMods, withoutMods + 5);
    });
  });

  group('Presets', () {
    test('kModifierPresets is non-empty', () {
      expect(kModifierPresets, isNotEmpty);
    });

    test('Soylent Purple preset has 2 modifiers', () {
      final soylent = kModifierPresets.firstWhere(
        (p) => p.label.contains('Soylent'),
      );
      expect(soylent.modifiers.length, 2);
      expect(soylent.modifiers[0].shipType, ShipType.scout);
      expect(soylent.modifiers[1].shipType, ShipType.dd);
    });
  });
}
