import 'dart:async';
import 'package:flutter/material.dart';

import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/game_config.dart';
import '../models/game_modifier.dart';
import '../models/game_state.dart';
import '../models/production_state.dart';
import '../models/ship_counter.dart';
import '../models/world.dart';
import '../widgets/ledger_grid.dart';
import '../widgets/number_input.dart';
import '../widgets/research_grant_dialog.dart';
import '../widgets/section_header.dart';
import '../widgets/ship_info_dialog.dart';
import '../widgets/manual_override_dialog.dart';
import '../widgets/tech_detail_dialog.dart';
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
// Ship build validation (Task 2)
// ---------------------------------------------------------------------------

/// Returns true if the player has the required tech to build [type].
/// Uses effective tech levels (including pending purchases this turn).
bool canBuildShip(
  ShipType type,
  int Function(TechId) effectiveLevel,
  GameConfig config,
  List<ShipPurchase> existingPurchases,
) {
  final def = kShipDefinitions[type];
  if (def == null) return false;

  final shipSize = effectiveLevel(TechId.shipSize);

  final isAlt = config.enableAlternateEmpire;

  switch (type) {
    // Flagships: free, unique, only 1 ever
    case ShipType.flag:
      // Can only have one flagship total
      final alreadyHave =
          existingPurchases.any((p) => p.type == ShipType.flag);
      return !alreadyHave;

    // Unique ships: skip for now (cost 0, special)
    case ShipType.un:
      return false;

    // Standard warships: require Ship Size >= hull size
    case ShipType.dd:
    case ShipType.ca:
    case ShipType.bc:
    case ShipType.bb:
    case ShipType.dn:
      return shipSize >= def.hullSize;

    // Titans: require Ship Size >= 4; blocked for alternate empire
    case ShipType.tn:
      if (isAlt) return false;
      return shipSize >= 4;

    // Fighters: require Fighters tech >= 1
    case ShipType.fighter:
      return effectiveLevel(TechId.fighters) >= 1;

    // Carriers: require Fighters tech >= 1; blocked for alternate empire
    case ShipType.cv:
      if (isAlt) return false;
      return effectiveLevel(TechId.fighters) >= 1;

    // Battle Carriers: require Advanced Construction >= 2 AND Fighters >= 1; blocked for alternate empire
    case ShipType.bv:
      if (isAlt) return false;
      return effectiveLevel(TechId.fighters) >= 1 &&
          effectiveLevel(TechId.advancedCon) >= 2;

    // Raiders: require Cloaking >= 1
    case ShipType.raider:
      return effectiveLevel(TechId.cloaking) >= 1;

    // Minesweepers: require Mine Sweep >= 1
    case ShipType.sw:
      return effectiveLevel(TechId.mineSweep) >= 1;

    // Boarding Ships / Missile Boats: require Boarding >= 1 OR Missile Boats >= 1
    // Alternate empire: also allow with just Missile Boats tech
    case ShipType.bdMb:
      return effectiveLevel(TechId.boarding) >= 1 ||
          effectiveLevel(TechId.missileBoats) >= 1;

    // Transports: require Ground tech >= 1
    case ShipType.transport:
      return effectiveLevel(TechId.ground) >= 1;

    // Mines: require Mines tech >= 1
    case ShipType.mine:
      return effectiveLevel(TechId.mines) >= 1;

    // Bases: require Ship Size >= 2
    case ShipType.base:
      return shipSize >= 2;

    // Starbases: require Advanced Construction >= 2
    case ShipType.starbase:
      return effectiveLevel(TechId.advancedCon) >= 2;

    // Always available: Colony Ships, Miners, MS Pipelines, Shipyards,
    // Decoys, Scouts, DSN
    case ShipType.colonyShip:
    case ShipType.miner:
    case ShipType.msPipeline:
    case ShipType.shipyard:
    case ShipType.decoy:
    case ShipType.scout:
    case ShipType.dsn:
      return true;
  }
}

// ---------------------------------------------------------------------------
// Production Page
// ---------------------------------------------------------------------------

class ProductionPage extends StatefulWidget {
  final GameConfig config;
  final int turnNumber;
  final ProductionState production;
  final List<ShipCounter> shipCounters;
  final List<GameModifier> activeModifiers;
  final ValueChanged<ProductionState> onProductionChanged;
  final VoidCallback onEndTurn;
  final void Function(String sectionId)? onRuleTap;
  final ValueChanged<GameState>? onGameStateOverride;

  const ProductionPage({
    super.key,
    required this.config,
    required this.turnNumber,
    required this.production,
    required this.shipCounters,
    this.activeModifiers = const [],
    required this.onProductionChanged,
    required this.onEndTurn,
    this.onRuleTap,
    this.onGameStateOverride,
  });

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage>
    with TickerProviderStateMixin {
  // ---- Animation: End Turn wiggle (Task 3A) ----
  late AnimationController _endTurnWiggleController;
  late Animation<double> _endTurnWiggle;
  Timer? _endTurnWiggleTimer;

  // ---- Animation: Ship purchase bounce (Task 3B) ----
  late AnimationController _shipBounceController;
  late Animation<double> _shipBounceScale;
  int? _lastBouncedIndex;

  // ---- Animation: Remaining CP pop (Task 3C) ----
  late AnimationController _cpPopController;
  late Animation<double> _cpPopScale;
  int? _prevRemainingCp;

  @override
  void initState() {
    super.initState();

    // End Turn wiggle: ±2 degrees over 400ms
    _endTurnWiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _endTurnWiggle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.035), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.035, end: -0.035), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.035, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _endTurnWiggleController,
      curve: Curves.easeInOut,
    ));
    _startWiggleTimer();

    // Ship bounce
    _shipBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shipBounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shipBounceController,
      curve: Curves.easeOut,
    ));

    // CP pop
    _cpPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _cpPopScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _cpPopController,
      curve: Curves.easeOut,
    ));

    _prevRemainingCp =
        widget.production.remainingCp(widget.config, widget.shipCounters, widget.activeModifiers);
  }

  @override
  void didUpdateWidget(ProductionPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Task 3C: pop on remaining CP change
    final newRemaining =
        widget.production.remainingCp(widget.config, widget.shipCounters, widget.activeModifiers);
    if (_prevRemainingCp != null && newRemaining != _prevRemainingCp) {
      _cpPopController.forward(from: 0);
    }
    _prevRemainingCp = newRemaining;

    // Task 3B: bounce on ship purchase added
    final oldCount = oldWidget.production.shipPurchases.length;
    final newCount = widget.production.shipPurchases.length;
    if (newCount > oldCount) {
      _lastBouncedIndex = newCount - 1;
      _shipBounceController.forward(from: 0);
    }
  }

  void _startWiggleTimer() {
    _endTurnWiggleTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted) {
          _endTurnWiggleController.forward(from: 0);
        }
      },
    );
  }

  @override
  void dispose() {
    _endTurnWiggleTimer?.cancel();
    _endTurnWiggleController.dispose();
    _shipBounceController.dispose();
    _cpPopController.dispose();
    super.dispose();
  }

  // ---- convenience accessors ----

  GameConfig get config => widget.config;
  ProductionState get production => widget.production;
  List<ShipCounter> get shipCounters => widget.shipCounters;
  List<GameModifier> get modifiers => widget.activeModifiers;

  // ---- helpers ----

  void _update(ProductionState Function(ProductionState) mutate) {
    widget.onProductionChanged(mutate(production));
  }

  void _updateWorld(int index, WorldState Function(WorldState) mutate) {
    final updated = List<WorldState>.from(production.worlds);
    updated[index] = mutate(updated[index]);
    widget.onProductionChanged(production.copyWith(worlds: updated));
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
  /// Applies EA techCostMultiplier (e.g. Gifted Scientists) if present.
  int? _nextCost(TechId id) {
    final table =
        config.useFacilitiesCosts ? kFacilitiesTechCosts : kBaseTechCosts;
    final entry = table[id];
    if (entry == null) return null;
    final baseCost = entry.costForNext(_effectiveLevel(id));
    if (baseCost == null) return null;
    final ea = config.empireAdvantage;
    if (ea != null && ea.techCostMultiplier != 1.0) {
      return (baseCost * ea.techCostMultiplier).floor();
    }
    return baseCost;
  }

  int _maxLevel(TechId id) {
    final table =
        config.useFacilitiesCosts ? kFacilitiesTechCosts : kBaseTechCosts;
    var max = table[id]?.maxLevel ?? 0;
    // Alternate empire: cap Fast BC at level 1 (no Fast 2)
    if (id == TechId.fastBcAbility && config.enableAlternateEmpire && max > 1) {
      max = 1;
    }
    return max;
  }

  /// Can afford the next tech level? Only one buy per tech per turn.
  bool _canAffordTech(TechId id) {
    // Only one buy per turn per tech.
    if (_pendingBuys(id) >= 1) return false;
    final cost = _nextCost(id);
    if (cost == null) return false;

    if (config.enableFacilities) {
      // Uses RP
      final rpAvail = production.remainingRp(config, modifiers);
      return rpAvail >= cost;
    } else {
      // Uses CP
      final cpAvail = production.remainingCp(config, shipCounters, modifiers);
      return cpAvail >= cost;
    }
  }

  void _buyTech(TechId id) {
    final newLevel = _effectiveLevel(id) + 1;
    final pending = Map<TechId, int>.from(production.pendingTechPurchases);
    pending[id] = newLevel;
    widget.onProductionChanged(
        production.copyWith(pendingTechPurchases: pending));
  }

  void _undoTech(TechId id) {
    final pending = Map<TechId, int>.from(production.pendingTechPurchases);
    pending.remove(id);
    widget.onProductionChanged(
        production.copyWith(pendingTechPurchases: pending));
  }

  // ---- unpredictable research helpers ----

  /// The next target level for research on a tech (accounts for pending).
  int _researchTargetLevel(TechId id) {
    return _effectiveLevel(id) + 1;
  }

  /// How many grants the player can afford (each grant = 5 CP).
  int _maxGrantsAffordable() {
    final remaining = production.remainingCp(config, shipCounters, modifiers);
    return (remaining / 5).floor().clamp(0, 999);
  }

  /// Build reassign targets: other non-maxed techs the player could assign to.
  List<ReassignTarget> _buildReassignTargets(TechId excludeId) {
    final fm = config.useFacilitiesCosts;
    final techs = visibleTechs(
      facilitiesMode: config.enableFacilities,
      closeEncountersOwned: config.ownership.closeEncounters,
      replicatorsEnabled: config.enableReplicators,
      advancedConEnabled: config.enableAdvancedConstruction,
    );
    final targets = <ReassignTarget>[];
    for (final tid in techs) {
      if (tid == excludeId) continue;
      final effectiveLevel = _effectiveLevel(tid);
      final maxLevel = _maxLevel(tid);
      if (effectiveLevel >= maxLevel) continue;
      final pending = _pendingBuys(tid);
      if (pending > 0) continue; // already has a breakthrough pending
      final tgtLevel = effectiveLevel + 1;
      final tgtCost = production.getResearchTarget(tid, tgtLevel, fm);
      if (tgtCost == null) continue;
      targets.add(ReassignTarget(
        techId: tid,
        name: _techDisplayNames[tid] ?? tid.name,
        targetLevel: tgtLevel,
        currentAccumulated: production.getAccumulated(tid, tgtLevel),
        targetCost: tgtCost,
      ));
    }
    return targets;
  }

  /// Fund research on a tech via the grant dialog.
  Future<void> _fundResearch(TechId id) async {
    final targetLevel = _researchTargetLevel(id);
    final fm = config.useFacilitiesCosts;
    final targetCost = production.getResearchTarget(id, targetLevel, fm);
    if (targetCost == null) return;

    final accumulated = production.getAccumulated(id, targetLevel);
    final maxGrants = _maxGrantsAffordable();
    if (maxGrants <= 0) return;

    final result = await showResearchGrantDialog(
      context: context,
      techId: id,
      techName: _techDisplayNames[id] ?? id.name,
      targetLevel: targetLevel,
      currentAccumulated: accumulated,
      targetCost: targetCost,
      maxGrantsAffordable: maxGrants,
      reassignTargets: _buildReassignTargets(id),
    );

    if (result == null || !mounted) return;

    final newAccumulated =
        Map<String, int>.from(production.accumulatedResearch);

    // If reassigned, the roll total goes to a different tech.
    final effectiveId = result.techId;
    final effectiveTargetLevel = result.targetLevel;
    final effectiveKey =
        ProductionState.researchKey(effectiveId, effectiveTargetLevel);
    final effectiveAccumulated =
        production.getAccumulated(effectiveId, effectiveTargetLevel);
    final newTotal = effectiveAccumulated + result.totalRolled;
    newAccumulated[effectiveKey] = newTotal;

    var newProduction = production.copyWith(
      accumulatedResearch: newAccumulated,
      researchGrantsCp: production.researchGrantsCp + result.cpSpent,
    );

    // If breakthrough: add to pending tech purchases and remove accumulated
    if (result.breakthroughAchieved) {
      final pending =
          Map<TechId, int>.from(newProduction.pendingTechPurchases);
      pending[effectiveId] = effectiveTargetLevel;
      final cleanAccumulated =
          Map<String, int>.from(newProduction.accumulatedResearch);
      cleanAccumulated.remove(effectiveKey);
      newProduction = newProduction.copyWith(
        pendingTechPurchases: pending,
        accumulatedResearch: cleanAccumulated,
      );
    }

    widget.onProductionChanged(newProduction);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // Turn header
        _buildTurnHeader(theme),
        const SizedBox(height: 8),

        // Carry-over warnings
        _buildCarryOverWarning(),

        // Ledger sections
        if (config.enableFacilities) ...[
          if (config.enableLogistics) ...[
            _buildLpLedger(),
            const SizedBox(height: 16),
          ],
          _buildCpLedgerFacilities(),
          const SizedBox(height: 16),
          _buildRpLedger(),
          if (config.enableTemporal) ...[
            const SizedBox(height: 16),
            _buildTpLedger(),
          ],
        ] else ...[
          _buildCpLedgerBase(),
        ],

        const SizedBox(height: 16),

        // Fleet Roster
        _buildFleetRoster(context),

        const SizedBox(height: 16),

        // Technology
        _buildTechSection(context),

        const SizedBox(height: 16),

        // Ship Purchases (Problem 4)
        _buildShipPurchaseSection(context),

        const SizedBox(height: 16),

        // Worlds
        _buildWorldsSection(context),

        const SizedBox(height: 20),

        // End Turn
        _buildEndTurnButton(context),

        const SizedBox(height: 16),
        _buildManualOverrideButton(context),

        const SizedBox(height: 32),
      ],
    );
  }

  // ===========================================================================
  // Turn header
  // ===========================================================================

  Widget _buildTurnHeader(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'TURN ${widget.turnNumber}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'ECONOMIC PHASE',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Carry-over warning banner
  // ===========================================================================

  Widget _buildCarryOverWarning() {
    final remainingCp = production.remainingCp(config, shipCounters, modifiers);
    final remainingRp =
        config.enableFacilities ? production.remainingRp(config, modifiers) : 0;
    final cpExcess = remainingCp - 30;
    final rpExcess = remainingRp - 30;

    final warnings = <Widget>[];

    if (cpExcess > 0) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$cpExcess CP will be lost at End Turn (carry-over cap is 30)',
                  style: const TextStyle(fontSize: 14, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (config.enableFacilities && rpExcess > 0) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$rpExcess RP will be lost at End Turn (carry-over cap is 30)',
                  style: const TextStyle(fontSize: 14, color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (warnings.isEmpty) return const SizedBox.shrink();
    return Column(children: warnings);
  }

  // ===========================================================================
  // Base-mode CP ledger
  // ===========================================================================

  Widget _buildCpLedgerBase() {
    final maint = production.maintenanceTotal(shipCounters, config, modifiers);
    final colonyCp = production.colonyCp(config);
    final mineralCp = production.mineralCp();
    final pipelineCp = production.pipelineCp();
    final totalCp = production.totalCp(config, modifiers);
    final subtotal = production.subtotalCp(config, shipCounters, modifiers);
    final techSpending = production.techSpendingCpDerived(config, modifiers);
    final shipSpending = production.effectiveShipSpending(config, modifiers);
    final remaining = production.remainingCp(config, shipCounters, modifiers);
    final unpredictable = config.enableUnpredictableResearch;

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
          trailing: _buildBidRevealButton(),
        ),
        LedgerRow(
          label: 'SUBTOTAL',
          computedValue: subtotal,
          isSubtotal: true,
        ),
        if (unpredictable)
          LedgerRow(label: '- Research Grants', computedValue: production.researchGrantsCp)
        else
          LedgerRow(label: '- Technology Spending', computedValue: techSpending),
        if (production.shipPurchases.isNotEmpty)
          LedgerRow(
              label: '- Ship Spending (purchases)',
              computedValue: shipSpending)
        else
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
          // Task 3C: animated remaining value
          trailingBuilder: (displayValue, valueStyle) =>
              _buildAnimatedRemainingCp(remaining, valueStyle),
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
    final maint = production.maintenanceTotal(shipCounters, config, modifiers);
    final remainingLp = production.remainingLp(config, shipCounters, modifiers);

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
    final totalCp = production.totalCp(config, modifiers);
    final penaltyLp = production.penaltyLp(config, shipCounters, modifiers);
    final subtotal = production.subtotalCp(config, shipCounters, modifiers);
    final shipSpending = production.effectiveShipSpending(config, modifiers);
    final remaining = production.remainingCp(config, shipCounters, modifiers);
    final unpredictable = config.enableUnpredictableResearch;

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
          trailing: _buildBidRevealButton(),
        ),
        LedgerRow(
          label: 'SUBTOTAL',
          computedValue: subtotal,
          isSubtotal: true,
        ),
        if (unpredictable)
          LedgerRow(label: '- Research Grants', computedValue: production.researchGrantsCp),
        if (production.shipPurchases.isNotEmpty)
          LedgerRow(
              label: '- Purchases (from list)',
              computedValue: shipSpending)
        else
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
          trailingBuilder: (displayValue, valueStyle) =>
              _buildAnimatedRemainingCp(remaining, valueStyle),
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
    final techSpending = production.techSpendingRpDerived(config, modifiers);
    final remainingRp = production.remainingRp(config, modifiers);

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
  // Bid reveal button & overlay (Task 1)
  // ===========================================================================

  Widget _buildBidRevealButton() {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 20,
        icon: const Icon(Icons.visibility),
        tooltip: 'Reveal bid',
        onPressed: () => _showBidReveal(context),
      ),
    );
  }

  void _showBidReveal(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return _BidRevealOverlay(
            bid: production.turnOrderBid,
            animation: animation,
          );
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  // ===========================================================================
  // Animated remaining CP (Task 3C + 3E)
  // ===========================================================================

  Widget _buildAnimatedRemainingCp(int remaining, TextStyle baseStyle) {
    final isNegative = remaining < 0;

    return AnimatedBuilder(
      animation: Listenable.merge([_cpPopController, if (isNegative) _cpPopController]),
      builder: (context, child) {
        return ScaleTransition(
          scale: _cpPopScale,
          child: isNegative
              ? _PulsingNegativeCp(value: remaining, baseStyle: baseStyle)
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    remaining.toString(),
                    style: baseStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
        );
      },
    );
  }

  // ===========================================================================
  // Fleet Roster
  // ===========================================================================

  Widget _buildFleetRoster(BuildContext context) {
    final theme = Theme.of(context);

    // Group built counters by type (only types with maxCounters > 0).
    final builtByType = <ShipType, int>{};
    for (final c in shipCounters) {
      if (!c.isBuilt) continue;
      final def = kShipDefinitions[c.type];
      if (def == null || def.maxCounters == 0) continue;
      builtByType[c.type] = (builtByType[c.type] ?? 0) + 1;
    }

    if (builtByType.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalMaint = production.maintenanceTotal(shipCounters, config, modifiers);

    // Build rows sorted by definition order.
    final sortedTypes = builtByType.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      initiallyExpanded: false,
      title: Row(
        children: [
          Text(
            'FLEET ROSTER',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            'Total Maint: $totalMaint',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      children: [
        const Divider(height: 1),
        for (final type in sortedTypes)
          _buildFleetRosterRow(theme, type, builtByType[type]!),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFleetRosterRow(ThemeData theme, ShipType type, int count) {
    final def = kShipDefinitions[type]!;
    final exempt = def.maintenanceExempt;
    final maintCost = exempt ? null : def.hullSize * count;
    final maintText = exempt ? 'exempt' : 'maint: $maintCost';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '${def.name}s',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () => showShipInfoDialog(context, type, onRuleTap: widget.onRuleTap),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '($maintText)',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Technology section
  // ===========================================================================

  Widget _buildTechSection(BuildContext context) {
    final allTechs = visibleTechs(
      facilitiesMode: config.enableFacilities,
      closeEncountersOwned: config.ownership.closeEncounters,
      replicatorsEnabled: config.enableReplicators,
      advancedConEnabled: config.enableAdvancedConstruction,
    );
    final blocked = config.empireAdvantage?.blockedTechs ?? const [];
    final techs = allTechs.where((id) => !blocked.contains(id)).toList();

    final unpredictable = config.enableUnpredictableResearch;
    final costLabel = config.enableFacilities ? 'RP' : 'CP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: unpredictable ? 'TECH RESEARCH' : 'TECHNOLOGY',
          subtitle: unpredictable ? 'unpredictable \u2022 5 CP/grant' : 'costs in $costLabel',
        ),
        const SizedBox(height: 4),
        for (final id in techs)
          if (unpredictable)
            _buildResearchTechRow(id)
          else
            _buildTechRow(id),
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
        onInfoTap: () => showTechDetailDialog(
          context,
          techId: id,
          techName: _techDisplayNames[id] ?? id.name,
          facilitiesMode: config.useFacilitiesCosts,
          currentLevel: effectiveLevel,
        ),
      ),
    );
  }

  /// Build a tech row for unpredictable research mode.
  Widget _buildResearchTechRow(TechId id) {
    final theme = Theme.of(context);
    final effectiveLevel = _effectiveLevel(id);
    final maxLevel = _maxLevel(id);
    final isMaxed = effectiveLevel >= maxLevel;
    final pending = _pendingBuys(id);
    final name = _techDisplayNames[id] ?? id.name;

    final monoStyle = TextStyle(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: 'monospace',
      fontSize: 15,
      color: theme.colorScheme.onSurface,
    );
    final dimStyle = monoStyle.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );

    if (isMaxed) {
      return SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(name,
                    style: TextStyle(
                        fontSize: 15, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                onPressed: () => showTechDetailDialog(
                  context,
                  techId: id,
                  techName: name,
                  facilitiesMode: config.useFacilitiesCosts,
                  currentLevel: effectiveLevel,
                ),
              ),
              const SizedBox(width: 4),
              Text('[$effectiveLevel]', style: monoStyle),
              const SizedBox(width: 6),
              Text(' MAX', style: dimStyle),
            ],
          ),
        ),
      );
    }

    final targetLevel = effectiveLevel + 1;
    final fm = config.useFacilitiesCosts;
    final targetCost =
        production.getResearchTarget(id, targetLevel, fm) ?? 0;
    final accumulated = production.getAccumulated(id, targetLevel);
    final progress =
        targetCost > 0 ? (accumulated / targetCost).clamp(0.0, 1.0) : 0.0;
    final canFund = _maxGrantsAffordable() > 0 && pending == 0;

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // Tech name
            SizedBox(
              width: 96,
              child: Text(name,
                  style: TextStyle(
                      fontSize: 15, color: theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              onPressed: () => showTechDetailDialog(
                context,
                techId: id,
                techName: name,
                facilitiesMode: config.useFacilitiesCosts,
                currentLevel: effectiveLevel,
              ),
            ),
            const SizedBox(width: 4),
            // Current level -> target
            Text('[$effectiveLevel]', style: monoStyle),
            const SizedBox(width: 4),
            Text('\u2192 $targetLevel', style: monoStyle),
            const SizedBox(width: 8),
            // Progress bar
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$accumulated / $targetCost',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Pending indicator
            if (pending > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '+$pending',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            // Fund button (disabled if breakthrough already pending)
            if (pending == 0)
              SizedBox(
                height: 40,
                child: TextButton(
                  onPressed: canFund ? () => _fundResearch(id) : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(48, 40),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    textStyle: const TextStyle(fontSize: 15),
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.disabledColor,
                  ),
                  child: const Text('Fund'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Ship Purchase section (Task 2 validation + Task 3B bounce)
  // ===========================================================================

  Widget _buildShipPurchaseSection(BuildContext context) {
    final theme = Theme.of(context);
    final purchases = production.shipPurchases;
    final totalCost = production.shipPurchaseCost(config, modifiers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: 'SHIP PURCHASES',
          subtitle: purchases.isNotEmpty ? 'total: ${totalCost}CP' : null,
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < purchases.length; i++)
          _buildShipPurchaseRow(i, purchases[i], theme),
        const SizedBox(height: 4),
        // F7: Maintenance forecast
        Builder(builder: (context) {
          int newMaint = 0;
          for (final p in purchases) {
            final def = kShipDefinitions[p.type];
            if (def != null && !def.maintenanceExempt) {
              newMaint += def.hullSize * p.quantity;
            }
          }
          if (newMaint > 0) {
            final currentMaint = production.maintenanceTotal(shipCounters, config, modifiers);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Next turn maint: ${currentMaint + newMaint} (+$newMaint)',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showAddShipDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label:
                const Text('Add Ship', style: TextStyle(fontSize: 15)),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShipPurchaseRow(
      int index, ShipPurchase purchase, ThemeData theme) {
    final def = kShipDefinitions[purchase.type];
    final name = def?.name ?? purchase.type.name;
    final abbr = def?.abbreviation ?? '';
    final unitCost = def?.effectiveBuildCost(config.enableAlternateEmpire) ?? 0;

    // Task 3B: bounce animation on the last added row
    final shouldBounce = _lastBouncedIndex == index;

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Ship name
            Expanded(
              child: Text(
                '$name ($abbr)',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              onPressed: () => showShipInfoDialog(context, purchase.type, onRuleTap: widget.onRuleTap),
            ),
            const SizedBox(width: 4),
            // Quantity controls
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                icon: const Icon(Icons.remove),
                onPressed: purchase.quantity > 1
                    ? () {
                        final updated =
                            List<ShipPurchase>.from(production.shipPurchases);
                        updated[index] =
                            purchase.copyWith(quantity: purchase.quantity - 1);
                        widget.onProductionChanged(
                            production.copyWith(shipPurchases: updated));
                      }
                    : null,
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                '${purchase.quantity}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                icon: const Icon(Icons.add),
                onPressed: _canAffordOneMore(purchase.type)
                    ? () {
                        final updated =
                            List<ShipPurchase>.from(production.shipPurchases);
                        updated[index] =
                            purchase.copyWith(quantity: purchase.quantity + 1);
                        widget.onProductionChanged(
                            production.copyWith(shipPurchases: updated));
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Cost
            SizedBox(
              width: 52,
              child: Text(
                '${purchase.cost}CP',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Unit cost hint
            Text(
              '(@$unitCost)',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            // Delete
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.error.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  final updated =
                      List<ShipPurchase>.from(production.shipPurchases);
                  updated.removeAt(index);
                  widget.onProductionChanged(
                      production.copyWith(shipPurchases: updated));
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldBounce) {
      row = AnimatedBuilder(
        animation: _shipBounceController,
        builder: (context, child) {
          return Transform.scale(
            scale: _shipBounceScale.value,
            child: child,
          );
        },
        child: row,
      );
    }

    return row;
  }

  /// Task 2: Check if player can afford one more of this ship type.
  bool _canAffordOneMore(ShipType type) {
    final def = kShipDefinitions[type];
    if (def == null) return false;
    final remaining = production.remainingCp(config, shipCounters, modifiers);
    return remaining >= def.effectiveBuildCost(config.enableAlternateEmpire);
  }

  void _showAddShipDialog(BuildContext context) {
    // Task 2: Filter to ships the player has tech to build AND can afford
    final remaining = production.remainingCp(config, shipCounters, modifiers);

    final isAlt = config.enableAlternateEmpire;
    final buyableShips = kShipDefinitions.entries
        .where((e) => e.value.effectiveBuildCost(isAlt) > 0)
        .where((e) => canBuildShip(
              e.key,
              _effectiveLevel,
              config,
              production.shipPurchases,
            ))
        .where((e) => e.value.effectiveBuildCost(isAlt) <= remaining)
        .toList()
      ..sort((a, b) => a.value.effectiveBuildCost(isAlt)
          .compareTo(b.value.effectiveBuildCost(isAlt)));

    showDialog<ShipType>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SimpleDialog(
          title: const Text('Add Ship Purchase'),
          children: [
            if (buyableShips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'No ships available.\nCheck your tech levels and remaining CP.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            for (final entry in buyableShips)
              InkWell(
                onTap: () => Navigator.of(ctx).pop(entry.key),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          entry.value.abbreviation,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.name,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Text(
                        '${entry.value.effectiveBuildCost(isAlt)}CP',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            showShipInfoDialog(ctx, entry.key, onRuleTap: widget.onRuleTap),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ).then((type) {
      if (type != null) {
        final updated =
            List<ShipPurchase>.from(production.shipPurchases)
              ..add(ShipPurchase(type: type));
        widget.onProductionChanged(
            production.copyWith(shipPurchases: updated));
      }
    });
  }

  // ===========================================================================
  // Worlds section (Problem 1 - redesigned)
  // ===========================================================================

  Widget _buildWorldsSection(BuildContext context) {
    final theme = Theme.of(context);
    final worlds = production.worlds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'WORLDS'),
        const SizedBox(height: 4),
        for (int i = 0; i < worlds.length; i++)
          worlds[i].isHomeworld
              ? _buildHomeworldRow(i, worlds[i], theme)
              : _buildColonyRow(context, i, worlds[i], theme),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addColony(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Colony', style: TextStyle(fontSize: 15)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworldRow(int index, WorldState world, ThemeData theme) {
    final labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: Homeworld label + value selector
            Row(
              children: [
                Text('Homeworld', style: labelStyle),
                const Spacer(),
                NumberInput(
                  value: world.homeworldValue,
                  onChanged: (v) =>
                      _updateWorld(index, (w) => w.copyWith(homeworldValue: v)),
                  min: 5,
                  max: 30,
                  step: 5,
                ),
              ],
            ),
            // Line 2: Facility (if enabled) + mineral/pipeline
            if (config.enableFacilities ||
                world.mineralIncome > 0 ||
                world.pipelineIncome > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (config.enableFacilities) ...[
                    _FacilityChip(
                      facility: world.facility,
                      onChanged: (f) => _updateWorld(
                        index,
                        (w) => f == null
                            ? w.copyWith(clearFacility: true)
                            : w.copyWith(facility: f),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  SizedBox(
                    width: 80,
                    child: NumberInput(
                      value: world.mineralIncome,
                      onChanged: (v) => _updateWorld(
                          index, (w) => w.copyWith(mineralIncome: v)),
                      min: 0,
                      label: 'M',
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 80,
                    child: NumberInput(
                      value: world.pipelineIncome,
                      onChanged: (v) => _updateWorld(
                          index, (w) => w.copyWith(pipelineIncome: v)),
                      min: 0,
                      label: 'P',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColonyRow(
      BuildContext context, int index, WorldState world, ThemeData theme) {
    final labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final dimStyle = TextStyle(
      fontSize: 14,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
    final growthCp = world.cpValue;
    final growthLabel = '${world.growthMarkerLevel}/3 (${growthCp}CP)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: Colony name (tap to edit), growth, blocked toggle, delete
            Row(
              children: [
                // Editable colony name
                GestureDetector(
                  onTap: () => _showEditColonyNameDialog(context, index, world),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 60,
                      maxWidth: 100,
                      minHeight: 44,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        world.name,
                        style: labelStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Growth marker with +/- adjustment
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 16,
                    icon: Icon(Icons.remove, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: world.growthMarkerLevel > 0
                        ? () => _updateWorld(index, (w) => w.copyWith(growthMarkerLevel: w.growthMarkerLevel - 1))
                        : null,
                  ),
                ),
                Text(growthLabel, style: dimStyle),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 16,
                    icon: Icon(Icons.add, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: world.growthMarkerLevel < 3
                        ? () => _updateWorld(index, (w) => w.copyWith(growthMarkerLevel: w.growthMarkerLevel + 1))
                        : null,
                  ),
                ),
                const Spacer(),
                // Blocked toggle
                _CompactToggle(
                  label: 'BLK',
                  value: world.isBlocked,
                  onChanged: (v) =>
                      _updateWorld(index, (w) => w.copyWith(isBlocked: v)),
                ),
                const SizedBox(width: 4),
                // Delete colony button
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.error.withValues(alpha: 0.6),
                    ),
                    onPressed: () => _removeColony(index),
                  ),
                ),
              ],
            ),
            // Line 2: Mineral, Pipeline, Facility
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: NumberInput(
                    value: world.mineralIncome,
                    onChanged: (v) =>
                        _updateWorld(index, (w) => w.copyWith(mineralIncome: v)),
                    min: 0,
                    label: 'M',
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 80,
                  child: NumberInput(
                    value: world.pipelineIncome,
                    onChanged: (v) => _updateWorld(
                        index, (w) => w.copyWith(pipelineIncome: v)),
                    min: 0,
                    label: 'P',
                  ),
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
          ],
        ),
      ),
    );
  }

  void _showEditColonyNameDialog(
      BuildContext context, int index, WorldState world) {
    final controller = TextEditingController(text: world.name);
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Colony'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Colony name',
            isDense: true,
          ),
          style: const TextStyle(fontSize: 16),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((newName) {
      if (newName != null && newName.isNotEmpty) {
        _updateWorld(index, (w) => w.copyWith(name: newName));
      }
    });
  }

  void _addColony() {
    final colonies =
        production.worlds.where((w) => !w.isHomeworld).toList();
    final nextNum = colonies.length + 1;
    final updated = List<WorldState>.from(production.worlds)
      ..add(WorldState(name: 'Colony $nextNum'));
    widget.onProductionChanged(production.copyWith(worlds: updated));
  }

  void _removeColony(int index) {
    if (production.worlds[index].isHomeworld) return;
    final updated = List<WorldState>.from(production.worlds)..removeAt(index);
    widget.onProductionChanged(production.copyWith(worlds: updated));
  }

  // ===========================================================================
  // End Turn button (Task 3A: periodic wiggle)
  // ===========================================================================

  Widget _buildEndTurnButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _endTurnWiggleController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _endTurnWiggle.value,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: () => _confirmEndTurn(context),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text('END TURN', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildManualOverrideButton(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showManualOverride(context),
        icon: Icon(Icons.build, size: 18, color: theme.colorScheme.error.withValues(alpha: 0.6)),
        label: Text('Manual Override', style: TextStyle(fontSize: 14, color: theme.colorScheme.error.withValues(alpha: 0.6))),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  void _showManualOverride(BuildContext context) async {
    final currentGameState = GameState(
      config: widget.config,
      turnNumber: widget.turnNumber,
      production: widget.production,
      shipCounters: widget.shipCounters,
      activeModifiers: widget.activeModifiers,
    );
    final result = await showManualOverrideDialog(context, currentGameState);
    if (result != null && widget.onGameStateOverride != null) {
      widget.onGameStateOverride!(result);
    }
  }

  void _confirmEndTurn(BuildContext context) {
    final remainingCp = production.remainingCp(config, shipCounters, modifiers);
    final cpLost = remainingCp > 30 ? remainingCp - 30 : 0;
    final remainingRp = config.enableFacilities ? production.remainingRp(config, modifiers) : null;
    final rpLost = (remainingRp != null && remainingRp > 30) ? remainingRp - 30 : 0;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Turn?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finalize turn ${widget.turnNumber} and advance to turn ${widget.turnNumber + 1}.\n'
              'Pending tech purchases will be applied, colonies will grow, '
              'and carry-overs will be computed.',
            ),
            if (cpLost > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Warning: $cpLost CP will be lost (carry-over max 30).',
                style: const TextStyle(color: Colors.amber),
              ),
            ],
            if (rpLost > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Warning: $rpLost RP will be lost (carry-over max 30).',
                style: const TextStyle(color: Colors.amber),
              ),
            ],
          ],
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
        widget.onEndTurn();
      }
    });
  }
}

// =============================================================================
// Bid Reveal Overlay (Task 1 + Task 3F dramatic animation)
// =============================================================================

class _BidRevealOverlay extends StatelessWidget {
  final int bid;
  final Animation<double> animation;

  const _BidRevealOverlay({
    required this.bid,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Task 3F: elastic scale for dramatic reveal
    final scaleAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: animation,
                child: Text(
                  'Turn Order Bid',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ScaleTransition(
                scale: scaleAnim,
                child: Text(
                  '$bid',
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: animation,
                child: Text(
                  'tap anywhere to dismiss',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Pulsing negative CP indicator (Task 3E)
// =============================================================================

class _PulsingNegativeCp extends StatefulWidget {
  final int value;
  final TextStyle baseStyle;

  const _PulsingNegativeCp({
    required this.value,
    required this.baseStyle,
  });

  @override
  State<_PulsingNegativeCp> createState() => _PulsingNegativeCpState();
}

class _PulsingNegativeCpState extends State<_PulsingNegativeCp>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _pulseOpacity,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          widget.value.toString(),
          style: widget.baseStyle.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        decoration: BoxDecoration(
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
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
