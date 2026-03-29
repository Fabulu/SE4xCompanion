import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/data/alien_tables.dart';
import 'package:se4x/models/alien_economy.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/world.dart';

void main() {
  group('GameState JSON round-trip', () {
    test('default GameState round-trips', () {
      const gs = GameState();
      final json = gs.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.turnNumber, 1);
      expect(restored.config.enableFacilities, false);
      expect(restored.shipCounters, isEmpty);
      expect(restored.alienPlayers, isEmpty);
    });

    test('populated GameState round-trips', () {
      final gs = GameState(
        config: const GameConfig(
          enableFacilities: true,
          enableLogistics: true,
          ownership: ExpansionOwnership(allGoodThings: true),
        ),
        turnNumber: 5,
        production: ProductionState(
          cpCarryOver: 15,
          worlds: [
            const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 25),
          ],
          techState: const TechState(levels: {TechId.attack: 2}),
        ),
        shipCounters: [
          const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true, attack: 1),
        ],
        alienPlayers: [
          const AlienPlayer(name: 'Red', color: 'red', currentTurn: 3),
        ],
      );

      final json = gs.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.turnNumber, 5);
      expect(restored.config.enableFacilities, true);
      expect(restored.config.enableLogistics, true);
      expect(restored.config.ownership.allGoodThings, true);
      expect(restored.production.cpCarryOver, 15);
      expect(restored.production.worlds.length, 1);
      expect(restored.production.worlds[0].homeworldValue, 25);
      expect(restored.production.techState.getLevel(TechId.attack), 2);
      expect(restored.shipCounters.length, 1);
      expect(restored.shipCounters[0].attack, 1);
      expect(restored.alienPlayers.length, 1);
      expect(restored.alienPlayers[0].name, 'Red');
    });
  });

  group('SavedGame JSON round-trip', () {
    test('round-trips with all fields', () {
      final sg = SavedGame(
        id: 'abc-123',
        name: 'My Game',
        updatedAt: DateTime.utc(2025, 6, 15, 10, 30),
        state: const GameState(turnNumber: 3),
        isArchived: true,
      );

      final json = sg.toJson();
      final restored = SavedGame.fromJson(json);

      expect(restored.id, 'abc-123');
      expect(restored.name, 'My Game');
      expect(restored.updatedAt, DateTime.utc(2025, 6, 15, 10, 30));
      expect(restored.state.turnNumber, 3);
      expect(restored.isArchived, true);
    });

    test('defaults isArchived to false', () {
      final json = {
        'id': 'x',
        'name': 'test',
        'updatedAt': '2025-01-01T00:00:00.000Z',
      };
      final restored = SavedGame.fromJson(json);
      expect(restored.isArchived, false);
    });
  });

  group('AppState JSON round-trip', () {
    test('empty AppState round-trips', () {
      const app = AppState();
      final json = app.toJson();
      final restored = AppState.fromJson(json);
      expect(restored.activeGameId, isNull);
      expect(restored.games, isEmpty);
    });

    test('populated AppState round-trips', () {
      final app = AppState(
        activeGameId: 'game-1',
        games: [
          SavedGame(
            id: 'game-1',
            name: 'First',
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
          SavedGame(
            id: 'game-2',
            name: 'Second',
            updatedAt: DateTime.utc(2025, 2, 1),
            isArchived: true,
          ),
        ],
      );

      final json = app.toJson();
      final restored = AppState.fromJson(json);

      expect(restored.activeGameId, 'game-1');
      expect(restored.games.length, 2);
      expect(restored.games[0].name, 'First');
      expect(restored.games[1].isArchived, true);
    });
  });

  group('Default game creation', () {
    test('default GameState has turn 1', () {
      const gs = GameState();
      expect(gs.turnNumber, 1);
    });

    test('default GameState has base config', () {
      const gs = GameState();
      expect(gs.config.enableFacilities, false);
      expect(gs.config.enableLogistics, false);
      expect(gs.config.enableTemporal, false);
      expect(gs.config.enableAdvancedConstruction, false);
      expect(gs.config.enableReplicators, false);
      expect(gs.config.enableShipExperience, false);
    });

    test('default GameConfig.useFacilitiesCosts matches enableFacilities', () {
      const base = GameConfig();
      expect(base.useFacilitiesCosts, false);

      const fac = GameConfig(enableFacilities: true);
      expect(fac.useFacilitiesCosts, true);
    });
  });

  group('AlienPlayer JSON round-trip', () {
    test('full alien player with turn records and fleets', () {
      const ap = AlienPlayer(
        name: 'Blue',
        color: 'blue',
        currentTurn: 4,
        turnRecords: [
          AlienTurnRecord(
            turnNumber: 1,
            extraEcon: 0,
            rolls: [
              AlienEconRoll(dieResult: 3, outcome: AlienEconOutcomeType.tech),
            ],
            fleetLaunched: false,
          ),
        ],
        fleets: [
          AlienFleetEntry(fleetNumber: 1, cp: 12, isRaider: false, launchTurn: 3),
        ],
        techsPurchased: ['Attack-1', 'Move-2'],
      );

      final json = ap.toJson();
      final restored = AlienPlayer.fromJson(json);

      expect(restored.name, 'Blue');
      expect(restored.color, 'blue');
      expect(restored.currentTurn, 4);
      expect(restored.turnRecords.length, 1);
      expect(restored.turnRecords[0].rolls[0].dieResult, 3);
      expect(restored.turnRecords[0].rolls[0].outcome, AlienEconOutcomeType.tech);
      expect(restored.fleets.length, 1);
      expect(restored.fleets[0].cp, 12);
      expect(restored.fleets[0].launchTurn, 3);
      expect(restored.techsPurchased, ['Attack-1', 'Move-2']);
    });
  });

  group('GameConfig JSON round-trip', () {
    test('full config round-trips', () {
      const config = GameConfig(
        ownership: ExpansionOwnership(
          closeEncounters: true,
          replicators: true,
          allGoodThings: true,
        ),
        enableFacilities: true,
        enableLogistics: true,
        enableTemporal: true,
        enableAdvancedConstruction: true,
        enableReplicators: true,
        enableShipExperience: true,
      );

      final json = config.toJson();
      final restored = GameConfig.fromJson(json);

      expect(restored.ownership.closeEncounters, true);
      expect(restored.ownership.replicators, true);
      expect(restored.ownership.allGoodThings, true);
      expect(restored.enableFacilities, true);
      expect(restored.enableLogistics, true);
      expect(restored.enableTemporal, true);
      expect(restored.enableAdvancedConstruction, true);
      expect(restored.enableReplicators, true);
      expect(restored.enableShipExperience, true);
    });

    test('default config round-trips with all false', () {
      const config = GameConfig();
      final json = config.toJson();
      final restored = GameConfig.fromJson(json);

      expect(restored.enableFacilities, false);
      expect(restored.enableLogistics, false);
      expect(restored.enableTemporal, false);
    });
  });
}
