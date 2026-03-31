// GENERATED FILE - DO NOT EDIT
// Generated from SE4X Master Rule Book

import 'rules_sections_1_9.dart';
import 'rules_sections_10_27.dart';
import 'rules_sections_28_41.dart';

class RuleSection {
  final String id;
  final String title;
  final String body;
  final int depth;
  final String? parentId;
  final bool isOptional;
  final List<String> tags;
  final int sourcePage;

  const RuleSection({
    required this.id,
    required this.title,
    required this.body,
    required this.depth,
    this.parentId,
    required this.isOptional,
    required this.tags,
    required this.sourcePage,
  });
}

final List<RuleSection> kAllRules = [
  ...kRuleSections1to9,
  ...kRuleSections10to27,
  ...kRuleSections28to41,
];

final Map<String, RuleSection> kRulesById = {
  for (final r in kAllRules) r.id: r,
};
