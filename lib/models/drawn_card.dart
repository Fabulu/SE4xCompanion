// Represents a card that has been drawn from a deck and is held in the
// player's hand. Unlike one-shot modifier applications, drawn cards are
// tracked as durable game state (see T3-C).
//
// A DrawnCard references an entry in `card_manifest.dart` by `cardNumber`.
// It may carry a snapshot of the GameModifier templates that were (or would
// be) applied if the card is "played as event". The hand lives on
// `GameState.drawnHand`.

import 'game_modifier.dart';

class DrawnCard {
  /// Matches `CardEntry.number` in `card_manifest.dart`
  /// (planet attribute IDs use 1001-1028 by convention).
  final int cardNumber;

  /// Turn the card was drawn on. Useful for "hold across turns" auditing.
  final int drawnOnTurn;

  /// Whether the card is face-up (revealed) or still face-down in hand.
  final bool isFaceUp;

  /// Free-form player notes attached to the card.
  final String notes;

  /// Modifier templates that are applied when the card is played as an event.
  /// Usually populated from `card_modifiers.dart` at draw time.
  final List<GameModifier> assignedModifiers;

  const DrawnCard({
    required this.cardNumber,
    required this.drawnOnTurn,
    this.isFaceUp = true,
    this.notes = '',
    this.assignedModifiers = const [],
  });

  DrawnCard copyWith({
    int? cardNumber,
    int? drawnOnTurn,
    bool? isFaceUp,
    String? notes,
    List<GameModifier>? assignedModifiers,
  }) => DrawnCard(
        cardNumber: cardNumber ?? this.cardNumber,
        drawnOnTurn: drawnOnTurn ?? this.drawnOnTurn,
        isFaceUp: isFaceUp ?? this.isFaceUp,
        notes: notes ?? this.notes,
        assignedModifiers: assignedModifiers ?? this.assignedModifiers,
      );

  Map<String, dynamic> toJson() => {
        'cardNumber': cardNumber,
        'drawnOnTurn': drawnOnTurn,
        'isFaceUp': isFaceUp,
        'notes': notes,
        'assignedModifiers':
            assignedModifiers.map((m) => m.toJson()).toList(),
      };

  factory DrawnCard.fromJson(Map<String, dynamic> json) => DrawnCard(
        cardNumber: json['cardNumber'] as int? ?? 0,
        drawnOnTurn: json['drawnOnTurn'] as int? ?? 1,
        isFaceUp: json['isFaceUp'] as bool? ?? true,
        notes: json['notes'] as String? ?? '',
        assignedModifiers: (json['assignedModifiers'] as List?)
                ?.map((m) => GameModifier.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const <GameModifier>[],
      );
}
