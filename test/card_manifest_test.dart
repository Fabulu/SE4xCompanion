import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_manifest.dart';

void main() {
  const validCardTypes = {
    'empire',
    'replicatorEmpire',
    'alienTech',
    'crew',
    'mission',
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

    test('cards 56 and 57 are alien tech cards', () {
      final card56 = kAllCards.firstWhere((card) => card.number == 56);
      final card57 = kAllCards.firstWhere((card) => card.number == 57);

      expect(card56.type, 'alienTech');
      expect(card57.type, 'alienTech');
      expect(card56.supportStatus, CardSupportStatus.partial); // has complexBehaviorNote
      expect(card57.supportStatus, CardSupportStatus.referenceOnly);
    });

    test('card entries carry support status metadata', () {
      final statuses = kAllCards.map((card) => card.supportStatus).toSet();

      expect(statuses.contains(CardSupportStatus.supported), true);
      expect(statuses.contains(CardSupportStatus.partial), true);
      expect(statuses.contains(CardSupportStatus.referenceOnly), true);
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

    // PP04: the old _buildReferenceCards helper stamped every
    // placeholder with "Reference only. See the physical card for the
    // full effect." After PP04 every crew/mission/resource/scenario
    // modifier card has been transcribed from the rulebook PNGs so
    // this literal should no longer appear anywhere in kAllCards.
    test('no card description uses the legacy placeholder string', () {
      const placeholder =
          'Reference only. See the physical card for the full effect.';
      for (final card in kAllCards) {
        expect(
          card.description,
          isNot(contains(placeholder)),
          reason:
              'Card #${card.number} "${card.name}" (${card.type}) still '
              'uses the legacy placeholder description',
        );
      }
    });
  });
}
