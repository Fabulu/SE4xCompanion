import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/scenarios.dart';
import 'package:se4x/models/drawn_card.dart';
import 'package:se4x/models/game_state.dart';
import 'package:se4x/util/scenario_auto_draw.dart';

void main() {
  group('applyScenarioAutoDrawnCards', () {
    test('no-op when scenario is null', () {
      const gs = GameState();
      final result = applyScenarioAutoDrawnCards(gs, null);
      expect(result.drawnHand, isEmpty);
      expect(identical(result, gs), true);
    });

    test('no-op when scenarioModifierCards is empty (standard 2p)', () {
      final scenario = scenarioById('standard_2p');
      expect(scenario, isNotNull);
      expect(scenario!.scenarioModifierCards, isEmpty);

      const gs = GameState();
      final result = applyScenarioAutoDrawnCards(gs, scenario);
      expect(result.drawnHand, isEmpty);
    });

    test(
      'quick_conquest auto-draws Technology Head Start (card 148) into hand',
      () {
        final scenario = scenarioById('quick_conquest');
        expect(scenario, isNotNull);
        expect(scenario!.scenarioModifierCards, [148]);

        const gs = GameState();
        final result = applyScenarioAutoDrawnCards(gs, scenario);
        expect(result.drawnHand, hasLength(1));
        final drawn = result.drawnHand.single;
        expect(drawn.cardNumber, 148);
        expect(drawn.drawnOnTurn, 1);
        expect(drawn.isFaceUp, true);
      },
    );

    test(
      'auto-drawn card is NOT added to activeModifiers (only hand)',
      () {
        final scenario = scenarioById('quick_conquest');
        const gs = GameState();
        final result = applyScenarioAutoDrawnCards(gs, scenario);
        expect(result.activeModifiers, isEmpty);
      },
    );

    test('idempotent: calling twice does not duplicate the card', () {
      final scenario = scenarioById('quick_conquest');
      const gs = GameState();
      final once = applyScenarioAutoDrawnCards(gs, scenario);
      final twice = applyScenarioAutoDrawnCards(once, scenario);
      expect(twice.drawnHand, hasLength(1));
      expect(twice.drawnHand.single.cardNumber, 148);
    });

    test('skips a card number that is already in the drawn hand', () {
      final scenario = scenarioById('quick_conquest');
      final gs = const GameState().copyWith(
        drawnHand: const [
          DrawnCard(cardNumber: 148, drawnOnTurn: 1),
        ],
      );
      final result = applyScenarioAutoDrawnCards(gs, scenario);
      expect(result.drawnHand, hasLength(1));
    });

    test(
      'only quick_conquest has a non-empty scenarioModifierCards list',
      () {
        for (final s in kScenarios) {
          if (s.id == 'quick_conquest') {
            expect(s.scenarioModifierCards, isNotEmpty);
          } else {
            expect(s.scenarioModifierCards, isEmpty);
          }
        }
      },
    );
  });
}
