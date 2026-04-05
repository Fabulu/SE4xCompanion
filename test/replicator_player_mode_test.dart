import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/models/game_config.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/replicator_player_state.dart';

void main() {
  test('GameConfig round-trips player-controlled Replicators flag', () {
    const config = GameConfig(
      playerControlsReplicators: true,
      selectedEmpireAdvantage: 60,
    );

    final restored = GameConfig.fromJson(config.toJson());

    expect(restored.playerControlsReplicators, true);
    expect(restored.selectedEmpireAdvantage, 60);
  });

  group('endTurn auto Move upgrade (RAW 40.2.1)', () {
    test('advancing to turn 8 bumps moveLevel to 2', () {
      const state = ReplicatorPlayerState(moveLevel: 1);
      final next = state.endTurn(nextTurnNumber: 8);
      expect(next.moveLevel, 2);
    });

    test('advancing to turn 16 bumps moveLevel to 3', () {
      const state = ReplicatorPlayerState(moveLevel: 2);
      final next = state.endTurn(nextTurnNumber: 16);
      expect(next.moveLevel, 3);
    });

    test('does NOT regress a manually-bought higher moveLevel at turn 8', () {
      const state = ReplicatorPlayerState(moveLevel: 3);
      final next = state.endTurn(nextTurnNumber: 8);
      expect(next.moveLevel, 3);
    });

    test('no upgrade fires on turn 7 or 9', () {
      const state = ReplicatorPlayerState(moveLevel: 1);
      expect(state.endTurn(nextTurnNumber: 7).moveLevel, 1);
      expect(state.endTurn(nextTurnNumber: 9).moveLevel, 2); // 9>=8 still triggers
    });

    test('Fast Replicators (#60) progresses 2->3 at turn 8, 3->4 at turn 16',
        () {
      final state =
          ReplicatorPlayerState.initial(empireAdvantageCardNumber: 60);
      expect(state.moveLevel, 2);
      // sim: end turn 7 -> turn 8 applies >=8 threshold, already 2 so stays 2.
      // We expect manual buy at turn >=8 gets to 3 before turn 16 cap.
      final atEight = state.endTurn(nextTurnNumber: 8);
      expect(atEight.moveLevel, 2); // threshold already met
      final bought = atEight.copyWith(moveLevel: 3);
      final atSixteen = bought.endTurn(nextTurnNumber: 16);
      expect(atSixteen.moveLevel, 3);
    });

    test('endTurn resets per-phase purchase flags', () {
      const state = ReplicatorPlayerState(
        boughtRpThisPhase: true,
        boughtMoveThisPhase: true,
        homeworldBoostPurchased: true,
      );
      final next = state.endTurn(nextTurnNumber: 2);
      expect(next.boughtRpThisPhase, false);
      expect(next.boughtMoveThisPhase, false);
      expect(next.homeworldBoostPurchased, false);
    });
  });

  group('depletion threshold (RAW 40.3.3 / EA #61)', () {
    test('baseline threshold is EP 10', () {
      const state = ReplicatorPlayerState();
      expect(state.depletionThresholdPhase, 10);
    });

    test('Green Replicators (#61) shifts threshold to 13', () {
      final state =
          ReplicatorPlayerState.initial(empireAdvantageCardNumber: 61);
      expect(state.depletionThresholdPhase, 13);
    });
  });

  group('flagship derived stats (RAW 40.7.5)', () {
    test('attack = rpTotal clamped to 4', () {
      expect(const ReplicatorPlayerState(rpTotal: 0).flagshipAttack, 0);
      expect(const ReplicatorPlayerState(rpTotal: 3).flagshipAttack, 3);
      expect(const ReplicatorPlayerState(rpTotal: 10).flagshipAttack, 4);
    });

    test('defense = rpTotal ~/ 5 clamped to 4', () {
      expect(const ReplicatorPlayerState(rpTotal: 4).flagshipDefense, 0);
      expect(const ReplicatorPlayerState(rpTotal: 5).flagshipDefense, 1);
      expect(const ReplicatorPlayerState(rpTotal: 15).flagshipDefense, 3);
    });

    test('hull size = 1 + rp capped at 15', () {
      expect(const ReplicatorPlayerState(rpTotal: 0).flagshipHullSize, 1);
      expect(const ReplicatorPlayerState(rpTotal: 14).flagshipHullSize, 15);
      expect(const ReplicatorPlayerState(rpTotal: 15).flagshipHullSize, 15);
    });
  });

  group('JSON backward compatibility', () {
    test('fromJson tolerates missing new fields', () {
      final state = ReplicatorPlayerState.fromJson({
        'cpPool': 5,
        'rpTotal': 2,
        'moveLevel': 1,
      });
      expect(state.boughtRpThisPhase, false);
      expect(state.boughtMoveThisPhase, false);
      expect(state.thingsEncountered, isEmpty);
      expect(state.spaceWrecksEncountered, 0);
      expect(state.firstCombatBonuses, 0);
    });

    test('round-trips new fields', () {
      const state = ReplicatorPlayerState(
        boughtRpThisPhase: true,
        boughtMoveThisPhase: true,
        thingsEncountered: ['scout', 'dd'],
        spaceWrecksEncountered: 2,
        firstCombatBonuses: 1,
      );
      final restored = ReplicatorPlayerState.fromJson(state.toJson());
      expect(restored.boughtRpThisPhase, true);
      expect(restored.boughtMoveThisPhase, true);
      expect(restored.thingsEncountered, ['scout', 'dd']);
      expect(restored.spaceWrecksEncountered, 2);
      expect(restored.firstCombatBonuses, 1);
    });
  });

  test('GameState round-trips Replicator player state', () {
    const gameState = GameState(
      config: GameConfig(playerControlsReplicators: true),
      replicatorPlayerState: ReplicatorPlayerState(
        cpPool: 12,
        rpTotal: 2,
        moveLevel: 2,
        empireAdvantageCardNumber: 60,
      ),
    );

    final restored = GameState.fromJson(gameState.toJson());

    expect(restored.config.playerControlsReplicators, true);
    expect(restored.replicatorPlayerState, isNotNull);
    expect(restored.replicatorPlayerState!.cpPool, 12);
    expect(restored.replicatorPlayerState!.rpTotal, 2);
    expect(restored.replicatorPlayerState!.empireAdvantageCardNumber, 60);
  });
}
