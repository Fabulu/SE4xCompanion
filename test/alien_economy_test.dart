// Tests for the alien economy page helper functions.
//
// Scope (PP03):
//   A.1 — Alien ship CP costs must come from the canonical kShipDefinitions
//         table via the effectiveBuildCost() pipeline, not a hardcoded map
//         that drifts (e.g. SW=5 instead of the rulebook's 6).
//   A.2 — The fleet row's CP value must be a derived function of its
//         composition, not a free-standing field that can drift.
//
// These are pure-data tests on the top-level helpers that the picker and
// fleet row call into. They do not exercise the Flutter widget tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/pages/alien_economy_page.dart';

void main() {
  const baseConfig = GameConfig();
  const agtConfig = GameConfig(enableFacilities: true);
  const altBaseConfig = GameConfig(enableAlternateEmpire: true);

  group('alienShipCost — canonical ship definitions (PP03 A.1)', () {
    test('DD is 6 in the base game (rulebook value, not the old hardcoded 9)',
        () {
      expect(alienShipCost(ShipType.dd, baseConfig), 6);
    });

    test('DD is 9 in AGT/Facilities mode', () {
      // ship_definitions.dart sets agtBuildCost: 9 for the Destroyer.
      expect(alienShipCost(ShipType.dd, agtConfig), 9);
    });

    test('SW is 6 in the base game (rulebook value, not the old hardcoded 5)',
        () {
      // The old hardcoded alien map listed 5; kShipDefinitions says 6.
      expect(alienShipCost(ShipType.sw, baseConfig), 6);
    });

    test('CA is 12 in both base and AGT', () {
      expect(alienShipCost(ShipType.ca, baseConfig), 12);
      expect(alienShipCost(ShipType.ca, agtConfig), 12);
    });

    test('BC is 15, BB is 20, DN is 24 in base', () {
      expect(alienShipCost(ShipType.bc, baseConfig), 15);
      expect(alienShipCost(ShipType.bb, baseConfig), 20);
      expect(alienShipCost(ShipType.dn, baseConfig), 24);
    });

    test('Raider is 12 base, 14 alternate', () {
      expect(alienShipCost(ShipType.raider, baseConfig), 12);
      expect(alienShipCost(ShipType.raider, altBaseConfig), 14);
    });

    test('Scout is 6 base, 5 alternate', () {
      expect(alienShipCost(ShipType.scout, baseConfig), 6);
      expect(alienShipCost(ShipType.scout, altBaseConfig), 5);
    });

    test('Transport is 6 (rulebook value, not the old hardcoded 12)', () {
      // The old map said 12 because it conflated Transport with a larger
      // carrier-style ship; canonical says 6.
      expect(alienShipCost(ShipType.transport, baseConfig), 6);
    });

    test('Carrier is 12', () {
      expect(alienShipCost(ShipType.cv, baseConfig), 12);
    });

    test('Fighter is 5', () {
      expect(alienShipCost(ShipType.fighter, baseConfig), 5);
    });

    test('Mine is 5', () {
      expect(alienShipCost(ShipType.mine, baseConfig), 5);
    });

    test('null config falls back to base-game GameConfig defaults', () {
      // This is the legacy call path: widgets that do not yet pipe
      // through the active GameConfig should still get canonical costs.
      expect(alienShipCost(ShipType.dd), 6);
      expect(alienShipCost(ShipType.sw), 6);
      expect(alienShipCost(ShipType.ca), 12);
    });
  });

  group('alienCompositionCp — picker-side totals (PP03 A.2)', () {
    test('empty map is 0 CP', () {
      expect(alienCompositionCp({}), 0);
    });

    test('{DD: 2, CA: 1} matches 2*dd_cost + 1*ca_cost in base', () {
      final cp = alienCompositionCp({'DD': 2, 'CA': 1}, baseConfig);
      expect(
        cp,
        2 * alienShipCost(ShipType.dd, baseConfig) +
            1 * alienShipCost(ShipType.ca, baseConfig),
      );
      expect(cp, 24); // 2*6 + 12
    });

    test('{DD: 2, CA: 1} matches AGT prices when facilities are on', () {
      final cp = alienCompositionCp({'DD': 2, 'CA': 1}, agtConfig);
      expect(cp, 2 * 9 + 1 * 12); // 30
    });

    test('unknown abbreviations are ignored, not crashed on', () {
      expect(alienCompositionCp({'XX': 99, 'DD': 1}, baseConfig), 6);
    });

    test('zero-quantity entries contribute 0', () {
      expect(alienCompositionCp({'DD': 0, 'CA': 0}, baseConfig), 0);
    });

    test('all picker ship classes are reachable via the helper', () {
      // Every abbreviation shown in the picker must resolve to a nonzero
      // cost under the base config — if any is 0, that means the wiring
      // from abbreviation → ShipType broke.
      final allAbbrevs = {
        'SC', 'DD', 'CA', 'BC', 'BB', 'DN',
        'Raider', 'Fighter', 'CV', 'Transport', 'Mine', 'SW',
      };
      for (final abbrev in allAbbrevs) {
        final cp = alienCompositionCp({abbrev: 1}, baseConfig);
        expect(cp, greaterThan(0),
            reason: 'Picker abbreviation "$abbrev" resolved to 0 CP');
      }
    });
  });

  group('parseAlienComposition — round-trip (PP03 A.2)', () {
    test('parses simple "2xDD, 1xCA"', () {
      expect(parseAlienComposition('2xDD, 1xCA'), {'DD': 2, 'CA': 1});
    });

    test('parses "3xSC" alone', () {
      expect(parseAlienComposition('3xSC'), {'SC': 3});
    });

    test('empty string returns empty map', () {
      expect(parseAlienComposition(''), isEmpty);
    });

    test('is tolerant of extra whitespace', () {
      expect(parseAlienComposition('2 x DD , 1 x CA'), {'DD': 2, 'CA': 1});
    });

    test('case-insensitive on the abbreviation', () {
      expect(parseAlienComposition('2xdd, 1xca'), {'DD': 2, 'CA': 1});
    });

    test('unknown tokens drop out silently', () {
      expect(parseAlienComposition('2xDD, 3xWAT'), {'DD': 2});
    });
  });

  group('alienCompositionCpFromString — fleet-row live CP (PP03 A.2)', () {
    test('empty composition → 0 CP', () {
      expect(alienCompositionCpFromString(''), 0);
    });

    test('"2xDD, 1xCA" base = 24', () {
      expect(alienCompositionCpFromString('2xDD, 1xCA', baseConfig), 24);
    });

    test('"2xDD, 1xCA" AGT = 30', () {
      expect(alienCompositionCpFromString('2xDD, 1xCA', agtConfig), 30);
    });

    test('editing composition updates the derived CP total', () {
      // Simulates what the picker does on Apply: compose a new map,
      // format it, re-parse, and expect the live helper to return the
      // new total.
      var cp = alienCompositionCpFromString('1xSC', baseConfig);
      expect(cp, 6);

      cp = alienCompositionCpFromString('1xSC, 1xDD', baseConfig);
      expect(cp, 12); // 6 + 6

      cp = alienCompositionCpFromString('1xSC, 1xDD, 1xCA', baseConfig);
      expect(cp, 24); // 6 + 6 + 12

      cp = alienCompositionCpFromString('1xSC, 1xDD, 1xCA, 1xDN', baseConfig);
      expect(cp, 48); // 6 + 6 + 12 + 24
    });
  });

  group('kShipDefinitions anchor guards', () {
    // If any of these drift, the helper tests above will produce
    // confusing failures. Lock the canonical table values in directly so
    // a future ship-data edit doesn't silently move alien economy.
    test('DD baseCost = 6, agtBuildCost = 9', () {
      final dd = kShipDefinitions[ShipType.dd]!;
      expect(dd.buildCost, 6);
      expect(dd.agtBuildCost, 9);
    });

    test('SW baseCost = 6 (rule 17.2)', () {
      final sw = kShipDefinitions[ShipType.sw]!;
      expect(sw.buildCost, 6);
    });

    test('Transport baseCost = 6 (rule 21.1)', () {
      final t = kShipDefinitions[ShipType.transport]!;
      expect(t.buildCost, 6);
    });
  });
}
