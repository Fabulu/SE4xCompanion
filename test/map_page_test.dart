import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/world.dart';
import 'package:se4x/pages/map_page.dart';

void main() {
  testWidgets('map fills the tab width and keeps the canvas visible without inline inspector', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      mapHarness(
        baseState(
          worlds: [
            world('world-home', 'Homeworld'),
            world('world-colony', 'Colony'),
          ],
          placedWorldIds: const {'world-home'},
          shipCounters: [
            ship(ShipType.dd, 1),
            ship(ShipType.ca, 2),
          ],
          fleets: const [
            FleetStackState(
              id: 'fleet-1',
              coord: HexCoord(0, 0),
              shipCounterIds: ['dd:1'],
            ),
          ],
          selectedHex: null,
        ),
        productionWorlds: [
          world('world-home', 'Homeworld'),
          world('world-colony', 'Colony'),
        ],
        shipCounters: [
          ship(ShipType.dd, 1),
          ship(ShipType.ca, 2),
        ],
      ),
    );

    final viewer = tester.getSize(find.byType(InteractiveViewer));
    expect(viewer.width, greaterThan(1700));
    // The new UX hides all chrome above the canvas when nothing is
    // selected. The old "Worlds: N" / "Ships: N" asset pills no longer
    // exist. Verify canvas is rendered and the old inspector is not inline.
    expect(find.text('Collapsed. Tap to expand.'), findsNothing);
    expect(find.text('Terrain'), findsNothing);
    // The inventory FAB should be rendered bottom-right with an
    // inventory icon.
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('tapping a selected hex opens the inspector', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      mapHarness(
        baseState(
          worlds: [world('world-home', 'Homeworld')],
          placedWorldIds: const {'world-home'},
          shipCounters: [ship(ShipType.dd, 1)],
          fleets: const [
            FleetStackState(
              id: 'fleet-1',
              coord: HexCoord(0, 0),
              shipCounterIds: ['dd:1'],
            ),
          ],
          selectedHex: const HexCoord(0, 0),
          selectedFleetId: 'fleet-1',
        ),
        productionWorlds: [world('world-home', 'Homeworld')],
        shipCounters: [ship(ShipType.dd, 1)],
      ),
    );

    expect(find.text('Terrain'), findsNothing);
    expect(find.text('Label'), findsNothing);

    // Inspector is now opened via the tonal "Edit Hex…" button in the
    // selection card.
    await tester.tap(find.text('Edit Hex\u2026'));
    await tester.pumpAndSettle();

    // Fleets surface first in the inspector; hex-detail fields sit below and
    // may be outside the initial viewport when a fleet is selected.
    await tester.scrollUntilVisible(find.text('Terrain'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);
  });

  testWidgets('only unplaced worlds can be placed', (tester) async {
    final state = baseState(
      worlds: [
        world('world-home', 'Homeworld'),
        world('world-colony', 'Colony'),
      ],
      placedWorldIds: const {'world-home'},
      selectedHex: const HexCoord(1, 0),
    );
    await tester.pumpWidget(
      mapHarness(
        state,
        productionWorlds: [
          world('world-home', 'Homeworld'),
          world('world-colony', 'Colony'),
        ],
      ),
    );

    // "Place World" now lives as an icon button in the selection card
    // title row. Locate it by its tooltip.
    await tester.tap(find.byTooltip('Place World'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Colony'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Homeworld'),
      ),
      findsNothing,
    );
  });

  testWidgets('unplacing a world clears only map placement', (tester) async {
    GameMapState? updated;
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final worlds = [
      world('world-home', 'Homeworld'),
      world('world-colony', 'Colony'),
    ];
    final state = baseState(
      worlds: worlds,
      placedWorldIds: const {'world-home'},
      selectedHex: const HexCoord(0, 0),
    );

    await tester.pumpWidget(
      mapHarness(
        state,
        productionWorlds: worlds,
        onChanged: (value, {recordUndo = true, description}) => updated = value,
      ),
    );

    await tester.tap(find.text('Edit Hex\u2026'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Unplace'));
    await tester.tap(find.text('Unplace'));
    await tester.pumpAndSettle();

    expect(updated?.hexAt(const HexCoord(0, 0))?.worldId, isNull);
    expect(worlds, hasLength(2));
  });

  testWidgets('dragging a fleet moves it to the target hex', (tester) async {
    GameMapState? updated;
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = baseState(
      shipCounters: [ship(ShipType.dd, 1)],
      fleets: const [
        FleetStackState(
          id: 'fleet-1',
          coord: HexCoord(0, 0),
          shipCounterIds: ['dd:1'],
        ),
      ],
      selectedHex: null,
    );

    await tester.pumpWidget(
      mapHarness(
        state,
        shipCounters: [ship(ShipType.dd, 1)],
        onChanged: (value, {recordUndo = true, description}) => updated = value,
      ),
    );

    final source = tester.getCenter(find.byKey(const ValueKey('fleet-fleet-1')));
    final target = tester.getCenter(find.byKey(const ValueKey('hex-1,0')));
    await tester.dragFrom(source, target - source);
    await tester.pumpAndSettle();

    expect(updated, isNotNull);
    expect(updated!.fleetById('fleet-1')?.coord.id, '1,0');
  });

  testWidgets('inventory FAB opens sheet showing assigned fleet location',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final counter = ship(ShipType.dd, 1);
    final state = baseState(
      shipCounters: [counter],
      fleets: const [
        FleetStackState(
          id: 'fleet-1',
          coord: HexCoord(2, 0),
          shipCounterIds: ['dd:1'],
        ),
      ],
    );

    await tester.pumpWidget(
      mapHarness(
        state,
        shipCounters: [counter],
      ),
    );

    // Tap the inventory FAB (Icons.inventory_2_outlined).
    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();

    // The new inventory sheet uses DraggableScrollableSheet. Section
    // headers show "Built Ships (N)".
    expect(find.text('Built Ships'), findsOneWidget);
    expect(find.text('dd:1'), findsOneWidget);
    expect(
      find.textContaining('2,0'),
      findsWidgets,
    );
  });

  group('fleetFanOutOffsets', () {
    test('single fleet at a hex gets no offset', () {
      final offsets = fleetFanOutOffsets(const [
        FleetStackState(
          id: 'a', coord: HexCoord(0, 0), shipCounterIds: [],
        ),
      ]);
      expect(offsets['a'], Offset.zero);
    });

    test('two fleets fan out horizontally', () {
      final offsets = fleetFanOutOffsets(const [
        FleetStackState(id: 'a', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'b', coord: HexCoord(0, 0), shipCounterIds: []),
      ]);
      expect(offsets['a'], const Offset(-12, 0));
      expect(offsets['b'], const Offset(12, 0));
    });

    test('three fleets form a triangle', () {
      final offsets = fleetFanOutOffsets(const [
        FleetStackState(id: 'a', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'b', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'c', coord: HexCoord(0, 0), shipCounterIds: []),
      ]);
      // All three should sit on a radius of ~14 from origin.
      for (final id in ['a', 'b', 'c']) {
        final o = offsets[id]!;
        final r = (o.dx * o.dx + o.dy * o.dy);
        expect(r, closeTo(14.0 * 14.0, 0.5));
      }
      // First fleet placed at the top (negative y).
      expect(offsets['a']!.dy, lessThan(0));
    });

    test('four fleets form a ring', () {
      final offsets = fleetFanOutOffsets(const [
        FleetStackState(id: 'a', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'b', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'c', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'd', coord: HexCoord(0, 0), shipCounterIds: []),
      ]);
      for (final id in ['a', 'b', 'c', 'd']) {
        final o = offsets[id]!;
        final r = (o.dx * o.dx + o.dy * o.dy);
        expect(r, closeTo(16.0 * 16.0, 0.5));
      }
    });

    test('fleets at distinct hexes do not interfere', () {
      final offsets = fleetFanOutOffsets(const [
        FleetStackState(id: 'a', coord: HexCoord(0, 0), shipCounterIds: []),
        FleetStackState(id: 'b', coord: HexCoord(1, 0), shipCounterIds: []),
      ]);
      expect(offsets['a'], Offset.zero);
      expect(offsets['b'], Offset.zero);
    });
  });
}

Widget mapHarness(
  GameMapState state, {
  List<WorldState> productionWorlds = const [],
  List<ShipCounter> shipCounters = const [],
  String? focusShipId,
  int focusRequestId = 0,
  int playerMoveLevel = 6,
  MapStateChanged? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MapPage(
        state: state,
        productionWorlds: productionWorlds,
        shipCounters: shipCounters,
        focusShipId: focusShipId,
        focusRequestId: focusRequestId,
        playerMoveLevel: playerMoveLevel,
        onChanged: onChanged ?? (_, {recordUndo = true, description}) {},
      ),
    ),
  );
}

GameMapState baseState({
  List<WorldState> worlds = const [],
  Set<String> placedWorldIds = const {},
  List<ShipCounter> shipCounters = const [],
  List<FleetStackState> fleets = const [],
  HexCoord? selectedHex,
  String? selectedFleetId,
}) {
  final hexes = GameMapState.initial().hexes.map((hex) {
    final worldId = placedWorldIds.isNotEmpty && hex.coord == const HexCoord(0, 0)
        ? placedWorldIds.first
        : null;
    return hex.copyWith(worldId: worldId);
  }).toList();

  return GameMapState.initial().copyWith(
    hexes: hexes,
    fleets: fleets,
    selectedHex: selectedHex,
    selectedFleetId: selectedFleetId,
  );
}

WorldState world(String id, String name) => WorldState(id: id, name: name);

ShipCounter ship(ShipType type, int number) =>
    ShipCounter(type: type, number: number, isBuilt: true);
