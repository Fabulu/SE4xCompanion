import 'package:flutter/material.dart';

import '../data/unique_ship_designer.dart';

/// Shows the Unique Ship designer dialog (§41).
///
/// Returns the saved [UniqueShipDesign] if the user tapped "Save", or
/// `null` if the user cancelled. Pass [initial] to edit an existing design.
Future<UniqueShipDesign?> showUniqueShipDesignerDialog(
  BuildContext context, {
  UniqueShipDesign? initial,
}) {
  return showDialog<UniqueShipDesign>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => UniqueShipDesignerDialog(initial: initial),
  );
}

/// The stateful designer dialog. Exposed for widget tests.
class UniqueShipDesignerDialog extends StatefulWidget {
  final UniqueShipDesign? initial;

  const UniqueShipDesignerDialog({super.key, this.initial});

  @override
  State<UniqueShipDesignerDialog> createState() =>
      _UniqueShipDesignerDialogState();
}

class _UniqueShipDesignerDialogState extends State<UniqueShipDesignerDialog> {
  late TextEditingController _nameCtrl;
  late int _hullSize;
  late UniqueShipWeaponClass _weaponClass;
  late Set<int> _abilityIds;

  @override
  void initState() {
    super.initState();
    final start = widget.initial ?? UniqueShipDesign.blank();
    _nameCtrl = TextEditingController(text: start.name);
    _hullSize = start.hullSize.clamp(1, 7);
    _weaponClass = start.weaponClass;
    _abilityIds = Set<int>.from(start.abilityIds);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  UniqueShipDesign _currentDesign() => UniqueShipDesign(
        name: _nameCtrl.text.trim(),
        hullSize: _hullSize,
        weaponClass: _weaponClass,
        abilityIds: _abilityIds.toList()..sort(),
      );

  void _save() {
    Navigator.of(context).pop(_currentDesign());
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final design = _currentDesign();
    final totalCost = uniqueShipDesignCost(design);
    final baseHullCost = kUniqueShipHullCosts[_hullSize] ?? 0;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Design Unique Ship',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'SE4X §41 — pick a hull size, weapon class, and any special '
                'abilities. The total CP is computed live.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Scrollable body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNameField(theme),
                    const SizedBox(height: 16),
                    _buildHullSizeSection(theme, baseHullCost),
                    const SizedBox(height: 16),
                    _buildWeaponClassDropdown(theme),
                    const SizedBox(height: 16),
                    _buildAbilitiesSection(theme),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // ── Total cost + buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '$totalCost CP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (totalCost == kUniqueShipMinCost)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '(§41.1.5 minimum cost is $kUniqueShipMinCost CP)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancel,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return TextField(
      controller: _nameCtrl,
      maxLength: 32,
      decoration: const InputDecoration(
        labelText: 'Name',
        hintText: 'e.g. Excalibur',
        border: OutlineInputBorder(),
        isDense: true,
        counterText: '',
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildHullSizeSection(ThemeData theme, int baseHullCost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hull Size', style: theme.textTheme.titleSmall),
            Text(
              'Hull $_hullSize = $baseHullCost CP base',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Slider(
          value: _hullSize.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '$_hullSize',
          onChanged: (v) => setState(() => _hullSize = v.round()),
        ),
      ],
    );
  }

  Widget _buildWeaponClassDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Weapon Class', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        DropdownButtonFormField<UniqueShipWeaponClass>(
          initialValue: _weaponClass,
          isDense: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: UniqueShipWeaponClass.values
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text('Class ${v.label}'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _weaponClass = v);
          },
        ),
      ],
    );
  }

  Widget _buildAbilitiesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Special Abilities', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final ability in kUniqueShipAbilities)
          _AbilityTile(
            ability: ability,
            selected: _abilityIds.contains(ability.id),
            onChanged: (selected) {
              setState(() {
                if (selected) {
                  _abilityIds.add(ability.id);
                } else {
                  _abilityIds.remove(ability.id);
                }
              });
            },
          ),
      ],
    );
  }
}

class _AbilityTile extends StatelessWidget {
  final UniqueShipDesignerAbility ability;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _AbilityTile({
    required this.ability,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surcharge = ability.costSurcharge;
    final surchargeLabel = surcharge >= 0 ? '+$surcharge CP' : '$surcharge CP';
    final surchargeColor = surcharge >= 0
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(!selected),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ability.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            surchargeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: surchargeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ability.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
