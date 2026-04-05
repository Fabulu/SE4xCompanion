import 'dart:async';
import 'package:flutter/material.dart';

import '../data/card_manifest.dart';
import '../data/card_modifiers.dart';
import '../data/counter_pool.dart' as counter_pool;
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/drawn_card.dart';
import '../models/game_config.dart';
import '../models/game_modifier.dart';
import '../models/game_state.dart';
import '../models/map_state.dart';
import '../models/production_state.dart';
import '../models/research_event.dart';
import '../models/ship_counter.dart';
import '../models/turn_summary.dart';
import '../models/world.dart';
import '../widgets/empire_summary_card.dart';
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
  List<ShipPurchase> existingPurchases, [
  List<ShipCounter> shipCounters = const [],
]) {
  final def = kShipDefinitions[type];
  if (def == null) return false;

  // Scenario-blocked ship types
  if (config.scenarioBlockedShips.contains(type)) return false;

  final shipSize = effectiveLevel(TechId.shipSize);
  final fm = config.useFacilitiesCosts;

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

    // Standard warships: require Ship Size >= prerequisite (AGT-aware)
    case ShipType.dd:
    case ShipType.ca:
    case ShipType.bc:
    case ShipType.bb:
    case ShipType.dn:
      final required = def.requiredShipSize(fm) ?? def.effectiveHullSize(fm);
      return shipSize >= required;

    // Titans: require Ship Size >= 4 (or 7 in AGT); blocked for alternate empire
    case ShipType.tn:
      if (isAlt) return false;
      final tnReq = def.requiredShipSize(fm) ?? def.effectiveHullSize(fm);
      return shipSize >= tnReq;

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

    // Ground Units (21.0): Ground Combat 1 is free at start of game.
    // Purchased at un-blockaded Colonies (21.3); no Shipyard required.
    case ShipType.groundUnit:
      return effectiveLevel(TechId.ground) >= 1;

    // Mines: require Mines tech >= 1
    case ShipType.mine:
      return effectiveLevel(TechId.mines) >= 1;

    // Bases: require Ship Size >= 2
    case ShipType.base:
      return shipSize >= 2;

    // Starbases: require Advanced Construction >= 2 and a built Base
    case ShipType.starbase:
      if (effectiveLevel(TechId.advancedCon) < 2) return false;
      return shipCounters.any((c) => c.type == ShipType.base && c.isBuilt);

    // The printed War Sun Empire Advantage grants a one-time free Titan and is
    // not modeled as a buildable unit in the ledger.
    case ShipType.warSun:
      return false;

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
  final Map<ShipType, int> shipSpecialAbilities;
  final GameMapState? mapState;
  final ValueChanged<ProductionState> onProductionChanged;
  final VoidCallback onEndTurn;
  final void Function(String sectionId)? onRuleTap;
  final ValueChanged<GameState>? onGameStateOverride;
  final ValueChanged<List<GameModifier>>? onActiveModifiersChanged;
  final ValueChanged<String>? onLocateShip;
  final List<DrawnCard> drawnHand;
  final ValueChanged<List<DrawnCard>>? onDrawnHandChanged;
  final void Function(String cardName, List<GameModifier> modifiers)?
      onPlayCardAsEvent;
  final void Function(String cardName, int cpGained)? onPlayCardForCredits;
  final List<TurnSummary> turnSummaries;

  const ProductionPage({
    super.key,
    required this.config,
    required this.turnNumber,
    required this.production,
    required this.shipCounters,
    this.activeModifiers = const [],
    this.shipSpecialAbilities = const {},
    this.mapState,
    required this.onProductionChanged,
    required this.onEndTurn,
    this.onRuleTap,
    this.onGameStateOverride,
    this.onActiveModifiersChanged,
    this.onLocateShip,
    this.drawnHand = const [],
    this.onDrawnHandChanged,
    this.onPlayCardAsEvent,
    this.onPlayCardForCredits,
    this.turnSummaries = const [],
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
        widget.production.remainingCp(widget.config, widget.shipCounters, widget.activeModifiers, widget.shipSpecialAbilities, widget.mapState);
  }

  @override
  void didUpdateWidget(ProductionPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Task 3C: pop on remaining CP change
    final newRemaining =
        widget.production.remainingCp(widget.config, widget.shipCounters, widget.activeModifiers, widget.shipSpecialAbilities, widget.mapState);
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
  Map<ShipType, int> get abilities => widget.shipSpecialAbilities;
  GameMapState? get mapState => widget.mapState;

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

  /// Display-tier effective level for a tech.
  ///
  /// Previously applied EA `techLevelBonuses`; no EA currently grants bonuses,
  /// so this now returns the plain effective level.
  int _bonusLevel(TechId id) => _effectiveLevel(id);

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
  /// Applies EA and scenario tech cost modifiers.
  int? _nextCost(TechId id) {
    final table =
        config.useFacilitiesCosts ? kFacilitiesTechCosts : kBaseTechCosts;
    final entry = table[id];
    if (entry == null) return null;
    final baseCost = entry.costForNext(_effectiveLevel(id));
    if (baseCost == null) return null;
    final ea = config.empireAdvantage;
    int cost = baseCost;
    if (ea != null && ea.techCostMultiplier != 1.0) {
      final adjusted = cost * ea.techCostMultiplier;
      cost = ea.roundTechCostsUp ? adjusted.ceil() : adjusted.floor();
    }
    // Scenario tech cost multiplier
    if (config.techCostMultiplier != 1.0) {
      cost = (cost * config.techCostMultiplier).ceil();
    }
    return cost;
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
      final cpAvail = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
      return cpAvail >= cost;
    }
  }

  void _buyTech(TechId id) {
    final newLevel = _effectiveLevel(id) + 1;
    final pending = Map<TechId, int>.from(production.pendingTechPurchases);
    pending[id] = newLevel;
    final order = List<TechId>.from(production.techPurchaseOrder);
    if (!order.contains(id)) order.add(id);
    widget.onProductionChanged(
        production.copyWith(pendingTechPurchases: pending, techPurchaseOrder: order));
  }

  /// Grants a free tech level bump, representing a Space Wreck tech-roll
  /// (rule 6.8.1). No CP/RP is spent. Bumps the committed techState level by 1;
  /// does not interact with pending purchases.
  void _applyWreckUpgrade(TechId id) {
    final fm = config.useFacilitiesCosts;
    final committedLevel = production.techState.getLevel(id, facilitiesMode: fm);
    final maxLevel = _maxLevel(id);
    if (committedLevel >= maxLevel) return;
    final newTechState =
        production.techState.setLevel(id, committedLevel + 1);
    widget.onProductionChanged(production.copyWith(techState: newTechState));
  }

  void _undoTech(TechId id) {
    final pending = Map<TechId, int>.from(production.pendingTechPurchases);
    pending.remove(id);
    final order = List<TechId>.from(production.techPurchaseOrder);
    order.remove(id);
    widget.onProductionChanged(
        production.copyWith(pendingTechPurchases: pending, techPurchaseOrder: order));
  }

  // ---- unpredictable research helpers ----

  /// The next target level for research on a tech (accounts for pending).
  int _researchTargetLevel(TechId id) {
    return _effectiveLevel(id) + 1;
  }

  /// How many grants the player can afford (each grant = 5 CP).
  int _maxGrantsAffordable() {
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
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

    // Append research audit events: the roll itself, and a reassignment
    // marker if the roll ended up on a different tech.
    final newLog = <ResearchEvent>[
      ...production.researchLog,
      GrantRolledEvent(
        techId: effectiveId,
        targetLevel: effectiveTargetLevel,
        dieResult: result.totalRolled,
        outcomeCpSpent: result.cpSpent,
        success: result.breakthroughAchieved,
      ),
      if (result.reassignedFrom != null)
        GrantReassignedEvent(
          fromTechId: result.reassignedFrom!,
          toTechId: effectiveId,
          accumulatedCp: result.totalRolled,
        ),
    ];

    var newProduction = production.copyWith(
      accumulatedResearch: newAccumulated,
      researchGrantsCp: production.researchGrantsCp + result.cpSpent,
      researchLog: newLog,
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

        // Empire Advantage / Alternate Empire summary
        EmpireSummaryCard(
          empireAdvantage: config.empireAdvantage,
          isAlternateEmpire: config.enableAlternateEmpire,
          shipSpecialAbilities: abilities,
        ),

        // Active card-derived modifiers (chips)
        _buildActiveModifierChips(theme),

        // Carry-over warnings
        _buildCarryOverWarning(),

        // Research pre-gate soft warning (rule 9.11)
        _buildResearchPreGateWarning(),

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

        // Pipeline inventory
        _buildPipelineSection(context),

        const SizedBox(height: 16),

        // Worlds
        _buildWorldsSection(context),

        const SizedBox(height: 16),

        // Cards in hand (T3-C)
        _buildCardsSection(context),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
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
              const Spacer(),
              // M-2: Turn Log button — opens modal with turn history.
              if (widget.turnSummaries.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.history, size: 22),
                  tooltip: 'Turn Log',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _showTurnLogModal(context),
                ),
            ],
          ),
        ),
        // M-3: sticky-ish active-rules chip strip under the header.
        _buildActiveRulesStrip(theme),
      ],
    );
  }

  // ===========================================================================
  // M-3: Active rules / EA summary chip strip
  // ===========================================================================

  Widget _buildActiveRulesStrip(ThemeData theme) {
    final ea = config.empireAdvantage;
    final chips = <Widget>[];

    Widget chip(String label, {Color? color}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
            border: Border.all(
              color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.4),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

    if (ea != null) {
      chips.add(chip('EA: ${ea.name}'));
    } else if (config.enableAlternateEmpire) {
      chips.add(chip('Alt Empire'));
    }

    final expansionFlags = <String>[];
    if (config.ownership.allGoodThings) expansionFlags.add('AGT');
    if (config.ownership.closeEncounters) expansionFlags.add('CE');
    if (config.ownership.replicators) expansionFlags.add('Rep');
    if (expansionFlags.isNotEmpty) {
      chips.add(chip(expansionFlags.join(' + '),
          color: theme.colorScheme.tertiary));
    }

    final ruleFlags = <String>[];
    if (config.enableFacilities) ruleFlags.add('Facilities');
    if (config.enableLogistics) ruleFlags.add('Logistics');
    if (config.enableTemporal) ruleFlags.add('Temporal');
    if (config.enableAdvancedConstruction) ruleFlags.add('Adv Con');
    if (config.enableShipExperience) ruleFlags.add('Experience');
    if (config.enableUnpredictableResearch) ruleFlags.add('Unpred. Res.');
    if (ruleFlags.isNotEmpty) {
      chips.add(chip(ruleFlags.join(' · '),
          color: theme.colorScheme.secondary));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _showActiveRulesDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: chips,
          ),
        ),
      ),
    );
  }

  void _showActiveRulesDialog(BuildContext context) {
    final ea = config.empireAdvantage;
    final lines = <String>[];
    lines.add('Turn: ${widget.turnNumber}');
    if (ea != null) {
      lines.add('EA: #${ea.cardNumber} ${ea.name}');
    } else if (config.enableAlternateEmpire) {
      lines.add('Alternate Empire mode');
    } else {
      lines.add('EA: (none selected)');
    }
    lines.add('');
    lines.add('Expansions owned:');
    lines.add('  All Good Things: ${config.ownership.allGoodThings ? "yes" : "no"}');
    lines.add('  Close Encounters: ${config.ownership.closeEncounters ? "yes" : "no"}');
    lines.add('  Replicators: ${config.ownership.replicators ? "yes" : "no"}');
    lines.add('');
    lines.add('Active rules:');
    lines.add('  Facilities: ${config.enableFacilities ? "on" : "off"}');
    lines.add('  Logistics: ${config.enableLogistics ? "on" : "off"}');
    lines.add('  Temporal: ${config.enableTemporal ? "on" : "off"}');
    lines.add('  Advanced Construction: ${config.enableAdvancedConstruction ? "on" : "off"}');
    lines.add('  Ship Experience: ${config.enableShipExperience ? "on" : "off"}');
    lines.add('  Unpredictable Research: ${config.enableUnpredictableResearch ? "on" : "off"}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Active Rules'),
        content: SingleChildScrollView(
          child: Text(
            lines.join('\n'),
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // M-4: Maintenance breakdown by ship type
  // ===========================================================================

  void _showMaintenanceBreakdown(BuildContext context, int total) {
    final ea = config.empireAdvantage;
    final hullMod = ea?.hullSizeModifier ?? 0;

    // Collect per-type percent modifiers from GameModifier list (mirrors
    // ProductionState.maintenanceTotal so the breakdown stays consistent).
    final typePercentMods = <ShipType, int>{};
    int? globalPercent;
    for (final mod in modifiers) {
      if (mod.type != 'maintenanceMod') continue;
      if (mod.isPercent) {
        if (mod.shipType != null) {
          typePercentMods[mod.shipType!] = mod.value;
        } else {
          globalPercent = mod.value;
        }
      }
    }

    // Count built ships by type and compute per-ship maint cost.
    final counts = <ShipType, int>{};
    final perShip = <ShipType, int>{};
    final subtotals = <ShipType, int>{};
    for (final c in shipCounters) {
      if (!c.isBuilt) continue;
      final def = kShipDefinitions[c.type];
      if (def == null || def.maintenanceExempt) continue;
      int m = (def.effectiveHullSize(config.useFacilitiesCosts) + hullMod)
          .clamp(0, 99);
      if (typePercentMods.containsKey(c.type)) {
        m = (m * typePercentMods[c.type]! / 100).ceil();
      }
      counts[c.type] = (counts[c.type] ?? 0) + 1;
      perShip[c.type] = m;
      subtotals[c.type] = (subtotals[c.type] ?? 0) + m;
    }

    final lines = <Widget>[];
    final theme = Theme.of(context);
    final rowStyle = TextStyle(
      fontSize: 14,
      color: theme.colorScheme.onSurface,
      fontFamily: 'monospace',
    );

    if (counts.isEmpty) {
      lines.add(Text('No maintained ships on the board.', style: rowStyle));
    } else {
      // Sort by descending subtotal.
      final entries = counts.keys.toList()
        ..sort((a, b) => (subtotals[b] ?? 0).compareTo(subtotals[a] ?? 0));
      for (final t in entries) {
        final def = kShipDefinitions[t];
        final name = def?.name ?? t.name;
        lines.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${counts[t]} × $name @ ${perShip[t]} = ${subtotals[t]} CP',
            style: rowStyle,
          ),
        ));
      }
    }

    // Adjustments beyond the raw per-ship sum.
    final rawSum = subtotals.values.fold<int>(0, (a, b) => a + b);
    final adjustments = <String>[];
    if (production.maintenanceIncrease > 0) {
      adjustments.add('+${production.maintenanceIncrease} (increase)');
    }
    if (production.maintenanceDecrease > 0) {
      adjustments.add('-${production.maintenanceDecrease} (decrease)');
    }
    if (ea != null && ea.maintenancePercent != 100) {
      adjustments.add('EA ${ea.name}: ×${ea.maintenancePercent}%');
    }
    if (globalPercent != null) {
      adjustments.add('Global modifier: ×$globalPercent%');
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maintenance Breakdown'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...lines,
              const Divider(height: 20),
              Text(
                'Raw ship total: $rawSum CP',
                style: rowStyle.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              if (adjustments.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final a in adjustments)
                  Text(a,
                      style: rowStyle.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7))),
              ],
              const SizedBox(height: 6),
              Text(
                'Total: $total CP',
                style: rowStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // M-2: Turn Log modal
  // ===========================================================================

  void _showTurnLogModal(BuildContext context) {
    final summaries = widget.turnSummaries;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final dimStyle = TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        );
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Text(
                      'Turn Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: summaries.length,
                  itemBuilder: (_, i) {
                    final summary = summaries[summaries.length - 1 - i];
                    final details = <String>[];
                    if (summary.techsGained.isNotEmpty) {
                      details.add('Techs: ${summary.techsGained.join(", ")}');
                    }
                    if (summary.shipsBuilt.isNotEmpty) {
                      details.add('Ships: ${summary.shipsBuilt.join(", ")}');
                    }
                    if (summary.coloniesGrown > 0) {
                      details.add('Colonies grown: ${summary.coloniesGrown}');
                    }
                    details.add('Maintenance: ${summary.maintenancePaid}');
                    details.add('CP carry-over: ${summary.cpCarryOver}');
                    if (summary.cpLostToCap > 0) {
                      details.add('CP lost to cap: ${summary.cpLostToCap}');
                    }
                    return ExpansionTile(
                      title: Text('Turn ${summary.turnNumber}',
                          style: const TextStyle(fontSize: 15)),
                      initiallyExpanded: i == 0,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final line in details)
                                Text(line, style: dimStyle),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Active modifier chips (card-derived + manual)
  // ===========================================================================

  Widget _buildActiveModifierChips(ThemeData theme) {
    final mods = modifiers;
    if (mods.isEmpty) return const SizedBox.shrink();
    final canRemove = widget.onActiveModifiersChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (int i = 0; i < mods.length; i++)
            InputChip(
              label: Text(
                '${mods[i].name}: ${mods[i].effectDescription}',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: canRemove ? () => _removeModifierAt(i) : null,
              deleteIconColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
        ],
      ),
    );
  }

  void _removeModifierAt(int index) {
    final cb = widget.onActiveModifiersChanged;
    if (cb == null) return;
    final newMods = List<GameModifier>.from(modifiers)..removeAt(index);
    cb(newMods);
  }

  // ===========================================================================
  // Carry-over warning banner
  // ===========================================================================

  Widget _buildCarryOverWarning() {
    final theme = Theme.of(context);
    final remainingCp = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final remainingRp =
        config.enableFacilities ? production.remainingRp(config, modifiers) : 0;
    final cpExcess = remainingCp - 30;
    final rpExcess = remainingRp - 30;

    final warnings = <Widget>[];

    if (cpExcess > 0) {
      warnings.add(
        _warningBanner(
          theme,
          icon: Icons.payments_outlined,
          prefix: 'CP Cap',
          message:
              '$cpExcess CP will be lost at End Turn (carry-over cap is 30)',
        ),
      );
    }

    if (config.enableFacilities && rpExcess > 0) {
      warnings.add(
        _warningBanner(
          theme,
          icon: Icons.science_outlined,
          prefix: 'RP Cap',
          message:
              '$rpExcess RP will be lost at End Turn (carry-over cap is 30)',
        ),
      );
    }

    if (warnings.isEmpty) return const SizedBox.shrink();
    return Column(children: warnings);
  }

  // ===========================================================================
  // Research pre-gate soft warning (rule 9.11)
  // ===========================================================================

  Widget _buildResearchPreGateWarning() {
    if (!production.hasShipsQueuedBeforeResearch) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return _warningBanner(
      theme,
      icon: Icons.lightbulb_outline,
      prefix: 'Research Order',
      message:
          'commit tech purchases first (rule 9.11). Ship purchases made '
          'now may use outdated tech levels.',
    );
  }

  /// Shared amber/tertiary warning banner. Per-banner icon + prefix
  /// label keep stacked warnings visually distinguishable while
  /// preserving consistent warning semantics.
  Widget _warningBanner(
    ThemeData theme, {
    required IconData icon,
    required String prefix,
    required String message,
  }) {
    final color = theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14, color: color),
                children: [
                  TextSpan(
                    text: '$prefix: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: message),
                ],
              ),
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
    final maint = production.maintenanceTotal(shipCounters, config, modifiers);
    final colonyCp = production.colonyCp(config);
    final mineralCp = production.mineralCp();
    final pipelineCp = production.pipelineCp(config);
    final asteroidCp = mapState != null
        ? production.asteroidMiningCp(mapState!, shipCounters)
        : 0;
    final nebulaCp = mapState != null
        ? production.nebulaMiningCp(
            mapState!,
            shipCounters,
            facilitiesMode: config.useFacilitiesCosts,
          )
        : 0;
    final totalCp = production.totalCp(config, modifiers, mapState, shipCounters);
    final subtotal = production.subtotalCp(config, shipCounters, modifiers, mapState);
    final techSpending = production.techSpendingCpDerived(config, modifiers);
    final shipSpending = production.effectiveShipSpending(config, modifiers, abilities);
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final unpredictable = config.enableUnpredictableResearch;

    return LedgerGrid(
      title: 'CP LEDGER',
      rows: [
        LedgerRow(
          // QW-4: On turn 1 there is no "previous turn" so rename the row to
          // "Starting CP" so new users aren't confused about what to enter.
          label: widget.turnNumber <= 1
              ? 'Starting CP'
              : 'CP carry over from last turn',
          value: production.cpCarryOver,
          isEditable: true,
          min: 0,
          max: 30,
          onChanged: (v) => _update((s) => s.copyWith(cpCarryOver: v)),
        ),
        LedgerRow(label: '+ Colony CPs', computedValue: colonyCp),
        LedgerRow(label: '+ Mineral CPs', computedValue: mineralCp),
        LedgerRow(label: '+ MS Pipeline CPs', computedValue: pipelineCp),
        // QW-3: Always surface the mining rows so players discover the rules
        // exist, even when no Miners are on those terrain types yet.
        LedgerRow(
          label: '+ Asteroid Mining CPs (rule 39.2)',
          computedValue: asteroidCp,
        ),
        LedgerRow(
          label: (production.techState.getLevel(
                    TechId.terraforming,
                    facilitiesMode: config.useFacilitiesCosts,
                  ) >=
                  2)
              ? '+ Nebula Mining CPs (rule 34.0)'
              : '+ Nebula Mining CPs (req. Terraforming 2)',
          computedValue: (production.techState.getLevel(
                    TechId.terraforming,
                    facilitiesMode: config.useFacilitiesCosts,
                  ) >=
                  2)
              ? nebulaCp
              : 0,
        ),
        LedgerRow(label: 'TOTAL', computedValue: totalCp, isTotal: true),
        LedgerRow(
          label: '- Maintenance',
          computedValue: maint,
          onTap: () => _showMaintenanceBreakdown(context, maint),
        ),
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
        if (config.enableFreeGroundTroops)
          LedgerRow(
            label: 'Free Ground Units (21.5)',
            computedValue: production.freeGroundTroopsPlaceable(config),
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
        LedgerRow(
          label: 'REMAINING CP',
          computedValue: remaining,
          isTotal: true,
          // Task 3C: animated remaining value
          trailingBuilder: (displayValue, valueStyle) =>
              _buildAnimatedRemainingCp(remaining, valueStyle),
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
        LedgerRow(
          label: '- Maintenance',
          computedValue: maint,
          onTap: () => _showMaintenanceBreakdown(context, maint),
        ),
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
    final pipelineCp = production.pipelineCp(config);
    final asteroidCp = mapState != null
        ? production.asteroidMiningCp(mapState!, shipCounters)
        : 0;
    final nebulaCp = mapState != null
        ? production.nebulaMiningCp(
            mapState!,
            shipCounters,
            facilitiesMode: config.useFacilitiesCosts,
          )
        : 0;
    final totalCp = production.totalCp(config, modifiers, mapState, shipCounters);
    final penaltyLp = production.penaltyLp(config, shipCounters, modifiers);
    final subtotal = production.subtotalCp(config, shipCounters, modifiers, mapState);
    final shipSpending = production.effectiveShipSpending(config, modifiers, abilities);
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final unpredictable = config.enableUnpredictableResearch;

    return LedgerGrid(
      title: 'CP LEDGER',
      rows: [
        LedgerRow(
          // QW-4: Turn 1 has no prior turn; show "Starting CP" to reduce
          // confusion for new users setting up a game.
          label: widget.turnNumber <= 1 ? 'Starting CP' : 'CP carry over',
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
        // QW-3: Always show mining rows (even at 0) so players discover
        // Asteroid/Nebula rules. Nebula row shows a hint when
        // Terraforming 2 is not yet researched.
        LedgerRow(
          label: '+ Asteroid Mining CP (rule 39.2)',
          computedValue: asteroidCp,
        ),
        LedgerRow(
          label: (production.techState.getLevel(
                    TechId.terraforming,
                    facilitiesMode: config.useFacilitiesCosts,
                  ) >=
                  2)
              ? '+ Nebula Mining CP (rule 34.0)'
              : '+ Nebula Mining CP (req. Terraforming 2)',
          computedValue: (production.techState.getLevel(
                    TechId.terraforming,
                    facilitiesMode: config.useFacilitiesCosts,
                  ) >=
                  2)
              ? nebulaCp
              : 0,
        ),
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
        if (config.enableFreeGroundTroops)
          LedgerRow(
            label: 'Free Ground Units (21.5)',
            computedValue: production.freeGroundTroopsPlaceable(config),
          ),
        LedgerRow(
          label: '- CP spent on upgrades',
          value: production.upgradesCp,
          isEditable: true,
          min: 0,
          onChanged: (v) => _update((s) => s.copyWith(upgradesCp: v)),
        ),
        LedgerRow(
          label: 'REMAINING CP (30 Max)',
          computedValue: remaining,
          isTotal: true,
          trailingBuilder: (displayValue, valueStyle) =>
              _buildAnimatedRemainingCp(remaining, valueStyle),
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
    final maintCost = exempt ? null : def.effectiveHullSize(config.useFacilitiesCosts) * count;
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
            onPressed: () => showShipInfoDialog(context, type, facilitiesMode: config.useFacilitiesCosts, onRuleTap: widget.onRuleTap),
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
          if (widget.onLocateShip != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.my_location, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              tooltip: 'Locate built ${def.name.toLowerCase()}s',
              onPressed: () => _showBuiltShipsByTypeDialog(context, type),
            ),
          ],
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

  Future<void> _showBuiltShipsByTypeDialog(BuildContext context, ShipType type) async {
    final ships = shipCounters
        .where((counter) => counter.isBuilt && counter.type == type)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (ships.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${kShipDefinitions[type]!.name} Counters'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: ships.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final counter = ships[index];
              return ListTile(
                dense: true,
                title: Text(counter.id),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Locate on Map',
                  onPressed: widget.onLocateShip == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onLocateShip!(counter.id);
                        },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
    final blocked = {
      ...config.empireAdvantage?.blockedTechs ?? <TechId>[],
      ...config.scenarioBlockedTechs,
    };
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
        if (techs.contains(TechId.shipYard)) _buildShipyardSummaryChip(context),
        for (final id in techs)
          if (unpredictable)
            _buildResearchTechRow(id)
          else
            _buildTechRow(id),
      ],
    );
  }

  /// Ship Yard tech summary chip (T1-D).
  /// Shows total shipyards owned and HP/turn per shipyard per rule 9.6.
  Widget _buildShipyardSummaryChip(BuildContext context) {
    final theme = Theme.of(context);
    final syLevel = _effectiveLevel(TechId.shipYard);
    // Rule 9.6: Lvl 1 = 1 HP, Lvl 2 = 1.5 HP, Lvl 3 = 2 HP per turn per shipyard.
    final double hpPerSy = switch (syLevel) {
      <= 1 => 1.0,
      2 => 1.5,
      _ => 2.0,
    };
    final owned = shipCounters
        .where((c) => c.type == ShipType.shipyard && c.isBuilt)
        .length;
    String fmtHp(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    final label = 'Shipyards: $owned \u00B7 ${fmtHp(hpPerSy)} HP/turn';
    final tooltip =
        'Ship Yard tech level $syLevel \u2192 ${fmtHp(hpPerSy)} HP/turn per shipyard (rule 9.6)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechRow(TechId id) {
    final effectiveLevel = _effectiveLevel(id);
    final displayLevel = _bonusLevel(id);
    final startLevel = (config.useFacilitiesCosts
            ? kFacilitiesTechCosts
            : kBaseTechCosts)[id]
        ?.startLevel ??
        0;
    final maxLevel = _maxLevel(id);
    final displayMax = maxLevel;
    final nextCost = _nextCost(id);
    final pending = _pendingBuys(id);
    final canAfford = _canAffordTech(id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TechRow(
        name: _techDisplayNames[id] ?? id.name,
        currentLevel: displayLevel,
        startLevel: startLevel,
        maxLevel: displayMax,
        nextCost: effectiveLevel >= maxLevel ? null : nextCost,
        pendingBuys: pending,
        canAfford: effectiveLevel >= maxLevel ? false : canAfford,
        onBuy: (canAfford && effectiveLevel < maxLevel) ? () => _buyTech(id) : null,
        onUndo: pending > 0 ? () => _undoTech(id) : null,
        onInfoTap: () => showTechDetailDialog(
          context,
          techId: id,
          techName: _techDisplayNames[id] ?? id.name,
          facilitiesMode: config.useFacilitiesCosts,
          currentLevel: displayLevel,
          maxLevel: maxLevel,
          onApplyWreckUpgrade: () => _applyWreckUpgrade(id),
        ),
      ),
    );
  }

  /// Build a tech row for unpredictable research mode.
  Widget _buildResearchTechRow(TechId id) {
    final theme = Theme.of(context);
    final effectiveLevel = _effectiveLevel(id);
    final displayLevel = _bonusLevel(id);
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
                  currentLevel: displayLevel,
                  maxLevel: maxLevel,
                  onApplyWreckUpgrade: () => _applyWreckUpgrade(id),
                ),
              ),
              const SizedBox(width: 4),
              Text('[$displayLevel]', style: monoStyle),
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
                currentLevel: displayLevel,
                maxLevel: maxLevel,
                onApplyWreckUpgrade: () => _applyWreckUpgrade(id),
              ),
            ),
            const SizedBox(width: 4),
            // Current level -> target
            Text('[$displayLevel]', style: monoStyle),
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
    final totalCost = production.shipPurchaseCost(config, modifiers, abilities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: 'SHIP PURCHASES',
          subtitle: purchases.isNotEmpty ? 'total: ${totalCost}CP' : null,
        ),
        const SizedBox(height: 4),
        // QW-2: Per-hex capacity strip so the player always knows how much
        // shipyard HP budget each hex has remaining this turn.
        _buildShipyardHexCapacityStrip(context),
        for (int i = 0; i < purchases.length; i++)
          _buildShipPurchaseRow(i, purchases[i], theme),
        const SizedBox(height: 4),
        // F7: Maintenance forecast
        Builder(builder: (context) {
          int newMaint = 0;
          for (final p in purchases) {
            final def = kShipDefinitions[p.type];
            if (def != null && !def.maintenanceExempt) {
              newMaint += def.effectiveHullSize(config.useFacilitiesCosts) * p.quantity;
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
    final unitCost = def?.effectiveBuildCost(config.enableAlternateEmpire, facilitiesMode: config.useFacilitiesCosts) ?? 0;

    // Task 3B: bounce animation on the last added row
    final shouldBounce = _lastBouncedIndex == index;

    // QW-2: Resolve the friendly label of the assigned shipyard hex, if any.
    String? hexLabel;
    if (purchase.shipyardHexId != null && mapState != null) {
      for (final hex in mapState!.hexes) {
        if (hex.coord.id == purchase.shipyardHexId) {
          hexLabel = hex.label.isNotEmpty ? hex.label : hex.coord.id;
          break;
        }
      }
      hexLabel ??= purchase.shipyardHexId;
    }

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
                hexLabel != null
                    ? '$name ($abbr) @ $hexLabel'
                    : '$name ($abbr)',
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
              onPressed: () => showShipInfoDialog(context, purchase.type, facilitiesMode: config.useFacilitiesCosts, onRuleTap: widget.onRuleTap),
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
              child: Builder(
                builder: (context) {
                  final hasStock = _hasCounterStock(purchase.type);
                  final canAfford = _canAffordOneMore(purchase.type);
                  final enabled = canAfford && hasStock;
                  final tooltip = !hasStock
                      ? _counterStockTooltip(purchase.type)
                      : (!canAfford ? 'Not enough CP for another unit' : '');
                  final button = IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                    icon: const Icon(Icons.add),
                    onPressed: enabled
                        ? () {
                            final updated = List<ShipPurchase>.from(
                                production.shipPurchases);
                            updated[index] = purchase.copyWith(
                                quantity: purchase.quantity + 1);
                            widget.onProductionChanged(production.copyWith(
                                shipPurchases: updated));
                          }
                        : null,
                  );
                  return tooltip.isEmpty
                      ? button
                      : Tooltip(message: tooltip, child: button);
                },
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
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    return remaining >= def.effectiveBuildCost(config.enableAlternateEmpire, facilitiesMode: config.useFacilitiesCosts);
  }

  /// T1-C: Hard block — true if at least one blank counter is available.
  bool _hasCounterStock(ShipType type) =>
      counter_pool.hasCounterStock(
        type,
        shipCounters,
        production.shipPurchases,
      );

  /// T1-C: Tooltip describing why the "+1" button is blocked.
  String _counterStockTooltip(ShipType type) {
    final def = kShipDefinitions[type];
    if (def == null || def.maxCounters == 0) return '';
    final built =
        shipCounters.where((c) => c.type == type && c.isBuilt).length;
    final queued = production.shipPurchases
        .where((p) => p.type == type)
        .fold<int>(0, (s, p) => s + p.quantity);
    final max = def.maxCounters;
    final abbr = def.abbreviation;
    return 'Cannot build: all $max $abbr counters in use '
        '($built built, $queued queued).';
  }

  // QW-2: Summarize the set of hexes that currently have shipyards so the
  // "Add Ship" dialog can expose a per-hex dropdown and the purchase list can
  // show which hex each purchase is assigned to.
  List<_ShipyardHexInfo> _shipyardHexes() {
    final map = mapState;
    if (map == null) return const [];
    final techState = production.techState.withPending(
      production.pendingTechPurchases,
    );
    final isAlt = config.enableAlternateEmpire;
    final facilitiesMode = config.useFacilitiesCosts;
    final result = <_ShipyardHexInfo>[];
    for (final hex in map.hexes) {
      if (hex.shipyardCount <= 0) continue;
      final cap = production.shipyardCapacityForHex(
        hex.coord,
        map,
        techState,
        facilitiesMode: facilitiesMode,
      );
      final used = production.hullPointsSpentInHex(
        hex.coord,
        facilitiesMode: facilitiesMode,
      );
      final isBlocked = cap <= 0 && hex.shipyardCount > 0;
      // Prefer the hex label, fall back to coord id.
      final displayLabel = hex.label.isNotEmpty ? hex.label : hex.coord.id;
      result.add(_ShipyardHexInfo(
        hexId: hex.coord.id,
        label: displayLabel,
        shipyardCount: hex.shipyardCount,
        capacity: cap,
        used: used,
        isBlocked: isBlocked,
        isHomeworld: _isHomeworldHex(hex, isAlt: isAlt),
      ));
    }
    // Homeworld first, then others.
    result.sort((a, b) {
      if (a.isHomeworld != b.isHomeworld) return a.isHomeworld ? -1 : 1;
      return a.label.compareTo(b.label);
    });
    return result;
  }

  bool _isHomeworldHex(MapHexState hex, {required bool isAlt}) {
    final wid = hex.worldId;
    if (wid == null || wid.isEmpty) return false;
    for (final w in production.worlds) {
      if (w.id == wid && w.isHomeworld) return true;
    }
    return false;
  }

  /// QW-2: Short summary of shipyards (e.g. "HW: 2/4 HP") for display next to
  /// the purchase list.
  Widget _buildShipyardHexCapacityStrip(BuildContext context) {
    final theme = Theme.of(context);
    final infos = _shipyardHexes();
    if (infos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final info in infos)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: info.isBlocked
                    ? theme.colorScheme.error.withValues(alpha: 0.10)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: info.isBlocked
                      ? theme.colorScheme.error.withValues(alpha: 0.35)
                      : theme.colorScheme.primary.withValues(alpha: 0.30),
                  width: 0.8,
                ),
              ),
              child: Text(
                info.isBlocked
                    ? '${info.label}: blocked'
                    : '${info.label}: ${info.used}/${info.capacity} HP',
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddShipDialog(BuildContext context) {
    // Task 2: Filter to ships the player has tech to build AND can afford
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);

    final isAlt = config.enableAlternateEmpire;
    final facilitiesMode = config.useFacilitiesCosts;
    final buyableShips = kShipDefinitions.entries
        .where((e) => e.value.effectiveBuildCost(isAlt, facilitiesMode: facilitiesMode) > 0)
        .where((e) => canBuildShip(
              e.key,
              _effectiveLevel,
              config,
              production.shipPurchases,
              shipCounters,
            ))
        .where((e) => e.value.effectiveBuildCost(isAlt, facilitiesMode: facilitiesMode) <= remaining)
        // T1-C: hard block when all physical counters of this type are in use.
        .where((e) => _hasCounterStock(e.key))
        .toList()
      ..sort((a, b) => a.value.effectiveBuildCost(isAlt, facilitiesMode: facilitiesMode)
          .compareTo(b.value.effectiveBuildCost(isAlt, facilitiesMode: facilitiesMode)));

    // QW-2: Surface shipyard hexes so the player can pick where each purchase
    // is built. Zero-capacity hexes (blocked or no capacity remaining) are
    // still listed but greyed out.
    final shipyardInfos = _shipyardHexes();
    final selectableInfos =
        shipyardInfos.where((i) => !i.isBlocked && i.capacity > 0).toList();

    showDialog<({ShipType type, String? hexId})>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        // Default to Homeworld hex, else first selectable.
        String? selectedHexId = selectableInfos.isNotEmpty
            ? (selectableInfos.firstWhere(
                (i) => i.isHomeworld,
                orElse: () => selectableInfos.first,
              )).hexId
            : null;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SimpleDialog(
              title: const Text('Add Ship Purchase'),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (shipyardInfos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Shipyard',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: selectedHexId,
                          hint: const Text('No shipyard available'),
                          onChanged: selectableInfos.isEmpty
                              ? null
                              : (v) =>
                                  setDialogState(() => selectedHexId = v),
                          items: [
                            for (final info in shipyardInfos)
                              DropdownMenuItem<String>(
                                value: info.hexId,
                                enabled:
                                    !info.isBlocked && info.capacity > 0,
                                child: Text(
                                  info.isBlocked
                                      ? '${info.label} \u00B7 blocked'
                                      : '${info.label} \u00B7 '
                                          '${info.capacity - info.used}'
                                          '/${info.capacity} HP remaining',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (info.isBlocked || info.capacity == 0)
                                            ? theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4)
                                            : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                if (buyableShips.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      'No ships available.\nCheck your tech levels and remaining CP.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                for (final entry in buyableShips)
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(
                      (type: entry.key, hexId: selectedHexId),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
                            '${entry.value.effectiveBuildCost(isAlt, facilitiesMode: facilitiesMode)}CP',
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
                            onPressed: () => showShipInfoDialog(
                              ctx,
                              entry.key,
                              facilitiesMode: facilitiesMode,
                              onRuleTap: widget.onRuleTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        final updated =
            List<ShipPurchase>.from(production.shipPurchases)
              ..add(ShipPurchase(
                type: result.type,
                shipyardHexId: result.hexId,
              ));
        widget.onProductionChanged(
            production.copyWith(shipPurchases: updated));
      }
    });
  }

  // ===========================================================================
  // Worlds section (Problem 1 - redesigned)
  // ===========================================================================

  Widget _buildPipelineSection(BuildContext context) {
    final theme = Theme.of(context);
    final connected = production.pipelineConnectedColonies;
    final traders = config.empireAdvantage?.cardNumber == 49;
    final multiplier = traders ? 2 : 1;
    final income = connected * multiplier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: 'PIPELINES',
          subtitle: connected > 0 ? '$connected connected' : null,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Enter the number of colonies currently connected to your pipeline trade network. Each gives +1 CP${traders ? ' (x2 for Traders)' : ''}. A colony counts only once per Economic Phase regardless of how many pipelines touch it (rule 13.2.2).',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            IconButton(
              tooltip: 'How pipeline income works',
              onPressed: () => _showInlineHelp(
                context,
                'Pipelines',
                'Enter the number of colonies currently connected to your pipeline trade network. Each connected colony gives +1 CP (or +2 CP with the Traders Empire Advantage). Per rule 13.2.2, each colony counts only once per Economic Phase no matter how many pipelines connect to it. Map placement of pipeline tokens is tracked separately in the Map tab.',
              ),
              icon: const Icon(Icons.info_outline, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 6,
              children: [
                _LabeledWorldControl(
                  label: 'Connected Colonies',
                  helpText:
                      'Count of colonies connected to the pipeline trade network. Each counts once per Economic Phase (rule 13.2.2).',
                  child: NumberInput(
                    value: connected,
                    onChanged: _updatePipelineConnectedColonies,
                    min: 0,
                  ),
                ),
                Text(
                  'Pipeline income: $income CP${traders ? ' ($connected x 2)' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
                // Blocked toggle (rule 2.8: colony rules apply to homeworlds;
                // rule 7.1.2: blockaded worlds defer income/staged minerals).
                _CompactToggle(
                  label: 'Blocked',
                  helpText:
                      'Per rule 2.8, rules that apply to Colonies also apply to Homeworlds. '
                      'A blockaded homeworld produces no CP/RP/LP/TP this turn, and any '
                      'staged mineral markers are deferred until the blockade lifts (7.1.2).',
                  value: world.isBlocked,
                  onChanged: (v) =>
                      _updateWorld(index, (w) => w.copyWith(isBlocked: v)),
                ),
                const SizedBox(width: 4),
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
            if (config.enableFacilities) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (config.enableFacilities) ...[
                    _LabeledWorldControl(
                      label: 'Facility',
                      helpText:
                          'Facilities are optional colony improvements. IC = Industrial Center, RC = Research Center, LC = Logistics Center, and TC = Temporal Center.',
                      child: _FacilityChip(
                        facility: world.facility,
                        onChanged: (f) => _updateWorld(
                          index,
                          (w) => f == null
                              ? w.copyWith(clearFacility: true)
                              : w.copyWith(facility: f),
                        ),
                      ),
                    ),
                  ],
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
                  label: 'Blocked',
                  helpText:
                      'Blocked colonies usually do not produce normally. Replicator colonies are a special case in the rules.',
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
            // Line 2: Mineral, Facility
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LabeledWorldControl(
                  label: 'Staged Minerals',
                  helpText:
                      'Mineral marker CP deposited on this colony by Mining Ships, awaiting collection. Cleared each Economic Phase (rule 7.2). Blockaded colonies defer collection until the blockade lifts (7.1.2).',
                  child: NumberInput(
                    value: world.stagedMineralCp,
                    onChanged: (v) =>
                        _updateWorld(index, (w) => w.copyWith(stagedMineralCp: v)),
                    min: 0,
                  ),
                ),
                if (config.enableFacilities) ...[
                  _LabeledWorldControl(
                    label: 'Facility',
                    helpText:
                        'Facilities are optional colony improvements. Industrial, Research, Logistics, and Temporal Centers change how a colony contributes to the ledger.',
                    child: _FacilityChip(
                      facility: world.facility,
                      onChanged: (f) => _updateWorld(
                        index,
                        (w) => f == null
                            ? w.copyWith(clearFacility: true)
                            : w.copyWith(facility: f),
                      ),
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
      ..add(WorldState(
        id: 'world-${production.worlds.length + 1}',
        name: 'Colony $nextNum',
      ));
    widget.onProductionChanged(production.copyWith(worlds: updated));
  }

  void _removeColony(int index) {
    if (production.worlds[index].isHomeworld) return;
    final updated = List<WorldState>.from(production.worlds)..removeAt(index);
    widget.onProductionChanged(production.copyWith(worlds: updated));
  }

  void _updatePipelineConnectedColonies(int value) {
    final clamped = value < 0 ? 0 : value;
    widget.onProductionChanged(
      production.copyWith(pipelineConnectedColonies: clamped),
    );
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

  // ===========================================================================
  // Cards in hand (T3-C)
  // ===========================================================================

  Widget _buildCardsSection(BuildContext context) {
    final theme = Theme.of(context);
    final hand = widget.drawnHand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'CARDS',
          subtitle: hand.isEmpty ? 'empty hand' : '${hand.length} in hand',
          trailing: TextButton.icon(
            onPressed: () => _showDrawCardDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Draw'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (hand.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'No cards drawn. Tap "Draw" to add Action, Alien Tech, or '
              'Crew cards from the deck.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          for (var i = 0; i < hand.length; i++) _buildDrawnCardTile(context, i),
      ],
    );
  }

  Widget _buildDrawnCardTile(BuildContext context, int index) {
    final theme = Theme.of(context);
    final card = widget.drawnHand[index];
    final entry = _lookupCardEntry(card.cardNumber);
    final title = entry != null
        ? '#${card.cardNumber} ${entry.name}'
        : '#${card.cardNumber}';
    final typeLabel = entry?.type ?? 'unknown';
    final canPlayAsEvent = card.assignedModifiers.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                card.isFaceUp ? Icons.visibility : Icons.visibility_off,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$typeLabel \u00B7 T${card.drawnOnTurn}',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (entry != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.description,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (card.assignedModifiers.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.assignedModifiers
                  .map((m) => m.effectDescription)
                  .join(' \u2022 '),
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed:
                    canPlayAsEvent ? () => _playCardAsEvent(index) : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Play as event',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: () => _playCardForCredits(index),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Play for credits',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: () => _toggleCardFaceUp(index),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  card.isFaceUp ? 'Flip down' : 'Flip up',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: () => _discardCard(index),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text(
                  'Discard',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static CardEntry? _lookupCardEntry(int cardNumber) {
    for (final c in kAllCards) {
      if (c.number == cardNumber) return c;
    }
    return null;
  }

  Future<void> _showDrawCardDialog(BuildContext context) async {
    String query = '';
    String typeFilter = 'all';
    final allCards = kAllCards;
    final selected = await showDialog<CardEntry>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            final q = query.toLowerCase();
            final filtered = allCards.where((c) {
              if (typeFilter != 'all' && c.type != typeFilter) return false;
              if (q.isEmpty) return true;
              return c.name.toLowerCase().contains(q) ||
                  c.description.toLowerCase().contains(q) ||
                  '#${c.number}'.contains(q);
            }).toList();
            return AlertDialog(
              title: const Text('Draw Card'),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        isDense: true,
                      ),
                      onChanged: (v) => setInnerState(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final t in const [
                          'all',
                          'resource',
                          'alienTech',
                          'crew',
                          'mission',
                          'planetAttribute',
                        ])
                          ChoiceChip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: typeFilter == t,
                            onSelected: (_) =>
                                setInnerState(() => typeFilter = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final card = filtered[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              '#${card.number} ${card.name}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${card.type} \u00B7 ${card.description}',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.pop(ctx, card),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) {
      _drawCard(selected);
    }
  }

  void _drawCard(CardEntry entry) {
    final binding = cardModifiersFor(entry.number);
    final mods = binding?.modifiers ?? const <GameModifier>[];
    final drawn = DrawnCard(
      cardNumber: entry.number,
      drawnOnTurn: widget.turnNumber,
      assignedModifiers: List<GameModifier>.from(mods),
    );
    widget.onDrawnHandChanged?.call([...widget.drawnHand, drawn]);
  }

  void _playCardAsEvent(int index) {
    final card = widget.drawnHand[index];
    if (card.assignedModifiers.isEmpty) return;
    final entry = _lookupCardEntry(card.cardNumber);
    final name = entry?.name ?? 'Card #${card.cardNumber}';
    widget.onPlayCardAsEvent?.call(name, card.assignedModifiers);
    final updated = List<DrawnCard>.from(widget.drawnHand)..removeAt(index);
    widget.onDrawnHandChanged?.call(updated);
  }

  Future<void> _playCardForCredits(int index) async {
    final card = widget.drawnHand[index];
    final entry = _lookupCardEntry(card.cardNumber);
    final name = entry?.name ?? 'Card #${card.cardNumber}';
    final defaultCp = _parseCpValue(entry?.cpValue) ?? 10;
    final controller = TextEditingController(text: '$defaultCp');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Play "$name" for credits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discard this card for a one-time CP income bonus this turn.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CP gained',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
    if (result == null || result <= 0) return;
    widget.onPlayCardForCredits?.call(name, result);
    final updated = List<DrawnCard>.from(widget.drawnHand)..removeAt(index);
    widget.onDrawnHandChanged?.call(updated);
  }

  void _discardCard(int index) {
    final updated = List<DrawnCard>.from(widget.drawnHand)..removeAt(index);
    widget.onDrawnHandChanged?.call(updated);
  }

  void _toggleCardFaceUp(int index) {
    final updated = List<DrawnCard>.from(widget.drawnHand);
    updated[index] =
        updated[index].copyWith(isFaceUp: !updated[index].isFaceUp);
    widget.onDrawnHandChanged?.call(updated);
  }

  static int? _parseCpValue(String? cpValue) {
    if (cpValue == null) return null;
    final m = RegExp(r'(\d+)').firstMatch(cpValue);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
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
    final remainingCp = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final cpLost = remainingCp > 30 ? remainingCp - 30 : 0;
    final remainingRp = config.enableFacilities ? production.remainingRp(config, modifiers) : null;
    final rpLost = (remainingRp != null && remainingRp > 30) ? remainingRp - 30 : 0;
    final warnColor = Theme.of(context).colorScheme.tertiary;

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
                style: TextStyle(color: warnColor),
              ),
            ],
            if (rpLost > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Warning: $rpLost RP will be lost (carry-over max 30).',
                style: TextStyle(color: warnColor),
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
  final String? helpText;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactToggle({
    required this.label,
    this.helpText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = value
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        ),
        if (helpText != null)
          IconButton(
            tooltip: 'What does this mean?',
            onPressed: () => _showInlineHelp(context, label, helpText!),
            icon: const Icon(Icons.info_outline, size: 18),
            visualDensity: VisualDensity.compact,
          ),
      ],
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

  static const _labels = {
    FacilityType.industrial: 'Industrial',
    FacilityType.research: 'Research',
    FacilityType.logistics: 'Logistics',
    FacilityType.temporal: 'Temporal',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = facility != null ? _labels[facility]! : 'None';
    final active = facility != null;

    return GestureDetector(
      onTap: _cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        constraints: const BoxConstraints(minWidth: 96, minHeight: 44),
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

class _LabeledWorldControl extends StatelessWidget {
  final String label;
  final String? helpText;
  final Widget child;

  const _LabeledWorldControl({
    required this.label,
    required this.child,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (helpText != null)
          IconButton(
            tooltip: 'What does this mean?',
            onPressed: () => _showInlineHelp(context, label, helpText!),
            icon: const Icon(Icons.info_outline, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        child,
      ],
    );
  }
}

/// QW-2: Per-hex shipyard summary used by the Add Ship dialog and the
/// shipyard capacity strip.
class _ShipyardHexInfo {
  final String hexId;
  final String label;
  final int shipyardCount;
  final int capacity;
  final int used;
  final bool isBlocked;
  final bool isHomeworld;

  const _ShipyardHexInfo({
    required this.hexId,
    required this.label,
    required this.shipyardCount,
    required this.capacity,
    required this.used,
    required this.isBlocked,
    required this.isHomeworld,
  });
}

void _showInlineHelp(BuildContext context, String title, String text) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
