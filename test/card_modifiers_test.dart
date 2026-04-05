import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_manifest.dart';
import 'package:se4x/data/card_modifiers.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('kCardModifiers bindings', () {
    test('is non-empty', () {
      expect(kCardModifiers, isNotEmpty);
    });

    test('every binding is either mechanical OR complex', () {
      for (final entry in kCardModifiers.entries) {
        final b = entry.value;
        expect(b.hasModifiers || b.isComplex, isTrue,
            reason:
                'Card ${entry.key} has neither modifiers nor complex note');
      }
    });

    test('every bound card number matches a real card', () {
      final allNumbers = kAllCards.map((c) => c.number).toSet();
      for (final cardNumber in kCardModifiers.keys) {
        expect(allNumbers.contains(cardNumber), isTrue,
            reason: 'Card number $cardNumber has a binding but no '
                'catalog entry.');
      }
    });

    test('cardModifiersFor returns null for unbound card', () {
      // 2 = Anti-Matter Warhead (combat only, no binding)
      expect(cardModifiersFor(2), isNull);
    });

    test('cardHasModifiers is false for pure combat card', () {
      // 5 = Long Lance Torpedo (combat only)
      expect(cardHasModifiers(5), isFalse);
    });

    test('complex cards have empty modifier lists', () {
      for (final b in kCardModifiers.values) {
        if (b.isComplex && !b.hasModifiers) {
          expect(b.modifiers, isEmpty);
        }
      }
    });
  });

  group('Soylent Purple binding', () {
    test('applies to SC and DD at 50%', () {
      final b = cardModifiersFor(1)!;
      expect(b.modifiers.length, 2);
      expect(b.modifiers[0].type, 'maintenanceMod');
      expect(b.modifiers[0].isPercent, isTrue);
      expect(b.modifiers[0].value, 50);
      final types = b.modifiers.map((m) => m.shipType).toSet();
      expect(types, {ShipType.scout, ShipType.dd});
    });
  });

  group('Card binding flows through ProductionState', () {
    const baseConfig = GameConfig();

    WorldState hw() =>
        const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 30);

    test('Omega Crystals adds 5 to income', () {
      final b = cardModifiersFor(22)!;
      expect(b.modifiers.length, 1);
      final ps = ProductionState(worlds: [hw()]);
      final base = ps.totalCp(baseConfig);
      expect(ps.totalCp(baseConfig, b.modifiers), base + 5);
    });

    test('Wealthy planet +1', () {
      final b = cardModifiersFor(1006)!;
      final ps = ProductionState(worlds: [hw()]);
      expect(ps.totalCp(baseConfig, b.modifiers),
          ps.totalCp(baseConfig) + 1);
    });

    test('Quantum Computing reduces tech cost', () {
      final b = cardModifiersFor(184)!;
      expect(b.modifiers.single.type, 'techCostMod');
      expect(b.modifiers.single.value, -10);
    });

    test('Desolate planet -4', () {
      final b = cardModifiersFor(1008)!;
      expect(b.modifiers.single.value, -4);
    });
  });

  group('Bespoke flags', () {
    test('Time Dilation (1028) flagged complex', () {
      final b = cardModifiersFor(1028)!;
      expect(b.isComplex, isTrue);
      expect(b.complexBehaviorNote, contains('Time Dilation'));
    });

    test('Dilithium Crystals (1004) flagged complex', () {
      final b = cardModifiersFor(1004)!;
      expect(b.isComplex, isTrue);
    });

    test('Jedun (1025) flagged complex', () {
      final b = cardModifiersFor(1025)!;
      expect(b.isComplex, isTrue);
    });

    test('Spice (1002) flagged complex', () {
      final b = cardModifiersFor(1002)!;
      expect(b.isComplex, isTrue);
    });
  });
}
