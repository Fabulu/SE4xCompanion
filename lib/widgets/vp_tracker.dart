import 'package:flutter/material.dart';

/// Compact Victory Point tracker for solo/coop scenarios.
/// Shows current VP count with +/-1 and +/-2 adjustment buttons.
class VpTracker extends StatelessWidget {
  final int vp;
  final String label;
  final String thresholdHint;
  final int lossThreshold;
  final ValueChanged<int> onChanged;

  const VpTracker({
    super.key,
    required this.vp,
    this.label = 'Victory Points',
    this.thresholdHint = '10 = enemy wins',
    this.lossThreshold = 10,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vpColor = vp >= lossThreshold
        ? Colors.red
        : vp >= (lossThreshold - 3)
            ? Colors.orange
            : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Label + threshold hint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  thresholdHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          // -2 button
          _vpButton(context, '-2', () => onChanged(vp - 2)),
          const SizedBox(width: 4),

          // -1 button
          _vpButton(context, '-1', () => onChanged(vp - 1)),
          const SizedBox(width: 8),

          // Current VP display
          SizedBox(
            width: 48,
            child: Text(
              '$vp',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: vpColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // +1 button
          _vpButton(context, '+1', () => onChanged(vp + 1)),
          const SizedBox(width: 4),

          // +2 button
          _vpButton(context, '+2', () => onChanged(vp + 2)),
        ],
      ),
    );
  }

  Widget _vpButton(BuildContext context, String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 40,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
