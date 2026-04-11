// PP01 Phase 2: card play history tests.
//
// The home_page composite handlers (`_onCardPlayedAsEvent`,
// `_onCardPlayedForCredits`, `_onCardDiscarded`) each apply ONE state
// mutation that:
//   1. stamps `disposition` (+ `cpGained` for credits) on the card
//   2. removes it from `drawnHand`
//   3. appends it to `playedCards`
//   4. (event) appends modifiers to `activeModifiers`
//   5. (credits) appends an income modifier to `activeModifiers`
//
// We exercise the same transformations via pure GameState.copyWith calls
// so the contract is enforced even from a non-widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/drawn_card.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/game_state.dart';

/// Play-as-event transform mirroring `_onCardPlayedAsEvent`.
GameState playAsEvent(GameState gs, int index) {
  final card = gs.drawnHand[index];
  final stamped = card.copyWith(disposition: 'event');
  final newHand = List<DrawnCard>.from(gs.drawnHand)..removeAt(index);
  return gs.copyWith(
    drawnHand: newHand,
    playedCards: [...gs.playedCards, stamped],
    activeModifiers: [...gs.activeModifiers, ...card.assignedModifiers],
  );
}

/// Play-for-credits transform mirroring `_onCardPlayedForCredits`.
GameState playForCredits(
  GameState gs,
  int index,
  int cp,
  String sourceCardId,
  String cardName,
) {
  final card = gs.drawnHand[index];
  final stamped = card.copyWith(disposition: 'credits', cpGained: cp);
  final newHand = List<DrawnCard>.from(gs.drawnHand)..removeAt(index);
  final mod = GameModifier(
    name: '$cardName (credits)',
    type: 'incomeMod',
    value: cp,
    sourceCardId: sourceCardId,
  );
  return gs.copyWith(
    drawnHand: newHand,
    playedCards: [...gs.playedCards, stamped],
    activeModifiers: [...gs.activeModifiers, mod],
  );
}

/// Discard transform mirroring `_onCardDiscarded`.
GameState discard(GameState gs, int index) {
  final card = gs.drawnHand[index];
  final stamped = card.copyWith(disposition: 'discarded');
  final newHand = List<DrawnCard>.from(gs.drawnHand)..removeAt(index);
  return gs.copyWith(
    drawnHand: newHand,
    playedCards: [...gs.playedCards, stamped],
  );
}

void main() {
  group('card play composite mutations', () {
    const exampleMod = GameModifier(
      name: 'Polytitanium Alloy',
      type: 'costMod',
      shipType: ShipType.dd,
      value: -2,
    );

    test('play-as-event: card moves to playedCards with disposition=event',
        () {
      final gs = const GameState().copyWith(
        drawnHand: const [
          DrawnCard(
            cardNumber: 4,
            drawnOnTurn: 1,
            assignedModifiers: [exampleMod],
          ),
        ],
      );
      final next = playAsEvent(gs, 0);
      expect(next.drawnHand, isEmpty);
      expect(next.playedCards, hasLength(1));
      expect(next.playedCards.single.disposition, 'event');
      expect(next.playedCards.single.cardNumber, 4);
      expect(next.activeModifiers, hasLength(1));
      expect(next.activeModifiers.single.name, 'Polytitanium Alloy');
    });

    test(
      'play-for-credits: card moves to playedCards with '
      "disposition='credits' and cpGained=N",
      () {
        final gs = const GameState().copyWith(
          drawnHand: const [
            DrawnCard(cardNumber: 85, drawnOnTurn: 2),
          ],
        );
        final next = playForCredits(
          gs,
          0,
          12,
          'card:resource:85:credits:2',
          'Polytitanium Alloy',
        );
        expect(next.drawnHand, isEmpty);
        expect(next.playedCards, hasLength(1));
        expect(next.playedCards.single.disposition, 'credits');
        expect(next.playedCards.single.cpGained, 12);
        expect(next.activeModifiers, hasLength(1));
        expect(next.activeModifiers.single.type, 'incomeMod');
        expect(next.activeModifiers.single.value, 12);
        expect(
          next.activeModifiers.single.sourceCardId,
          'card:resource:85:credits:2',
        );
      },
    );

    test(
      'discard: card moves to playedCards with disposition=discarded and '
      'no ledger mutation',
      () {
        final gs = const GameState().copyWith(
          drawnHand: const [
            DrawnCard(cardNumber: 200, drawnOnTurn: 1),
          ],
          activeModifiers: const [],
        );
        final next = discard(gs, 0);
        expect(next.drawnHand, isEmpty);
        expect(next.playedCards, hasLength(1));
        expect(next.playedCards.single.disposition, 'discarded');
        expect(next.activeModifiers, isEmpty);
      },
    );

    test('multiple plays append in order', () {
      var gs = const GameState().copyWith(
        drawnHand: const [
          DrawnCard(cardNumber: 10, drawnOnTurn: 1),
          DrawnCard(
            cardNumber: 11,
            drawnOnTurn: 1,
            assignedModifiers: [exampleMod],
          ),
          DrawnCard(cardNumber: 12, drawnOnTurn: 1),
        ],
      );
      gs = discard(gs, 0);
      gs = playAsEvent(gs, 0);
      gs = playForCredits(gs, 0, 5, 'card:resource:12:credits:1', 'c12');
      expect(gs.drawnHand, isEmpty);
      expect(gs.playedCards, hasLength(3));
      expect(gs.playedCards[0].cardNumber, 10);
      expect(gs.playedCards[0].disposition, 'discarded');
      expect(gs.playedCards[1].cardNumber, 11);
      expect(gs.playedCards[1].disposition, 'event');
      expect(gs.playedCards[2].cardNumber, 12);
      expect(gs.playedCards[2].disposition, 'credits');
      expect(gs.playedCards[2].cpGained, 5);
    });

    test('play history survives JSON round-trip', () {
      var gs = const GameState().copyWith(
        drawnHand: const [
          DrawnCard(
            cardNumber: 4,
            drawnOnTurn: 1,
            assignedModifiers: [exampleMod],
          ),
          DrawnCard(cardNumber: 85, drawnOnTurn: 1),
        ],
      );
      gs = playAsEvent(gs, 0);
      gs = playForCredits(gs, 0, 10, 'card:resource:85:credits:1', 'c85');

      final restored = GameState.fromJson(gs.toJson());
      expect(restored.playedCards, hasLength(2));
      expect(restored.playedCards[0].disposition, 'event');
      expect(restored.playedCards[1].disposition, 'credits');
      expect(restored.playedCards[1].cpGained, 10);
    });
  });
}
