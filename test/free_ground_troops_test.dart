import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/world.dart';

/// Tests for T3-F: Free ground troops allocation (Rule 21.5).
///
/// Rule 21.5: "A player receives one free Ground Unit for every three,
/// un-blockaded 5 CP Colonies (not the Homeworld) that they have at the
/// start of an Economic Phase (rounded down). ... The free units are
/// placed at any un-blockaded 5 CP Colony or Homeworld, one per Colony."
void main() {
  // Helpers --------------------------------------------------------------
  WorldState hw({bool blocked = false}) => WorldState(
        name: 'HW',
        isHomeworld: true,
        homeworldValue: 30,
        isBlocked: blocked,
      );

  WorldState fiveCpColony({bool blocked = false}) => WorldState(
        name: '5cp',
        growthMarkerLevel: 3, // 5 CP per kColonyGrowthCp
        isBlocked: blocked,
      );

  WorldState threeCpColony({bool blocked = false}) => WorldState(
        name: '3cp',
        growthMarkerLevel: 2, // 3 CP
        isBlocked: blocked,
      );

  const offConfig = GameConfig();
  const onConfig = GameConfig(enableFreeGroundTroops: true);

  group('ShipType.groundUnit definition', () {
    test('ShipType.groundUnit has a ShipDefinition', () {
      expect(kShipDefinitions.containsKey(ShipType.groundUnit), isTrue);
    });

    test('Ground Unit is maintenance exempt (Rule 21.2)', () {
      expect(kShipDefinitions[ShipType.groundUnit]!.maintenanceExempt, isTrue);
    });

    test('Ground Unit has 0 maxCounters (tracked via on-colony count)', () {
      expect(kShipDefinitions[ShipType.groundUnit]!.maxCounters, 0);
    });

    test('Ground Unit cites rule section 21.0', () {
      expect(kShipDefinitions[ShipType.groundUnit]!.ruleSection, '21.0');
    });

    test('Ground Unit requires Ground tech 1', () {
      expect(
        kShipDefinitions[ShipType.groundUnit]!.prerequisite,
        equals('Ground 1'),
      );
    });

    test('Ground Unit has abbreviation GU', () {
      expect(kShipDefinitions[ShipType.groundUnit]!.abbreviation, 'GU');
    });
  });

  group('GameConfig.enableFreeGroundTroops', () {
    test('default is off', () {
      expect(const GameConfig().enableFreeGroundTroops, isFalse);
    });

    test('round-trips through JSON', () {
      final cfg = onConfig;
      final restored = GameConfig.fromJson(cfg.toJson());
      expect(restored.enableFreeGroundTroops, isTrue);
    });

    test('JSON back-compat: legacy save with no field defaults to off', () {
      final legacy = <String, dynamic>{
        'ownership': <String, dynamic>{},
        'enableFacilities': false,
      };
      final cfg = GameConfig.fromJson(legacy);
      expect(cfg.enableFreeGroundTroops, isFalse);
    });

    test('copyWith toggles the flag', () {
      final cfg = const GameConfig().copyWith(enableFreeGroundTroops: true);
      expect(cfg.enableFreeGroundTroops, isTrue);
      final off = cfg.copyWith(enableFreeGroundTroops: false);
      expect(off.enableFreeGroundTroops, isFalse);
    });
  });

  group('freeGroundTroopSourceColonies: eligibility filter (21.5)', () {
    test('only counts 5-CP (growth level 3) colonies', () {
      final ps = ProductionState(worlds: [
        hw(),
        fiveCpColony(),
        threeCpColony(),
        fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopSourceColonies(), 2);
    });

    test('excludes the Homeworld even if it has 5+ CP', () {
      final ps = ProductionState(worlds: [hw(), hw()]);
      expect(ps.freeGroundTroopSourceColonies(), 0);
    });

    test('excludes blockaded 5-CP colonies', () {
      final ps = ProductionState(worlds: [
        hw(),
        fiveCpColony(blocked: true),
        fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopSourceColonies(), 1);
    });

    test('returns 0 when no qualifying colonies exist', () {
      final ps = ProductionState(worlds: [hw(), threeCpColony()]);
      expect(ps.freeGroundTroopSourceColonies(), 0);
    });
  });

  group('freeGroundTroopsGranted: allocation math (21.5)', () {
    test('rule gate: off → 0 regardless of colony count', () {
      final ps = ProductionState(worlds: [
        hw(),
        for (int i = 0; i < 9; i++) fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsGranted(offConfig), 0);
    });

    test('0 qualifying colonies → 0 units', () {
      final ps = ProductionState(worlds: [hw()]);
      expect(ps.freeGroundTroopsGranted(onConfig), 0);
    });

    test('2 qualifying colonies → 0 units (rounded down)', () {
      final ps = ProductionState(worlds: [
        hw(),
        fiveCpColony(),
        fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsGranted(onConfig), 0);
    });

    test('3 qualifying colonies → 1 unit', () {
      final ps = ProductionState(worlds: [
        hw(),
        fiveCpColony(),
        fiveCpColony(),
        fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsGranted(onConfig), 1);
    });

    test('8 qualifying colonies → 2 units (rounded down)', () {
      final ps = ProductionState(worlds: [
        hw(),
        for (int i = 0; i < 8; i++) fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsGranted(onConfig), 2);
    });

    test('9 qualifying colonies → 3 units', () {
      final ps = ProductionState(worlds: [
        hw(),
        for (int i = 0; i < 9; i++) fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsGranted(onConfig), 3);
    });
  });

  group('Blockade impact on free Ground Units', () {
    test('blockaded 5-CP colony does NOT count as a source', () {
      final ps = ProductionState(worlds: [
        hw(),
        fiveCpColony(blocked: true),
        fiveCpColony(blocked: true),
        fiveCpColony(blocked: true),
      ]);
      // All three sources blocked → 0 units.
      expect(ps.freeGroundTroopsGranted(onConfig), 0);
    });

    test('lifting a blockade makes a colony eligible again', () {
      final blocked = ProductionState(worlds: [
        hw(),
        fiveCpColony(),
        fiveCpColony(),
        fiveCpColony(blocked: true),
      ]);
      expect(blocked.freeGroundTroopsGranted(onConfig), 0);
      // Replace the blocked world with an un-blocked copy.
      final lifted = blocked.copyWith(worlds: [
        blocked.worlds[0],
        blocked.worlds[1],
        blocked.worlds[2],
        blocked.worlds[3].copyWith(isBlocked: false),
      ]);
      expect(lifted.freeGroundTroopsGranted(onConfig), 1);
    });

    test('blockaded Homeworld does not eat a placement slot', () {
      // 3 qualifying colonies grant 1 GU; HW is blocked so only the 3
      // colonies are placement slots, which still covers 1.
      final ps = ProductionState(worlds: [
        hw(blocked: true),
        fiveCpColony(),
        fiveCpColony(),
        fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsGranted(onConfig), 1);
      expect(ps.freeGroundTroopPlacementSlots(), 3);
      expect(ps.freeGroundTroopsPlaceable(onConfig), 1);
    });
  });

  group('freeGroundTroopPlacementSlots', () {
    test('un-blockaded Homeworld + 5-CP colonies each grant one slot', () {
      final ps = ProductionState(worlds: [
        hw(),
        fiveCpColony(),
        fiveCpColony(),
        threeCpColony(),
      ]);
      expect(ps.freeGroundTroopPlacementSlots(), 3); // HW + 2 five-cp
    });

    test('blockaded colonies/HW do not count as slots', () {
      final ps = ProductionState(worlds: [
        hw(blocked: true),
        fiveCpColony(blocked: true),
        fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopPlacementSlots(), 1);
    });
  });

  group('freeGroundTroopsPlaceable (grant capped by slots)', () {
    test('grant <= slots → grant', () {
      final ps = ProductionState(worlds: [
        hw(),
        for (int i = 0; i < 3; i++) fiveCpColony(),
      ]);
      // 3 sources → 1 granted; 4 slots (HW + 3 colonies).
      expect(ps.freeGroundTroopsPlaceable(onConfig), 1);
    });

    test('rule disabled → 0 placeable', () {
      final ps = ProductionState(worlds: [
        hw(),
        for (int i = 0; i < 9; i++) fiveCpColony(),
      ]);
      expect(ps.freeGroundTroopsPlaceable(offConfig), 0);
    });
  });
}
