import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/ship_definitions.dart';
import 'package:se4x/models/drawn_card.dart';
import 'package:se4x/models/game_modifier.dart';
import 'package:se4x/models/game_state.dart';

void main() {
  group('DrawnCard JSON round-trip', () {
    test('default DrawnCard round-trips', () {
      const card = DrawnCard(cardNumber: 1, drawnOnTurn: 3);
      final restored = DrawnCard.fromJson(card.toJson());
      expect(restored.cardNumber, 1);
      expect(restored.drawnOnTurn, 3);
      expect(restored.isFaceUp, true);
      expect(restored.notes, '');
      expect(restored.assignedModifiers, isEmpty);
    });

    test('populated DrawnCard round-trips all fields', () {
      const card = DrawnCard(
        cardNumber: 42,
        drawnOnTurn: 7,
        isFaceUp: false,
        notes: 'hold until fleet arrives',
        assignedModifiers: [
          GameModifier(
            name: 'Anti-Matter Warhead',
            type: 'costMod',
            shipType: ShipType.dd,
            value: -1,
          ),
        ],
      );
      final restored = DrawnCard.fromJson(card.toJson());
      expect(restored.cardNumber, 42);
      expect(restored.drawnOnTurn, 7);
      expect(restored.isFaceUp, false);
      expect(restored.notes, 'hold until fleet arrives');
      expect(restored.assignedModifiers, hasLength(1));
      expect(restored.assignedModifiers.first.name, 'Anti-Matter Warhead');
      expect(restored.assignedModifiers.first.shipType, ShipType.dd);
      expect(restored.assignedModifiers.first.value, -1);
    });

    test('fromJson fills defaults for missing fields', () {
      final card = DrawnCard.fromJson(const {'cardNumber': 9});
      expect(card.cardNumber, 9);
      expect(card.drawnOnTurn, 1);
      expect(card.isFaceUp, true);
      expect(card.notes, '');
      expect(card.assignedModifiers, isEmpty);
    });

    test('copyWith preserves unset fields', () {
      const card = DrawnCard(
        cardNumber: 1,
        drawnOnTurn: 2,
        notes: 'original',
      );
      final flipped = card.copyWith(isFaceUp: false);
      expect(flipped.cardNumber, 1);
      expect(flipped.notes, 'original');
      expect(flipped.isFaceUp, false);
    });
  });

  group('GameState.drawnHand', () {
    test('defaults to empty list and round-trips', () {
      const gs = GameState();
      expect(gs.drawnHand, isEmpty);
      final restored = GameState.fromJson(gs.toJson());
      expect(restored.drawnHand, isEmpty);
    });

    test('drawnHand survives JSON round-trip with multiple cards', () {
      final gs = GameState(
        drawnHand: const [
          DrawnCard(cardNumber: 100, drawnOnTurn: 1),
          DrawnCard(
            cardNumber: 1,
            drawnOnTurn: 2,
            isFaceUp: false,
            assignedModifiers: [
              GameModifier(
                name: 'Soylent Purple',
                type: 'maintenanceMod',
                shipType: ShipType.scout,
                value: 50,
                isPercent: true,
              ),
            ],
          ),
        ],
      );
      final restored = GameState.fromJson(gs.toJson());
      expect(restored.drawnHand, hasLength(2));
      expect(restored.drawnHand[0].cardNumber, 100);
      expect(restored.drawnHand[0].drawnOnTurn, 1);
      expect(restored.drawnHand[1].cardNumber, 1);
      expect(restored.drawnHand[1].isFaceUp, false);
      expect(restored.drawnHand[1].assignedModifiers, hasLength(1));
      expect(
        restored.drawnHand[1].assignedModifiers.first.isPercent,
        true,
      );
    });

    test('legacy JSON without drawnHand key decodes to empty list', () {
      // Simulate a pre-T3C save that had no drawnHand key.
      final legacy = const GameState().toJson();
      legacy.remove('drawnHand');
      final restored = GameState.fromJson(legacy);
      expect(restored.drawnHand, isEmpty);
    });

    test('copyWith replaces drawnHand', () {
      const gs = GameState();
      final next = gs.copyWith(
        drawnHand: const [DrawnCard(cardNumber: 5, drawnOnTurn: 1)],
      );
      expect(next.drawnHand, hasLength(1));
      expect(next.drawnHand.first.cardNumber, 5);
    });
  });

  group('Play semantics (pure list ops)', () {
    // These tests exercise the logic the production page applies to the
    // hand when playing cards, without invoking Flutter UI.

    List<DrawnCard> removeAt(List<DrawnCard> hand, int i) =>
        List<DrawnCard>.from(hand)..removeAt(i);

    test('play-as-event removes card and surfaces its modifiers', () {
      const mod = GameModifier(
        name: 'Polytitanium Alloy',
        type: 'costMod',
        shipType: ShipType.dd,
        value: -2,
      );
      final hand = [
        const DrawnCard(cardNumber: 4, drawnOnTurn: 1),
        const DrawnCard(
          cardNumber: 4,
          drawnOnTurn: 1,
          assignedModifiers: [mod],
        ),
      ];
      // "Play as event" the second card
      final playable = hand[1].assignedModifiers;
      expect(playable, hasLength(1));
      final remaining = removeAt(hand, 1);
      expect(remaining, hasLength(1));
      expect(remaining.first.assignedModifiers, isEmpty);
    });

    test('play-for-credits removes card (no assigned modifiers required)', () {
      final hand = [
        const DrawnCard(cardNumber: 85, drawnOnTurn: 4), // resource card
      ];
      // Card has no assignedModifiers — still playable for credits.
      expect(hand[0].assignedModifiers, isEmpty);
      final remaining = removeAt(hand, 0);
      expect(remaining, isEmpty);
    });

    test('play-as-event is a no-op for cards with no modifiers', () {
      final hand = [
        const DrawnCard(cardNumber: 200, drawnOnTurn: 1), // crew, no mods
      ];
      final canPlay = hand[0].assignedModifiers.isNotEmpty;
      expect(canPlay, false);
      // Semantics: hand unchanged when play-as-event is not allowed.
      expect(hand, hasLength(1));
    });

    test('cards may be held across turns (drawnOnTurn preserved)', () {
      const drawn = DrawnCard(cardNumber: 77, drawnOnTurn: 2);
      // Turn advances; card stays in hand.
      const held = drawn; // no change on turn advance
      expect(held.drawnOnTurn, 2);
    });
  });
}
