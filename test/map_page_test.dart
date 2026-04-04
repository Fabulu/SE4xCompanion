import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/world.dart';
import 'package:se4x/pages/map_page.dart';

void main() {
  testWidgets('map fills the tab width and the inspector expands when selection exists', (tester) async {
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
          pipelineAssets: const [
            PipelineAsset(id: 'pipe-1'),
            PipelineAsset(id: 'pipe-2'),
          ],
          placedPipelineIds: const {'pipe-1'},
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
        pipelineAssets: const [
          PipelineAsset(id: 'pipe-1'),
          PipelineAsset(id: 'pipe-2'),
        ],
      ),
    );

    final viewer = tester.getSize(find.byType(InteractiveViewer));
    expect(viewer.width, greaterThan(1700));
    expect(find.text('Worlds: 1'), findsOneWidget);
    expect(find.text('Ships: 1'), findsOneWidget);
    expect(find.text('Pipelines: 1'), findsOneWidget);
    expect(find.text('Collapsed. Tap to expand.'), findsOneWidget);
  });

  testWidgets('a preselected hex opens the inspector content immediately', (tester) async {
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

    await tester.tap(find.text('Place World'));
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

  testWidgets('pipeline mode places and removes one pipeline asset', (tester) async {
    GameMapState? updated;
    await tester.binding.setSurfaceSize(const Size(1800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = baseState(
      pipelineAssets: const [PipelineAsset(id: 'pipe-1')],
      selectedHex: null,
    );
    await tester.pumpWidget(
      mapHarness(
        state,
        pipelineAssets: const [PipelineAsset(id: 'pipe-1')],
        onChanged: (value, {recordUndo = true, description}) => updated = value,
      ),
    );

    await tester.tap(find.text('Pipeline'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hex-0,0')));
    await tester.pumpAndSettle();

    expect(updated?.hexAt(const HexCoord(0, 0))?.pipelineIds, ['pipe-1']);

    await tester.pumpWidget(
      mapHarness(
        updated ?? state,
        pipelineAssets: const [PipelineAsset(id: 'pipe-1')],
        onChanged: (value, {recordUndo = true, description}) => updated = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hex-0,0')));
    await tester.pumpAndSettle();

    expect(updated?.hexAt(const HexCoord(0, 0))?.pipelineIds, isEmpty);
  });
}

Widget mapHarness(
  GameMapState state, {
  List<WorldState> productionWorlds = const [],
  List<ShipCounter> shipCounters = const [],
  List<PipelineAsset> pipelineAssets = const [],
  MapStateChanged? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MapPage(
        state: state,
        productionWorlds: productionWorlds,
        shipCounters: shipCounters,
        pipelineAssets: pipelineAssets,
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
  List<PipelineAsset> pipelineAssets = const [],
  Set<String> placedPipelineIds = const {},
  HexCoord? selectedHex,
  String? selectedFleetId,
}) {
  final hexes = GameMapState.initial().hexes.map((hex) {
    final worldId = placedWorldIds.isNotEmpty && hex.coord == const HexCoord(0, 0)
        ? placedWorldIds.first
        : null;
    final pipelineIds = placedPipelineIds.isNotEmpty && hex.coord == const HexCoord(0, 0)
        ? placedPipelineIds.toList()
        : const <String>[];
    return hex.copyWith(worldId: worldId, pipelineIds: pipelineIds);
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
