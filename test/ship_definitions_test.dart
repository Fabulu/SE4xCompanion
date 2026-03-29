import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';

void main() {
  group('All ship types have definitions', () {
    test('every ShipType enum value has a definition', () {
      for (final type in ShipType.values) {
        expect(kShipDefinitions.containsKey(type), true,
            reason: '${type.name} should have a definition');
      }
    });
  });

  group('Hull sizes', () {
    test('SC hull = 1', () {
      expect(kShipDefinitions[ShipType.scout]!.hullSize, 1);
    });

    test('DD hull = 1', () {
      expect(kShipDefinitions[ShipType.dd]!.hullSize, 1);
    });

    test('CA hull = 2', () {
      expect(kShipDefinitions[ShipType.ca]!.hullSize, 2);
    });

    test('BC hull = 3', () {
      expect(kShipDefinitions[ShipType.bc]!.hullSize, 3);
    });

    test('BB hull = 3', () {
      expect(kShipDefinitions[ShipType.bb]!.hullSize, 3);
    });

    test('DN hull = 3', () {
      expect(kShipDefinitions[ShipType.dn]!.hullSize, 3);
    });

    test('TN hull = 4', () {
      expect(kShipDefinitions[ShipType.tn]!.hullSize, 4);
    });

    test('FLAG hull = 3', () {
      expect(kShipDefinitions[ShipType.flag]!.hullSize, 3);
    });
  });

  group('Maintenance exemptions', () {
    test('exempt ships', () {
      final exemptTypes = [
        ShipType.base,
        ShipType.starbase,
        ShipType.dsn,
        ShipType.colonyShip,
        ShipType.miner,
        ShipType.msPipeline,
        ShipType.shipyard,
        ShipType.mine,
        ShipType.flag,
        ShipType.decoy,
      ];
      for (final type in exemptTypes) {
        expect(kShipDefinitions[type]!.maintenanceExempt, true,
            reason: '${type.name} should be maintenance exempt');
      }
    });

    test('non-exempt ships', () {
      final nonExemptTypes = [
        ShipType.scout,
        ShipType.dd,
        ShipType.ca,
        ShipType.bc,
        ShipType.bb,
        ShipType.dn,
        ShipType.tn,
        ShipType.fighter,
        ShipType.cv,
        ShipType.bv,
        ShipType.raider,
        ShipType.sw,
        ShipType.bdMb,
        ShipType.transport,
        ShipType.un,
      ];
      for (final type in nonExemptTypes) {
        expect(kShipDefinitions[type]!.maintenanceExempt, false,
            reason: '${type.name} should NOT be maintenance exempt');
      }
    });
  });

  group('Build costs', () {
    test('DD costs 6', () {
      expect(kShipDefinitions[ShipType.dd]!.buildCost, 6);
    });

    test('CA costs 12', () {
      expect(kShipDefinitions[ShipType.ca]!.buildCost, 12);
    });

    test('BC costs 15', () {
      expect(kShipDefinitions[ShipType.bc]!.buildCost, 15);
    });

    test('BB costs 20', () {
      expect(kShipDefinitions[ShipType.bb]!.buildCost, 20);
    });

    test('DN costs 24', () {
      expect(kShipDefinitions[ShipType.dn]!.buildCost, 24);
    });

    test('TN costs 32', () {
      expect(kShipDefinitions[ShipType.tn]!.buildCost, 32);
    });

    test('FLAG costs 0', () {
      expect(kShipDefinitions[ShipType.flag]!.buildCost, 0);
    });

    test('Decoy costs 1', () {
      expect(kShipDefinitions[ShipType.decoy]!.buildCost, 1);
    });
  });

  group('Counter counts', () {
    test('DD has 6 counters', () {
      expect(kShipDefinitions[ShipType.dd]!.maxCounters, 6);
    });

    test('Scout has 7 counters', () {
      expect(kShipDefinitions[ShipType.scout]!.maxCounters, 7);
    });

    test('Fighter has 10 counters', () {
      expect(kShipDefinitions[ShipType.fighter]!.maxCounters, 10);
    });

    test('TN has 5 counters', () {
      expect(kShipDefinitions[ShipType.tn]!.maxCounters, 5);
    });

    test('FLAG has 1 counter', () {
      expect(kShipDefinitions[ShipType.flag]!.maxCounters, 1);
    });

    test('non-counter ships have 0 maxCounters', () {
      final zeroCounterTypes = [
        ShipType.mine, ShipType.miner, ShipType.msPipeline,
        ShipType.colonyShip, ShipType.base, ShipType.starbase,
        ShipType.dsn, ShipType.shipyard, ShipType.decoy,
      ];
      for (final type in zeroCounterTypes) {
        expect(kShipDefinitions[type]!.maxCounters, 0,
            reason: '${type.name} should have 0 counters');
      }
    });
  });

  group('Weapon classes', () {
    test('BB and DN are class A', () {
      expect(kShipDefinitions[ShipType.bb]!.weaponClass, 'A');
      expect(kShipDefinitions[ShipType.dn]!.weaponClass, 'A');
      expect(kShipDefinitions[ShipType.tn]!.weaponClass, 'A');
    });

    test('CA, BC, CV are class B', () {
      expect(kShipDefinitions[ShipType.ca]!.weaponClass, 'B');
      expect(kShipDefinitions[ShipType.bc]!.weaponClass, 'B');
      expect(kShipDefinitions[ShipType.cv]!.weaponClass, 'B');
    });

    test('DD, Raider are class C', () {
      expect(kShipDefinitions[ShipType.dd]!.weaponClass, 'C');
      expect(kShipDefinitions[ShipType.raider]!.weaponClass, 'C');
    });

    test('Scout, SW, Transport are class E', () {
      expect(kShipDefinitions[ShipType.scout]!.weaponClass, 'E');
      expect(kShipDefinitions[ShipType.sw]!.weaponClass, 'E');
      expect(kShipDefinitions[ShipType.transport]!.weaponClass, 'E');
    });
  });
}
