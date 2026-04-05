import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/world.dart';
import 'package:se4x/pages/map_page.dart';

/// Tests for Item 1: surfacing Colony Ship -> Colony transform on the
/// map toolbar and fleet markers, instead of only exposing it at End Turn.
void main() {
  testWidgets(
    'toolbar shows "Ready to colonize" chip when a CS is on a colonizable hex',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final built = ShipCounter(
        type: ShipType.colonyShip,
        number: 1,
        isBuilt: true,
      );

      final mapState = GameMapState.initial().copyWith(
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            coord: const HexCoord(0, 0),
            shipCounterIds: [built.id],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPage(
              state: mapState,
              productionWorlds: const [],
              shipCounters: [built],
              terraformingLevel: 0,
              onColonizeCandidatesTapped: () {},
              onChanged: (_, {recordUndo = true, description}) {},
            ),
          ),
        ),
      );

      // The chip text contains a count of colonizable candidates.
      expect(find.textContaining('Ready to colonize'), findsOneWidget);
    },
  );

  testWidgets(
    'no chip appears when no Colony Ship is built',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // A Destroyer, not a Colony Ship.
      final built = ShipCounter(
        type: ShipType.dd,
        number: 1,
        isBuilt: true,
      );
      final mapState = GameMapState.initial().copyWith(
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            coord: const HexCoord(0, 0),
            shipCounterIds: [built.id],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPage(
              state: mapState,
              productionWorlds: const [],
              shipCounters: [built],
              terraformingLevel: 0,
              onChanged: (_, {recordUndo = true, description}) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Ready to colonize'), findsNothing);
    },
  );

  testWidgets(
    'tapping the chip invokes onColonizeCandidatesTapped',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int taps = 0;
      final built = ShipCounter(
        type: ShipType.colonyShip,
        number: 1,
        isBuilt: true,
      );
      final mapState = GameMapState.initial().copyWith(
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            coord: const HexCoord(0, 0),
            shipCounterIds: [built.id],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPage(
              state: mapState,
              productionWorlds: const [],
              shipCounters: [built],
              terraformingLevel: 0,
              onColonizeCandidatesTapped: () => taps++,
              onChanged: (_, {recordUndo = true, description}) {},
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('Ready to colonize'));
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets(
    'chip hidden when the CS hex already hosts a placed world',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final built = ShipCounter(
        type: ShipType.colonyShip,
        number: 1,
        isBuilt: true,
      );
      // Stamp worldId on the (0,0) hex so it is no longer colonizable.
      final initial = GameMapState.initial();
      final hexes = initial.hexes.map((hex) {
        if (hex.coord == const HexCoord(0, 0)) {
          return hex.copyWith(worldId: 'existing-world');
        }
        return hex;
      }).toList();
      final mapState = initial.copyWith(
        hexes: hexes,
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            coord: const HexCoord(0, 0),
            shipCounterIds: [built.id],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPage(
              state: mapState,
              productionWorlds: [
                WorldState(id: 'existing-world', name: 'World'),
              ],
              shipCounters: [built],
              terraformingLevel: 0,
              onChanged: (_, {recordUndo = true, description}) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Ready to colonize'), findsNothing);
    },
  );
}
