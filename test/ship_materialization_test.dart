// T3-A: ShipPurchase -> ShipCounter materialization.
//
// When a purchase is fully built (buildProgressHp >= totalHpNeeded, or
// totalHpNeeded is null implying RAW instant build), the purchase should be
// consumed and blank counters of that type should be stamped with the
// current tech. Partially-built purchases stay on the ledger for the
// following turn.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';

void main() {
  group('T3-A: materializeCompletedPurchases', () {
    final tech = const TechState()
        .setLevel(TechId.attack, 1)
        .setLevel(TechId.defense, 1)
        .setLevel(TechId.tactics, 1)
        .setLevel(TechId.move, 1);

    test('RAW mode: full purchase materializes blank counters', () {
      final counters = createAllCounters();
      final prod = const ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, quantity: 2),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      // Two DDs should now be built.
      final builtDd = result.counters
          .where((c) => c.type == ShipType.dd && c.isBuilt)
          .toList();
      expect(builtDd.length, 2);
      expect(result.newCounterIds.length, 2);
      // Tech should be stamped from the current state (DD is hull 1 so
      // attack/defense are clamped to 1).
      expect(builtDd.first.attack, 1);
      expect(builtDd.first.defense, 1);
      expect(builtDd.first.tactics, 1);
      expect(builtDd.first.move, 1);
      // Purchase should be cleared from the state.
      expect(result.state.shipPurchases, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('multi-turn partial progress: purchase stays, nothing stamped', () {
      final counters = createAllCounters();
      // CA has hull 2 (per se4x definitions). Build progress 1 of 2 => still
      // partial.
      final prod = const ProductionState(
        shipPurchases: [
          ShipPurchase(
            type: ShipType.ca,
            quantity: 1,
            buildProgressHp: 1,
            totalHpNeeded: 2,
          ),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      expect(result.state.shipPurchases.length, 1);
      expect(result.state.shipPurchases.first.buildProgressHp, 1);
      expect(result.newCounterIds, isEmpty);
      expect(result.counters.any((c) => c.type == ShipType.ca && c.isBuilt),
          isFalse);
    });

    test('multi-turn completed progress: purchase materializes', () {
      final counters = createAllCounters();
      final hull = kShipDefinitions[ShipType.ca]!.effectiveHullSize(false);
      final prod = ProductionState(
        shipPurchases: [
          ShipPurchase(
            type: ShipType.ca,
            quantity: 1,
            buildProgressHp: hull,
            totalHpNeeded: hull,
          ),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      expect(result.state.shipPurchases, isEmpty);
      expect(result.newCounterIds.length, 1);
      expect(
        result.counters.where((c) => c.type == ShipType.ca && c.isBuilt).length,
        1,
      );
    });

    test('no blank counters left: warning emitted, remainder kept', () {
      // Pre-fill every DD counter as built so the pool is exhausted.
      final ddMax = kShipDefinitions[ShipType.dd]!.maxCounters;
      final counters = createAllCounters();
      for (int i = 0; i < counters.length; i++) {
        if (counters[i].type == ShipType.dd) {
          counters[i] = counters[i].copyWith(isBuilt: true);
        }
      }
      final prod = const ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, quantity: 1),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      expect(result.warnings, isNotEmpty);
      expect(result.newCounterIds, isEmpty);
      // Purchase remainder (quantity 1) stays on the ledger.
      expect(result.state.shipPurchases.length, 1);
      expect(result.state.shipPurchases.first.quantity, 1);
      // Built DD count unchanged.
      expect(
        result.counters.where((c) => c.type == ShipType.dd && c.isBuilt).length,
        ddMax,
      );
    });

    test('untracked pool (mines) consumes purchase but materializes nothing',
        () {
      final counters = createAllCounters();
      final prod = const ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.mine, quantity: 3),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      expect(result.state.shipPurchases, isEmpty);
      expect(result.newCounterIds, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('mixed purchase list: completes fulfilled, keeps partial', () {
      final counters = createAllCounters();
      final hull = kShipDefinitions[ShipType.ca]!.effectiveHullSize(false);
      final prod = ProductionState(
        shipPurchases: [
          const ShipPurchase(type: ShipType.dd, quantity: 1),
          ShipPurchase(
            type: ShipType.ca,
            quantity: 1,
            buildProgressHp: hull - 1,
            totalHpNeeded: hull,
          ),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      expect(result.newCounterIds.length, 1);
      expect(
        result.counters.where((c) => c.type == ShipType.dd && c.isBuilt).length,
        1,
      );
      expect(
        result.counters.where((c) => c.type == ShipType.ca && c.isBuilt).length,
        0,
      );
      // Only the partial CA build remains.
      expect(result.state.shipPurchases.length, 1);
      expect(result.state.shipPurchases.first.type, ShipType.ca);
    });

    test('partial pool fulfillment keeps unfulfilled remainder', () {
      // DD pool has 6 slots. Pre-build 5 so only 1 is free.
      final counters = createAllCounters();
      int seen = 0;
      for (int i = 0; i < counters.length; i++) {
        if (counters[i].type == ShipType.dd && seen < 5) {
          counters[i] = counters[i].copyWith(isBuilt: true);
          seen++;
        }
      }
      final prod = const ProductionState(
        shipPurchases: [
          ShipPurchase(type: ShipType.dd, quantity: 3),
        ],
      );

      final result = prod.materializeCompletedPurchases(tech, counters);

      expect(result.newCounterIds.length, 1);
      expect(result.warnings, isNotEmpty);
      // 2 ships still owed, kept as a pending purchase.
      expect(result.state.shipPurchases.length, 1);
      expect(result.state.shipPurchases.first.quantity, 2);
    });
  });
}
