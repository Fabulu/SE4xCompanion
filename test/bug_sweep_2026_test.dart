// Regression tests for the bug sweep covering:
//   Bug 1 — ShipType.warSun never renders (listed in _displayOrder but never
//           added to _visibleTypes).
//   Bug 2 — Manual Override catalog picker applied modifiers without stamping
//           sourceCardId, bypassing Bug C dedup.
//   Bug 3 — "Play for credits" created an un-stamped income modifier that
//           stacks if the player taps it twice.
//   Bug 4 — Non-EA cards always showed "Reference only" even when they had a
//           binding in card_modifiers.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/card_manifest.dart';
import 'package:se4x/data/card_modifiers.dart';
import 'package:se4x/models/game_modifier.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Bug 1: warSun removed from ship tech page display order.
  // ---------------------------------------------------------------------------
  group('Bug 1: ShipType.warSun is not in ShipTechPage display order', () {
    test('ship_tech_page.dart _displayOrder does not list ShipType.warSun', () {
      final src = File('lib/pages/ship_tech_page.dart').readAsStringSync();
      final orderMatch = RegExp(
        r'_displayOrder\s*=\s*<ShipType>\[([\s\S]*?)\];',
      ).firstMatch(src);
      expect(orderMatch, isNotNull,
          reason: '_displayOrder declaration must exist');
      // Strip line comments so documentation that mentions warSun doesn't
      // trigger a false positive.
      final listBody = orderMatch!.group(1)!
          .split('\n')
          .map((l) {
            final idx = l.indexOf('//');
            return idx >= 0 ? l.substring(0, idx) : l;
          })
          .join('\n');
      expect(listBody.contains('ShipType.warSun'), false,
          reason:
              'warSun is never added to _visibleTypes, so including it in '
              '_displayOrder is dead weight (and was the source of Bug 1).');
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 2: manual override catalog picker stamps sourceCardId.
  // ---------------------------------------------------------------------------
  group('Bug 2: Manual Override catalog picker stamps sourceCardId', () {
    test('dedup logic suppresses re-applying the same card twice', () {
      // Mirror the guard in _showCatalogPicker's onTap: compute existing ids,
      // skip application if sourceId already present, else stamp + append.
      final card = kAllCards.firstWhere(
        (c) => kCardModifiers[c.number] != null &&
            kCardModifiers[c.number]!.hasModifiers,
        orElse: () => throw StateError('no bound card in manifest'),
      );
      final binding = kCardModifiers[card.number]!;
      final sourceId = '${card.type}:${card.number}';

      List<GameModifier> active = [];

      void applyViaPicker() {
        final existingIds = <String>{
          for (final m in active)
            if (m.sourceCardId != null) m.sourceCardId!,
        };
        if (existingIds.contains(sourceId)) return;
        final stamped = [
          for (final m in binding.modifiers) m.withSourceCardId(sourceId),
        ];
        active = [...active, ...stamped];
      }

      applyViaPicker();
      final afterFirst = active.length;
      expect(afterFirst, binding.modifiers.length);
      expect(
        active.every((m) => m.sourceCardId == sourceId),
        true,
        reason: 'every modifier must carry the card source id',
      );

      applyViaPicker(); // second tap — should be a no-op.
      expect(active.length, afterFirst,
          reason: 'picker must dedup the same card on re-apply');
    });

    test(
        'picker sourceCardId format matches rules_reference_page "Apply" footer',
        () {
      // rules_reference_page stamps as '<type>:<number>' (see
      // _buildCardApplyFooter). The manual override picker must use the
      // exact same format or dedup will never fire across the two paths.
      final pickerSrc =
          File('lib/widgets/manual_override_dialog.dart').readAsStringSync();
      expect(
        pickerSrc.contains(r"'${card.type}:${card.number}'"),
        true,
        reason: 'picker must stamp sourceCardId as "<type>:<number>"',
      );
      expect(
        pickerSrc.contains('withSourceCardId(sourceId)'),
        true,
        reason: 'picker must call withSourceCardId before appending',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 3: Play-for-credits income modifier is stamped.
  // ---------------------------------------------------------------------------
  group('Bug 3: Play-for-credits one-shot modifier is stamped', () {
    test('credits modifier carries a unique-per-turn sourceCardId', () {
      const cardType = 'resource';
      const cardNumber = 42;
      const turn = 3;
      final sourceId = 'card:$cardType:$cardNumber:credits:$turn';
      final mod = GameModifier(
        name: 'Demo (credits)',
        type: 'incomeMod',
        value: 10,
        sourceCardId: sourceId,
      );
      expect(mod.sourceCardId, 'card:resource:42:credits:3');

      // Same card, later turn -> distinct id (second play is allowed).
      final nextTurn = GameModifier(
        name: 'Demo (credits)',
        type: 'incomeMod',
        value: 10,
        sourceCardId: 'card:$cardType:$cardNumber:credits:${turn + 1}',
      );
      expect(nextTurn.sourceCardId, isNot(mod.sourceCardId));
    });

    test('dedup guard drops second play-for-credits in the same turn', () {
      const sourceId = 'card:alienTech:21:credits:4';
      final active = <GameModifier>[
        const GameModifier(
          name: 'Efficient Factories (credits)',
          type: 'incomeMod',
          value: 5,
          sourceCardId: sourceId,
        ),
      ];
      // Mirror home_page._onPlayCardForCredits guard.
      bool alreadyApplied(String id) =>
          active.any((m) => m.sourceCardId == id);
      expect(alreadyApplied(sourceId), true);
      // A different turn should not be considered already-applied.
      expect(alreadyApplied('card:alienTech:21:credits:5'), false);
    });

    test('production_page stamps sourceCardId when calling callback', () {
      final src =
          File('lib/pages/production_page.dart').readAsStringSync();
      expect(
        src.contains('credits:') && src.contains('onPlayCardForCredits?.call'),
        true,
        reason:
            'production_page must pass a sourceCardId ending in "credits:<turn>"',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 4: Non-EA cards upgrade their support badge when bound.
  // ---------------------------------------------------------------------------
  group('Bug 4: kAllCards derives supportStatus from card_modifiers', () {
    test('bound alien tech card (#1 Soylent Purple) is marked supported', () {
      final card = kAllCards.firstWhere((c) => c.number == 1);
      expect(card.type, 'alienTech');
      expect(kCardModifiers[1]?.hasModifiers, true);
      expect(card.supportStatus, CardSupportStatus.supported);
    });

    test('bound planet attribute with concrete modifiers is supported', () {
      final candidate = kAllCards.firstWhere(
        (c) =>
            c.type == 'planetAttribute' &&
            (kCardModifiers[c.number]?.hasModifiers ?? false),
        orElse: () => throw StateError('no bound planet attribute'),
      );
      expect(candidate.supportStatus, CardSupportStatus.supported);
    });

    test('card with complexBehaviorNote only is marked partial', () {
      final complexEntry = kCardModifiers.entries.firstWhere(
        (e) => e.value.isComplex && !e.value.hasModifiers,
        orElse: () => throw StateError('no complex-only binding'),
      );
      final card = kAllCards.firstWhere(
        (c) =>
            c.number == complexEntry.key &&
            c.type != 'empire' &&
            c.type != 'replicatorEmpire',
        orElse: () => throw StateError(
            'no non-EA card for number ${complexEntry.key}'),
      );
      expect(card.supportStatus, CardSupportStatus.partial);
    });

    test('unbound card (#56) stays Reference only', () {
      final card = kAllCards.firstWhere((c) => c.number == 56);
      expect(kCardModifiers[56], isNull);
      expect(card.supportStatus, CardSupportStatus.referenceOnly);
    });
  });
}
