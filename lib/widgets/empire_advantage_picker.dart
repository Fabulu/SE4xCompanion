// Shared Empire Advantage picker widget.
//
// Used by the new-game wizard (radio-tile style, inline) and the
// settings bottom-sheet (avatar-tile style). The caller picks the
// visual style via [EmpireAdvantagePickerStyle].

import 'package:flutter/material.dart';

import '../data/card_manifest.dart';
import '../data/empire_advantages.dart';
import 'card_detail_dialog.dart';

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

  // PP04: delegate to the universal card-detail dialog. Map the EA
  // onto a `CardEntry` on the fly so the dialog can render its title,
  // type chip, support badge, and full description uniformly. The EA
  // implementation note (if any) is surfaced via a simple complex-
  // behavior banner.
  static void _showFullCardDialog(BuildContext context, EmpireAdvantage ea) {
    CardSupportStatus status;
    switch (ea.supportStatus) {
      case EaSupportStatus.implemented:
        status = CardSupportStatus.supported;
        break;
      case EaSupportStatus.partial:
        status = CardSupportStatus.partial;
        break;
      case EaSupportStatus.referenceOnly:
        status = CardSupportStatus.referenceOnly;
        break;
    }
    final entry = CardEntry(
      number: ea.cardNumber,
      name: ea.name,
      type: ea.isReplicator ? 'replicatorEmpire' : 'empire',
      description: ea.description,
      revealCondition: ea.revealCondition,
      supportStatus: status,
    );
    showCardDetailDialog(
      context,
      card: entry,
      complexBehaviorNote:
          (ea.implementationNote != null && ea.implementationNote!.isNotEmpty)
              ? ea.implementationNote
              : null,
    );
  }

  List<EmpireAdvantage> _filtered() {
    return kEmpireAdvantages
        .where((ea) => ea.isReplicator == showReplicatorAdvantages)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
