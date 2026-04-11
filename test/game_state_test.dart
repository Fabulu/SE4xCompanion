import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/data/tech_costs.dart';
import 'package:se4x/data/alien_tables.dart';
import 'package:se4x/models/alien_economy.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/drawn_card.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/map_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/replicator_player_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/technology.dart';
import 'package:se4x/models/turn_summary.dart';
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
          pipelineConnectedColonies: 1,
          worlds: [
            const WorldState(name: 'HW', isHomeworld: true, homeworldValue: 25),
          ],
          techState: const TechState(levels: {TechId.attack: 2}),
        ),
        shipCounters: [
          const ShipCounter(
            type: ShipType.dd,
            number: 1,
            isBuilt: true,
            attack: 1,
          ),
        ],
        alienPlayers: [
          const AlienPlayer(name: 'Red', color: 'red', currentTurn: 3),
        ],
        replicatorPlayerState: const ReplicatorPlayerState(
          cpPool: 12,
          rpTotal: 3,
          empireAdvantageCardNumber: 60,
        ),
        mapState: GameMapState.initial(layoutPreset: MapLayoutPreset.special5p)
            .copyWith(
              selectedHex: const HexCoord(0, 0),
              fleets: const [
                FleetStackState(
                  id: 'fleet-1',
                  coord: HexCoord(0, 0),
                  owner: 'Blue',
                  label: 'Fleet',
                  shipCounterIds: ['dd:1'],
                  composition: {'SC': 3},
                ),
              ],
            ),
      );

      final json = gs.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.turnNumber, 5);
      expect(restored.config.enableFacilities, true);
      expect(restored.config.enableLogistics, true);
      expect(restored.config.ownership.allGoodThings, true);
      expect(restored.production.cpCarryOver, 15);
      expect(restored.production.pipelineConnectedColonies, 1);
      expect(restored.production.worlds.length, 1);
      expect(restored.production.worlds[0].homeworldValue, 25);
      expect(restored.production.techState.getLevel(TechId.attack), 2);
      expect(restored.shipCounters.length, 1);
      expect(restored.shipCounters[0].attack, 1);
      expect(restored.alienPlayers.length, 1);
      expect(restored.alienPlayers[0].name, 'Red');
      expect(restored.replicatorPlayerState?.cpPool, 12);
      expect(restored.replicatorPlayerState?.empireAdvantageCardNumber, 60);
      expect(restored.mapState.layoutPreset, MapLayoutPreset.special5p);
      expect(restored.mapState.selectedHex?.id, '0,0');
      expect(restored.mapState.fleets, hasLength(1));
    });

    test('legacy GameState without mapState gets default board', () {
      final restored = GameState.fromJson({
        'turnNumber': 2,
        'production': {
          'worlds': [
            {'name': 'HW', 'isHomeworld': true, 'homeworldValue': 30},
          ],
        },
      });

      expect(restored.turnNumber, 2);
      expect(restored.mapState.hexes, isNotEmpty);
      expect(restored.mapState.layoutPreset, MapLayoutPreset.standard4p);
    });

    test('legacy map world names migrate on load', () {
      final restored = GameState.fromJson({
        'turnNumber': 2,
        'production': {
          'worlds': [
            {'name': 'Homeworld', 'isHomeworld': true, 'homeworldValue': 30},
            {'name': 'Colony 1', 'growthMarkerLevel': 2},
          ],
        },
        'mapState': {
          'layoutPreset': 'standard4p',
          'hexes': [
            {
              'coord': {'q': 3, 'r': 0},
              'worldName': 'Homeworld',
              // Legacy 'pipelines' / 'pipelineIds' keys are silently
              // ignored on load — Layer 1 visual pipeline placement
              // has been removed.
              'pipelines': 2,
            },
          ],
        },
      });

      final placedHex = restored.mapState.hexAt(const HexCoord(3, 0));
      expect(restored.production.worlds[0].id, isNotEmpty);
      expect(restored.production.worlds[1].id, isNotEmpty);
      expect(placedHex?.worldId, restored.production.worlds[0].id);
      // Legacy 'pipelines' hex counts are dropped on load. Pipeline income
      // is now driven exclusively by ProductionState.pipelineConnectedColonies
      // (Layer 2), which defaults to 0 when not present in the saved JSON.
      expect(restored.production.pipelineConnectedColonies, 0);
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

    group('confirmEndTurn (PP13)', () {
      test('default AppState has confirmEndTurn == true', () {
        const app = AppState();
        expect(app.confirmEndTurn, true);
      });

      test('round-trips when toggled off', () {
        const app = AppState(confirmEndTurn: false);
        final restored = AppState.fromJson(app.toJson());
        expect(restored.confirmEndTurn, false);
      });

      test('round-trips when explicitly on', () {
        const app = AppState(confirmEndTurn: true);
        final restored = AppState.fromJson(app.toJson());
        expect(restored.confirmEndTurn, true);
      });

      test('legacy JSON without confirmEndTurn defaults to true', () {
        // Simulates a save written before PP13 shipped: no
        // 'confirmEndTurn' key at all.
        final restored = AppState.fromJson({
          'version': 1,
          'activeGameId': null,
          'games': [],
        });
        expect(restored.confirmEndTurn, true);
      });

      test('copyWith updates confirmEndTurn', () {
        const app = AppState();
        final updated = app.copyWith(confirmEndTurn: false);
        expect(updated.confirmEndTurn, false);
        // Original is unchanged.
        expect(app.confirmEndTurn, true);
      });

      test('copyWith preserves confirmEndTurn when not specified', () {
        const app = AppState(confirmEndTurn: false);
        final updated = app.copyWith(activeGameId: 'g1');
        expect(updated.confirmEndTurn, false);
        expect(updated.activeGameId, 'g1');
      });
    });

    group('textScale (PP18)', () {
      test('default AppState has textScale == 1.0', () {
        const app = AppState();
        expect(app.textScale, 1.0);
      });

      test('round-trips when scaled up', () {
        const app = AppState(textScale: 1.25);
        final restored = AppState.fromJson(app.toJson());
        expect(restored.textScale, 1.25);
      });

      test('round-trips when scaled down', () {
        const app = AppState(textScale: 0.85);
        final restored = AppState.fromJson(app.toJson());
        expect(restored.textScale, 0.85);
      });

      test('legacy JSON without textScale defaults to 1.0', () {
        // Simulates a save written before PP18 shipped: no
        // 'textScale' key at all.
        final restored = AppState.fromJson({
          'version': 1,
          'activeGameId': null,
          'games': [],
        });
        expect(restored.textScale, 1.0);
      });

      test('copyWith updates textScale', () {
        const app = AppState();
        final updated = app.copyWith(textScale: 1.5);
        expect(updated.textScale, 1.5);
        // Original is unchanged.
        expect(app.textScale, 1.0);
      });

      test('copyWith preserves textScale when not specified', () {
        const app = AppState(textScale: 1.2);
        final updated = app.copyWith(activeGameId: 'g1');
        expect(updated.textScale, 1.2);
        expect(updated.activeGameId, 'g1');
      });
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

    test('useFacilitiesCosts is true when AGT is owned without Facilities', () {
      const agtNoFac = GameConfig(
        ownership: ExpansionOwnership(allGoodThings: true),
      );
      expect(agtNoFac.useFacilitiesCosts, true);
      expect(agtNoFac.enableFacilities, false);
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
          AlienFleetEntry(
            fleetNumber: 1,
            cp: 12,
            isRaider: false,
            launchTurn: 3,
          ),
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
      expect(
        restored.turnRecords[0].rolls[0].outcome,
        AlienEconOutcomeType.tech,
      );
      expect(restored.fleets.length, 1);
      expect(restored.fleets[0].cp, 12);
      expect(restored.fleets[0].launchTurn, 3);
      expect(restored.techsPurchased, ['Attack-1', 'Move-2']);
    });
  });

  group('GameState with turnSummaries', () {
    test('GameState with turnSummaries round-trips correctly', () {
      final gs = GameState(
        turnNumber: 4,
        turnSummaries: [
          TurnSummary(
            turnNumber: 1,
            completedAt: DateTime.utc(2025, 1, 1),
            techsGained: ['Attack-1'],
            shipsBuilt: ['DD x2'],
            coloniesGrown: 1,
            cpLostToCap: 5,
            rpLostToCap: 0,
            cpCarryOver: 25,
            rpCarryOver: 10,
            maintenancePaid: 3,
          ),
          TurnSummary(
            turnNumber: 2,
            completedAt: DateTime.utc(2025, 2, 1),
            techsGained: ['Defense-1', 'Move-2'],
            shipsBuilt: ['CA x1'],
            coloniesGrown: 2,
            cpLostToCap: 0,
            rpLostToCap: 8,
            cpCarryOver: 30,
            rpCarryOver: 20,
            maintenancePaid: 5,
          ),
        ],
      );

      final json = gs.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.turnNumber, 4);
      expect(restored.turnSummaries.length, 2);
      expect(restored.turnSummaries[0].turnNumber, 1);
      expect(restored.turnSummaries[0].completedAt, DateTime.utc(2025, 1, 1));
      expect(restored.turnSummaries[0].techsGained, ['Attack-1']);
      expect(restored.turnSummaries[0].shipsBuilt, ['DD x2']);
      expect(restored.turnSummaries[0].coloniesGrown, 1);
      expect(restored.turnSummaries[0].cpLostToCap, 5);
      expect(restored.turnSummaries[0].cpCarryOver, 25);
      expect(restored.turnSummaries[0].maintenancePaid, 3);
      expect(restored.turnSummaries[1].turnNumber, 2);
      expect(restored.turnSummaries[1].techsGained, ['Defense-1', 'Move-2']);
      expect(restored.turnSummaries[1].rpLostToCap, 8);
    });

    test('GameState with empty turnSummaries round-trips correctly', () {
      const gs = GameState(turnNumber: 1, turnSummaries: []);

      final json = gs.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.turnSummaries, isEmpty);
    });

    test('GameState without turnSummaries key defaults to empty list', () {
      final json = <String, dynamic>{'turnNumber': 3};
      final restored = GameState.fromJson(json);
      expect(restored.turnSummaries, isEmpty);
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
        playerControlsReplicators: true,
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
      expect(restored.playerControlsReplicators, true);
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

    test(
      'GameConfig with enableUnpredictableResearch round-trips correctly',
      () {
        const config = GameConfig(
          enableUnpredictableResearch: true,
          enableFacilities: true,
        );
        final json = config.toJson();
        final restored = GameConfig.fromJson(json);

        expect(restored.enableUnpredictableResearch, true);
        expect(restored.enableFacilities, true);
        expect(restored.enableLogistics, false);
      },
    );

    test('GameConfig with selectedEmpireAdvantage round-trips correctly', () {
      const config = GameConfig(selectedEmpireAdvantage: 34);
      final json = config.toJson();
      final restored = GameConfig.fromJson(json);

      expect(restored.selectedEmpireAdvantage, 34);
    });

    test('GameConfig.empireAdvantage getter returns correct EA', () {
      const config = GameConfig(selectedEmpireAdvantage: 34);
      final ea = config.empireAdvantage;

      expect(ea, isNotNull);
      expect(ea!.cardNumber, 34);
      expect(ea.name, 'Giant Race');
      expect(ea.hullSizeModifier, 1);
    });

    test('GameConfig.empireAdvantage returns null when no EA selected', () {
      const config = GameConfig();
      expect(config.empireAdvantage, isNull);
    });

    test('GameConfig.empireAdvantage returns null for invalid card number', () {
      const config = GameConfig(selectedEmpireAdvantage: 9999);
      expect(config.empireAdvantage, isNull);
    });

    test(
      'GameConfig.shipCostModifiers returns empty map when no EA selected',
      () {
        const config = GameConfig();
        expect(config.shipCostModifiers, isEmpty);
      },
    );

    test(
      'GameConfig.shipCostModifiers surfaces Immortals colony-ship surcharge',
      () {
        // Immortals (#44): Colony Ships cost 2 more.
        const config = GameConfig(selectedEmpireAdvantage: 44);
        expect(config.shipCostModifiers[ShipType.colonyShip], 2);
      },
    );

    test(
      'GameConfig.shipCostModifiers surfaces Star Wolves destroyer discount',
      () {
        // Star Wolves (#51): Destroyers cost 1 less.
        const config = GameConfig(selectedEmpireAdvantage: 51);
        expect(config.shipCostModifiers[ShipType.dd], -1);
      },
    );

    test('GameConfig.shipCostModifiers is empty for hull-size-only EAs', () {
      // Giant Race (#34) and Insectoids (#43) express their cost effect via
      // hullSizeModifier (affects maintenance + construction capacity per the
      // current rule text), not via direct ship cost modifiers.
      const giantRace = GameConfig(selectedEmpireAdvantage: 34);
      const insectoids = GameConfig(selectedEmpireAdvantage: 43);
      expect(giantRace.shipCostModifiers, isEmpty);
      expect(insectoids.shipCostModifiers, isEmpty);
    });
  });

  group('GameState.playedCards', () {
    test('default GameState has empty playedCards', () {
      const gs = GameState();
      expect(gs.playedCards, isEmpty);
    });

    test('playedCards round-trips through JSON', () {
      final gs = GameState(
        playedCards: const [
          DrawnCard(
            cardNumber: 85,
            drawnOnTurn: 2,
            disposition: 'credits',
            cpGained: 10,
          ),
          DrawnCard(
            cardNumber: 1,
            drawnOnTurn: 3,
            disposition: 'event',
          ),
          DrawnCard(
            cardNumber: 1001,
            drawnOnTurn: 4,
            disposition: 'discarded',
            attachedWorldId: 'world-1',
          ),
        ],
      );
      final restored = GameState.fromJson(gs.toJson());
      expect(restored.playedCards, hasLength(3));
      expect(restored.playedCards[0].disposition, 'credits');
      expect(restored.playedCards[0].cpGained, 10);
      expect(restored.playedCards[1].disposition, 'event');
      expect(restored.playedCards[2].disposition, 'discarded');
      expect(restored.playedCards[2].attachedWorldId, 'world-1');
    });

    test('legacy JSON without playedCards key decodes to empty list', () {
      final legacy = const GameState().toJson();
      legacy.remove('playedCards');
      final restored = GameState.fromJson(legacy);
      expect(restored.playedCards, isEmpty);
    });

    test('copyWith replaces playedCards', () {
      const gs = GameState();
      final next = gs.copyWith(
        playedCards: const [
          DrawnCard(
            cardNumber: 5,
            drawnOnTurn: 1,
            disposition: 'discarded',
          ),
        ],
      );
      expect(next.playedCards, hasLength(1));
      expect(next.playedCards.first.disposition, 'discarded');
    });

    test('reopenLastTurn restores playedCards from gameStateSnapshot', () {
      // Simulate a committed turn whose snapshot carries a playedCards entry
      // that is different from the current state's playedCards list.
      final snapshotPlayed = const [
        DrawnCard(
          cardNumber: 85,
          drawnOnTurn: 1,
          disposition: 'credits',
          cpGained: 12,
        ),
      ];
      final summary = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime.utc(2025, 1, 1),
        productionSnapshot: const ProductionState(),
        gameStateSnapshot: {
          'production': const ProductionState().toJson(),
          'drawnHand': const <dynamic>[],
          'playedCards': [for (final c in snapshotPlayed) c.toJson()],
          'activeModifiers': const <dynamic>[],
          'shipCounters': const <dynamic>[],
        },
      );
      final gs = GameState(
        turnNumber: 2,
        turnSummaries: [summary],
        playedCards: const [],
      );
      final reopened = gs.reopenLastTurn();
      expect(reopened.playedCards, hasLength(1));
      expect(reopened.playedCards.first.cardNumber, 85);
      expect(reopened.playedCards.first.disposition, 'credits');
      expect(reopened.turnNumber, 1);
      expect(reopened.turnSummaries, isEmpty);
    });

    test('reopenLastTurn legacy path (no gss) keeps playedCards unchanged',
        () {
      final summary = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime.utc(2025, 1, 1),
        productionSnapshot: const ProductionState(),
      );
      final gs = GameState(
        turnNumber: 2,
        turnSummaries: [summary],
        playedCards: const [
          DrawnCard(
            cardNumber: 5,
            drawnOnTurn: 1,
            disposition: 'discarded',
          ),
        ],
      );
      final reopened = gs.reopenLastTurn();
      // Legacy path falls back to production + turnNumber only, so the
      // current playedCards list is preserved unchanged.
      expect(reopened.playedCards, hasLength(1));
      expect(reopened.playedCards.first.cardNumber, 5);
      expect(reopened.turnNumber, 1);
    });
  });
}
