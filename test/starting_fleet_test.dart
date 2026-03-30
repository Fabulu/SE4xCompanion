import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/widgets/starting_fleet_dialog.dart';

void main() {
  // Starting tech: Att:0, Def:0, Tac:0, Mov:1
  const startingTech = TechState();

  group('applyFleetPreset', () {
    test('builds correct number of counters', () {
      final allCounters = createAllCounters();
      final preset = {ShipType.scout: 4, ShipType.dd: 2};
      final result = applyFleetPreset(allCounters, preset, startingTech, false);

      final builtScouts = result.where((c) => c.type == ShipType.scout && c.isBuilt).length;
      final builtDDs = result.where((c) => c.type == ShipType.dd && c.isBuilt).length;
      expect(builtScouts, 4);
      expect(builtDDs, 2);
    });

    test('stamps starting tech (Att:0, Def:0, Tac:0, Mov:1)', () {
      final allCounters = createAllCounters();
      final preset = {ShipType.scout: 1};
      final result = applyFleetPreset(allCounters, preset, startingTech, false);

      final builtScout = result.firstWhere(
        (c) => c.type == ShipType.scout && c.isBuilt,
      );
      expect(builtScout.attack, 0);
      expect(builtScout.defense, 0);
      expect(builtScout.tactics, 0);
      expect(builtScout.move, 1);
    });

    test('skips types with maxCounters 0', () {
      final allCounters = createAllCounters();
      // colonyShip has maxCounters 0, so no counters exist on the sheet
      final preset = {ShipType.colonyShip: 3, ShipType.scout: 2};
      final result = applyFleetPreset(allCounters, preset, startingTech, false);

      // No colony ship counters should be built (they don't exist in allCounters)
      final builtCS = result.where((c) => c.type == ShipType.colonyShip && c.isBuilt).length;
      expect(builtCS, 0);

      // Scouts should still be built
      final builtScouts = result.where((c) => c.type == ShipType.scout && c.isBuilt).length;
      expect(builtScouts, 2);
    });

    test("doesn't build more counters than available", () {
      final allCounters = createAllCounters();
      // Flagship only has maxCounters=1, so requesting 5 should only build 1
      final preset = {ShipType.flag: 5};
      final result = applyFleetPreset(allCounters, preset, startingTech, false);

      final builtFlags = result.where((c) => c.type == ShipType.flag && c.isBuilt).length;
      expect(builtFlags, 1);
    });
  });
}
