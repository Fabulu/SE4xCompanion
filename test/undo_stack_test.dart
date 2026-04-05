// Tests for the multi-step undo model (T3-E).
//
// The undo history itself lives inside _HomePageState (session-only,
// never persisted) and is exercised end-to-end through home_page.dart.
// These tests focus on the pure model-level primitives that back it:
//
//   * GameState.canReopenLastTurn
//   * GameState.reopenLastTurn() — the "reopen committed turn" operation
//   * The push / pop semantics that _updateGameState relies on
//     (modeled here via a minimal stack harness).

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/drawn_card.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/models/production_state.dart';
import 'package:se4x/models/ship_counter.dart';
import 'package:se4x/models/turn_summary.dart';

/// Minimal port of the undo-stack semantics used inside _HomePageState,
/// extracted so it can be unit-tested without mounting the widget tree.
class _UndoHarness {
  static const int maxDepth = 20;
  final List<GameState> history = [];
  final List<String> descriptions = [];
  GameState current;

  _UndoHarness(this.current);

  void apply(GameState next, String description) {
    history.add(current);
    descriptions.add(description);
    if (history.length > maxDepth) {
      history.removeAt(0);
      descriptions.removeAt(0);
    }
    current = next;
  }

  bool get canUndo => history.isNotEmpty;

  void undo() {
    if (history.isEmpty) return;
    current = history.removeLast();
    descriptions.removeLast();
  }
}

GameState _stateWithCp(int cp, {int turnNumber = 1}) {
  return GameState(
    turnNumber: turnNumber,
    production: ProductionState(cpCarryOver: cp),
  );
}

void main() {
  group('Undo stack — push / pop', () {
    test('single push then undo restores prior state', () {
      final h = _UndoHarness(_stateWithCp(10));
      h.apply(_stateWithCp(20), 'Production');
      expect(h.canUndo, isTrue);
      expect(h.current.production.cpCarryOver, 20);
      h.undo();
      expect(h.current.production.cpCarryOver, 10);
      expect(h.canUndo, isFalse);
    });

    test('multi-step undo walks back through history', () {
      final h = _UndoHarness(_stateWithCp(0));
      h.apply(_stateWithCp(5), 'a');
      h.apply(_stateWithCp(10), 'b');
      h.apply(_stateWithCp(15), 'c');
      expect(h.history.length, 3);
      h.undo();
      expect(h.current.production.cpCarryOver, 10);
      h.undo();
      expect(h.current.production.cpCarryOver, 5);
      h.undo();
      expect(h.current.production.cpCarryOver, 0);
      expect(h.canUndo, isFalse);
    });

    test('undo on empty history is a no-op', () {
      final h = _UndoHarness(_stateWithCp(7));
      h.undo();
      expect(h.current.production.cpCarryOver, 7);
      expect(h.canUndo, isFalse);
    });

    test('history is capped at maxDepth, oldest dropped FIFO', () {
      final h = _UndoHarness(_stateWithCp(0));
      for (int i = 1; i <= _UndoHarness.maxDepth + 5; i++) {
        h.apply(_stateWithCp(i), 'step-$i');
      }
      expect(h.history.length, _UndoHarness.maxDepth);
      expect(h.descriptions.length, _UndoHarness.maxDepth);
      // Oldest five should have been dropped; bottom of stack is step-5's
      // predecessor value (i.e. the state snapshot right before step-6).
      expect(h.descriptions.first, 'step-6');
      expect(h.history.first.production.cpCarryOver, 5);
    });

    test('descriptions track the action that produced each state', () {
      final h = _UndoHarness(_stateWithCp(0));
      h.apply(_stateWithCp(1), 'Production');
      h.apply(_stateWithCp(2), 'Ship Tech');
      h.apply(_stateWithCp(3), 'End Turn 1');
      expect(h.descriptions, ['Production', 'Ship Tech', 'End Turn 1']);
      h.undo();
      expect(h.descriptions, ['Production', 'Ship Tech']);
    });
  });

  group('GameState.reopenLastTurn', () {
    GameState buildCommittedTurn({int turnEnding = 3, int snapshotCp = 12}) {
      // Pre-commit production the player had mid-Economic-Phase.
      final preCommit = ProductionState(cpCarryOver: snapshotCp);
      final summary = TurnSummary(
        turnNumber: turnEnding,
        completedAt: DateTime(2026, 4, 4),
        productionSnapshot: preCommit,
        cpCarryOver: snapshotCp,
      );
      // Post-commit state: turn advanced, production rolled forward.
      return GameState(
        turnNumber: turnEnding + 1,
        production: const ProductionState(cpCarryOver: 0),
        turnSummaries: [summary],
      );
    }

    test('canReopenLastTurn is false when no summaries', () {
      const gs = GameState();
      expect(gs.canReopenLastTurn, isFalse);
      expect(identical(gs.reopenLastTurn(), gs), isTrue);
    });

    test('canReopenLastTurn is false when last summary has no snapshot', () {
      final gs = GameState(
        turnNumber: 2,
        turnSummaries: [
          TurnSummary(turnNumber: 1, completedAt: DateTime(2026, 4, 4)),
        ],
      );
      expect(gs.canReopenLastTurn, isFalse);
      expect(identical(gs.reopenLastTurn(), gs), isTrue);
    });

    test('reopenLastTurn pops summary and restores snapshot', () {
      final gs = buildCommittedTurn(turnEnding: 3, snapshotCp: 17);
      expect(gs.canReopenLastTurn, isTrue);
      expect(gs.turnNumber, 4);
      expect(gs.production.cpCarryOver, 0);

      final reopened = gs.reopenLastTurn();
      expect(reopened.turnNumber, 3);
      expect(reopened.production.cpCarryOver, 17);
      expect(reopened.turnSummaries, isEmpty);
    });

    test('reopenLastTurn only pops one summary when multiple exist', () {
      final earlier = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime(2026, 4, 4),
        productionSnapshot: const ProductionState(cpCarryOver: 3),
      );
      final later = TurnSummary(
        turnNumber: 2,
        completedAt: DateTime(2026, 4, 4),
        productionSnapshot: const ProductionState(cpCarryOver: 8),
      );
      final gs = GameState(
        turnNumber: 3,
        production: const ProductionState(cpCarryOver: 0),
        turnSummaries: [earlier, later],
      );

      final reopened = gs.reopenLastTurn();
      expect(reopened.turnSummaries.length, 1);
      expect(reopened.turnSummaries.single.turnNumber, 1);
      expect(reopened.turnNumber, 2);
      expect(reopened.production.cpCarryOver, 8);
    });

    test('reopen is composable with the undo stack', () {
      // Scenario: player ends turn, then makes a few edits on the new turn.
      // They realize they want to reopen the Economic Phase — undo won't
      // cleanly unwind the snapshot restore unless we capture it on the
      // stack like any other action.
      final preCommit = buildCommittedTurn(turnEnding: 2, snapshotCp: 9);
      final h = _UndoHarness(preCommit);
      // Two trivial edits on the new turn.
      h.apply(
        preCommit.copyWith(
          production: const ProductionState(cpCarryOver: 4),
        ),
        'edit-a',
      );
      h.apply(
        h.current.copyWith(
          production: const ProductionState(cpCarryOver: 6),
        ),
        'edit-b',
      );
      // Reopen the committed turn (pushes current onto the stack).
      h.apply(h.current.reopenLastTurn(), 'Reopen Turn 2');
      expect(h.current.turnNumber, 2);
      expect(h.current.production.cpCarryOver, 9);
      expect(h.current.turnSummaries, isEmpty);

      // Undo reopen — we should be back on the new turn with edit-b in
      // place and the committed summary restored.
      h.undo();
      expect(h.current.turnNumber, 3);
      expect(h.current.production.cpCarryOver, 6);
      expect(h.current.turnSummaries.length, 1);
    });
  });

  group('GameState.reopenLastTurn — full gameStateSnapshot', () {
    test('restores drawnHand, activeModifiers, shipCounters from snapshot',
        () {
      // Pre-commit state the player had on turn 2 mid-Economic-Phase.
      final preCommitProduction = const ProductionState(cpCarryOver: 12);
      final preCommitDrawn = [
        const DrawnCard(cardNumber: 1001, drawnOnTurn: 2),
        const DrawnCard(cardNumber: 1007, drawnOnTurn: 2, notes: 'keep'),
      ];
      final preCommitMods = [
        const GameModifier(
          name: 'Soylent Purple',
          type: 'maintenanceMod',
          value: 50,
          isPercent: true,
        ),
      ];
      final preCommitCounters = [
        const ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
      ];

      final snapshot = <String, dynamic>{
        'production': preCommitProduction.toJson(),
        'drawnHand': preCommitDrawn.map((c) => c.toJson()).toList(),
        'activeModifiers': preCommitMods.map((m) => m.toJson()).toList(),
        'shipCounters': preCommitCounters.map((c) => c.toJson()).toList(),
      };
      final summary = TurnSummary(
        turnNumber: 2,
        completedAt: DateTime(2026, 4, 4),
        productionSnapshot: preCommitProduction,
        gameStateSnapshot: snapshot,
      );

      // Post-commit state: turn advanced, hand changed, modifier dropped,
      // a fresh built counter materialized from T3-A.
      final gs = GameState(
        turnNumber: 3,
        production: const ProductionState(cpCarryOver: 0),
        drawnHand: const [],
        activeModifiers: const [],
        shipCounters: const [
          ShipCounter(type: ShipType.dd, number: 1, isBuilt: true),
          ShipCounter(type: ShipType.dd, number: 2, isBuilt: true),
        ],
        turnSummaries: [summary],
      );

      final reopened = gs.reopenLastTurn();
      expect(reopened.turnNumber, 2);
      expect(reopened.production.cpCarryOver, 12);
      expect(reopened.drawnHand.length, 2);
      expect(reopened.drawnHand.first.cardNumber, 1001);
      expect(reopened.drawnHand.last.notes, 'keep');
      expect(reopened.activeModifiers.length, 1);
      expect(reopened.activeModifiers.single.name, 'Soylent Purple');
      expect(reopened.shipCounters.length, 1);
      expect(reopened.shipCounters.single.number, 1);
      expect(reopened.turnSummaries, isEmpty);
    });

    test('legacy summaries (no gameStateSnapshot) fall back to '
        'production-only restore', () {
      // Summary without gameStateSnapshot — represents a legacy save.
      final summary = TurnSummary(
        turnNumber: 1,
        completedAt: DateTime(2026, 4, 4),
        productionSnapshot: const ProductionState(cpCarryOver: 5),
      );
      // Post-commit gameplay mutated drawnHand / shipCounters. Under the
      // fallback path we must NOT clobber those — only production and
      // turnNumber rewind.
      final gs = GameState(
        turnNumber: 2,
        production: const ProductionState(cpCarryOver: 0),
        drawnHand: const [DrawnCard(cardNumber: 42, drawnOnTurn: 1)],
        shipCounters: const [
          ShipCounter(type: ShipType.ca, number: 1, isBuilt: true),
        ],
        turnSummaries: [summary],
      );

      final reopened = gs.reopenLastTurn();
      expect(reopened.turnNumber, 1);
      expect(reopened.production.cpCarryOver, 5);
      // Legacy fallback preserves current drawnHand / shipCounters.
      expect(reopened.drawnHand.length, 1);
      expect(reopened.drawnHand.single.cardNumber, 42);
      expect(reopened.shipCounters.length, 1);
      expect(reopened.turnSummaries, isEmpty);
    });

    test('gameStateSnapshot round-trips through toJson/fromJson', () {
      final snapshot = <String, dynamic>{
        'production': const ProductionState(cpCarryOver: 7).toJson(),
        'drawnHand': const [
          DrawnCard(cardNumber: 3, drawnOnTurn: 1),
        ].map((c) => c.toJson()).toList(),
        'activeModifiers': const <Map<String, dynamic>>[],
        'shipCounters': const [
          ShipCounter(type: ShipType.dd, number: 2, isBuilt: true),
        ].map((c) => c.toJson()).toList(),
      };
      final original = TurnSummary(
        turnNumber: 4,
        completedAt: DateTime(2026, 4, 4),
        productionSnapshot: const ProductionState(cpCarryOver: 7),
        gameStateSnapshot: snapshot,
      );
      final roundtripped = TurnSummary.fromJson(original.toJson());
      expect(roundtripped.gameStateSnapshot, isNotNull);
      expect(roundtripped.gameStateSnapshot!['drawnHand'], isA<List>());
      final drawnList =
          (roundtripped.gameStateSnapshot!['drawnHand'] as List);
      expect(drawnList.length, 1);

      // And that the round-tripped summary still drives a full reopen.
      final gs = GameState(
        turnNumber: 5,
        production: const ProductionState(cpCarryOver: 0),
        turnSummaries: [roundtripped],
      );
      final reopened = gs.reopenLastTurn();
      expect(reopened.turnNumber, 4);
      expect(reopened.production.cpCarryOver, 7);
      expect(reopened.drawnHand.length, 1);
      expect(reopened.drawnHand.single.cardNumber, 3);
      expect(reopened.shipCounters.length, 1);
    });
  });
}
