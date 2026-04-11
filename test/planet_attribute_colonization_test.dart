// PP01 Phase 5 tests: Planet Attribute colonization flow.
//
// Pure-model coverage for:
//   - pickRandomPlanetAttribute exclusion logic
//   - DrawnCard attachedWorldId round-trip in GameState
//
// The UI prompt (showPlanetAttributePrompt) and the _HomePageState glue
// that calls it are exercised end-to-end by the existing widget tests;
// here we focus on the deterministic parts.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_manifest.dart';
import 'package:se4x/models/drawn_card.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/util/planet_attribute_picker.dart';

void main() {
  group('pickRandomPlanetAttribute', () {
    test('returns some planet attribute when exclusion set is empty', () {
      final rng = Random(42);
      final pick = pickRandomPlanetAttribute(<int>{}, random: rng);
      expect(pick, isNotNull);
      final numbers = kPlanetAttributes.map((c) => c.number).toSet();
      expect(numbers.contains(pick), true);
    });

    test('never returns a card already in the exclusion set', () {
      final rng = Random(0);
      // Run many trials with a partial exclusion set.
      final excluded = <int>{1001, 1002, 1003};
      for (var i = 0; i < 200; i++) {
        final pick = pickRandomPlanetAttribute(excluded, random: rng);
        expect(pick, isNotNull);
        expect(excluded.contains(pick), false);
      }
    });

    test('returns null when all planet attributes are excluded', () {
      final allNumbers = {
        for (final c in kPlanetAttributes) c.number,
      };
      final pick = pickRandomPlanetAttribute(allNumbers);
      expect(pick, isNull);
    });

    test('picks from remaining one correctly when only one card left', () {
      final allButOne = {
        for (final c in kPlanetAttributes.skip(1)) c.number,
      };
      final pick = pickRandomPlanetAttribute(allButOne);
      expect(pick, kPlanetAttributes.first.number);
    });
  });

  group('DrawnCard.attachedWorldId in GameState', () {
    test('attached planet attribute survives full GameState round-trip', () {
      final gs = const GameState().copyWith(
        drawnHand: const [
          DrawnCard(
            cardNumber: 1001,
            drawnOnTurn: 3,
            attachedWorldId: 'world-colony-7',
          ),
        ],
      );
      final restored = GameState.fromJson(gs.toJson());
      expect(restored.drawnHand, hasLength(1));
      expect(restored.drawnHand.single.cardNumber, 1001);
      expect(restored.drawnHand.single.attachedWorldId, 'world-colony-7');
    });

    test(
      'moving an attached card to playedCards preserves attachedWorldId',
      () {
        final gs = const GameState().copyWith(
          drawnHand: const [
            DrawnCard(
              cardNumber: 1005,
              drawnOnTurn: 4,
              attachedWorldId: 'world-x',
            ),
          ],
        );
        // Mimic discard transform.
        final card = gs.drawnHand[0];
        final next = gs.copyWith(
          drawnHand: const [],
          playedCards: [
            card.copyWith(disposition: 'discarded'),
          ],
        );
        final restored = GameState.fromJson(next.toJson());
        expect(restored.drawnHand, isEmpty);
        expect(restored.playedCards, hasLength(1));
        expect(restored.playedCards.single.attachedWorldId, 'world-x');
        expect(restored.playedCards.single.disposition, 'discarded');
      },
    );
  });
}
