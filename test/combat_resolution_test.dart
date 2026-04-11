import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/util/combat_resolution.dart';

GameState _buildState({
  List<ShipCounter>? shipCounters,
  List<FleetStackState> fleets = const [],
  int moveLevel = 2,
}) {
  return GameState(
    production: ProductionState(
      techState: TechState(levels: {TechId.move: moveLevel}),
    ),
    shipCounters: shipCounters ??
        const [
          ShipCounter(
            type: ShipType.dd,
            number: 1,
            isBuilt: true,
            attack: 1,
            defense: 0,
            move: 2,
          ),
          ShipCounter(
            type: ShipType.ca,
            number: 1,
            isBuilt: true,
            attack: 1,
            defense: 1,
            move: 2,
          ),
        ],
    mapState: GameMapState.initial().copyWith(fleets: fleets),
  );
}

void main() {
  group('applyCombatResolution', () {
    test('destroying one counter unbuilds it and zeroes its stats', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1', 'ca:1'],
          ),
        ],
      );

      final out = applyCombatResolution(
        state,
        const CombatResolution(destroyedShipCounterIds: ['dd:1']),
      );

      final dd = out.shipCounters.firstWhere((c) => c.id == 'dd:1');
      expect(dd.isBuilt, false);
      expect(dd.attack, 0);
      expect(dd.defense, 0);
      expect(dd.move, 0);
      // Surviving counter untouched.
      final ca = out.shipCounters.firstWhere((c) => c.id == 'ca:1');
      expect(ca.isBuilt, true);
      expect(ca.attack, 1);
      // Fleet still exists (CA survived) but lost the destroyed ship.
      final fleet = out.mapState.fleetById('fleet-1');
      expect(fleet, isNotNull);
      expect(fleet!.shipCounterIds, ['ca:1']);
    });

    test('destroying every ship in a fleet sanitizes the fleet away', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
        shipCounters: const [
          ShipCounter(
            type: ShipType.dd,
            number: 1,
            isBuilt: true,
            attack: 1,
            move: 2,
          ),
        ],
      );

      final out = applyCombatResolution(
        state,
        const CombatResolution(destroyedShipCounterIds: ['dd:1']),
      );

      expect(out.mapState.fleetById('fleet-1'), isNull);
      expect(
        out.shipCounters.firstWhere((c) => c.id == 'dd:1').isBuilt,
        false,
      );
    });

    test('retreating a fleet within range moves it and marks it as moved', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1', 'ca:1'],
          ),
        ],
      );

      // Distance 1 — well within DD/CA move of 2.
      final destination = state.mapState.hexes
          .firstWhere((h) => h.coord.distanceTo(const HexCoord(0, 0)) == 1)
          .coord;

      final out = applyCombatResolution(
        state,
        CombatResolution(retreats: {'fleet-1': destination}),
      );

      final fleet = out.mapState.fleetById('fleet-1')!;
      expect(fleet.coord, destination);
      expect(fleet.hasMovedThisTurn, true);
    });

    test('retreating beyond range leaves the fleet in place', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
      );

      // Pick a hex at distance > slowestShipMoveInFleet (=2).
      final tooFar = state.mapState.hexes
          .where((h) => h.coord.distanceTo(const HexCoord(0, 0)) >= 5)
          .first
          .coord;

      final out = applyCombatResolution(
        state,
        CombatResolution(retreats: {'fleet-1': tooFar}),
      );

      final fleet = out.mapState.fleetById('fleet-1')!;
      expect(fleet.coord, const HexCoord(0, 0));
      expect(fleet.hasMovedThisTurn, false);
    });

    test('destroy + retreat in same resolution', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1', 'ca:1'],
          ),
        ],
      );

      final destination = state.mapState.hexes
          .firstWhere((h) => h.coord.distanceTo(const HexCoord(0, 0)) == 1)
          .coord;

      final out = applyCombatResolution(
        state,
        CombatResolution(
          destroyedShipCounterIds: const ['dd:1'],
          retreats: {'fleet-1': destination},
        ),
      );

      // DD scrapped.
      expect(
        out.shipCounters.firstWhere((c) => c.id == 'dd:1').isBuilt,
        false,
      );
      // Fleet still present (CA survived) and retreated.
      final fleet = out.mapState.fleetById('fleet-1')!;
      expect(fleet.coord, destination);
      expect(fleet.shipCounterIds, ['ca:1']);
      expect(fleet.hasMovedThisTurn, true);
    });

    test('empty resolution is a no-op and returns same instance', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-1',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
      );

      final out = applyCombatResolution(state, const CombatResolution());

      expect(identical(out, state), true);
    });

    test('explicit fleet deletion removes the fleet', () {
      final state = _buildState(
        fleets: const [
          FleetStackState(
            id: 'fleet-enemy',
            isEnemy: true,
            coord: HexCoord(0, 0),
          ),
          FleetStackState(
            id: 'fleet-friendly',
            owner: 'Blue',
            coord: HexCoord(0, 0),
            shipCounterIds: ['dd:1'],
          ),
        ],
      );

      final out = applyCombatResolution(
        state,
        const CombatResolution(deletedFleetIds: ['fleet-enemy']),
      );

      expect(out.mapState.fleetById('fleet-enemy'), isNull);
      expect(out.mapState.fleetById('fleet-friendly'), isNotNull);
    });
  });

  group('CombatResolution', () {
    test('preserves the combat log note field', () {
      const res = CombatResolution(
        destroyedShipCounterIds: ['dd:1'],
        combatLogNote: 'DD lost to BB crit',
      );
      expect(res.combatLogNote, 'DD lost to BB crit');
    });

    test('isEmpty is true only when all fields are empty', () {
      expect(const CombatResolution().isEmpty, true);
      expect(
        const CombatResolution(destroyedShipCounterIds: ['dd:1']).isEmpty,
        false,
      );
      expect(
        CombatResolution(retreats: {'f': const HexCoord(0, 0)}).isEmpty,
        false,
      );
      expect(
        const CombatResolution(deletedFleetIds: ['f']).isEmpty,
        false,
      );
    });
  });
}
