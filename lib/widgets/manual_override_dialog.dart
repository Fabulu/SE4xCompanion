import 'package:flutter/material.dart';

import '../data/tech_costs.dart';
import '../models/game_state.dart';
import '../models/technology.dart';
import 'number_input.dart';
import 'section_header.dart';

/// Human-readable tech names (mirrors production_page.dart).
const Map<TechId, String> _techDisplayNames = {
  TechId.shipSize: 'Ship Size',
  TechId.attack: 'Attack',
  TechId.defense: 'Defense',
  TechId.tactics: 'Tactics',
  TechId.move: 'Movement',
  TechId.shipYard: 'Ship Yard',
  TechId.terraforming: 'Terraform',
  TechId.exploration: 'Exploration',
  TechId.fighters: 'Fighters',
  TechId.pointDefense: 'Point Def',
  TechId.cloaking: 'Cloaking',
  TechId.scanners: 'Scanners',
  TechId.mines: 'Mines',
  TechId.mineSweep: 'Mine Sweep',
  TechId.supplyRange: 'Supply',
  TechId.ground: 'Ground',
  TechId.advancedCon: 'Adv Constr',
  TechId.antiReplicator: 'Anti-Repl',
  TechId.militaryAcad: 'Mil Acad',
  TechId.boarding: 'Boarding',
  TechId.securityForces: 'Security',
  TechId.missileBoats: 'Missiles',
  TechId.jammers: 'Jammers',
  TechId.fastBcAbility: 'Fast BC',
  TechId.tractorBeamBb: 'Tractor BB',
  TechId.shieldProjDn: 'Shield DN',
};

/// Shows a dialog that lets the player manually override any game value.
///
/// Returns a modified [GameState] if the user taps "Apply", or null on cancel.
Future<GameState?> showManualOverrideDialog(
  BuildContext context,
  GameState gameState,
) {
  return showDialog<GameState>(
    context: context,
    builder: (ctx) => _ManualOverrideDialog(gameState: gameState),
  );
}

class _ManualOverrideDialog extends StatefulWidget {
  final GameState gameState;

  const _ManualOverrideDialog({required this.gameState});

  @override
  State<_ManualOverrideDialog> createState() => _ManualOverrideDialogState();
}

class _ManualOverrideDialogState extends State<_ManualOverrideDialog> {
  late int _cpCarryOver;
  late int _lpCarryOver;
  late int _rpCarryOver;
  late int _tpCarryOver;
  late int _turnOrderBid;
  late int _shipSpendingCp;
  late int _upgradesCp;
  late int _maintenanceIncrease;
  late int _maintenanceDecrease;
  late int _researchGrantsCp;
  late int _turnNumber;
  late Map<TechId, int> _techLevels;

  @override
  void initState() {
    super.initState();
    final prod = widget.gameState.production;
    _cpCarryOver = prod.cpCarryOver;
    _lpCarryOver = prod.lpCarryOver;
    _rpCarryOver = prod.rpCarryOver;
    _tpCarryOver = prod.tpCarryOver;
    _turnOrderBid = prod.turnOrderBid;
    _shipSpendingCp = prod.shipSpendingCp;
    _upgradesCp = prod.upgradesCp;
    _maintenanceIncrease = prod.maintenanceIncrease;
    _maintenanceDecrease = prod.maintenanceDecrease;
    _researchGrantsCp = prod.researchGrantsCp;
    _turnNumber = widget.gameState.turnNumber;

    // Snapshot current tech levels.
    final fm = widget.gameState.config.useFacilitiesCosts;
    _techLevels = {};
    for (final id in _visibleTechs()) {
      _techLevels[id] = prod.techState.getLevel(id, facilitiesMode: fm);
    }
  }

  List<TechId> _visibleTechs() {
    final config = widget.gameState.config;
    return visibleTechs(
      facilitiesMode: config.enableFacilities,
      closeEncountersOwned: config.ownership.closeEncounters,
      replicatorsEnabled: config.enableReplicators,
      advancedConEnabled: config.enableAdvancedConstruction,
    );
  }

  int _maxLevel(TechId id) {
    final fm = widget.gameState.config.useFacilitiesCosts;
    return widget.gameState.production.techState
        .maxLevel(id, facilitiesMode: fm);
  }

  GameState _buildResult() {
    // Apply tech level changes.
    TechState newTech = widget.gameState.production.techState;
    for (final entry in _techLevels.entries) {
      newTech = newTech.setLevel(entry.key, entry.value);
    }

    final newProd = widget.gameState.production.copyWith(
      cpCarryOver: _cpCarryOver,
      lpCarryOver: _lpCarryOver,
      rpCarryOver: _rpCarryOver,
      tpCarryOver: _tpCarryOver,
      turnOrderBid: _turnOrderBid,
      shipSpendingCp: _shipSpendingCp,
      upgradesCp: _upgradesCp,
      maintenanceIncrease: _maintenanceIncrease,
      maintenanceDecrease: _maintenanceDecrease,
      researchGrantsCp: _researchGrantsCp,
      techState: newTech,
    );

    return widget.gameState.copyWith(
      turnNumber: _turnNumber,
      production: newProd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techs = _visibleTechs();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.build, size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Manual Override',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Warning text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Manually override any game value. Use for card effects, '
                'house rules, or corrections.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),

            const Divider(height: 1),

            // Scrollable content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shrinkWrap: true,
                children: [
                  // --- Resources ---
                  const SectionHeader(title: 'Resources'),
                  const SizedBox(height: 4),
                  _row('CP Carry Over', _cpCarryOver, 0, 999, (v) => setState(() => _cpCarryOver = v)),
                  _row('LP Carry Over', _lpCarryOver, 0, 999, (v) => setState(() => _lpCarryOver = v)),
                  _row('RP Carry Over', _rpCarryOver, 0, 999, (v) => setState(() => _rpCarryOver = v)),
                  _row('TP Carry Over', _tpCarryOver, 0, 999, (v) => setState(() => _tpCarryOver = v)),
                  _row('Turn Order Bid', _turnOrderBid, 0, 999, (v) => setState(() => _turnOrderBid = v)),
                  _row('Ship Spending CP', _shipSpendingCp, 0, 999, (v) => setState(() => _shipSpendingCp = v)),
                  _row('Upgrades CP', _upgradesCp, 0, 999, (v) => setState(() => _upgradesCp = v)),
                  _row('Maintenance Increase', _maintenanceIncrease, 0, 999, (v) => setState(() => _maintenanceIncrease = v)),
                  _row('Maintenance Decrease', _maintenanceDecrease, 0, 999, (v) => setState(() => _maintenanceDecrease = v)),
                  _row('Research Grants CP', _researchGrantsCp, 0, 999, (v) => setState(() => _researchGrantsCp = v)),

                  const SizedBox(height: 12),

                  // --- Technology Levels ---
                  const SectionHeader(title: 'Technology Levels'),
                  const SizedBox(height: 4),
                  for (final id in techs)
                    _row(
                      _techDisplayNames[id] ?? id.name,
                      _techLevels[id] ?? 0,
                      0,
                      _maxLevel(id),
                      (v) => setState(() => _techLevels[id] = v),
                    ),

                  const SizedBox(height: 12),

                  // --- Turn ---
                  const SectionHeader(title: 'Turn'),
                  const SizedBox(height: 4),
                  _row('Turn Number', _turnNumber, 1, 99, (v) => setState(() => _turnNumber = v)),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            const Divider(height: 1),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_buildResult()),
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

  /// A dense row: label on left, NumberInput on right.
  Widget _row(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          NumberInput(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
