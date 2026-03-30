import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/rules_data.dart';
import 'package:se4x/data/rules_phases.dart';

void main() {
  group('kPhaseGroupings integrity', () {
    test('all section IDs in phase groupings exist in kAllRules', () {
      final allIds = {for (final s in kAllRules) s.id};
      for (final entry in kPhaseGroupings.entries) {
        for (final sectionId in entry.value) {
          expect(allIds.contains(sectionId), true,
              reason:
                  'Phase "${entry.key}" references non-existent section "$sectionId"');
        }
      }
    });

    test('no duplicate section IDs across phases', () {
      final seen = <String>{};
      for (final entry in kPhaseGroupings.entries) {
        for (final sectionId in entry.value) {
          expect(seen.contains(sectionId), false,
              reason:
                  'Section "$sectionId" appears in multiple phases (found in "${entry.key}")');
          seen.add(sectionId);
        }
      }
    });

    test('phase groupings map is non-empty', () {
      expect(kPhaseGroupings, isNotEmpty);
    });

    test('each phase has at least one section', () {
      for (final entry in kPhaseGroupings.entries) {
        expect(entry.value, isNotEmpty,
            reason: 'Phase "${entry.key}" has no sections');
      }
    });
  });
}
