import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/map_state.dart';

void main() {
  group('GameMapState', () {
    test('default layouts are non-empty and distinct', () {
      final standard4p =
          GameMapState.defaultHexesFor(MapLayoutPreset.standard4p);
      final special5p =
          GameMapState.defaultHexesFor(MapLayoutPreset.special5p);

      expect(standard4p, isNotEmpty);
      expect(special5p, isNotEmpty);
      expect(
        standard4p.map((hex) => hex.coord.id).toSet(),
        isNot(equals(special5p.map((hex) => hex.coord.id).toSet())),
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
          pipelineIds: const ['pipeline-1'],
          terrain: HexTerrain.asteroid,
        ),
      );

      final restored = updated.hexAt(target.coord);
      expect(restored?.explored, true);
      expect(restored?.label, 'Home');
      expect(restored?.worldId, 'world-home');
      expect(restored?.minerals, 2);
      expect(restored?.pipelineIds, ['pipeline-1']);
      expect(restored?.terrain, HexTerrain.asteroid);
    });

    test('sanitizeAgainstLedger deduplicates worlds, ships, and pipelines', () {
      final state = GameMapState.initial().copyWith(
        hexes: [
          stateHex(const HexCoord(0, 0), worldId: 'world-1', pipelineIds: const ['pipe-1']),
          stateHex(const HexCoord(1, 0), worldId: 'world-1', pipelineIds: const ['pipe-1', 'pipe-2']),
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
        validPipelineIds: {'pipe-1'},
      );

      expect(sanitized.hexAt(const HexCoord(0, 0))?.worldId, 'world-1');
      expect(sanitized.hexAt(const HexCoord(1, 0))?.worldId, isNull);
      expect(sanitized.hexAt(const HexCoord(0, 0))?.pipelineIds, ['pipe-1']);
      expect(sanitized.hexAt(const HexCoord(1, 0))?.pipelineIds, isEmpty);
      expect(sanitized.fleetById('fleet-1')?.shipCounterIds, ['dd:1']);
      expect(sanitized.fleetById('fleet-2'), isNull);
    });

    test('sanitizeAgainstLedger prunes removed ledger assets', () {
      final state = GameMapState.initial().copyWith(
        hexes: [
          stateHex(const HexCoord(0, 0), worldId: 'world-1', pipelineIds: const ['pipe-1']),
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
        validPipelineIds: const {},
      );

      expect(sanitized.hexAt(const HexCoord(0, 0))?.worldId, isNull);
      expect(sanitized.hexAt(const HexCoord(0, 0))?.pipelineIds, isEmpty);
      expect(sanitized.fleets, isEmpty);
    });
  });
}

MapHexState stateHex(
  HexCoord coord, {
  String? worldId,
  List<String> pipelineIds = const [],
}) {
  return MapHexState(
    coord: coord,
    worldId: worldId,
    pipelineIds: pipelineIds,
  );
}
