import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/ship_counter.dart';

void main() {
  group('GameMapState', () {
    test('standard4p is a 12x12 staggered rectangle', () {
      final hexes = GameMapState.defaultHexesFor(MapLayoutPreset.standard4p);

      expect(hexes, hasLength(144));
      const expectedStarts = [3, 3, 2, 2, 1, 1, 0, 0, -1, -1, -2, -2];
      for (var rowIndex = 0; rowIndex < 12; rowIndex++) {
        final r = rowIndex - 6;
        final row = _rowQs(hexes, r);
        expect(row, hasLength(12));
        final expectedStart = expectedStarts[rowIndex];
        expect(row.first, expectedStart);
        expect(row.last, expectedStart + 11);
      }
    });

    test('special5p matches the provided 18-row 214-hex layout', () {
      final hexes = GameMapState.defaultHexesFor(MapLayoutPreset.special5p);

      expect(hexes, hasLength(214));
      expect(
        GameMapState(layoutPreset: MapLayoutPreset.special5p, hexes: hexes)
            .rowLengths,
        [3, 5, 8, 10, 12, 14, 15, 16, 16, 15, 15, 14, 13, 12, 13, 12, 11, 10],
      );
    });

    test('json round-trips selected hex and fleets', () {
      final state = GameMapState.initial(
        layoutPreset: MapLayoutPreset.special5p,
      ).copyWith(
        selectedHex: const HexCoord(1, -1),
        selectedFleetId: 'fleet-1',
        zoom: 1.8,
        panX: 24,
        panY: -16,
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            label: '1st Fleet',
            isEnemy: false,
            shipCounterIds: ['ca:1', 'dd:2'],
            composition: {'CA': 2, 'DD': 3},
            coord: HexCoord(1, -1),
            facedown: true,
            inSupply: false,
            notes: 'Watching home lane',
          ),
        ],
      );

      final restored = GameMapState.fromJson(state.toJson());

      expect(restored.layoutPreset, MapLayoutPreset.special5p);
      expect(restored.selectedHex?.id, '1,-1');
      expect(restored.selectedFleetId, 'fleet-1');
      expect(restored.zoom, closeTo(1.8, 0.0001));
      expect(restored.panX, closeTo(24, 0.0001));
      expect(restored.panY, closeTo(-16, 0.0001));
      expect(restored.fleets, hasLength(1));
      expect(restored.fleets.first.facedown, true);
      expect(restored.fleets.first.inSupply, false);
    });

    test('replaceHex updates a single hex in place', () {
      final state = GameMapState.initial();
      final target = state.hexes.first;

      final updated = state.replaceHex(
        target.copyWith(
          explored: true,
          label: 'Home',
          worldId: 'world-home',
          minerals: 2,
          terrain: HexTerrain.asteroid,
        ),
      );

      final restored = updated.hexAt(target.coord);
      expect(restored?.explored, true);
      expect(restored?.label, 'Home');
      expect(restored?.worldId, 'world-home');
      expect(restored?.minerals, 2);
      expect(restored?.terrain, HexTerrain.asteroid);
    });

    test('sanitizeAgainstLedger deduplicates worlds and ships', () {
      final state = GameMapState.initial().copyWith(
        hexes: [
          stateHex(const HexCoord(0, 0), worldId: 'world-1'),
          stateHex(const HexCoord(1, 0), worldId: 'world-1'),
        ],
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1', 'ca:1'],
          ),
          FleetStackState(
            id: 'fleet-2',
            owner: 'Blue',
            coord: HexCoord(1, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
      );

      final sanitized = state.sanitizeAgainstLedger(
        validWorldIds: {'world-1'},
        validShipIds: {'dd:1'},
      );

      expect(sanitized.hexAt(const HexCoord(0, 0))?.worldId, 'world-1');
      expect(sanitized.hexAt(const HexCoord(1, 0))?.worldId, isNull);
      expect(sanitized.fleetById('fleet-1')?.shipCounterIds, ['dd:1']);
      expect(sanitized.fleetById('fleet-2'), isNull);
    });

    test('sanitizeAgainstLedger prunes removed ledger assets', () {
      final state = GameMapState.initial().copyWith(
        hexes: [
          stateHex(const HexCoord(0, 0), worldId: 'world-1'),
        ],
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
      );

      final sanitized = state.sanitizeAgainstLedger(
        validWorldIds: const {},
        validShipIds: const {},
      );

      expect(sanitized.hexAt(const HexCoord(0, 0))?.worldId, isNull);
      expect(sanitized.fleets, isEmpty);
    });
  });

  group('GameMapState.moveFleet auto-reveal (rule 6.1)', () {
    GameMapState buildMoveState({bool isEnemy = false}) {
      // Use a tiny explicit hex set so distances are predictable and the
      // standard 12x12 layout's unrelated hexes do not interfere.
      // Hexes laid out so we can assert reveal at distance 0, 1, and 2 from
      // HexCoord(1, 0). Using axial hex distance:
      //   (1,0)->(2,0) = 1, (1,0)->(0,1) = 1, (1,0)->(1,1) = 1,
      //   (1,0)->(3,0) = 2, (1,0)->(4,0) = 3 (out-of-range sentinel).
      return const GameMapState(
        hexes: [
          MapHexState(coord: HexCoord(0, 0), explored: true),
          MapHexState(coord: HexCoord(1, 0)),
          MapHexState(coord: HexCoord(2, 0)),
          MapHexState(coord: HexCoord(3, 0)),
          MapHexState(coord: HexCoord(4, 0)),
          MapHexState(coord: HexCoord(0, 1)),
          MapHexState(coord: HexCoord(1, 1)),
        ],
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
      ).copyWith(
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: const HexCoord(0, 0),
            isEnemy: isEnemy,
            shipCounterIds: const ['dd:1'],
          ),
        ],
      );
    }

    test('friendly move reveals destination hex (exploration 0)', () {
      final state = buildMoveState();
      expect(state.hexAt(const HexCoord(1, 0))?.explored, isFalse);

      final moved = state.moveFleet('fleet-1', const HexCoord(1, 0));

      expect(moved.hexAt(const HexCoord(1, 0))?.explored, isTrue);
      // Neighboring hexes should still be unexplored at level 0.
      expect(moved.hexAt(const HexCoord(2, 0))?.explored, isFalse);
      expect(moved.hexAt(const HexCoord(0, 1))?.explored, isFalse);
      expect(moved.hexAt(const HexCoord(1, 1))?.explored, isFalse);
      expect(moved.fleetById('fleet-1')?.coord, const HexCoord(1, 0));
    });

    test('exploration level 1 also reveals hexes adjacent to destination', () {
      final state = buildMoveState();

      final moved = state.moveFleet(
        'fleet-1',
        const HexCoord(1, 0),
        explorationLevel: 1,
      );

      // Destination and all hexes within 1 step are revealed.
      expect(moved.hexAt(const HexCoord(1, 0))?.explored, isTrue);
      expect(moved.hexAt(const HexCoord(2, 0))?.explored, isTrue);
      expect(moved.hexAt(const HexCoord(0, 1))?.explored, isTrue);
      expect(moved.hexAt(const HexCoord(1, 1))?.explored, isTrue);
      // A hex 2 steps away stays hidden.
      expect(moved.hexAt(const HexCoord(3, 0))?.explored, isFalse);
    });

    test('exploration level 2 extends reveal ring to distance 2', () {
      final state = buildMoveState();

      final moved = state.moveFleet(
        'fleet-1',
        const HexCoord(1, 0),
        explorationLevel: 2,
      );

      // The distance-2 hex is now revealed as well.
      expect(moved.hexAt(const HexCoord(3, 0))?.explored, isTrue);
      // But not distance-3.
      expect(moved.hexAt(const HexCoord(4, 0))?.explored, isFalse);
    });

    test('enemy fleet moves do not reveal anything', () {
      final state = buildMoveState(isEnemy: true);

      final moved = state.moveFleet(
        'fleet-1',
        const HexCoord(1, 0),
        explorationLevel: 2,
      );

      expect(moved.hexAt(const HexCoord(1, 0))?.explored, isFalse);
      expect(moved.hexAt(const HexCoord(2, 0))?.explored, isFalse);
      // Fleet still moved even though no reveal happens.
      expect(moved.fleetById('fleet-1')?.coord, const HexCoord(1, 0));
    });

    test('already-explored hex is left alone', () {
      final state = buildMoveState();

      final moved = state.moveFleet('fleet-1', const HexCoord(0, 0));

      expect(moved.hexAt(const HexCoord(0, 0))?.explored, isTrue);
      // Was already explored; no change, no crash.
      expect(moved.fleetById('fleet-1')?.coord, const HexCoord(0, 0));
    });

    test('unknown fleet id is a no-op', () {
      final state = buildMoveState();

      final moved = state.moveFleet('fleet-nope', const HexCoord(1, 0));

      expect(identical(moved, state), isTrue);
    });
  });

  group('Movement allowance (PP09)', () {
    // Small predictable 5-hex axial strip so distance assertions are easy.
    GameMapState buildAllowanceState({
      bool hasMovedThisTurn = false,
      List<String> shipCounterIds = const ['dd:1'],
    }) {
      return GameMapState(
        hexes: const [
          MapHexState(coord: HexCoord(0, 0), explored: true),
          MapHexState(coord: HexCoord(1, 0)),
          MapHexState(coord: HexCoord(2, 0)),
          MapHexState(coord: HexCoord(3, 0)),
          MapHexState(coord: HexCoord(4, 0)),
        ],
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: const HexCoord(0, 0),
            shipCounterIds: shipCounterIds,
            hasMovedThisTurn: hasMovedThisTurn,
          ),
        ],
      );
    }

    ShipCounter shipCounter(String id, int move) {
      final parts = id.split(':');
      final type = ShipType.values.firstWhere(
        (t) => t.name == parts[0],
        orElse: () => ShipType.dd,
      );
      final number = int.parse(parts[1]);
      return ShipCounter(
        type: type,
        number: number,
        isBuilt: true,
        move: move,
      );
    }

    test('base moveFleet still works without validation', () {
      final state = buildAllowanceState();
      // Base moveFleet is the "force move" API — it ignores allowance and
      // the hasMovedThisTurn flag by design.
      final moved = state.moveFleet('fleet-1', const HexCoord(4, 0));
      expect(moved.fleetById('fleet-1')?.coord, const HexCoord(4, 0));
      // And it does NOT auto-mark the fleet as moved — marking belongs to
      // the validated wrapper.
      expect(moved.fleetById('fleet-1')?.hasMovedThisTurn, isFalse);
    });

    test('moveFleetWithAllowance blocks out-of-range moves', () {
      final state = buildAllowanceState();
      final blocked = state.moveFleetWithAllowance(
        'fleet-1',
        const HexCoord(4, 0),
        allowance: 2,
        shipCounters: [shipCounter('dd:1', 2)],
      );
      expect(identical(blocked, state), isTrue);
      expect(blocked.fleetById('fleet-1')?.coord, const HexCoord(0, 0));
    });

    test('moveFleetWithAllowance blocks fleets that already moved', () {
      final state = buildAllowanceState(hasMovedThisTurn: true);
      final blocked = state.moveFleetWithAllowance(
        'fleet-1',
        const HexCoord(1, 0),
        allowance: 5,
        shipCounters: [shipCounter('dd:1', 2)],
      );
      expect(identical(blocked, state), isTrue);
      expect(blocked.fleetById('fleet-1')?.coord, const HexCoord(0, 0));
    });

    test('moveFleetWithAllowance marks fleet as moved on success', () {
      final state = buildAllowanceState();
      final moved = state.moveFleetWithAllowance(
        'fleet-1',
        const HexCoord(2, 0),
        allowance: 3,
        shipCounters: [shipCounter('dd:1', 3)],
      );
      final fleet = moved.fleetById('fleet-1');
      expect(fleet?.coord, const HexCoord(2, 0));
      expect(fleet?.hasMovedThisTurn, isTrue);
    });

    test('moveFleetWithAllowance still auto-reveals the destination', () {
      final state = buildAllowanceState();
      expect(state.hexAt(const HexCoord(2, 0))?.explored, isFalse);
      final moved = state.moveFleetWithAllowance(
        'fleet-1',
        const HexCoord(2, 0),
        allowance: 3,
        shipCounters: [shipCounter('dd:1', 3)],
      );
      expect(moved.hexAt(const HexCoord(2, 0))?.explored, isTrue);
    });

    test('clearAllFleetMoveFlags clears the flag on every fleet', () {
      final state = GameMapState(
        hexes: const [MapHexState(coord: HexCoord(0, 0))],
        fleets: const [
          FleetStackState(
            id: 'a',
            coord: HexCoord(0, 0),
            hasMovedThisTurn: true,
          ),
          FleetStackState(
            id: 'b',
            coord: HexCoord(0, 0),
            hasMovedThisTurn: true,
          ),
          FleetStackState(
            id: 'c',
            coord: HexCoord(0, 0),
          ),
        ],
      );
      final cleared = state.clearAllFleetMoveFlags();
      for (final f in cleared.fleets) {
        expect(f.hasMovedThisTurn, isFalse);
      }
    });

    test('slowestShipMoveInFleet returns the min move across ships', () {
      final state = buildAllowanceState(
        shipCounterIds: const ['dd:1', 'dd:2', 'dd:3'],
      );
      final fleet = state.fleetById('fleet-1')!;
      final result = state.slowestShipMoveInFleet(fleet, [
        shipCounter('dd:1', 3),
        shipCounter('dd:2', 1),
        shipCounter('dd:3', 2),
      ]);
      expect(result, 1);
    });

    test('slowestShipMoveInFleet returns null for an empty fleet', () {
      final state = buildAllowanceState(shipCounterIds: const []);
      final fleet = state.fleetById('fleet-1')!;
      final result = state.slowestShipMoveInFleet(fleet, const []);
      expect(result, isNull);
    });

    test('fleetMoveAllowance falls back to player tech on empty fleet', () {
      final state = buildAllowanceState(shipCounterIds: const []);
      final fleet = state.fleetById('fleet-1')!;
      final allowance = state.fleetMoveAllowance(fleet, const [], 4);
      expect(allowance, 4);
    });

    test('fleetMoveAllowance uses slowest ship when ships are present', () {
      final state = buildAllowanceState(
        shipCounterIds: const ['dd:1', 'dd:2'],
      );
      final fleet = state.fleetById('fleet-1')!;
      final allowance = state.fleetMoveAllowance(
        fleet,
        [shipCounter('dd:1', 2), shipCounter('dd:2', 5)],
        9, // player tech 9 is ignored when ships are present
      );
      expect(allowance, 2);
    });

    test(
      'reachableHexes returns hexes within allowance and excludes current hex',
      () {
        final state = buildAllowanceState();
        final fleet = state.fleetById('fleet-1')!;
        final reachable = state.reachableHexes(fleet, 2);
        expect(reachable, contains(const HexCoord(1, 0)));
        expect(reachable, contains(const HexCoord(2, 0)));
        expect(reachable, isNot(contains(const HexCoord(3, 0))));
        expect(reachable, isNot(contains(const HexCoord(0, 0))));
      },
    );

    test('reachableHexes is empty when allowance is 0', () {
      final state = buildAllowanceState();
      final fleet = state.fleetById('fleet-1')!;
      final reachable = state.reachableHexes(fleet, 0);
      expect(reachable, isEmpty);
    });

    test('FleetStackState json round-trips hasMovedThisTurn', () {
      const fleet = FleetStackState(
        id: 'fleet-1',
        owner: 'Blue',
        coord: HexCoord(0, 0),
        hasMovedThisTurn: true,
      );
      final restored = FleetStackState.fromJson(fleet.toJson());
      expect(restored.hasMovedThisTurn, isTrue);
    });

    test(
      'FleetStackState legacy decode defaults hasMovedThisTurn to false',
      () {
        final legacyJson = <String, dynamic>{
          'id': 'fleet-1',
          'owner': 'Blue',
          'coord': const HexCoord(1, -1).toJson(),
          // No hasMovedThisTurn key — simulates a save from before PP09.
        };
        final restored = FleetStackState.fromJson(legacyJson);
        expect(restored.hasMovedThisTurn, isFalse);
      },
    );

    test('markMoved and clearMoveFlag helpers flip the flag', () {
      const fleet = FleetStackState(id: 'f', coord: HexCoord(0, 0));
      expect(fleet.hasMovedThisTurn, isFalse);
      expect(fleet.markMoved().hasMovedThisTurn, isTrue);
      expect(fleet.markMoved().clearMoveFlag().hasMovedThisTurn, isFalse);
    });
  });

  group('HexTerrain.isColonizable', () {
    test('deep space is always colonizable', () {
      expect(HexTerrain.deepSpace.isColonizable(0), isTrue);
      expect(HexTerrain.deepSpace.isColonizable(2), isTrue);
    });

    test('asteroid belt needs Terraforming 1', () {
      expect(HexTerrain.asteroid.isColonizable(0), isFalse);
      expect(HexTerrain.asteroid.isColonizable(1), isTrue);
      expect(HexTerrain.asteroid.isColonizable(2), isTrue);
    });

    test('nebula needs Terraforming 2', () {
      expect(HexTerrain.nebula.isColonizable(0), isFalse);
      expect(HexTerrain.nebula.isColonizable(1), isFalse);
      expect(HexTerrain.nebula.isColonizable(2), isTrue);
    });

    test('hazards are never colonizable', () {
      for (final t in [
        HexTerrain.blackHole,
        HexTerrain.supernova,
        HexTerrain.foldInSpace,
      ]) {
        expect(t.isColonizable(5), isFalse, reason: 'terrain=$t');
      }
    });
  });

  group('GameMapState.findColonizeCandidates', () {
    GameMapState buildState({
      HexTerrain terrain = HexTerrain.deepSpace,
      String? worldId,
      bool isEnemy = false,
      List<String> shipIds = const ['colonyShip:1'],
    }) {
      return GameMapState(
        hexes: [
          MapHexState(
            coord: const HexCoord(2, -3),
            terrain: terrain,
            worldId: worldId,
          ),
          const MapHexState(coord: HexCoord(0, 0)),
        ],
        fleets: [
          FleetStackState(
            id: 'fleet-1',
            coord: const HexCoord(2, -3),
            isEnemy: isEnemy,
            shipCounterIds: shipIds,
          ),
        ],
      );
    }

    test('finds a colony ship on an empty deep-space hex', () {
      final state = buildState();
      final hits = state.findColonizeCandidates(
        candidateShipIds: {'colonyShip:1'},
        terraformingLevel: 0,
      );
      expect(hits, hasLength(1));
      expect(hits.first.shipId, 'colonyShip:1');
      expect(hits.first.fleetId, 'fleet-1');
      expect(hits.first.coord, const HexCoord(2, -3));
      expect(hits.first.terrain, HexTerrain.deepSpace);
    });

    test('skips hex that already has a world', () {
      final state = buildState(worldId: 'world-1');
      final hits = state.findColonizeCandidates(
        candidateShipIds: {'colonyShip:1'},
        terraformingLevel: 0,
      );
      expect(hits, isEmpty);
    });

    test('skips asteroid without Terraforming 1', () {
      final state = buildState(terrain: HexTerrain.asteroid);
      expect(
        state.findColonizeCandidates(
          candidateShipIds: {'colonyShip:1'},
          terraformingLevel: 0,
        ),
        isEmpty,
      );
      expect(
        state.findColonizeCandidates(
          candidateShipIds: {'colonyShip:1'},
          terraformingLevel: 1,
        ),
        hasLength(1),
      );
    });

    test('skips enemy fleets', () {
      final state = buildState(isEnemy: true);
      expect(
        state.findColonizeCandidates(
          candidateShipIds: {'colonyShip:1'},
          terraformingLevel: 0,
        ),
        isEmpty,
      );
    });

    test('only returns ships listed in candidateShipIds', () {
      final state = buildState(shipIds: const ['dd:1', 'colonyShip:2']);
      final hits = state.findColonizeCandidates(
        candidateShipIds: {'colonyShip:2'},
        terraformingLevel: 0,
      );
      expect(hits, hasLength(1));
      expect(hits.first.shipId, 'colonyShip:2');
    });

    test('skips hazard terrains regardless of terraforming', () {
      final state = buildState(terrain: HexTerrain.blackHole);
      expect(
        state.findColonizeCandidates(
          candidateShipIds: {'colonyShip:1'},
          terraformingLevel: 9,
        ),
        isEmpty,
      );
    });
  });
}

MapHexState stateHex(
  HexCoord coord, {
  String? worldId,
}) {
  return MapHexState(
    coord: coord,
    worldId: worldId,
  );
}

List<int> _rowQs(List<MapHexState> hexes, int r) {
  final row = hexes.where((hex) => hex.coord.r == r).map((hex) => hex.coord.q).toList();
  row.sort();
  return row;
}
