import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/pages/ship_tech_page.dart';
import 'package:se4x/widgets/counter_row.dart';

void main() {
  // Tech state with att=3, def=3, tactics=2, move=3.
  // BC is hull 3, so stamping yields A=3, D=3, T=2, M=3 (no hull caps).
  const techHigh = TechState(levels: {
    TechId.attack: 3,
    TechId.defense: 3,
    TechId.tactics: 2,
    TechId.move: 3,
  });

  group('ShipTechDriftCheck.firstDriftingStat', () {
    test('returns null when attack update matches stamped value', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      final update = CounterUpdate(attack: stamped.attack);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), isNull);
    });

    test('returns "Attack" when attack proposed value differs from stamped',
        () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      // Stamped attack is 3, user tries to set it to 5.
      final update = CounterUpdate(attack: 5);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), 'Attack');
    });

    test('returns "Defense" when only defense drifts', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      final update = CounterUpdate(defense: 0);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), 'Defense');
    });

    test('returns "Tactics" when only tactics drifts', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      final update = CounterUpdate(tactics: 5);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), 'Tactics');
    });

    test('returns "Move" when only move drifts', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      final update = CounterUpdate(move: 0);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), 'Move');
    });

    test('ignores otherTechs drift (no tech-stamped counterpart)', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      final update = CounterUpdate(otherTechs: {'P': 1});
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), isNull);
    });

    test('ignores experience drift', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      final update = CounterUpdate(experience: 3);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), isNull);
    });

    test('returns null when the update restores attack to stamped value', () {
      // Scout (hull 1) attack is capped to 1. If a player previously
      // overrode scout A to 3 and then taps to set it back to 1, no drift.
      final stamped = ShipCounter.stampFromTech(ShipType.scout, 1, techHigh);
      expect(stamped.attack, 1);
      final update = CounterUpdate(attack: 1);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), isNull);
    });

    test('scout drifts when attack overridden above hull cap', () {
      final stamped = ShipCounter.stampFromTech(ShipType.scout, 1, techHigh);
      // Stamped attack is capped to 1 by hull 1; user tries to set it to 3.
      final update = CounterUpdate(attack: 3);
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), 'Attack');
    });

    test('returns first field in A/D/T/M order when multiple drift', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      // All four drift; attack should be reported first.
      final update = CounterUpdate(
        attack: 0,
        defense: 0,
        tactics: 5,
        move: 5,
      );
      expect(ShipTechDriftCheck.firstDriftingStat(update, stamped), 'Attack');
    });
  });

  group('ShipTechDriftCheck.proposedValueFor', () {
    test('reads attack from update', () {
      expect(
        ShipTechDriftCheck.proposedValueFor(
            const CounterUpdate(attack: 5), 'Attack'),
        5,
      );
    });

    test('reads defense from update', () {
      expect(
        ShipTechDriftCheck.proposedValueFor(
            const CounterUpdate(defense: 4), 'Defense'),
        4,
      );
    });

    test('reads tactics from update', () {
      expect(
        ShipTechDriftCheck.proposedValueFor(
            const CounterUpdate(tactics: 2), 'Tactics'),
        2,
      );
    });

    test('reads move from update', () {
      expect(
        ShipTechDriftCheck.proposedValueFor(
            const CounterUpdate(move: 6), 'Move'),
        6,
      );
    });
  });

  group('ShipTechDriftCheck.stampedValueFor', () {
    test('reads each core stat from a stamped counter', () {
      final stamped = ShipCounter.stampFromTech(ShipType.bc, 1, techHigh);
      expect(ShipTechDriftCheck.stampedValueFor(stamped, 'Attack'), 3);
      expect(ShipTechDriftCheck.stampedValueFor(stamped, 'Defense'), 3);
      expect(ShipTechDriftCheck.stampedValueFor(stamped, 'Tactics'), 2);
      expect(ShipTechDriftCheck.stampedValueFor(stamped, 'Move'), 3);
    });
  });
}
