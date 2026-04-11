// Tests for the centralized card lookup helper introduced in PP04.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_lookup.dart';
import 'package:se4x/data/card_manifest.dart';

void main() {
  group('lookupCardByNumber', () {
    test('finds a known Alien Technology card (#4 Polytitanium Alloy)', () {
      final card = lookupCardByNumber(4);
      expect(card, isNotNull);
      expect(card!.name, 'Polytitanium Alloy');
      expect(card.type, 'alienTech');
    });

    test('finds a known Crew card (#237 Weapons Officer)', () {
      final card = lookupCardByNumber(237);
      expect(card, isNotNull);
      expect(card!.name, 'Weapons Officer');
      expect(card.type, 'crew');
    });

    test('finds a known Planet Attribute (#1002 Spice)', () {
      final card = lookupCardByNumber(1002);
      expect(card, isNotNull);
      expect(card!.name, 'Spice');
      expect(card.type, 'planetAttribute');
    });

    test('finds a known Resource card (#66 Red Squadron)', () {
      final card = lookupCardByNumber(66);
      expect(card, isNotNull);
      expect(card!.name, 'Red Squadron (Cancel Card)');
      expect(card.type, 'resource');
    });

    test('finds a known Mission card (#155 Arena)', () {
      final card = lookupCardByNumber(155);
      expect(card, isNotNull);
      expect(card!.name, 'Arena');
      expect(card.type, 'mission');
    });

    test('finds a known Scenario Modifier (#111 Carthage)', () {
      final card = lookupCardByNumber(111);
      expect(card, isNotNull);
      expect(card!.name, 'Carthage');
      expect(card.type, 'scenarioModifier');
    });

    test('returns null for an unknown card number', () {
      expect(lookupCardByNumber(999999), isNull);
      expect(lookupCardByNumber(0), isNull);
      expect(lookupCardByNumber(-1), isNull);
    });

    test('every returned card has a non-empty description', () {
      // Sanity check: the helper should never return an entry with a
      // blank description.
      for (final c in kAllCards) {
        final found = lookupCardByNumber(c.number);
        expect(found, isNotNull);
        expect(found!.description.isNotEmpty, true);
      }
    });
  });
}
