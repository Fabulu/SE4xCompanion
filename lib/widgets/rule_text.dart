import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders rule body text with tappable cross-reference links.
///
/// Patterns like `(5.1.3)` become tappable links in primary color.
/// SSB/CSB references (e.g. `(SSB 8.0)`) are rendered dimmed and not tappable.
class RuleTextWidget extends StatelessWidget {
  final String text;
  final void Function(String sectionId)? onReferenceTap;

  const RuleTextWidget({
    super.key,
    required this.text,
    this.onReferenceTap,
  });

  static final RegExp _refPattern = RegExp(
    r'\((\d{1,2}\.\d{1,2}(?:\.\d{1,2}(?:\.\d{1,2})?)?)\)',
  );

  static final RegExp _ssbCsbPattern = RegExp(
    r'\(((?:SSB|CSB)\s+\d{1,2}\.\d{1,2}(?:\.\d{1,2}(?:\.\d{1,2})?)?)\)',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final linkStyle = bodyStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );
    final dimStyle = bodyStyle.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
    );

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    // Merge both patterns into a single pass by finding all matches sorted by position
    final allMatches = <_MatchInfo>[];

    for (final m in _ssbCsbPattern.allMatches(text)) {
      allMatches.add(_MatchInfo(m.start, m.end, m.group(1)!, _MatchType.ssbCsb));
    }
    for (final m in _refPattern.allMatches(text)) {
      // Skip if this overlaps with an SSB/CSB match
      final overlaps = allMatches.any(
        (a) => a.type == _MatchType.ssbCsb && m.start >= a.start && m.start < a.end,
      );
      if (!overlaps) {
        allMatches.add(_MatchInfo(m.start, m.end, m.group(1)!, _MatchType.ref));
      }
    }
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    for (final info in allMatches) {
      if (info.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, info.start), style: bodyStyle));
      }

      if (info.type == _MatchType.ssbCsb) {
        spans.add(TextSpan(text: '(${info.content})', style: dimStyle));
      } else {
        final sectionId = info.content;
        spans.add(TextSpan(
          text: '($sectionId)',
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onReferenceTap?.call(sectionId),
        ));
      }
      lastEnd = info.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: bodyStyle));
    }

    if (spans.isEmpty) {
      return Text(text, style: bodyStyle);
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}

enum _MatchType { ref, ssbCsb }

class _MatchInfo {
  final int start;
  final int end;
  final String content;
  final _MatchType type;

  const _MatchInfo(this.start, this.end, this.content, this.type);
}
