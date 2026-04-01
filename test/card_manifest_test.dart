import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_manifest.dart';

void main() {
  const validCardTypes = {
    'empire',
    'replicatorEmpire',
    'alienTech',
    'crew',
    'resource',
    'scenarioModifier',
    'planetAttribute',
  };

  group('Card Manifest data integrity', () {
    test('kAllCards is non-empty', () {
      expect(kAllCards.isNotEmpty, true);
    });

    test('all card entries have non-empty name and description', () {
      for (final card in kAllCards) {
        expect(card.name.isNotEmpty, true,
            reason: 'Card #${card.number} (${card.type}) has empty name');
        expect(card.description.isNotEmpty, true,
            reason: 'Card #${card.number} (${card.type}) has empty description');
      }
    });

    test('card types are all valid values', () {
      for (final card in kAllCards) {
        expect(validCardTypes.contains(card.type), true,
            reason:
                'Card #${card.number} "${card.name}" has invalid type: ${card.type}');
      }
    });

    test('no duplicate card numbers within the same type', () {
      final seen = <String, Set<int>>{};
      for (final card in kAllCards) {
        seen.putIfAbsent(card.type, () => <int>{});
        expect(seen[card.type]!.add(card.number), true,
            reason:
                'Duplicate card number ${card.number} in type ${card.type} ("${card.name}")');
      }
    });
  });
}
