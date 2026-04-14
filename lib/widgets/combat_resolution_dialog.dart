// PP14 Combat Outcome Wizard. Let the player resolve a whole battle in one
// dialog: tick destroyed ships per fleet, optionally pick a retreat
// destination per friendly fleet, optionally leave a log note. Returns a
// [CombatResolution] that the caller applies via
// `applyCombatResolution` (see lib/util/combat_resolution.dart).

import 'package:flutter/material.dart';

import '../data/ship_definitions.dart';
import '../models/map_state.dart';
import '../models/ship_counter.dart';
import '../util/combat_resolution.dart';

/// Show the combat outcome wizard for [hex]. Returns null if the user
/// cancels. On apply, returns a [CombatResolution] which the caller must
/// pass to `applyCombatResolution` (or the `_resolveCombat` helper on
/// `_HomePageState`).
Future<CombatResolution?> showCombatResolutionDialog(
  BuildContext context, {
  required HexCoord hex,
  required List<FleetStackState> fleetsAtHex,
  required List<ShipCounter> shipCounters,
  required GameMapState mapState,
  required int playerMoveLevel,
}) {
  return showDialog<CombatResolution>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CombatResolutionDialog(
      hex: hex,
      fleetsAtHex: fleetsAtHex,
      shipCounters: shipCounters,
      mapState: mapState,
      playerMoveLevel: playerMoveLevel,
    ),
  );
}

class _CombatResolutionDialog extends StatefulWidget {
  final HexCoord hex;
  final List<FleetStackState> fleetsAtHex;
  final List<ShipCounter> shipCounters;
  final GameMapState mapState;
  final int playerMoveLevel;

  const _CombatResolutionDialog({
    required this.hex,
    required this.fleetsAtHex,
    required this.shipCounters,
    required this.mapState,
    required this.playerMoveLevel,
  });

  @override
  State<_CombatResolutionDialog> createState() =>
      _CombatResolutionDialogState();
}

class _CombatResolutionDialogState extends State<_CombatResolutionDialog> {
  final Set<String> _destroyed = <String>{};
  final Map<String, HexCoord?> _retreats = <String, HexCoord?>{};
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  ShipCounter? _counterById(String id) {
    for (final c in widget.shipCounters) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool get _canApply => _destroyed.isNotEmpty ||
      _retreats.values.any((v) => v != null) ||
      _noteCtrl.text.trim().isNotEmpty;

  CombatResolution _buildResolution() {
    final retreats = <String, HexCoord>{};
    _retreats.forEach((fleetId, dest) {
      if (dest != null) retreats[fleetId] = dest;
    });
    final note = _noteCtrl.text.trim();
    return CombatResolution(
      destroyedShipCounterIds: _destroyed.toList(),
      retreats: retreats,
      combatLogNote: note.isEmpty ? null : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendlyFleets =
        widget.fleetsAtHex.where((f) => f.isFriendly).toList();

    return AlertDialog(
      title: Text('Resolve Combat — Hex ${widget.hex.id}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Combat log note (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.fleetsAtHex.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'No fleets in this hex.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                for (final fleet in widget.fleetsAtHex)
                  _FleetSection(
                    fleet: fleet,
                    counterById: _counterById,
                    destroyed: _destroyed,
                    isRetreatable:
                        fleet.isFriendly && friendlyFleets.contains(fleet),
                    mapState: widget.mapState,
                    playerMoveLevel: widget.playerMoveLevel,
                    shipCounters: widget.shipCounters,
                    currentRetreat: _retreats[fleet.id],
                    onToggleDestroyed: (id, v) {
                      setState(() {
                        if (v) {
                          _destroyed.add(id);
                        } else {
                          _destroyed.remove(id);
                        }
                      });
                    },
                    onRetreatChanged: (dest) {
                      setState(() {
                        _retreats[fleet.id] = dest;
                      });
                    },
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Tooltip(
          message: _canApply
              ? ''
              : 'Mark ships destroyed, set a retreat, or write a note',
          child: FilledButton(
            onPressed:
                _canApply ? () => Navigator.of(context).pop(_buildResolution()) : null,
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}

class _FleetSection extends StatelessWidget {
  final FleetStackState fleet;
  final ShipCounter? Function(String id) counterById;
  final Set<String> destroyed;
  final bool isRetreatable;
  final GameMapState mapState;
  final int playerMoveLevel;
  final List<ShipCounter> shipCounters;
  final HexCoord? currentRetreat;
  final void Function(String shipId, bool destroyed) onToggleDestroyed;
  final ValueChanged<HexCoord?> onRetreatChanged;

  const _FleetSection({
    required this.fleet,
    required this.counterById,
    required this.destroyed,
    required this.isRetreatable,
    required this.mapState,
    required this.playerMoveLevel,
    required this.shipCounters,
    required this.currentRetreat,
    required this.onToggleDestroyed,
    required this.onRetreatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerParts = <String>[];
    if (fleet.owner.isNotEmpty) headerParts.add(fleet.owner);
    if (fleet.label.isNotEmpty) headerParts.add(fleet.label);
    if (headerParts.isEmpty) {
      headerParts.add(fleet.isEnemy ? 'Enemy fleet' : 'Fleet');
    }
    final header = headerParts.join(' — ');
    final shipCount = fleet.shipCounterIds.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
        color: fleet.isEnemy
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fleet.isEnemy ? Icons.visibility_off : Icons.directions_boat,
                size: 16,
                color: fleet.isEnemy
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  header,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$shipCount ship${shipCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (fleet.isEnemy && fleet.shipCounterIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Enemy fleet has no tracked counters. Tick to eliminate.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (final shipId in fleet.shipCounterIds)
            _buildShipRow(context, shipId),
          if (isRetreatable) ...[
            const SizedBox(height: 6),
            _buildRetreatDropdown(context),
          ],
        ],
      ),
    );
  }

  Widget _buildShipRow(BuildContext context, String shipId) {
    final theme = Theme.of(context);
    final counter = counterById(shipId);
    final abbr = counter == null
        ? shipId
        : (kShipDefinitions[counter.type]?.abbreviation ?? counter.type.name);
    final stats = counter == null
        ? ''
        : 'A${counter.attack}/D${counter.defense}';
    final isDestroyed = destroyed.contains(shipId);
    return InkWell(
      onTap: () => onToggleDestroyed(shipId, !isDestroyed),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isDestroyed,
                onChanged: (v) => onToggleDestroyed(shipId, v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              abbr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shipId,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (stats.isNotEmpty)
              Text(stats, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRetreatDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final allowance = mapState.fleetMoveAllowance(
      fleet,
      shipCounters,
      playerMoveLevel,
    );
    final reachable = mapState.reachableHexes(fleet, allowance).toList()
      ..sort((a, b) {
        final r = a.r.compareTo(b.r);
        return r != 0 ? r : a.q.compareTo(b.q);
      });

    return Row(
      children: [
        Icon(
          Icons.arrow_outward,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 6),
        Text('Retreat to:', style: theme.textTheme.bodySmall),
        const SizedBox(width: 8),
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<HexCoord?>(
                value: currentRetreat,
                isDense: true,
                isExpanded: true,
                items: <DropdownMenuItem<HexCoord?>>[
                  const DropdownMenuItem<HexCoord?>(
                    value: null,
                    child: Text('Stay'),
                  ),
                  for (final coord in reachable)
                    DropdownMenuItem<HexCoord?>(
                      value: coord,
                      child: Text('Hex ${coord.id}'),
                    ),
                ],
                onChanged: (v) => onRetreatChanged(v),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
