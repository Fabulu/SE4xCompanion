import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/replicator_state.dart';

void main() {
  group('ReplicatorState.fromScenario', () {
    test('standard scenario initializes normal solitaire baseline', () {
      final state = ReplicatorState.fromScenario(
        'replicator_standard',
        difficulty: 'Normal',
      );

      expect(state.scenarioId, 'replicator_standard');
      expect(state.mapLabel, 'Standard');
      expect(state.difficultyLabel, 'Normal');
      expect(state.coloniesCount, 1);
      expect(state.colonyLevel, 3);
      expect(state.hullsInField, 6);
      expect(state.moveLevel, 2);
      expect(state.pointDefenseUnlocked, true);
      expect(state.scannersUnlocked, true);
      expect(state.minesweepersUnlocked, true);
      expect(state.hullsProducedPerTurn, 3);
    });

    test('fast replicators start at move 3', () {
      final state = ReplicatorState.fromScenario(
        'replicator_large',
        difficulty: 'Normal',
        empireAdvantage: 'Fast Replicators',
      );

      expect(state.scenarioId, 'replicator_large');
      expect(state.mapLabel, 'Large');
      expect(state.moveLevel, 3);
    });

    test('hard and impossible add starting hulls and RP', () {
      final hard = ReplicatorState.fromScenario(
        'replicator_standard',
        difficulty: 'Hard',
      );
      final impossible = ReplicatorState.fromScenario(
        'replicator_standard',
        difficulty: 'Impossible',
      );

      expect(hard.hullsInField, 8);
      expect(hard.rpTotal, 1);
      expect(impossible.hullsInField, 9);
      expect(impossible.rpTotal, 2);
    });
  });

  group('ReplicatorState.endTurn', () {
    test('adds current production and advances turn', () {
      const state = ReplicatorState(
        turnNumber: 4,
        coloniesCount: 2,
        colonyLevel: 1,
        hullsAtHomeworld: 3,
      );

      final next = state.endTurn();

      expect(next.turnNumber, 5);
      expect(next.economicPhasesCompleted, 1);
      expect(next.hullsAtHomeworld, 5);
      expect(next.colonyLevel, 1);
      expect(next.attackBonus, 0);
    });

    test('every third economic phase upgrades colony level and attack bonus', () {
      const state = ReplicatorState(
        economicPhasesCompleted: 2,
        coloniesCount: 2,
        colonyLevel: 1,
        attackBonus: 0,
        hullsAtHomeworld: 4,
      );

      final next = state.endTurn();

      expect(next.economicPhasesCompleted, 3);
      expect(next.hullsAtHomeworld, 6, reason: 'Production uses the current colony level');
      expect(next.colonyLevel, 2);
      expect(next.attackBonus, 1);
      expect(next.hullsProducedPerTurn, 4);
    });

    test('caps colony level and attack bonus at 3', () {
      const state = ReplicatorState(
        economicPhasesCompleted: 8,
        coloniesCount: 3,
        colonyLevel: 3,
        attackBonus: 3,
      );

      final next = state.endTurn();

      expect(next.economicPhasesCompleted, 9);
      expect(next.colonyLevel, 3);
      expect(next.attackBonus, 3);
      expect(next.hullsAtHomeworld, 9);
    });
  });

  group('ReplicatorState JSON', () {
    test('round-trips new scenario and progression fields', () {
      const state = ReplicatorState(
        scenarioId: 'replicator_large',
        mapLabel: 'Large',
        difficultyLabel: 'Hard',
        turnNumber: 3,
        economicPhasesCompleted: 2,
        cpPool: 11,
        rpTotal: 7,
        hullsAtHomeworld: 5,
        hullsInField: 14,
        moveLevel: 2,
        coloniesCount: 1,
        colonyLevel: 3,
        attackBonus: 1,
        pointDefenseUnlocked: true,
        scannersUnlocked: true,
        minesweepersUnlocked: true,
        fleetLog: ['sent destroyers'],
        empireAdvantage: 'Fast Replicators',
      );

      final restored = ReplicatorState.fromJson(state.toJson());

      expect(restored.scenarioId, 'replicator_large');
      expect(restored.mapLabel, 'Large');
      expect(restored.difficultyLabel, 'Hard');
      expect(restored.economicPhasesCompleted, 2);
      expect(restored.colonyLevel, 3);
      expect(restored.attackBonus, 1);
      expect(restored.pointDefenseUnlocked, true);
      expect(restored.empireAdvantage, 'Fast Replicators');
    });

    test('older JSON without new fields still restores safely', () {
      final restored = ReplicatorState.fromJson({
        'turnNumber': 2,
        'coloniesCount': 3,
      });

      expect(restored.turnNumber, 2);
      expect(restored.coloniesCount, 3);
      expect(restored.economicPhasesCompleted, 0);
      expect(restored.mapLabel, 'Custom');
      expect(restored.colonyLevel, 1);
      expect(restored.attackBonus, 0);
    });
  });

  group('GameState JSON with replicator state', () {
    test('round-trips replicator scenario fields through game state', () {
      const gameState = GameState(
        replicatorState: ReplicatorState(
          scenarioId: 'replicator_standard',
          mapLabel: 'Standard',
          difficultyLabel: 'Hard',
          economicPhasesCompleted: 3,
          colonyLevel: 2,
          attackBonus: 1,
        ),
      );

      final restored = GameState.fromJson(gameState.toJson());

      expect(restored.replicatorState, isNotNull);
      expect(restored.replicatorState!.scenarioId, 'replicator_standard');
      expect(restored.replicatorState!.mapLabel, 'Standard');
      expect(restored.replicatorState!.colonyLevel, 2);
      expect(restored.replicatorState!.attackBonus, 1);
    });
  });
}
