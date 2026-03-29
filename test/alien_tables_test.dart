import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/alien_tables.dart';

void main() {
  group('Alien economy schedule structure', () {
    test('has exactly 20 turn entries', () {
      expect(kAlienEconSchedule.length, 20);
    });

    test('turn numbers are 1 through 20', () {
      for (int i = 0; i < 20; i++) {
        expect(kAlienEconSchedule[i].turn, i + 1);
      }
    });
  });

  group('Econ rolls escalation', () {
    test('econ rolls follow pattern 1,1,2,2,2,3,3,3,3,4,4,4,4,4,5,5,5,5,5,5', () {
      final expected = [1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5];
      for (int i = 0; i < 20; i++) {
        expect(kAlienEconSchedule[i].econRolls, expected[i],
            reason: 'Turn ${i + 1} should have ${expected[i]} econ rolls');
      }
    });
  });

  group('Die roll resolution', () {
    test('turn 1: rolls 1-2 are econ, 3-10 are tech', () {
      final t = kAlienEconSchedule[0];
      expect(t.resolveRoll(1), AlienEconOutcomeType.econ);
      expect(t.resolveRoll(2), AlienEconOutcomeType.econ);
      expect(t.resolveRoll(3), AlienEconOutcomeType.tech);
      expect(t.resolveRoll(10), AlienEconOutcomeType.tech);
    });

    test('turn 1: no fleet launches', () {
      final t = kAlienEconSchedule[0];
      expect(t.fleetLaunchRange, '-');
      for (int r = 1; r <= 10; r++) {
        expect(t.fleetLaunches(r), false);
      }
    });

    test('turn 2: roll 1 is econ, 2-3 fleet, 4-10 tech', () {
      final t = kAlienEconSchedule[1];
      expect(t.resolveRoll(1), AlienEconOutcomeType.econ);
      expect(t.resolveRoll(2), AlienEconOutcomeType.fleet);
      expect(t.resolveRoll(3), AlienEconOutcomeType.fleet);
      expect(t.resolveRoll(4), AlienEconOutcomeType.tech);
      expect(t.resolveRoll(10), AlienEconOutcomeType.tech);
    });

    test('turn 2: fleet launches on any roll 1-10', () {
      final t = kAlienEconSchedule[1];
      expect(t.fleetLaunches(1), true);
      expect(t.fleetLaunches(10), true);
    });

    test('turn 3: has defense range 9-10', () {
      final t = kAlienEconSchedule[2];
      expect(t.resolveRoll(9), AlienEconOutcomeType.def);
      expect(t.resolveRoll(10), AlienEconOutcomeType.def);
      expect(t.resolveRoll(8), AlienEconOutcomeType.tech);
    });

    test('turn 5: def range is just 10', () {
      final t = kAlienEconSchedule[4];
      expect(t.resolveRoll(10), AlienEconOutcomeType.def);
      expect(t.resolveRoll(9), AlienEconOutcomeType.tech);
    });

    test('turn 7: no econ range, fleet is 1-5', () {
      final t = kAlienEconSchedule[6];
      expect(t.econRange, '-');
      expect(t.resolveRoll(1), AlienEconOutcomeType.fleet);
      expect(t.resolveRoll(5), AlienEconOutcomeType.fleet);
      expect(t.resolveRoll(6), AlienEconOutcomeType.tech);
    });

    test('turn 13: no defense range', () {
      final t = kAlienEconSchedule[12];
      expect(t.defRange, '-');
      expect(t.resolveRoll(7), AlienEconOutcomeType.tech);
      expect(t.resolveRoll(10), AlienEconOutcomeType.tech);
    });

    test('turn 20: fleet 1-9, tech 10 only', () {
      final t = kAlienEconSchedule[19];
      expect(t.resolveRoll(1), AlienEconOutcomeType.fleet);
      expect(t.resolveRoll(9), AlienEconOutcomeType.fleet);
      expect(t.resolveRoll(10), AlienEconOutcomeType.tech);
    });
  });

  group('getAlienEconDef boundary handling', () {
    test('turn < 1 returns turn 1 entry', () {
      final t = getAlienEconDef(0);
      expect(t.turn, 1);
    });

    test('turn > 20 returns turn 20 entry', () {
      final t = getAlienEconDef(25);
      expect(t.turn, 20);
    });

    test('turn 1 returns correct entry', () {
      final t = getAlienEconDef(1);
      expect(t.turn, 1);
      expect(t.econRolls, 1);
    });

    test('turn 20 returns correct entry', () {
      final t = getAlienEconDef(20);
      expect(t.turn, 20);
      expect(t.econRolls, 5);
    });
  });

  group('Fleet launch ranges', () {
    test('turn 4: fleet launches on 1-5 only', () {
      final t = kAlienEconSchedule[3];
      expect(t.fleetLaunches(1), true);
      expect(t.fleetLaunches(5), true);
      expect(t.fleetLaunches(6), false);
    });

    test('turn 5: fleet launches on 1-3 only', () {
      final t = kAlienEconSchedule[4];
      expect(t.fleetLaunches(1), true);
      expect(t.fleetLaunches(3), true);
      expect(t.fleetLaunches(4), false);
    });
  });
}
