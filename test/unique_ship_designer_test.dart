import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/unique_ship_designer.dart';
import 'package:se4x/widgets/unique_ship_designer_dialog.dart';

void main() {
  group('uniqueShipDesignCost — §41.1.6 hull table', () {
    test('hull size 1 with no abilities returns 6', () {
      final design = UniqueShipDesign.blank().copyWith(hullSize: 1);
      expect(uniqueShipDesignCost(design), 6);
    });

    test('hull size 2 with no abilities returns 9', () {
      final design = UniqueShipDesign.blank().copyWith(hullSize: 2);
      expect(uniqueShipDesignCost(design), 9);
    });

    test('hull size 3 with no abilities returns 12', () {
      final design = UniqueShipDesign.blank().copyWith(hullSize: 3);
      expect(uniqueShipDesignCost(design), 12);
    });

    test('hull size 7 with no abilities returns 32', () {
      final design = UniqueShipDesign.blank().copyWith(hullSize: 7);
      expect(uniqueShipDesignCost(design), 32);
    });

    test('hull size 0 (invalid) clamps to minimum 5 CP', () {
      final design = UniqueShipDesign.blank().copyWith(hullSize: 0);
      expect(uniqueShipDesignCost(design), kUniqueShipMinCost);
      expect(uniqueShipDesignCost(design), 5);
    });

    test('hull size 99 (invalid) clamps to minimum 5 CP', () {
      final design = UniqueShipDesign.blank().copyWith(hullSize: 99);
      expect(uniqueShipDesignCost(design), 5);
    });

    test('all documented hull sizes match the rulebook table', () {
      const expected = {1: 6, 2: 9, 3: 12, 4: 15, 5: 20, 6: 24, 7: 32};
      for (final entry in expected.entries) {
        final design = UniqueShipDesign.blank().copyWith(hullSize: entry.key);
        expect(
          uniqueShipDesignCost(design),
          entry.value,
          reason: 'hull ${entry.key}',
        );
      }
    });
  });

  group('uniqueShipDesignCost — §41.1.7 ability surcharges', () {
    test('adding a +2 ability adds 2 CP', () {
      // Fast 1 (id 4) costs +2 CP.
      final base = UniqueShipDesign.blank().copyWith(hullSize: 3);
      final withAbility = base.copyWith(abilityIds: const [4]);
      expect(
        uniqueShipDesignCost(withAbility) - uniqueShipDesignCost(base),
        2,
      );
    });

    test('adding a +10 ability adds 10 CP', () {
      // Shield Projector (id 7) costs +10 CP.
      final base = UniqueShipDesign.blank().copyWith(hullSize: 4);
      final withAbility = base.copyWith(abilityIds: const [7]);
      expect(
        uniqueShipDesignCost(withAbility) - uniqueShipDesignCost(base),
        10,
      );
    });

    test('multiple abilities stack additively', () {
      // DD (+1) + Scanners (+1) + Fast 1 (+2) + Heavy Warheads (+2) = +6
      final design = UniqueShipDesign.blank()
          .copyWith(hullSize: 3, abilityIds: const [1, 2, 4, 13]);
      expect(uniqueShipDesignCost(design), 12 + 6);
    });

    test('unknown ability ids are ignored', () {
      final design = UniqueShipDesign.blank()
          .copyWith(hullSize: 3, abilityIds: const [999]);
      expect(uniqueShipDesignCost(design), 12);
    });

    test('negative Design Weakness ability reduces cost', () {
      // Design Weakness (id 8) costs -1 CP.
      final base = UniqueShipDesign.blank().copyWith(hullSize: 3);
      final withAbility = base.copyWith(abilityIds: const [8]);
      expect(uniqueShipDesignCost(withAbility), 11);
    });
  });

  group('uniqueShipDesignCost — §41.1.5 minimum clamp', () {
    test('design with -100 worth of abilities still returns 5 CP', () {
      // We don't have a single -100 ability, so simulate by stuffing
      // many copies of Design Weakness (-1 each). 100 copies => -100.
      final design = UniqueShipDesign.blank().copyWith(
        hullSize: 1,
        abilityIds: List<int>.filled(100, 8),
      );
      expect(uniqueShipDesignCost(design), kUniqueShipMinCost);
    });

    test('hull 1 with exactly -1 Design Weakness returns 5 CP', () {
      // Hull 1 = 6, minus 1 = 5, exactly the minimum.
      final design = UniqueShipDesign.blank()
          .copyWith(hullSize: 1, abilityIds: const [8]);
      expect(uniqueShipDesignCost(design), 5);
    });

    test('the minimum cost constant equals 5 per §41.1.5', () {
      expect(kUniqueShipMinCost, 5);
    });
  });

  group('UniqueShipDesign JSON round-trip', () {
    test('blank design round-trips', () {
      final original = UniqueShipDesign.blank();
      final decoded =
          UniqueShipDesign.fromJson(jsonDecode(jsonEncode(original.toJson())));
      expect(decoded, equals(original));
    });

    test('populated design round-trips exactly', () {
      const original = UniqueShipDesign(
        name: 'Excalibur',
        hullSize: 5,
        weaponClass: UniqueShipWeaponClass.b,
        abilityIds: [1, 4, 7],
      );
      final decoded =
          UniqueShipDesign.fromJson(jsonDecode(jsonEncode(original.toJson())));
      expect(decoded.name, 'Excalibur');
      expect(decoded.hullSize, 5);
      expect(decoded.weaponClass, UniqueShipWeaponClass.b);
      expect(decoded.abilityIds, [1, 4, 7]);
      expect(decoded, equals(original));
    });

    test('missing fields fall back to sensible defaults', () {
      final decoded = UniqueShipDesign.fromJson(const {});
      expect(decoded.name, '');
      expect(decoded.hullSize, 1);
      expect(decoded.weaponClass, UniqueShipWeaponClass.e);
      expect(decoded.abilityIds, isEmpty);
    });

    test('unknown weapon class in JSON falls back to class E', () {
      final decoded = UniqueShipDesign.fromJson(const {
        'name': 'Ghost',
        'hullSize': 2,
        'weaponClass': 'zzz',
        'abilityIds': [1],
      });
      expect(decoded.weaponClass, UniqueShipWeaponClass.e);
      expect(decoded.name, 'Ghost');
    });
  });

  group('Ability catalog integrity', () {
    test('every ability has a unique stable id', () {
      final ids = kUniqueShipAbilities.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
    });

    test('catalog is non-empty and contains the §41.1.7 rulebook entries', () {
      expect(kUniqueShipAbilities, isNotEmpty);
      final names = kUniqueShipAbilities.map((a) => a.name).toSet();
      expect(names, containsAll(const [
        'DD',
        'Scanners',
        'Exploration',
        'Fast 1',
        'Mini-Fighter Bay',
        'Anti-Sensor Hull',
        'Shield Projector',
        'Design Weakness',
        'Construction Bay',
        'Tractor Beam',
        'Warp Gates',
        'Second Salvo',
        'Heavy Warheads',
      ]));
    });

    test('uniqueShipAbilityById returns null for unknown ids', () {
      expect(uniqueShipAbilityById(-1), isNull);
      expect(uniqueShipAbilityById(99999), isNull);
    });
  });

  group('UniqueShipDesignerDialog widget', () {
    testWidgets('renders title, name field, slider, dropdown, and totals',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      UniqueShipDesign? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showUniqueShipDesignerDialog(ctx);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Design Unique Ship'), findsOneWidget);
      expect(find.text('Hull 1 = 6 CP base'), findsOneWidget);
      expect(find.text('6 CP'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel should resolve with null.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('Save returns the edited design', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      UniqueShipDesign? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showUniqueShipDesignerDialog(
                      ctx,
                      initial: const UniqueShipDesign(
                        name: 'Test',
                        hullSize: 2,
                        weaponClass: UniqueShipWeaponClass.d,
                        abilityIds: [1],
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Hull 2 = 9 base + DD (+1) = 10 CP.
      expect(find.text('10 CP'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Test');
      expect(result!.hullSize, 2);
      expect(result!.weaponClass, UniqueShipWeaponClass.d);
      expect(result!.abilityIds, contains(1));
    });
  });
}
