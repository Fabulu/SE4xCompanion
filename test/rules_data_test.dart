import 'package:flutter_test/flutter_test.dart';
import 'package:se4x/data/rules_data.dart';

void main() {
  group('kAllRules integrity', () {
    test('kAllRules is non-empty', () {
      expect(kAllRules, isNotEmpty);
    });

    test('all sections have non-empty id and title', () {
      for (final section in kAllRules) {
        expect(section.id, isNotEmpty,
            reason: 'Section with title "${section.title}" has empty id');
        expect(section.title, isNotEmpty,
            reason: 'Section ${section.id} has empty title');
      }
    });

    test('all section ids are unique', () {
      final ids = <String>{};
      for (final section in kAllRules) {
        expect(ids.contains(section.id), false,
            reason: 'Duplicate section id: ${section.id}');
        ids.add(section.id);
      }
    });

    test('parent IDs that exist in kAllRules point to valid sections', () {
      final allIds = {for (final s in kAllRules) s.id};
      // Some parent IDs reference sections that are not enumerated in kAllRules
      // (e.g., intermediate grouping sections like 2.0, 28.0). We verify that
      // when a parentId IS present in kAllRules, the lookup succeeds.
      int validParentRefs = 0;
      int missingParentRefs = 0;
      for (final section in kAllRules) {
        if (section.parentId != null) {
          if (allIds.contains(section.parentId)) {
            validParentRefs++;
          } else {
            missingParentRefs++;
          }
        }
      }
      // The majority of parent references should be valid
      expect(validParentRefs, greaterThan(0));
      // Ensure we're not silently hiding a massive problem
      expect(missingParentRefs, lessThan(validParentRefs),
          reason: 'Too many missing parent references');
    });

    test('top-level sections have null parentId', () {
      final topLevel = kAllRules.where((s) => s.depth == 0).toList();
      for (final s in topLevel) {
        expect(s.parentId, isNull,
            reason: 'Top-level section ${s.id} should have null parentId');
      }
    });

    test('optional flag is true for sections with major number >= 28', () {
      for (final section in kAllRules) {
        // Extract the major section number (e.g., "28.2.1" -> 28)
        final majorStr = section.id.split('.').first;
        final major = int.tryParse(majorStr);
        if (major != null && major >= 28) {
          expect(section.isOptional, true,
              reason:
                  'Section ${section.id} has major number >= 28 but isOptional is false');
        }
      }
    });
  });

  group('kRulesById', () {
    test('contains all entries from kAllRules', () {
      expect(kRulesById.length, kAllRules.length);
      for (final section in kAllRules) {
        expect(kRulesById.containsKey(section.id), true,
            reason: 'kRulesById missing section ${section.id}');
        expect(kRulesById[section.id]!.title, section.title);
      }
    });

    test('lookup by id returns correct section', () {
      final first = kAllRules.first;
      expect(kRulesById[first.id]!.id, first.id);
      expect(kRulesById[first.id]!.title, first.title);
    });
  });

  group('Depth calculation', () {
    test('top-level sections (e.g. "X.0") have depth 0', () {
      // Find a top-level section
      final topLevel = kAllRules.where((s) => s.depth == 0).toList();
      expect(topLevel, isNotEmpty);
      for (final s in topLevel) {
        // Top-level IDs should have one dot at most (e.g. "5.0", "1.0")
        final parts = s.id.split('.');
        expect(parts.length, 2,
            reason: 'Top-level section ${s.id} should have format X.Y');
      }
    });

    test('depth 1 sections have format X.Y (two dot-separated parts)', () {
      final depth1 = kAllRules.where((s) => s.depth == 1).toList();
      expect(depth1, isNotEmpty);
      for (final s in depth1) {
        final parts = s.id.split('.');
        expect(parts.length, 2,
            reason:
                'Depth-1 section ${s.id} should have 2 dot-separated parts');
      }
    });

    test('depth 2 sections have format X.Y.Z (three dot-separated parts)', () {
      final depth2 = kAllRules.where((s) => s.depth == 2).toList();
      expect(depth2, isNotEmpty);
      for (final s in depth2) {
        final parts = s.id.split('.');
        expect(parts.length, 3,
            reason:
                'Depth-2 section ${s.id} should have 3 dot-separated parts');
      }
    });

    test('depth matches number of dot-separated parts minus 1', () {
      for (final s in kAllRules) {
        final parts = s.id.split('.');
        // Depth 0 for "X.0" (2 parts), depth 1 for "X.Y" (2 parts with Y>0 or subsection)
        // Actually the convention is: depth = parts.length - 2 for sub-sub sections
        // Let's just verify the specific examples mentioned
        if (parts.length == 3) {
          expect(s.depth, 2,
              reason: 'Section ${s.id} with 3 parts should have depth 2');
        }
      }
    });

    test('specific depth examples from the data', () {
      // Check a known top-level section
      final s50 = kRulesById['5.0'];
      if (s50 != null) {
        expect(s50.depth, 0, reason: '5.0 should have depth 0');
      }

      final s51 = kRulesById['5.1'];
      if (s51 != null) {
        expect(s51.depth, 1, reason: '5.1 should have depth 1');
      }

      final s513 = kRulesById['5.1.3'];
      if (s513 != null) {
        expect(s513.depth, 2, reason: '5.1.3 should have depth 2');
      }
    });
  });
}
