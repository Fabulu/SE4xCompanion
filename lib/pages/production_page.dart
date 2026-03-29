import 'package:flutter/material.dart';

import '../data/tech_costs.dart';
import '../models/game_config.dart';
import '../models/production_state.dart';
import '../models/ship_counter.dart';
import '../models/world.dart';
import '../widgets/ledger_grid.dart';
import '../widgets/number_input.dart';
import '../widgets/section_header.dart';
import '../widgets/tech_tracker.dart';

// ---------------------------------------------------------------------------
// Human-readable tech names
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Production Page
// ---------------------------------------------------------------------------

class ProductionPage extends StatelessWidget {
  final GameConfig config;
  final int turnNumber;
  final ProductionState production;
  final List<ShipCounter> shipCounters;
  final ValueChanged<ProductionState> onProductionChanged;
  final VoidCallback onEndTurn;

  const ProductionPage({
    super.key,
    required this.config,
    required this.turnNumber,
    required this.production,
    required this.shipCounters,
    required this.onProductionChanged,
    required this.onEndTurn,
  });

  // ---- helpers ----

  void _update(ProductionState Function(ProductionState) mutate) {
    onProductionChanged(mutate(production));
  }

  void _updateWorld(int index, WorldState Function(WorldState) mutate) {
    final updated = List<WorldState>.from(production.worlds);
    updated[index] = mutate(updated[index]);
    onProductionChanged(production.copyWith(worlds: updated));
  }

  // ---- tech helpers ----

  /// Effective level of a tech accounting for pending purchases.
  int _effectiveLevel(TechId id) {
    final pending = production.pendingTechPurchases[id];
    if (pending != null) return pending;
    return production.techState.getLevel(
      id,
      facilitiesMode: config.useFacilitiesCosts,
    );
  }

  /// Number of pending buy levels for a tech this turn.
  int _pendingBuys(TechId id) {
    final pending = production.pendingTechPurchases[id];
    if (pending == null) return 0;
    final base = production.techState.getLevel(
      id,
      facilitiesMode: config.useFacilitiesCosts,
    );
    return pending - base;
  }

  /// Cost to buy the next level of a tech (from its effective level).
  int? _nextCost(TechId id) {
    final table =
        config.useFacilitiesCosts ? kFacilitiesTechCosts : kBaseTechCosts;
    final entry = table[id];
    if (entry == null) return null;
    return entry.costForNext(_effectiveLevel(id));
  }

  int _maxLevel(TechId id) {
    final table =
        config.useFacilitiesCosts ? kFacilitiesTechCosts : kBaseTechCosts;
    return table[id]?.maxLevel ?? 0;
  }

  /// Can afford the next tech level? Only one buy per tech per turn.
  bool _canAffordTech(TechId id) {
    // Only one buy per turn per tech.
    if (_pendingBuys(id) >= 1) return false;
    final cost = _nextCost(id);
    if (cost == null) return false;

    if (config.enableFacilities) {
      // Uses RP
      final rpAvail = production.remainingRp(config);
      return rpAvail >= cost;
    } else {
      // Uses CP
      final cpAvail = production.remainingCp(config, shipCounters);
      return cpAvail >= cost;
    }
  }

  void _buyTech(TechId id) {
    final newLevel = _effectiveLevel(id) + 1;
    final pending = Map<TechId, int>.from(production.pendingTechPurchases);
    pending[id] = newLevel;
    onProductionChanged(production.copyWith(pendingTechPurchases: pending));
  }

  void _undoTech(TechId id) {
    final pending = Map<TechId, int>.from(production.pendingTechPurchases);
    pending.remove(id);
    onProductionChanged(production.copyWith(pendingTechPurchases: pending));
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        // Turn header
        _buildTurnHeader(theme),
        const SizedBox(height: 4),

        // Ledger sections
        if (config.enableFacilities) ...[
          _buildLpLedger(),
          const SizedBox(height: 8),
          _buildCpLedgerFacilities(),
          const SizedBox(height: 8),
          _buildRpLedger(),
          if (config.enableTemporal) ...[
            const SizedBox(height: 8),
            _buildTpLedger(),
          ],
        ] else ...[
          _buildCpLedgerBase(),
        ],

        const SizedBox(height: 8),

        // Technology
        _buildTechSection(context),

        const SizedBox(height: 8),

        // Worlds
        _buildWorldsSection(context),

        const SizedBox(height: 16),

        // End Turn
        _buildEndTurnButton(context),

        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // Turn header
  // ===========================================================================

  Widget _buildTurnHeader(ThemeData theme) {
    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'TURN $turnNumber',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ECONOMIC PHASE',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Base-mode CP ledger
  // ===========================================================================

  Widget _buildCpLedgerBase() {
    final maint = production.maintenanceTotal(shipCounters);
    final colonyCp = production.colonyCp(config);
    final mineralCp = production.mineralCp();
    final pipelineCp = production.pipelineCp();
    final totalCp = production.totalCp(config);
    final subtotal = production.subtotalCp(config, shipCounters);
    final techSpending = production.techSpendingCpDerived(config);
    final remaining = production.remainingCp(config, shipCounters);

    return LedgerGrid(
      title: 'CP LEDGER',
      rows: [
        LedgerRow(
          label: 'CP carry over from last turn',
          value: production.cpCarryOver,
          isEditable: true,
          min: 0,
          max: 30,
          onChanged: (v) => _update((s) => s.copyWith(cpCarryOver: v)),
        ),
        LedgerRow(label: '+ Colony CPs', computedValue: colonyCp),
        LedgerRow(label: '+ Mineral CPs', computedValue: mineralCp),
        LedgerRow(label: '+ MS Pipeline CPs', computedValue: pipelineCp),
        LedgerRow(label: 'TOTAL', computedValue: totalCp, isTotal: true),
        LedgerRow(label: '- Maintenance', computedValue: maint),
        LedgerRow(
          label: '- Turn order bid',
          value: production.turnOrderBid,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(turnOrderBid: v)),
        ),
        LedgerRow(
          label: 'SUBTOTAL',
          computedValue: subtotal,
          isSubtotal: true,
        ),
        LedgerRow(label: '- Technology Spending', computedValue: techSpending),
        LedgerRow(
          label: '- Ship Spending',
          value: production.shipSpendingCp,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(shipSpendingCp: v)),
        ),
        LedgerRow(
          label: 'REMAINING CP',
          computedValue: remaining,
          isTotal: true,
        ),
        LedgerRow(
          label: '- CP spent on upgrades',
          value: production.upgradesCp,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(upgradesCp: v)),
        ),
        LedgerRow(
          label: 'Maintenance Inc (buys)',
          value: production.maintenanceIncrease,
          isEditable: true,
          min: 0,
          onChanged: (v) =>
              _update((s) => s.copyWith(maintenanceIncrease: v)),
        ),
        LedgerRow(
          label: 'Maintenance Dec (losses)',
          value: production.maintenanceDecrease,
          isEditable: true,
          min: 0,
          onChanged: (v) =>
              _update((s) => s.copyWith(maintenanceDecrease: v)),
        ),
      ],
    );
  }

  // ===========================================================================
  // Facilities-mode LP ledger
  // ===========================================================================

  Widget _buildLpLedger() {
    final colonyLp = production.colonyLp(config);
    final maint = production.maintenanceTotal(shipCounters);
    final remainingLp = production.remainingLp(config, shipCounters);

    return LedgerGrid(
      title: 'LP LEDGER',
      rows: [
        LedgerRow(
          label: 'LP carry over',
          value: production.lpCarryOver,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(lpCarryOver: v)),
        ),
        LedgerRow(label: '+ Colony/Facility LP', computedValue: colonyLp),
        LedgerRow(label: '- Maintenance', computedValue: maint),
        LedgerRow(
          label: '- LP placed on LC colonies',
          value: production.lpPlacedOnLc,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(lpPlacedOnLc: v)),
        ),
        LedgerRow(
          label: 'REMAINING LP (unlimited)',
          computedValue: remainingLp,
          isTotal: true,
        ),
      ],
    );
  }

  // ===========================================================================
  // Facilities-mode CP ledger
  // ===========================================================================

  Widget _buildCpLedgerFacilities() {
    final colonyCp = production.colonyCp(config);
    final mineralCp = production.mineralCp();
    final pipelineCp = production.pipelineCp();
    final totalCp = production.totalCp(config);
    final penaltyLp = production.penaltyLp(config, shipCounters);
    final subtotal = production.subtotalCp(config, shipCounters);
    final remaining = production.remainingCp(config, shipCounters);

    return LedgerGrid(
      title: 'CP LEDGER',
      rows: [
        LedgerRow(
          label: 'CP carry over',
          value: production.cpCarryOver,
          isEditable: true,
          min: 0,
          max: 30,
          onChanged: (v) => _update((s) => s.copyWith(cpCarryOver: v)),
        ),
        LedgerRow(label: '+ Colony/Facility CP', computedValue: colonyCp),
        LedgerRow(
            label: '+ Mineral/Resource Card CP', computedValue: mineralCp),
        LedgerRow(label: '+ MS Pipeline CP', computedValue: pipelineCp),
        LedgerRow(label: 'TOTAL CP', computedValue: totalCp, isTotal: true),
        if (penaltyLp > 0)
          LedgerRow(label: '- 3x Penalty LP', computedValue: penaltyLp),
        LedgerRow(
          label: '- Turn order bid',
          value: production.turnOrderBid,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(turnOrderBid: v)),
        ),
        LedgerRow(
          label: 'SUBTOTAL',
          computedValue: subtotal,
          isSubtotal: true,
        ),
        LedgerRow(
          label: '- Purchases (Ship Spending)',
          value: production.shipSpendingCp,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(shipSpendingCp: v)),
        ),
        LedgerRow(
          label: 'REMAINING CP (30 Max)',
          computedValue: remaining,
          isTotal: true,
        ),
        LedgerRow(
          label: '- CP spent on upgrades',
          value: production.upgradesCp,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(upgradesCp: v)),
        ),
      ],
    );
  }

  // ===========================================================================
  // Facilities-mode RP ledger
  // ===========================================================================

  Widget _buildRpLedger() {
    final colonyRp = production.colonyRp(config);
    final techSpending = production.techSpendingRpDerived(config);
    final remainingRp = production.remainingRp(config);

    return LedgerGrid(
      title: 'RP LEDGER',
      rows: [
        LedgerRow(
          label: 'RP carry over',
          value: production.rpCarryOver,
          isEditable: true,
          min: 0,
          max: 30,
          onChanged: (v) => _update((s) => s.copyWith(rpCarryOver: v)),
        ),
        LedgerRow(label: '+ Colony/Facility RP', computedValue: colonyRp),
        LedgerRow(label: '- Technology Spending', computedValue: techSpending),
        LedgerRow(
          label: 'REMAINING RP (30 Max)',
          computedValue: remainingRp,
          isTotal: true,
        ),
      ],
    );
  }

  // ===========================================================================
  // Facilities-mode TP ledger
  // ===========================================================================

  Widget _buildTpLedger() {
    final colonyTp = production.colonyTp(config);
    final remainingTp = production.remainingTp(config);

    return LedgerGrid(
      title: 'TP LEDGER',
      rows: [
        LedgerRow(
          label: 'TP carry over',
          value: production.tpCarryOver,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(tpCarryOver: v)),
        ),
        LedgerRow(label: '+ Colony/Facility TP', computedValue: colonyTp),
        LedgerRow(
          label: '- TP Spending',
          value: production.tpSpending,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(tpSpending: v)),
        ),
        LedgerRow(
          label: 'REMAINING TP (unlimited)',
          computedValue: remainingTp,
          isTotal: true,
        ),
      ],
    );
  }

  // ===========================================================================
  // Technology section
  // ===========================================================================

  Widget _buildTechSection(BuildContext context) {
    final techs = visibleTechs(
      facilitiesMode: config.enableFacilities,
      closeEncountersOwned: config.ownership.closeEncounters,
      replicatorsEnabled: config.enableReplicators,
      advancedConEnabled: config.enableAdvancedConstruction,
    );

    final costLabel = config.enableFacilities ? 'RP' : 'CP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: 'TECHNOLOGY PROGRESSION',
          subtitle: 'costs in $costLabel',
        ),
        const SizedBox(height: 2),
        for (final id in techs) _buildTechRow(id),
      ],
    );
  }

  Widget _buildTechRow(TechId id) {
    final effectiveLevel = _effectiveLevel(id);
    final startLevel = (config.useFacilitiesCosts
            ? kFacilitiesTechCosts
            : kBaseTechCosts)[id]
        ?.startLevel ??
        0;
    final maxLevel = _maxLevel(id);
    final nextCost = _nextCost(id);
    final pending = _pendingBuys(id);
    final canAfford = _canAffordTech(id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TechRow(
        name: _techDisplayNames[id] ?? id.name,
        currentLevel: effectiveLevel,
        startLevel: startLevel,
        maxLevel: maxLevel,
        nextCost: nextCost,
        pendingBuys: pending,
        canAfford: canAfford,
        onBuy: canAfford ? () => _buyTech(id) : null,
        onUndo: pending > 0 ? () => _undoTech(id) : null,
      ),
    );
  }

  // ===========================================================================
  // Worlds section
  // ===========================================================================

  Widget _buildWorldsSection(BuildContext context) {
    final theme = Theme.of(context);
    final worlds = production.worlds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'WORLDS'),
        const SizedBox(height: 2),
        for (int i = 0; i < worlds.length; i++)
          worlds[i].isHomeworld
              ? _buildHomeworldRow(i, worlds[i], theme)
              : _buildColonyRow(i, worlds[i], theme),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addColony(),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Colony', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworldRow(int index, WorldState world, ThemeData theme) {
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          const SizedBox(width: 4),
          Text('Homeworld', style: labelStyle),
          const Spacer(),
          // Value selector: 5/10/15/20/25/30
          NumberInput(
            value: world.homeworldValue,
            onChanged: (v) =>
                _updateWorld(index, (w) => w.copyWith(homeworldValue: v)),
            min: 5,
            max: 30,
            step: 5,
          ),
          if (config.enableFacilities) ...[
            const SizedBox(width: 8),
            _FacilityChip(
              facility: world.facility,
              onChanged: (f) => _updateWorld(
                index,
                (w) => f == null
                    ? w.copyWith(clearFacility: true)
                    : w.copyWith(facility: f),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColonyRow(int index, WorldState world, ThemeData theme) {
    final labelStyle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface,
    );
    final dimStyle = TextStyle(
      fontSize: 11,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
    final growthCp = world.cpValue;
    final growthLabel = '${world.growthMarkerLevel}/3 (${growthCp}CP)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            const SizedBox(width: 4),
            // Colony name
            SizedBox(
              width: 64,
              child: Text(
                world.name,
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Growth marker
            Text(growthLabel, style: dimStyle),
            const Spacer(),
            // Blocked toggle
            _CompactToggle(
              label: 'BLK',
              value: world.isBlocked,
              onChanged: (v) =>
                  _updateWorld(index, (w) => w.copyWith(isBlocked: v)),
            ),
            if (config.enableFacilities) ...[
              const SizedBox(width: 4),
              _FacilityChip(
                facility: world.facility,
                onChanged: (f) => _updateWorld(
                  index,
                  (w) => f == null
                      ? w.copyWith(clearFacility: true)
                      : w.copyWith(facility: f),
                ),
              ),
            ],
            const SizedBox(width: 4),
            // Mineral income
            SizedBox(
              width: 68,
              child: NumberInput(
                value: world.mineralIncome,
                onChanged: (v) =>
                    _updateWorld(index, (w) => w.copyWith(mineralIncome: v)),
                min: 0,
                label: 'M',
              ),
            ),
            const SizedBox(width: 2),
            // Pipeline income
            SizedBox(
              width: 68,
              child: NumberInput(
                value: world.pipelineIncome,
                onChanged: (v) =>
                    _updateWorld(index, (w) => w.copyWith(pipelineIncome: v)),
                min: 0,
                label: 'P',
              ),
            ),
            // Delete colony button
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 14,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.error.withValues(alpha: 0.6),
                ),
                onPressed: () => _removeColony(index),
                splashRadius: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addColony() {
    final colonies =
        production.worlds.where((w) => !w.isHomeworld).toList();
    final nextNum = colonies.length + 1;
    final updated = List<WorldState>.from(production.worlds)
      ..add(WorldState(name: 'Colony $nextNum'));
    onProductionChanged(production.copyWith(worlds: updated));
  }

  void _removeColony(int index) {
    final updated = List<WorldState>.from(production.worlds)..removeAt(index);
    onProductionChanged(production.copyWith(worlds: updated));
  }

  // ===========================================================================
  // End Turn button
  // ===========================================================================

  Widget _buildEndTurnButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: () => _confirmEndTurn(context),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: const Text('END TURN', style: TextStyle(fontSize: 13)),
      ),
    );
  }

  void _confirmEndTurn(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Turn?'),
        content: Text(
          'Finalize turn $turnNumber and advance to turn ${turnNumber + 1}.\n'
          'Pending tech purchases will be applied, colonies will grow, '
          'and carry-overs will be computed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        onEndTurn();
      }
    });
  }
}

// =============================================================================
// Small helper widgets
// =============================================================================

/// Compact on/off toggle that shows a short label.
class _CompactToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = value
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(3),
          color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Compact facility selector chip. Tap to cycle through facility types, or
/// tap again on the active one to clear.
class _FacilityChip extends StatelessWidget {
  final FacilityType? facility;
  final ValueChanged<FacilityType?> onChanged;

  const _FacilityChip({
    required this.facility,
    required this.onChanged,
  });

  static const _abbrev = {
    FacilityType.industrial: 'IC',
    FacilityType.research: 'RC',
    FacilityType.logistics: 'LC',
    FacilityType.temporal: 'TC',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = facility != null ? _abbrev[facility]! : '--';
    final active = facility != null;

    return GestureDetector(
      onTap: _cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(3),
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  void _cycle() {
    const order = [null, ...FacilityType.values];
    final idx = order.indexOf(facility);
    final next = order[(idx + 1) % order.length];
    onChanged(next);
  }
}
