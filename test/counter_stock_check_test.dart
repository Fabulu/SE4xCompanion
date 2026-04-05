// T1-C: Counter stock check on ship purchase (hard block).
//
// The production UI must prevent queueing ship purchases beyond the physical
// counter pool for each ship type. Both the "+1" button enable/disable logic
// in `production_page.dart` and this test call the shared helper in
// `lib/data/counter_pool.dart`, so regressions in either the data
// (`ShipDefinition.maxCounters`) or the queue-vs-counter math are caught
// against the real implementation — no widget tree required.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/counter_pool.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';

void main() {
  group('T1-C: counter stock hard block', () {
    test('DD has maxCounters 6 in the data definitions', () {
      expect(kShipDefinitions[ShipType.dd]!.maxCounters, 6);
    });

    test('under cap: +1 allowed when some counters remain', () {
      final built = List.generate(
        4,
        (i) => ShipCounter(type: ShipType.dd, number: i + 1, isBuilt: true),
      );
      final queued = [const ShipPurchase(type: ShipType.dd, quantity: 1)];
      expect(countersRemaining(ShipType.dd, built, queued), 1);
      expect(hasCounterStock(ShipType.dd, built, queued), isTrue);
    });

    test('at cap via queued purchases: +1 disabled', () {
      final queued = [const ShipPurchase(type: ShipType.dd, quantity: 6)];
      expect(countersRemaining(ShipType.dd, const [], queued), 0);
      expect(hasCounterStock(ShipType.dd, const [], queued), isFalse);
    });

    test('at cap via built + queued mix: +1 disabled', () {
      final built = List.generate(
        4,
        (i) => ShipCounter(type: ShipType.dd, number: i + 1, isBuilt: true),
      );
      final queued = [const ShipPurchase(type: ShipType.dd, quantity: 2)];
      expect(countersRemaining(ShipType.dd, built, queued), 0);
      expect(hasCounterStock(ShipType.dd, built, queued), isFalse);
    });

    test('unbuilt counters do not consume stock', () {
      final counters = List.generate(
        6,
        (i) => ShipCounter(type: ShipType.dd, number: i + 1, isBuilt: false),
      );
      expect(countersRemaining(ShipType.dd, counters, const []), 6);
      expect(hasCounterStock(ShipType.dd, counters, const []), isTrue);
    });

    test('removing one queued item re-enables +1', () {
      final queued = [const ShipPurchase(type: ShipType.dd, quantity: 6)];
      expect(hasCounterStock(ShipType.dd, const [], queued), isFalse);
      final shrunk = [const ShipPurchase(type: ShipType.dd, quantity: 5)];
      expect(hasCounterStock(ShipType.dd, const [], shrunk), isTrue);
      expect(countersRemaining(ShipType.dd, const [], shrunk), 1);
    });

    test('untracked pools (maxCounters == 0) are unlimited', () {
      // Mines, miners, pipelines, colony ships, bases etc. have maxCounters 0.
      expect(kShipDefinitions[ShipType.mine]!.maxCounters, 0);
      final queued = [
        const ShipPurchase(type: ShipType.mine, quantity: 99),
      ];
      expect(countersRemaining(ShipType.mine, const [], queued), isNull);
      expect(hasCounterStock(ShipType.mine, const [], queued), isTrue);
    });

    test('each ship type has its own independent pool', () {
      // Filling DD to cap must NOT affect CA availability.
      final queued = [const ShipPurchase(type: ShipType.dd, quantity: 6)];
      expect(hasCounterStock(ShipType.dd, const [], queued), isFalse);
      expect(hasCounterStock(ShipType.ca, const [], queued), isTrue);
    });

    test('TN cap is 5 (smaller counter pool)', () {
      expect(kShipDefinitions[ShipType.tn]!.maxCounters, 5);
      final queued = [const ShipPurchase(type: ShipType.tn, quantity: 5)];
      expect(hasCounterStock(ShipType.tn, const [], queued), isFalse);
      final partial = [const ShipPurchase(type: ShipType.tn, quantity: 4)];
      expect(hasCounterStock(ShipType.tn, const [], partial), isTrue);
    });
  });
}
