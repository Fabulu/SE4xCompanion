import 'package:flutter/material.dart';

import '../data/ship_definitions.dart';
import '../models/ship_counter.dart';
import '../models/technology.dart';

/// Ship types eligible for inclusion in a starting fleet.
const List<ShipType> _startingShipTypes = [
  ShipType.scout,
  ShipType.colonyShip,
  ShipType.miner,
  ShipType.shipyard,
  ShipType.decoy,
  ShipType.flag,
];

/// Standard starting fleet preset.
const Map<ShipType, int> kStandardFleet = {
  ShipType.scout: 4,
  ShipType.colonyShip: 3,
  ShipType.miner: 3,
  ShipType.shipyard: 2,
};

/// Standard fleet plus a Flagship.
const Map<ShipType, int> kStandardPlusFlagship = {
  ShipType.scout: 4,
  ShipType.colonyShip: 3,
  ShipType.miner: 3,
  ShipType.shipyard: 2,
  ShipType.flag: 1,
};

/// Shows a dialog for choosing a starting fleet preset or building a custom
/// fleet. Returns a [Map<ShipType, int>] mapping ship types to counts, or
/// `null` if the user cancels.
Future<Map<ShipType, int>?> showStartingFleetDialog(BuildContext context) {
  return showDialog<Map<ShipType, int>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _StartingFleetDialog(),
  );
}

// -----------------------------------------------------------------------------
// Dialog implementation
// -----------------------------------------------------------------------------

enum _FleetMode { preset, custom }

class _StartingFleetDialog extends StatefulWidget {
  const _StartingFleetDialog();

  @override
  State<_StartingFleetDialog> createState() => _StartingFleetDialogState();
}

class _StartingFleetDialogState extends State<_StartingFleetDialog> {
  _FleetMode _mode = _FleetMode.preset;
  int _selectedPreset = 0; // 0 = Standard, 1 = Standard+Flagship
  final Map<ShipType, int> _customCounts = {
    for (final t in _startingShipTypes) t: 0,
  };

  @override
  void initState() {
    super.initState();
    // Pre-populate custom with the standard preset so switching to custom
    // isn't an empty list.
    for (final entry in kStandardFleet.entries) {
      _customCounts[entry.key] = entry.value;
    }
  }

  Map<ShipType, int> get _activePreset {
    if (_mode == _FleetMode.custom) {
      return Map.fromEntries(
        _customCounts.entries.where((e) => e.value > 0),
      );
    }
    return _selectedPreset == 0 ? kStandardFleet : kStandardPlusFlagship;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Starting Fleet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose which ships you begin the game with.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Mode selector ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<_FleetMode>(
                segments: const [
                  ButtonSegment(
                    value: _FleetMode.preset,
                    label: Text('Preset'),
                    icon: Icon(Icons.list_alt, size: 18),
                  ),
                  ButtonSegment(
                    value: _FleetMode.custom,
                    label: Text('Custom'),
                    icon: Icon(Icons.tune, size: 18),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 12),

            // ── Body: preset list OR custom counters ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _mode == _FleetMode.preset
                    ? _buildPresetList(theme)
                    : _buildCustomList(theme),
              ),
            ),

            const Divider(height: 1),

            // ── Actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_activePreset),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preset list ──

  Widget _buildPresetList(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PresetCard(
          title: 'Standard Start',
          subtitle: '4 Scouts, 3 Colony Ships, 3 Miners, 2 Shipyards',
          selected: _selectedPreset == 0,
          onTap: () => setState(() => _selectedPreset = 0),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _PresetCard(
          title: 'Standard + Flagship',
          subtitle: 'Standard fleet plus 1 Flagship',
          selected: _selectedPreset == 1,
          onTap: () => setState(() => _selectedPreset = 1),
          theme: theme,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Custom list ──

  Widget _buildCustomList(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final shipType in _startingShipTypes)
          _QuantityRow(
            shipType: shipType,
            count: _customCounts[shipType] ?? 0,
            onChanged: (v) => setState(() => _customCounts[shipType] = v),
            theme: theme,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Preset card
// -----------------------------------------------------------------------------

class _PresetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _PresetCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.dividerColor,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 22,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Quantity row for custom mode
// -----------------------------------------------------------------------------

class _QuantityRow extends StatelessWidget {
  final ShipType shipType;
  final int count;
  final ValueChanged<int> onChanged;
  final ThemeData theme;

  const _QuantityRow({
    required this.shipType,
    required this.count,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final def = kShipDefinitions[shipType];
    final name = def?.name ?? shipType.name;
    final maxCounters = def?.maxCounters ?? 0;
    // For types with counters on the sheet, cap at that number.
    // For types without counters (maxCounters == 0), allow a reasonable max.
    final max = maxCounters > 0 ? maxCounters : 10;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              def?.abbreviation ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            splashRadius: 18,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: count > 0
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
          IconButton(
            onPressed: count < max ? () => onChanged(count + 1) : null,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper: apply a fleet preset to existing counters
// -----------------------------------------------------------------------------

/// Takes the full counter list from the game state and, for each ship type in
/// [preset], marks the first N unbuilt counters of that type as built with
/// starting tech (Att:0, Def:0, Tac:0, Mov:1).
///
/// Ship types with `maxCounters: 0` in [kShipDefinitions] (Colony Ship, Miner,
/// Shipyard, Decoy) have no counters on the sheet, so they are skipped.
/// The preset still includes them for informational purposes.
List<ShipCounter> applyFleetPreset(
  List<ShipCounter> allCounters,
  Map<ShipType, int> preset,
  TechState startingTech,
  bool facilitiesMode,
) {
  final result = List<ShipCounter>.from(allCounters);

  for (final entry in preset.entries) {
    final shipType = entry.key;
    final wantCount = entry.value;

    // Skip types that have no counters on the sheet.
    final def = kShipDefinitions[shipType];
    if (def == null || def.maxCounters == 0) continue;

    int built = 0;
    for (int i = 0; i < result.length && built < wantCount; i++) {
      if (result[i].type == shipType && !result[i].isBuilt) {
        result[i] = ShipCounter.stampFromTech(
          shipType,
          result[i].number,
          startingTech,
          facilitiesMode: facilitiesMode,
        );
        built++;
      }
    }
  }

  return result;
}
