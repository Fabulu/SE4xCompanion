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
          worldName: 'Homeworld',
          minerals: 2,
          terrain: HexTerrain.asteroid,
        ),
      );

      final restored = updated.hexAt(target.coord);
      expect(restored?.explored, true);
      expect(restored?.label, 'Home');
      expect(restored?.worldName, 'Homeworld');
      expect(restored?.minerals, 2);
      expect(restored?.terrain, HexTerrain.asteroid);
    });
  });
}
