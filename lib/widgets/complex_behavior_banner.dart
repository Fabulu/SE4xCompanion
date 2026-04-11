// Complex-behavior banner (PP01 Phase 4).
//
// Collapsible banner surfaced on a drawn-card tile when the card has a
// `CardModifierBinding.complexBehaviorNote`. Collapsed state shows only
// a warning icon and a tap hint; expanded state reveals the full note.

import 'package:flutter/material.dart';

class ComplexBehaviorBanner extends StatefulWidget {
  final String note;

  const ComplexBehaviorBanner({super.key, required this.note});

  @override
  State<ComplexBehaviorBanner> createState() => _ComplexBehaviorBannerState();
}

class _ComplexBehaviorBannerState extends State<ComplexBehaviorBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.tertiaryContainer;
    final fg = theme.colorScheme.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _expanded
                          ? 'Complex behavior'
                          : 'Complex behavior — tap to expand',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: fg,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 6),
                Text(
                  widget.note,
                  style: TextStyle(fontSize: 11, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
