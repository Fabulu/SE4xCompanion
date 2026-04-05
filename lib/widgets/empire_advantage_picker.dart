// Shared Empire Advantage picker widget.
//
// Used by the new-game wizard (radio-tile style, inline) and the
// settings bottom-sheet (avatar-tile style). The caller picks the
// visual style via [EmpireAdvantagePickerStyle].

import 'package:flutter/material.dart';

import '../data/empire_advantages.dart';

/// Visual style of the picker rows.
enum EmpireAdvantagePickerStyle {
  /// Radio-button ListTiles suitable for inline forms (e.g. wizard).
  /// Renders as a non-scrollable Column (caller wraps in scroll view).
  radio,

  /// CircleAvatar ListTiles with selected highlight, scrollable list.
  /// Used inside bottom sheets.
  avatar,
}

class EmpireAdvantagePicker extends StatelessWidget {
  final bool showReplicatorAdvantages;
  final int? selectedCardNumber;
  final ValueChanged<int?> onChanged;
  final int descriptionTruncation;
  final bool includeNoneOption;
  final EmpireAdvantagePickerStyle style;
  final ScrollController? scrollController;

  const EmpireAdvantagePicker({
    super.key,
    this.showReplicatorAdvantages = false,
    required this.selectedCardNumber,
    required this.onChanged,
    this.descriptionTruncation = 80,
    this.includeNoneOption = true,
    this.style = EmpireAdvantagePickerStyle.radio,
    this.scrollController,
  });

  // QW-6: Expand a card's full text so players can read descriptions before
  // committing. Shows name, card number, full description, reveal condition,
  // support status badge and implementation notes.
  static void _showFullCardDialog(BuildContext context, EmpireAdvantage ea) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        Color badgeColor;
        String badgeText;
        switch (ea.supportStatus) {
          case EaSupportStatus.implemented:
            badgeColor = theme.colorScheme.primary;
            badgeText = 'Implemented';
            break;
          case EaSupportStatus.partial:
            badgeColor = theme.colorScheme.tertiary;
            badgeText = 'Partial';
            break;
          case EaSupportStatus.referenceOnly:
            badgeColor = theme.colorScheme.outline;
            badgeText = 'Reference only';
            break;
        }
        return AlertDialog(
          title: Text('#${ea.cardNumber} ${ea.name}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor, width: 0.5),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(ea.description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                Text(
                  'Reveal:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(ea.revealCondition,
                    style: const TextStyle(fontSize: 12)),
                if (ea.implementationNote != null &&
                    ea.implementationNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Implementation note:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(ea.implementationNote!,
                      style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<EmpireAdvantage> _filtered() {
    return kEmpireAdvantages
        .where((ea) => ea.isReplicator == showReplicatorAdvantages)
        .toList();
  }

  String _truncate(String desc) {
    if (desc.length > descriptionTruncation) {
      return '${desc.substring(0, descriptionTruncation)}...';
    }
    return desc;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered();

    switch (style) {
      case EmpireAdvantagePickerStyle.radio:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (includeNoneOption)
              _radioTile(
                theme,
                'None',
                selectedCardNumber == null,
                () => onChanged(null),
              ),
            for (final ea in filtered)
              _radioTile(
                theme,
                '#${ea.cardNumber} ${ea.name}',
                selectedCardNumber == ea.cardNumber,
                () => onChanged(ea.cardNumber),
                subtitle: _truncate(ea.description),
                trailing: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    tooltip: 'Read full description',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showFullCardDialog(ctx, ea),
                  ),
                ),
              ),
          ],
        );
      case EmpireAdvantagePickerStyle.avatar:
        return ListView.builder(
          controller: scrollController,
          itemCount: filtered.length + (includeNoneOption ? 1 : 0),
          itemBuilder: (_, index) {
            if (includeNoneOption && index == 0) {
              return ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('None'),
                selected: selectedCardNumber == null,
                onTap: () => onChanged(null),
              );
            }
            final ea = filtered[index - (includeNoneOption ? 1 : 0)];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: ea.isReplicator
                    ? theme.colorScheme.error.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  '${ea.cardNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ea.isReplicator
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              title: Text(ea.name, style: const TextStyle(fontSize: 15)),
              subtitle: Text(
                _truncate(ea.description),
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: 'Read full description',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showFullCardDialog(ctx, ea),
                ),
              ),
              selected: selectedCardNumber == ea.cardNumber,
              onTap: () => onChanged(ea.cardNumber),
            );
          },
        );
    }
  }

  Widget _radioTile(
    ThemeData theme,
    String title,
    bool selected,
    VoidCallback onTap, {
    String? subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
