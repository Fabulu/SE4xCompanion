import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';

void main() {
  group('stampFromTech - hull size caps on attack/defense', () {
    // Tech state with att=3, def=3, tactics=3, move=4
    final highTech = const TechState(levels: {
      TechId.attack: 3,
      TechId.defense: 3,
      TechId.tactics: 3,
      TechId.move: 4,
    });

    test('Scout (hull 1): att/def capped at 1', () {
      final sc = ShipCounter.stampFromTech(ShipType.scout, 1, highTech);
      expect(sc.attack, 1);
      expect(sc.defense, 1);
      expect(sc.tactics, 3); // not capped
      expect(sc.move, 4); // not capped
      expect(sc.isBuilt, true);
    });

    test('DD (hull 1): att/def capped at 1', () {
      final dd = ShipCounter.stampFromTech(ShipType.dd, 1, highTech);
      expect(dd.attack, 1);
      expect(dd.defense, 1);
    });

    test('CA (hull 2): att/def capped at 2', () {
      final ca = ShipCounter.stampFromTech(ShipType.ca, 1, highTech);
      expect(ca.attack, 2);
      expect(ca.defense, 2);
    });

    test('BC (hull 3): att/def gets full tech level 3', () {
      final bc = ShipCounter.stampFromTech(ShipType.bc, 1, highTech);
      expect(bc.attack, 3);
      expect(bc.defense, 3);
    });

    test('BB (hull 3): att/def gets full tech level 3', () {
      final bb = ShipCounter.stampFromTech(ShipType.bb, 1, highTech);
      expect(bb.attack, 3);
      expect(bb.defense, 3);
    });

    test('DN (hull 3): att/def gets full tech level 3', () {
      final dn = ShipCounter.stampFromTech(ShipType.dn, 1, highTech);
      expect(dn.attack, 3);
      expect(dn.defense, 3);
    });

    test('TN (hull 4): att/def gets full tech level', () {
      final tn = ShipCounter.stampFromTech(ShipType.tn, 1, highTech);
      expect(tn.attack, 3);
      expect(tn.defense, 3);
    });

    test('Raider (hull 1) is exempt from hull cap', () {
      final r = ShipCounter.stampFromTech(ShipType.raider, 1, highTech);
      expect(r.attack, 3); // NOT capped despite hull 1
      expect(r.defense, 3);
    });
  });

  group('stampFromTech - tactics and move not limited by hull', () {
    final highTech = const TechState(levels: {
      TechId.attack: 1,
      TechId.defense: 1,
      TechId.tactics: 3,
      TechId.move: 6,
    });

    test('Scout (hull 1) gets full tactics and move', () {
      final sc = ShipCounter.stampFromTech(ShipType.scout, 1, highTech);
      expect(sc.tactics, 3);
      expect(sc.move, 6);
    });

    test('DD (hull 1) gets full tactics and move', () {
      final dd = ShipCounter.stampFromTech(ShipType.dd, 1, highTech);
      expect(dd.tactics, 3);
      expect(dd.move, 6);
    });
  });

  group('stampFromTech - default tech levels', () {
    test('with no tech upgrades, uses start levels', () {
      const tech = TechState();
      final dd = ShipCounter.stampFromTech(ShipType.dd, 1, tech);
      expect(dd.attack, 0);
      expect(dd.defense, 0);
      expect(dd.tactics, 0);
      expect(dd.move, 1); // Move starts at 1
    });
  });

  group('stampFromTech - facilities mode', () {
    test('uses facilities tech table for start levels', () {
      const tech = TechState();
      final dd = ShipCounter.stampFromTech(ShipType.dd, 1, tech,
          facilitiesMode: true);
      expect(dd.move, 1); // Move starts at 1 in both modes
    });
  });

  group('createAllCounters', () {
    test('creates correct number of counters per type', () {
      final counters = createAllCounters();
      // Count by type
      final counts = <ShipType, int>{};
      for (final c in counters) {
        counts[c.type] = (counts[c.type] ?? 0) + 1;
      }

      expect(counts[ShipType.flag], 1);
      expect(counts[ShipType.dd], 6);
      expect(counts[ShipType.ca], 6);
      expect(counts[ShipType.bc], 6);
      expect(counts[ShipType.bb], 6);
      expect(counts[ShipType.dn], 6);
      expect(counts[ShipType.tn], 5);
      expect(counts[ShipType.un], 6);
      expect(counts[ShipType.scout], 7);
      expect(counts[ShipType.raider], 6);
      expect(counts[ShipType.fighter], 10);
      expect(counts[ShipType.cv], 6);
      expect(counts[ShipType.bv], 6);
      expect(counts[ShipType.sw], 6);
      expect(counts[ShipType.bdMb], 6);
      expect(counts[ShipType.transport], 6);
    });

    test('skips types with maxCounters=0', () {
      final counters = createAllCounters();
      final types = counters.map((c) => c.type).toSet();
      // These have maxCounters=0 so should not appear
      expect(types.contains(ShipType.mine), false);
      expect(types.contains(ShipType.miner), false);
      expect(types.contains(ShipType.msPipeline), false);
      expect(types.contains(ShipType.colonyShip), false);
      expect(types.contains(ShipType.base), false);
      expect(types.contains(ShipType.starbase), false);
      expect(types.contains(ShipType.dsn), false);
      expect(types.contains(ShipType.shipyard), false);
      expect(types.contains(ShipType.decoy), false);
    });

    test('all counters start as unbuilt', () {
      final counters = createAllCounters();
      for (final c in counters) {
        expect(c.isBuilt, false, reason: '${c.type.name} #${c.number} should be unbuilt');
      }
    });
  });

  group('needsUpgrade', () {
    test('returns true when counter is behind tech', () {
      const counter = ShipCounter(
        type: ShipType.bc, number: 1, isBuilt: true,
        attack: 1, defense: 1, tactics: 0, move: 1,
      );
      const tech = TechState(levels: {
        TechId.attack: 2, TechId.defense: 2, TechId.tactics: 1, TechId.move: 2,
      });
      expect(counter.needsUpgrade(tech), true);
    });

    test('returns false when counter matches tech', () {
      const counter = ShipCounter(
        type: ShipType.bc, number: 1, isBuilt: true,
        attack: 2, defense: 2, tactics: 1, move: 2,
      );
      const tech = TechState(levels: {
        TechId.attack: 2, TechId.defense: 2, TechId.tactics: 1, TechId.move: 2,
      });
      expect(counter.needsUpgrade(tech), false);
    });
  });

  group('upgradeToTech', () {
    test('returns upgraded counter with correct levels', () {
      const counter = ShipCounter(
        type: ShipType.bc, number: 1, isBuilt: true,
        attack: 1, defense: 0, tactics: 0, move: 1,
      );
      const tech = TechState(levels: {
        TechId.attack: 3, TechId.defense: 2, TechId.tactics: 2, TechId.move: 3,
      });
      final upgraded = counter.upgradeToTech(tech);
      expect(upgraded, isNotNull);
      expect(upgraded!.attack, 3);
      expect(upgraded.defense, 2);
      expect(upgraded.tactics, 2);
      expect(upgraded.move, 3);
      expect(upgraded.isBuilt, true);
      expect(upgraded.type, ShipType.bc);
      expect(upgraded.number, 1);
    });

    test('returns null when already up to date', () {
      const counter = ShipCounter(
        type: ShipType.bc, number: 1, isBuilt: true,
        attack: 2, defense: 2, tactics: 1, move: 3,
      );
      const tech = TechState(levels: {
        TechId.attack: 2, TechId.defense: 2, TechId.tactics: 1, TechId.move: 3,
      });
      expect(counter.upgradeToTech(tech), isNull);
    });

    test('respects hull size caps', () {
      // DD is hull 1, so att/def should cap at 1
      const counter = ShipCounter(
        type: ShipType.dd, number: 1, isBuilt: true,
        attack: 0, defense: 0, tactics: 0, move: 1,
      );
      const tech = TechState(levels: {
        TechId.attack: 3, TechId.defense: 3, TechId.tactics: 2, TechId.move: 4,
      });
      final upgraded = counter.upgradeToTech(tech);
      expect(upgraded, isNotNull);
      expect(upgraded!.attack, 1);  // capped at hull size 1
      expect(upgraded.defense, 1);  // capped at hull size 1
      expect(upgraded.tactics, 2);  // not capped
      expect(upgraded.move, 4);     // not capped
    });

    test('raiders exempt from hull cap in upgrade', () {
      const counter = ShipCounter(
        type: ShipType.raider, number: 1, isBuilt: true,
        attack: 0, defense: 0, tactics: 0, move: 1,
      );
      const tech = TechState(levels: {
        TechId.attack: 3, TechId.defense: 3, TechId.tactics: 2, TechId.move: 4,
      });
      final upgraded = counter.upgradeToTech(tech);
      expect(upgraded, isNotNull);
      expect(upgraded!.attack, 3);  // NOT capped despite hull 1
      expect(upgraded.defense, 3);  // NOT capped despite hull 1
    });
  });

  group('upgradeCost', () {
    test('returns correct hull size', () {
      const dd = ShipCounter(type: ShipType.dd, number: 1, isBuilt: true);
      expect(dd.upgradeCost(), 1);

      const ca = ShipCounter(type: ShipType.ca, number: 1, isBuilt: true);
      expect(ca.upgradeCost(), 2);

      const bc = ShipCounter(type: ShipType.bc, number: 1, isBuilt: true);
      expect(bc.upgradeCost(), 3);

      const bb = ShipCounter(type: ShipType.bb, number: 1, isBuilt: true);
      expect(bb.upgradeCost(), 3);

      const tn = ShipCounter(type: ShipType.tn, number: 1, isBuilt: true);
      expect(tn.upgradeCost(), 4);
    });

    test('returns AGT hull size when facilitiesMode is true', () {
      const bc = ShipCounter(type: ShipType.bc, number: 1, isBuilt: true);
      expect(bc.upgradeCost(facilitiesMode: true), 2); // AGT BC hull = 2

      const tn = ShipCounter(type: ShipType.tn, number: 1, isBuilt: true);
      expect(tn.upgradeCost(facilitiesMode: true), 5); // AGT TN hull = 5
    });
  });

  group('ShipCounter JSON round-trip', () {
    test('default counter serializes and deserializes', () {
      const c = ShipCounter(type: ShipType.dd, number: 1);
      final json = c.toJson();
      final restored = ShipCounter.fromJson(json);
      expect(restored.type, ShipType.dd);
      expect(restored.number, 1);
      expect(restored.isBuilt, false);
      expect(restored.attack, 0);
      expect(restored.defense, 0);
      expect(restored.tactics, 0);
      expect(restored.move, 0);
      expect(restored.experience, ShipExperience.unset);
      expect(restored.notes, '');
    });

    test('built counter with full state round-trips', () {
      const c = ShipCounter(
        type: ShipType.bc,
        number: 3,
        isBuilt: true,
        attack: 2,
        defense: 3,
        tactics: 1,
        move: 4,
        otherTechs: {'Fast': 1},
        experience: ShipExperience.veteran,
        notes: 'flanking',
      );
      final json = c.toJson();
      final restored = ShipCounter.fromJson(json);
      expect(restored.type, ShipType.bc);
      expect(restored.number, 3);
      expect(restored.isBuilt, true);
      expect(restored.attack, 2);
      expect(restored.defense, 3);
      expect(restored.tactics, 1);
      expect(restored.move, 4);
      expect(restored.otherTechs, {'Fast': 1});
      expect(restored.experience, ShipExperience.veteran);
      expect(restored.notes, 'flanking');
    });
  });
}
