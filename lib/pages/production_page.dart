import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/card_lookup.dart';
import '../data/card_manifest.dart';
import '../data/card_modifiers.dart';
import '../data/counter_pool.dart' as counter_pool;
import '../data/scenarios.dart';
import '../data/sci_fi_names.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../data/temporal_effects.dart';
import '../data/unique_ship_designer.dart';
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
import '../tutorial/tutorial_targets.dart';
import '../widgets/card_detail_dialog.dart';
import '../widgets/card_history_dialog.dart';
import '../widgets/complex_behavior_banner.dart';
import '../widgets/empire_summary_card.dart';
import '../widgets/ledger_grid.dart';
import '../widgets/number_input.dart';
import '../widgets/research_grant_dialog.dart';
import '../widgets/section_header.dart';
import '../widgets/ship_info_dialog.dart';
import '../widgets/manual_override_dialog.dart';
import '../widgets/tech_detail_dialog.dart';
import '../widgets/tech_tracker.dart';
import '../widgets/unique_ship_designer_dialog.dart';

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

    // Unique ships (§41): require Advanced Construction >= 1. Cost is
    // computed from a UniqueShipDesign payload via the designer dialog
    // (PP02). We do not enforce per-ability tech prereqs here — those are
    // surfaced as advisory text in the designer itself.
    case ShipType.un:
      return effectiveLevel(TechId.advancedCon) >= 1;

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
  final List<DrawnCard> playedCards;
  final ValueChanged<List<DrawnCard>>? onDrawnHandChanged;
  final void Function(String cardName, List<GameModifier> modifiers)?
      onPlayCardAsEvent;
  /// Fired when the player discards a drawn card for a one-shot CP bonus.
  /// [sourceCardId] is the stable identity string (`card:<type>:<number>:credits:<turn>`)
  /// used to deduplicate the generated income modifier in the active ledger.
  final void Function(
          String cardName, int cpGained, String sourceCardId)?
      onPlayCardForCredits;

  /// PP01: composite card-play handlers. When set, the ProductionPage
  /// delegates the full play mutation to home_page in one step. The
  /// legacy [onDrawnHandChanged] / [onPlayCardAsEvent] / [onPlayCardForCredits]
  /// plumbing is bypassed for those actions.
  final void Function(int index, List<GameModifier> modifiers)?
      onCardPlayedAsEvent;
  final void Function(int index, int cpGained, String sourceCardId)?
      onCardPlayedForCredits;
  final void Function(int index)? onCardDiscarded;
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
    this.playedCards = const [],
    this.onDrawnHandChanged,
    this.onPlayCardAsEvent,
    this.onPlayCardForCredits,
    this.onCardPlayedAsEvent,
    this.onCardPlayedForCredits,
    this.onCardDiscarded,
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

  // ---- Wave 2.1: Research log expansion state ----
  bool _researchLogExpanded = false;

  // ---- PP06: Jump-menu anchor keys ----
  //
  // Each major section on the Production page gets a GlobalKey so the
  // quick-jump menu in the sticky header can scroll to it with
  // Scrollable.ensureVisible. Keys are attached via KeyedSubtree in build().
  final GlobalKey _anchorCpLedger = GlobalKey(debugLabel: 'anchor-cp-ledger');
  final GlobalKey _anchorFleetRoster = GlobalKey(debugLabel: 'anchor-fleet-roster');
  final GlobalKey _anchorTech = GlobalKey(debugLabel: 'anchor-tech');
  final GlobalKey _anchorShipyards = GlobalKey(debugLabel: 'anchor-shipyards');
  final GlobalKey _anchorShipPurchases = GlobalKey(debugLabel: 'anchor-ship-purchases');
  final GlobalKey _anchorPipelines = GlobalKey(debugLabel: 'anchor-pipelines');
  final GlobalKey _anchorWorlds = GlobalKey(debugLabel: 'anchor-worlds');
  final GlobalKey _anchorCards = GlobalKey(debugLabel: 'anchor-cards');

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
    if (config.strongHaptics) HapticFeedback.selectionClick();
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
    if (config.strongHaptics) HapticFeedback.selectionClick();
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

    // PP06: sticky REMAINING CP header + quick-jump menu sit ABOVE the
    // scrollable content so they stay visible no matter where the player
    // has scrolled.
    return Column(
      children: [
        _buildStickyProductionHeader(theme),
        Expanded(
          child: ListView(
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
                KeyedSubtree(
                  key: TutorialTargets.prodCpLedger,
                  child: KeyedSubtree(
                    key: _anchorCpLedger,
                    child: _buildCpLedgerFacilities(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildRpLedger(),
                if (config.enableTemporal) ...[
                  const SizedBox(height: 16),
                  _buildTpLedger(),
                  if (config.enableFacilities)
                    _buildTpEffectsSection(context),
                ],
              ] else ...[
                KeyedSubtree(
                  key: TutorialTargets.prodCpLedger,
                  child: KeyedSubtree(
                    key: _anchorCpLedger,
                    child: _buildCpLedgerBase(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Fleet Roster
              KeyedSubtree(
                key: _anchorFleetRoster,
                child: _buildFleetRoster(context),
              ),

              const SizedBox(height: 16),

              // Technology
              KeyedSubtree(
                key: TutorialTargets.prodTechSection,
                child: KeyedSubtree(
                  key: _anchorTech,
                  child: _buildTechSection(context),
                ),
              ),

              // Wave 2.1: Research log (current turn audit trail)
              _buildResearchLogSection(context),

              const SizedBox(height: 16),

              // Ship Purchases (Problem 4)
              // The outer anchor lands on SHIPYARDS; a second inner anchor
              // for SHIP PURCHASES is attached inside the builder.
              KeyedSubtree(
                key: _anchorShipyards,
                child: _buildShipPurchaseSection(context),
              ),

              const SizedBox(height: 16),

              // Pipeline inventory
              KeyedSubtree(
                key: _anchorPipelines,
                child: _buildPipelineSection(context),
              ),

              const SizedBox(height: 16),

              // Worlds
              KeyedSubtree(
                key: _anchorWorlds,
                child: _buildWorldsSection(context),
              ),

              const SizedBox(height: 16),

              // Cards in hand (T3-C)
              KeyedSubtree(
                key: _anchorCards,
                child: _buildCardsSection(context),
              ),

              const SizedBox(height: 20),

              // End Turn
              KeyedSubtree(
                key: TutorialTargets.prodEndTurnButton,
                child: _buildEndTurnButton(context),
              ),

              const SizedBox(height: 16),
              _buildManualOverrideButton(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PP06: Sticky header (REMAINING CP, Turn, Hand) + quick-jump menu
  // ===========================================================================

  /// Slim sticky bar that always shows turn, remaining CP, and hand size.
  /// Hosts the quick-jump popup menu on the right.
  Widget _buildStickyProductionHeader(ThemeData theme) {
    final remaining = production.remainingCp(
      config,
      shipCounters,
      modifiers,
      abilities,
      mapState,
    );
    final handSize = widget.drawnHand.length;
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final accent = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 0,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Turn N
            Text(
              'Turn ${widget.turnNumber}',
              style: TextStyle(
                fontSize: 13,
                color: dim,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 14),
            // REMAINING CP label + value
            Text(
              'REMAINING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: dim,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$remaining CP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: remaining < 0
                    ? theme.colorScheme.error
                    : accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (handSize > 0) ...[
              const SizedBox(width: 14),
              Icon(Icons.style_outlined, size: 14, color: dim),
              const SizedBox(width: 4),
              Text(
                '$handSize',
                style: TextStyle(
                  fontSize: 13,
                  color: dim,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const Spacer(),
            _buildJumpMenuButton(theme),
          ],
        ),
      ),
    );
  }

  /// Quick-jump menu — tap to open a list of section anchors.
  Widget _buildJumpMenuButton(ThemeData theme) {
    return PopupMenuButton<GlobalKey>(
      tooltip: 'Jump to section',
      icon: const Icon(Icons.menu, size: 20),
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: _scrollToAnchor,
      itemBuilder: (context) => [
        _jumpMenuItem('Income / CP Ledger', _anchorCpLedger),
        _jumpMenuItem('Fleet Roster', _anchorFleetRoster),
        _jumpMenuItem('Technology', _anchorTech),
        _jumpMenuItem('Shipyards', _anchorShipyards),
        _jumpMenuItem('Ship Purchases', _anchorShipPurchases),
        _jumpMenuItem('Pipelines', _anchorPipelines),
        _jumpMenuItem('Worlds', _anchorWorlds),
        _jumpMenuItem('Cards', _anchorCards),
      ],
    );
  }

  PopupMenuItem<GlobalKey> _jumpMenuItem(String label, GlobalKey key) {
    return PopupMenuItem<GlobalKey>(
      value: key,
      child: Text(label),
    );
  }

  /// Scrolls the ListView so the widget attached to [key] is visible.
  /// Silently no-ops if the key's context is not yet mounted (section may
  /// be hidden behind a config flag, e.g. SHIPYARDS collapses out with no
  /// purchases pending).
  void _scrollToAnchor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message:
                        'Turn Log (${widget.turnSummaries.length} past turn'
                        '${widget.turnSummaries.length == 1 ? '' : 's'})',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history, size: 22),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                          onPressed: () => _showTurnLogModal(context),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${widget.turnSummaries.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...chips,
              // 2.3: tappable indicator for full config dialog
              Tooltip(
                message: 'Tap for full config',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'details',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.75),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.75),
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
    lines.add('  Multi-Turn Builds: ${config.enableMultiTurnBuilds ? "on" : "off"}');
    lines.add('  Free Ground Troops: ${config.enableFreeGroundTroops ? "on" : "off"}');
    lines.add('  Nebula Mining: ${config.enableNebulaMining ? "on" : "off"}');
    lines.add('  Alternate Empire: ${config.enableAlternateEmpire ? "on" : "off"}');
    final scenario = scenarioById(config.scenarioId);
    lines.add('  Scenario: ${scenario?.name ?? "(none)"}');
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

    // Collect the global (across-all-types) percent modifier for display.
    int? globalPercent;
    for (final mod in modifiers) {
      if (mod.type != 'maintenanceMod') continue;
      if (mod.isPercent && mod.shipType == null) {
        globalPercent = mod.value;
      }
    }

    // Use the canonical per-type subtotal helper so the dialog and the
    // fleet-roster rows never disagree.
    final subtotals =
        production.maintenanceSubtotalsByType(shipCounters, config, modifiers);

    // Per-ship cost (for the "N × Type @ X = Y CP" display line) is the
    // subtotal / count for each type.
    final counts = <ShipType, int>{};
    final perShip = <ShipType, int>{};
    for (final c in shipCounters) {
      if (!c.isBuilt) continue;
      final def = kShipDefinitions[c.type];
      if (def == null || def.maintenanceExempt) continue;
      counts[c.type] = (counts[c.type] ?? 0) + 1;
    }
    for (final t in counts.keys) {
      final n = counts[t] ?? 0;
      if (n > 0) perShip[t] = (subtotals[t] ?? 0) ~/ n;
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Recompute the live total each build so the dialog reflects
          // edits to maintenance inc/dec without reopening.
          final liveTotal =
              production.maintenanceTotal(shipCounters, config, modifiers);
          return AlertDialog(
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
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7)),
                  ),
                  if (adjustments.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    for (final a in adjustments)
                      Text(a,
                          style: rowStyle.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7))),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Manual adjustments',
                    style: rowStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Maintenance increase from buys',
                          style: rowStyle,
                        ),
                      ),
                      NumberInput(
                        value: production.maintenanceIncrease,
                        min: 0,
                        onChanged: (v) {
                          _update(
                              (s) => s.copyWith(maintenanceIncrease: v));
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Maintenance decrease from losses',
                          style: rowStyle,
                        ),
                      ),
                      NumberInput(
                        value: production.maintenanceDecrease,
                        min: 0,
                        onChanged: (v) {
                          _update(
                              (s) => s.copyWith(maintenanceDecrease: v));
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total: $liveTotal CP',
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
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Reserved CP info
  // ===========================================================================

  void _showReservedCpTooltip(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reserved CP'),
        content: const Text(
          'Reserved CP carries forward above the 30-cap, for planned upgrade '
          'purchases next turn.\n\n'
          'Normally any CP remaining at End Turn is clamped to 30 and the rest '
          'is lost. CP you earmark here is subtracted from your available CP '
          'this turn (so you can\'t spend it), and is added back on top of '
          'the normal carry-over next turn as '
          '"+ Carried from last turn (above cap)".',
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
  // Upgrades CP info (BUG-L5: ledger row is now read-only / auto-accumulated)
  // ===========================================================================

  void _showUpgradesCpInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CP spent on upgrades'),
        content: const Text(
          'This number is auto-accumulated from upgrade actions you take on '
          'the Ships tab. It is read-only here to prevent accidentally '
          'overwriting the running total.\n\n'
          'If you need to correct the value manually, use the manual override '
          'dialog (gear menu).',
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
  // Free Ground Units info chip (BUG-L1: surfaced below the CP ledger)
  // ===========================================================================

  Widget _buildFreeGroundUnitsInfo() {
    if (!config.enableFreeGroundTroops) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final count = production.freeGroundTroopsPlaceable(config);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Placeable this turn: $count free ground unit'
              '${count == 1 ? '' : 's'} (rule 21.5)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
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
                    // Bug D: surface activeModifiers that were active at end
                    // of turn so history is auditable.
                    final snapModifiers = <GameModifier>[];
                    final gss = summary.gameStateSnapshot;
                    if (gss != null) {
                      final raw = gss['activeModifiers'];
                      if (raw is List) {
                        for (final entry in raw) {
                          if (entry is Map<String, dynamic>) {
                            snapModifiers.add(GameModifier.fromJson(entry));
                          } else if (entry is Map) {
                            snapModifiers.add(GameModifier.fromJson(
                                Map<String, dynamic>.from(entry)));
                          }
                        }
                      }
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
                              if (snapModifiers.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Active modifiers at end of turn:',
                                  style: dimStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    for (final m in snapModifiers)
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        label: Text(
                                          '${m.name}: ${m.effectDescription}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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
    final shipSpending = production.shipPurchaseCost(config, modifiers, abilities);
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final unpredictable = config.enableUnpredictableResearch;

    final ledger = LedgerGrid(
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
        if (production.reservedCpFromPrevTurn > 0)
          LedgerRow(
            label: '+ Carried from last turn (above cap)',
            computedValue: production.reservedCpFromPrevTurn,
            onTap: () => _showReservedCpTooltip(context),
            onTapTooltip:
                'CP you reserved last turn for use this turn '
                '(above the 30-cap rollover).',
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
          onTapTooltip: 'Tap for ship-type breakdown',
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
        LedgerRow(
            label: '- Ship Spending (purchases)',
            computedValue: shipSpending),
        LedgerRow(
          label: '- CP spent on upgrades',
          computedValue: production.upgradesCp,
          onTap: () => _showUpgradesCpInfo(context),
          onTapTooltip:
              'Auto-accumulated from upgrade actions on the Ships tab. '
              'Tap for details. To override, use the manual override dialog.',
        ),
        LedgerRow(
          label: '- Reserved for next turn',
          value: production.reservedCpForNextTurn,
          isEditable: true,
          min: 0,
          onChanged: (v) =>
              _update((s) => s.copyWith(reservedCpForNextTurn: v)),
          onTap: () => _showReservedCpTooltip(context),
          onTapTooltip:
              'No restrictions — just an above-the-cap CP carry-over earmark.',
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
    if (config.enableFreeGroundTroops) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ledger,
          _buildFreeGroundUnitsInfo(),
        ],
      );
    }
    return ledger;
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
          onTapTooltip: 'Tap for ship-type breakdown',
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
    final shipSpending = production.shipPurchaseCost(config, modifiers, abilities);
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final unpredictable = config.enableUnpredictableResearch;

    final ledger = LedgerGrid(
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
        if (production.reservedCpFromPrevTurn > 0)
          LedgerRow(
            label: '+ Carried from last turn (above cap)',
            computedValue: production.reservedCpFromPrevTurn,
            onTap: () => _showReservedCpTooltip(context),
            onTapTooltip:
                'CP you reserved last turn for use this turn '
                '(above the 30-cap rollover).',
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
        LedgerRow(
            label: '- Purchases (from list)',
            computedValue: shipSpending),
        LedgerRow(
          label: '- CP spent on upgrades',
          computedValue: production.upgradesCp,
          onTap: () => _showUpgradesCpInfo(context),
          onTapTooltip:
              'Auto-accumulated from upgrade actions on the Ships tab. '
              'Tap for details. To override, use the manual override dialog.',
        ),
        LedgerRow(
          label: '- Reserved for next turn',
          value: production.reservedCpForNextTurn,
          isEditable: true,
          min: 0,
          onChanged: (v) =>
              _update((s) => s.copyWith(reservedCpForNextTurn: v)),
          onTap: () => _showReservedCpTooltip(context),
          onTapTooltip:
              'No restrictions — just an above-the-cap CP carry-over earmark.',
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
    if (config.enableFreeGroundTroops) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ledger,
          _buildFreeGroundUnitsInfo(),
        ],
      );
    }
    return ledger;
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
          label: '- TP Spending (effects)',
          computedValue: production.tpSpendingDerived(),
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
  // TP Effects shopping cart (WP4)
  // ===========================================================================

  Widget _buildTpEffectsSection(BuildContext context) {
    final theme = Theme.of(context);
    final expenditures = production.tpExpenditures;
    final totalCost = production.tpSpendingDerived();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'TP EFFECTS',
          subtitle: totalCost > 0 ? '$totalCost TP' : null,
        ),
        if (expenditures.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Spend TP to activate temporal effects during your turn.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        for (int i = 0; i < expenditures.length; i++)
          _buildTpExpenditureRow(context, i, expenditures[i]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Effect'),
            onPressed: () => _showAddEffectDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTpExpenditureRow(BuildContext context, int index, TpExpenditure exp) {
    final theme = Theme.of(context);
    if (exp.effectIndex < 0 || exp.effectIndex >= kTemporalEffects.length) {
      return const SizedBox.shrink();
    }
    final effect = kTemporalEffects[exp.effectIndex];
    final cost = exp.cost();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(effect.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  effect.costDescription,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          if (effect.perUnit)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: exp.quantity <= 1 ? null : () {
                    _updateTpExpenditure(index, exp.copyWith(quantity: exp.quantity - 1));
                  },
                ),
                SizedBox(width: 28, child: Text('${exp.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _updateTpExpenditure(index, exp.copyWith(quantity: exp.quantity + 1));
                  },
                ),
              ],
            ),
          if (effect.perHullPoint)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('HP:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: exp.hullPoints <= 0 ? null : () {
                    _updateTpExpenditure(index, exp.copyWith(hullPoints: exp.hullPoints - 1));
                  },
                ),
                SizedBox(width: 28, child: Text('${exp.hullPoints}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _updateTpExpenditure(index, exp.copyWith(hullPoints: exp.hullPoints + 1));
                  },
                ),
              ],
            ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text('$cost TP', textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _removeTpExpenditure(index),
          ),
        ],
        ),
      ),
    );
  }

  void _updateTpExpenditure(int index, TpExpenditure updated) {
    final list = List<TpExpenditure>.from(production.tpExpenditures);
    list[index] = updated;
    widget.onProductionChanged(production.copyWith(tpExpenditures: list));
  }

  void _removeTpExpenditure(int index) {
    final list = List<TpExpenditure>.from(production.tpExpenditures)..removeAt(index);
    widget.onProductionChanged(production.copyWith(tpExpenditures: list));
  }

  void _showAddEffectDialog(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <TemporalRange, List<(int, TemporalEffect)>>{};
    for (int i = 0; i < kTemporalEffects.length; i++) {
      final e = kTemporalEffects[i];
      groups.putIfAbsent(e.locationRequirement, () => []).add((i, e));
    }

    final rangeLabels = {
      TemporalRange.sameHex: 'Same Hex as Temporal Engine',
      TemporalRange.within3: 'Within 3 Hexes of Temporal Engine',
      TemporalRange.anywhere: 'Temporal Engine Anywhere on Board',
    };

    showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add Temporal Effect'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final range in TemporalRange.values)
            if (groups[range] != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(
                  rangeLabels[range]!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final (idx, effect) in groups[range]!)
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(idx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(effect.name, style: const TextStyle(fontSize: 14)),
                              Text(
                                effect.costDescription,
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        Text('${effect.baseCost} TP',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                ),
            ],
        ],
      ),
    ).then((effectIndex) {
      if (effectIndex != null) {
        final list = List<TpExpenditure>.from(production.tpExpenditures)
          ..add(TpExpenditure(effectIndex: effectIndex));
        widget.onProductionChanged(
          production.copyWith(tpExpenditures: list),
        );
      }
    });
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
    // Use the canonical per-type subtotal so row values always agree with
    // the header's total (which goes through maintenanceTotal). This
    // applies EA hull-size mod, per-type percent modifiers, etc.
    final subtotals =
        production.maintenanceSubtotalsByType(shipCounters, config, modifiers);
    final maintCost = exempt ? null : (subtotals[type] ?? 0);
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
            onPressed: () => showShipInfoDialog(context, type, facilitiesMode: config.useFacilitiesCosts, isAlternateEmpire: config.enableAlternateEmpire, onRuleTap: widget.onRuleTap),
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

  // ===========================================================================
  // Wave 2.1: Research log (current turn)
  // ===========================================================================

  Widget _buildResearchLogSection(BuildContext context) {
    final log = production.researchLog;
    if (log.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final count = log.length;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(
              () => _researchLogExpanded = !_researchLogExpanded,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _researchLogExpanded
                        ? Icons.expand_more
                        : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'RESEARCH LOG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($count this turn)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_researchLogExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final event in log) _buildResearchLogRow(theme, event),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResearchLogRow(ThemeData theme, ResearchEvent event) {
    IconData icon;
    String label;
    Color color = theme.colorScheme.onSurface.withValues(alpha: 0.8);
    switch (event.kind) {
      case ResearchEventKind.techPurchased:
        final e = event as TechPurchasedEvent;
        icon = Icons.shopping_cart_outlined;
        final name = _techDisplayNames[e.techId] ?? e.techId.name;
        final costParts = <String>[];
        if (e.cpCost > 0) costParts.add('${e.cpCost}CP');
        if (e.rpCost > 0) costParts.add('${e.rpCost}RP');
        final cost = costParts.isEmpty ? '' : ' (${costParts.join(" + ")})';
        label = '$name L${e.fromLevel}\u2192L${e.toLevel}$cost';
        break;
      case ResearchEventKind.grantRolled:
        final e = event as GrantRolledEvent;
        icon = e.success ? Icons.check_circle_outline : Icons.casino_outlined;
        final name = _techDisplayNames[e.techId] ?? e.techId.name;
        label = 'Grant roll $name L${e.targetLevel}: '
            '${e.dieResult} (${e.outcomeCpSpent}CP)'
            '${e.success ? " \u2014 breakthrough" : ""}';
        color = e.success
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.8);
        break;
      case ResearchEventKind.grantReassigned:
        final e = event as GrantReassignedEvent;
        icon = Icons.swap_horiz;
        final from = _techDisplayNames[e.fromTechId] ?? e.fromTechId.name;
        final to = _techDisplayNames[e.toTechId] ?? e.toTechId.name;
        label = 'Reassigned ${e.accumulatedCp}CP: $from \u2192 $to';
        break;
      case ResearchEventKind.techGrantedByCard:
        final e = event as TechGrantedByCardEvent;
        icon = Icons.card_giftcard;
        final name = _techDisplayNames[e.techId] ?? e.techId.name;
        label = 'Card grant: $name L${e.targetLevel} '
            '(${e.sourceCardName})';
        color = theme.colorScheme.tertiary;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

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
    // Rule 9.6: Lvl 1 = 1 HP, Lvl 2 = 2 HP, Lvl 3 = 3 HP per turn per shipyard.
    // Source of truth: ProductionState.hullPointsPerShipyard.
    final double hpPerSy = ProductionState.hullPointsPerShipyard(syLevel);
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

    final shipyardInfos = _shipyardHexes();
    // Warning trigger: queued non-SY, non-exempt ships but no active SY hex.
    final hasQueuedNonSyShips = purchases.any((p) =>
        p.type != ShipType.shipyard &&
        !(kShipDefinitions[p.type]?.isShipyardExempt ?? true));
    final showShipyardWarning =
        hasQueuedNonSyShips && shipyardInfos.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // SHIPYARDS section — hoisted so the player can see at a glance
        // where ships will be built (or that they have none yet).
        KeyedSubtree(
          key: TutorialTargets.prodShipyardsSection,
          child: SectionHeader(
            title: 'SHIPYARDS',
            subtitle: shipyardInfos.isEmpty
                ? 'none yet'
                : '${shipyardInfos.length} active',
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              tooltip: 'About Shipyards',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _showShipyardHelpDialog(context),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // QW-2: Per-hex capacity strip so the player always knows how much
        // shipyard HP budget each hex has remaining this turn.
        _buildShipyardHexCapacityStrip(context),
        if (shipyardInfos.isEmpty) _buildShipyardEmptyStateCard(context),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: TutorialTargets.prodPurchasesSection,
          child: KeyedSubtree(
            key: _anchorShipPurchases,
            child: SectionHeader(
              title: 'SHIP PURCHASES',
              subtitle: purchases.isNotEmpty ? 'total: ${totalCost}CP' : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (showShipyardWarning) _buildNoShipyardWarningCard(context),
        for (int i = 0; i < purchases.length; i++)
          _buildShipPurchaseRow(i, purchases[i], theme),
        const SizedBox(height: 4),
        // F7: Maintenance forecast. To stay consistent with the header
        // maintenance total, we construct hypothetical ShipCounter objects
        // that represent what each queued purchase will materialize into,
        // then run the whole list through the canonical maintenanceTotal
        // pipeline (EA hull-size mod, per-type and global modifier %, etc).
        Builder(builder: (context) {
          final hypotheticals = <ShipCounter>[];
          for (final p in purchases) {
            final def = kShipDefinitions[p.type];
            if (def == null || def.maintenanceExempt) continue;
            for (int i = 0; i < p.quantity; i++) {
              // number is irrelevant for maintenance math; use a sentinel.
              hypotheticals.add(ShipCounter(
                type: p.type,
                number: -1 - i,
                isBuilt: true,
              ));
            }
          }
          if (hypotheticals.isEmpty) {
            return const SizedBox.shrink();
          }
          final currentMaint =
              production.maintenanceTotal(shipCounters, config, modifiers);
          final hypotheticalMaint = production.maintenanceTotal(
            [...shipCounters, ...hypotheticals],
            config,
            modifiers,
          );
          final delta = hypotheticalMaint - currentMaint;
          if (delta <= 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Next turn maint: $hypotheticalMaint (+$delta)',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
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

  /// Empty-state card shown above SHIP PURCHASES when the player has no
  /// active shipyards. Explains the requirement and offers a one-tap path
  /// to queue a Shipyard purchase.
  Widget _buildShipyardEmptyStateCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Card(
        color: theme.colorScheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.construction,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have no Shipyards yet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ships must be built at a hex that has a Shipyard. '
                      'Buy one below and assign it to a colony hex; next '
                      'turn it will be placed there.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _showAddShipDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Buy Shipyard'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
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

  /// Amber warning shown above the purchase rows when the player has queued
  /// non-shipyard ships but has no active shipyard hex to materialize them.
  Widget _buildNoShipyardWarningCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Card(
        color: Colors.amber.withValues(alpha: 0.18),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.amber.shade700, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.amber.shade800, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Warning: you have ship purchases queued but no active '
                  'Shipyard. Queue a Shipyard too \u2014 it will be placed '
                  'at End Turn.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Help dialog explaining what Shipyards are and how they work.
  void _showShipyardHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Shipyards'),
        content: const SingleChildScrollView(
          child: Text(
            'Shipyards (SY) are the factories that let you build ships. '
            'Every ship purchase must be assigned to a hex that already has '
            'a Shipyard \u2014 the hex provides hull-point (HP) capacity '
            'each Economic Phase, scaled by your Shipyard tech level.\n\n'
            'To get one:\n'
            '  1. Add a Shipyard purchase from the Add Ship dialog and '
            'assign it to a colony hex.\n'
            '  2. At End Turn, the Shipyard is placed on that hex and '
            'becomes active next turn.\n'
            '  3. From then on, ships queued at that hex will draw HP from '
            'its Shipyard pool.\n\n'
            'You can also adjust a hex\u2019s Shipyard count manually from '
            'the Map tab\u2019s hex inspector.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildShipPurchaseRow(
      int index, ShipPurchase purchase, ThemeData theme) {
    final def = kShipDefinitions[purchase.type];
    final name = def?.name ?? purchase.type.name;
    final abbr = def?.abbreviation ?? '';
    // Route through the canonical per-unit pricer so display, affordability,
    // and the charged total always agree (AGT mode, alternate empire, EA
    // modifiers, card `costMod`s, scenario multipliers, and ability-12
    // discount all flow through ProductionState.effectiveUnitShipCost).
    final unitCost = def == null
        ? 0
        : production.effectiveUnitShipCost(
            purchase.type,
            config,
            modifiers: modifiers,
            shipSpecialAbilities: abilities,
            uniqueDesign: purchase.uniqueDesign,
          );
    final lineCost = unitCost * purchase.quantity;

    // Task 3B: bounce animation on the last added row
    final shouldBounce = _lastBouncedIndex == index;

    // QW-2: Resolve the friendly label of the assigned shipyard hex, if any.
    // Prefer the colony / world name (users remember names, not coords).
    String? hexLabel;
    if (purchase.shipyardHexId != null && mapState != null) {
      for (final hex in mapState!.hexes) {
        if (hex.coord.id == purchase.shipyardHexId) {
          hexLabel = _friendlyHexLabel(hex);
          break;
        }
      }
      hexLabel ??= purchase.shipyardHexId;
    }

    // PP08: Multi-turn build progress forecast. When the purchase is
    // tracking `totalHpNeeded`, surface X/Y HP + an estimated turn count
    // alongside a slim progress bar. Instant builds (totalHpNeeded == null)
    // still materialize on End Turn and are rendered without the chip.
    final int? progressNeed = purchase.totalHpNeeded;
    final bool showProgress = progressNeed != null && progressNeed > 0;
    int progressDone = 0;
    double progressFraction = 0;
    int turnsRemaining = 0;
    if (showProgress) {
      progressDone = purchase.buildProgressHp.clamp(0, progressNeed);
      progressFraction =
          progressNeed == 0 ? 0 : progressDone / progressNeed;
      final map = mapState;
      if (map != null) {
        final techState = production.techState.withPending(
          production.pendingTechPurchases,
        );
        turnsRemaining = production.turnsRemainingFor(
          purchase,
          map,
          techState,
          facilitiesMode: config.useFacilitiesCosts,
          modifiers: modifiers,
        );
      }
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
            // Ship name + optional "Build at: …" chip on a second line.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$name ($abbr)',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (hexLabel != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place,
                            size: 11,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Build at: $hexLabel',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // PP02 §41.1.6: Unique Ship design summary chip. Tap to
                  // re-open the designer dialog with the current design as
                  // its initial value.
                  if (purchase.uniqueDesign != null) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _editUniqueShipDesign(index, purchase),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 11,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _uniqueDesignLabel(purchase.uniqueDesign!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.edit_outlined,
                              size: 10,
                              color: theme.colorScheme.tertiary
                                  .withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // PP08: Build progress row (multi-turn builds only).
                  if (showProgress) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 11,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Build progress: $progressDone/$progressNeed HP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                        if (turnsRemaining > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '~$turnsRemaining turn${turnsRemaining == 1 ? '' : 's'} remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        width: 180,
                        child: LinearProgressIndicator(
                          value: progressFraction.clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              onPressed: () => showShipInfoDialog(context, purchase.type, facilitiesMode: config.useFacilitiesCosts, isAlternateEmpire: config.enableAlternateEmpire, onRuleTap: widget.onRuleTap),
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
                        final newQty = purchase.quantity - 1;
                        final hullHere = _hullCostFor(purchase.type);
                        final newTotalHp = purchase.totalHpNeeded == null
                            ? null
                            : hullHere * newQty;
                        updated[index] = purchase.copyWith(
                            quantity: newQty, totalHpNeeded: newTotalHp);
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
                  final canAfford = _canAffordOneMore(
                    purchase.type,
                    uniqueDesign: purchase.uniqueDesign,
                  );
                  // Bug A: enforce shipyard HP capacity at +1 time. When
                  // enableMultiTurnBuilds is ON the user may intentionally
                  // over-queue to build across turns, so we don't block.
                  final hull = _hullCostFor(purchase.type);
                  final hexId = purchase.shipyardHexId;
                  final hasCapacity = hexId == null ||
                      config.enableMultiTurnBuilds ||
                      _remainingHpForHex(hexId) >= hull;
                  final enabled = canAfford && hasStock && hasCapacity;
                  String tooltip;
                  if (!hasStock) {
                    tooltip = _counterStockTooltip(purchase.type);
                  } else if (!canAfford) {
                    tooltip = 'Not enough CP for another unit';
                  } else if (!hasCapacity) {
                    tooltip = 'Shipyard capacity full for this turn '
                        '(needs $hull HP). Turn on Multi-Turn Builds to queue '
                        'across turns.';
                  } else {
                    tooltip = '';
                  }
                  final button = IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                    icon: const Icon(Icons.add),
                    onPressed: enabled
                        ? () {
                            final updated = List<ShipPurchase>.from(
                                production.shipPurchases);
                            final newQty = purchase.quantity + 1;
                            // Bug F: keep totalHpNeeded in sync with quantity
                            // when it is being tracked for multi-turn builds.
                            final newTotalHp = purchase.totalHpNeeded == null
                                ? null
                                : hull * newQty;
                            updated[index] = purchase.copyWith(
                                quantity: newQty,
                                totalHpNeeded: newTotalHp);
                            widget.onProductionChanged(production.copyWith(
                                shipPurchases: updated));
                          }
                        : null,
                  );
                  if (tooltip.isEmpty) return button;
                  // Fire a light haptic when the user taps a blocked +1
                  // so tremor-prone users feel that the app registered
                  // their tap but the action is unavailable.
                  return Tooltip(
                    message: tooltip,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: enabled
                          ? null
                          : () {
                              if (config.strongHaptics) {
                                HapticFeedback.selectionClick();
                              }
                            },
                      child: button,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            // Cost
            SizedBox(
              width: 52,
              child: Text(
                '${lineCost}CP',
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

  /// PP02 §41.1.6: Short summary string for a Unique Ship design — used as
  /// the chip label in [_buildShipPurchaseRow]. Falls back to the abbreviated
  /// "Unique Ship" if the player never named the design.
  String _uniqueDesignLabel(UniqueShipDesign d) {
    final shipName = d.name.isEmpty ? 'Unique Ship' : d.name;
    final cnt = d.abilityIds.length;
    final abilWord = cnt == 1 ? 'ability' : 'abilities';
    return '$shipName (Hull ${d.hullSize}, '
        'Class ${d.weaponClass.label}, $cnt $abilWord)';
  }

  /// PP02 §41.1.6: Re-open the Unique Ship designer for an existing
  /// purchase. The Save result replaces the design on the queued
  /// [ShipPurchase] without altering its quantity / hex assignment.
  Future<void> _editUniqueShipDesign(int index, ShipPurchase purchase) async {
    final updated = await showUniqueShipDesignerDialog(
      context,
      initial: purchase.uniqueDesign,
    );
    if (updated == null) return;
    if (!mounted) return;
    final list = List<ShipPurchase>.from(production.shipPurchases);
    if (index < 0 || index >= list.length) return;
    list[index] = list[index].copyWith(uniqueDesign: updated);
    widget.onProductionChanged(production.copyWith(shipPurchases: list));
  }

  /// Task 2: Check if player can afford one more of this ship type.
  /// Uses the canonical modifier pipeline so affordability matches the
  /// charged total (Empire Advantage mods, card `costMod`s, scenario
  /// multipliers, and the ability-12 discount all count).
  bool _canAffordOneMore(ShipType type, {UniqueShipDesign? uniqueDesign}) {
    final def = kShipDefinitions[type];
    if (def == null) return false;
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);
    final unitCost = production.effectiveUnitShipCost(
      type,
      config,
      modifiers: modifiers,
      shipSpecialAbilities: abilities,
      uniqueDesign: uniqueDesign,
    );
    return remaining >= unitCost;
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
  /// Bug A: Remaining HP capacity for a given hex, factoring in the
  /// purchases already assigned to it this turn. Returns 0 for unknown or
  /// blocked hexes.
  int _remainingHpForHex(String hexId) {
    final map = mapState;
    if (map == null) return 0;
    for (final hex in map.hexes) {
      if (hex.coord.id != hexId) continue;
      final techState = production.techState.withPending(
        production.pendingTechPurchases,
      );
      final cap = production.shipyardCapacityForHex(
        hex.coord,
        map,
        techState,
        facilitiesMode: config.useFacilitiesCosts,
      );
      final used = production.hullPointsSpentInHex(
        hex.coord,
        facilitiesMode: config.useFacilitiesCosts,
      );
      final remaining = cap - used;
      return remaining < 0 ? 0 : remaining;
    }
    return 0;
  }

  /// Bug A: Hull size required to add one more of [type] this turn.
  int _hullCostFor(ShipType type) =>
      kShipDefinitions[type]?.effectiveHullSize(config.useFacilitiesCosts) ?? 0;

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
      result.add(_ShipyardHexInfo(
        hexId: hex.coord.id,
        label: _friendlyHexLabel(hex),
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

  /// All non-blockaded colony hexes (for SY placement — rule 8.2).
  List<_ShipyardHexInfo> _colonyHexes() {
    final map = mapState;
    if (map == null) return const [];
    final isAlt = config.enableAlternateEmpire;
    final result = <_ShipyardHexInfo>[];
    for (final hex in map.hexes) {
      final wid = hex.worldId;
      if (wid == null || wid.isEmpty) continue;
      // Skip blockaded colonies.
      final isBlocked = production.worlds.any(
        (w) => w.id == wid && w.isBlocked,
      );
      if (isBlocked) continue;
      result.add(_ShipyardHexInfo(
        hexId: hex.coord.id,
        label: _friendlyHexLabel(hex),
        shipyardCount: hex.shipyardCount,
        capacity: 0,
        used: 0,
        isBlocked: false,
        isHomeworld: _isHomeworldHex(hex, isAlt: isAlt),
      ));
    }
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

  /// Friendly display label for a hex: prefers the colony / world name on
  /// the hex (e.g. "Homeworld", "Alpha Centauri"), then falls back to the
  /// user-provided hex label, then finally the raw axial coord id (e.g.
  /// "3,2"). Coordinates are only shown when the hex has neither a world
  /// nor a custom label, since users remember names — not coords.
  String _friendlyHexLabel(MapHexState hex) {
    final wid = hex.worldId;
    if (wid != null && wid.isNotEmpty) {
      for (final w in production.worlds) {
        if (w.id == wid && w.name.isNotEmpty) return w.name;
      }
    }
    if (hex.label.isNotEmpty) return hex.label;
    return hex.coord.id;
  }

  /// QW-2: Short summary of shipyards (e.g. "HW: 2/4 HP") for display next to
  /// the purchase list.
  Widget _buildShipyardHexCapacityStrip(BuildContext context) {
    final theme = Theme.of(context);
    final shipyardInfos = _shipyardHexes();
    final colonyInfos = _colonyHexes();
    final syHexIds = shipyardInfos.map((i) => i.hexId).toSet();
    final infos = [
      ...shipyardInfos,
      ...colonyInfos.where((c) => !syHexIds.contains(c.hexId)),
    ];
    if (infos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: infos.length,
          itemBuilder: (context, index) {
            final info = infos[index];
            final isColonyOnly = info.shipyardCount == 0;
            final remaining = info.capacity - info.used;
            final ratio = info.capacity > 0 ? info.used / info.capacity : 0.0;
            final progressColor = ratio > 0.8
                ? Colors.red
                : ratio >= 0.5
                    ? Colors.amber
                    : Colors.green;

            return SizedBox(
              width: 160,
              child: Card(
                color: info.isBlocked
                    ? theme.colorScheme.error.withValues(alpha: 0.10)
                    : isColonyOnly
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
                        : null,
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: info.shipyardCount > 0
                            ? '${info.shipyardCount} Shipyard'
                                '${info.shipyardCount == 1 ? '' : 's'} '
                                '(SY) at this hex'
                            : 'No Shipyard (SY) at this hex',
                        child: Text(
                          info.shipyardCount > 0
                              ? '${info.label} \u00B7 '
                                  '${info.shipyardCount} SY'
                              : info.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (info.isBlocked)
                        Text(
                          'Blocked',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.error,
                          ),
                        )
                      else if (isColonyOnly)
                        Text(
                          'No SY',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor:
                                theme.colorScheme.onSurface.withValues(alpha: 0.10),
                            color: progressColor,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${info.used}/${info.capacity} HP',
                              style: TextStyle(
                                fontSize: 11,
                                fontFeatures: const [FontFeature.tabularFigures()],
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (remaining > 0)
                              SizedBox(
                                height: 36,
                                child: TextButton(
                                  onPressed: () => _showAddShipDialog(
                                    context,
                                    preselectedHexId: info.hexId,
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: const Size(48, 32),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text('+ Build'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddShipDialog(BuildContext context, {String? preselectedHexId}) {
    // Task 2: Filter to ships the player has tech to build AND can afford
    final remaining = production.remainingCp(config, shipCounters, modifiers, abilities, mapState);

    final isAlt = config.enableAlternateEmpire;
    final facilitiesMode = config.useFacilitiesCosts;
    // Route all per-unit cost reads through the canonical pipeline so that
    // the filter, sort, and display agree with what the player is actually
    // charged at purchase time.
    int unitCostFor(ShipType type) => production.effectiveUnitShipCost(
          type,
          config,
          modifiers: modifiers,
          shipSpecialAbilities: abilities,
        );
    final buyableShips = kShipDefinitions.entries
        // Skip ships whose base table value is 0 (flagship, starbase, etc. —
        // these are placed by other mechanisms, not via the purchase dialog).
        .where((e) => e.value.effectiveBuildCost(isAlt, facilitiesMode: facilitiesMode) > 0)
        .where((e) => canBuildShip(
              e.key,
              _effectiveLevel,
              config,
              production.shipPurchases,
              shipCounters,
            ))
        .where((e) => unitCostFor(e.key) <= remaining)
        // T1-C: hard block when all physical counters of this type are in use.
        .where((e) => _hasCounterStock(e.key))
        .toList()
      ..sort((a, b) => unitCostFor(a.key).compareTo(unitCostFor(b.key)));

    // QW-2: Surface shipyard hexes so the player can pick where each purchase
    // is built. Zero-capacity hexes (blocked or no capacity remaining) are
    // still listed but greyed out. Colony-only hexes (no SY) are included so
    // that new shipyards can be placed there (rule 8.2).
    final shipyardInfos = _shipyardHexes();
    final colonyInfos = _colonyHexes();
    // Merge: shipyard hexes first (with capacity data), then colony-only hexes.
    final syHexIds = shipyardInfos.map((i) => i.hexId).toSet();
    final allHexInfos = [
      ...shipyardInfos,
      ...colonyInfos.where((c) => !syHexIds.contains(c.hexId)),
    ];
    final selectableInfos =
        allHexInfos.where((i) => !i.isBlocked && (i.capacity > 0 || i.shipyardCount == 0)).toList();

    showDialog<({ShipType type, String? hexId, UniqueShipDesign? uniqueDesign})>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        // Default to Homeworld hex, else first selectable.
        final validPreselect = preselectedHexId != null &&
            selectableInfos.any((i) => i.hexId == preselectedHexId)
            ? preselectedHexId
            : null;
        String? selectedHexId = validPreselect ?? (selectableInfos.isNotEmpty
            ? (selectableInfos.firstWhere(
                (i) => i.isHomeworld,
                orElse: () => selectableInfos.first,
              )).hexId
            : null);
        final noShipyards = _shipyardHexes().isEmpty;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SimpleDialog(
              title: const Text('Add Ship Purchase'),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (noShipyards)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.construction,
                              color: theme.colorScheme.onSecondaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No Shipyards yet. Buy a Shipyard (SY) below '
                              'and assign it to a colony hex. At End Turn '
                              'it will land on that hex and enable ship '
                              'production there.',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (allHexInfos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Build at hex',
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
                            for (final info in allHexInfos)
                              DropdownMenuItem<String>(
                                value: info.hexId,
                                enabled: !info.isBlocked &&
                                    (info.capacity > 0 || info.shipyardCount == 0),
                                child: Text(
                                  info.isBlocked
                                      ? '${info.label} \u00B7 blocked'
                                      : info.shipyardCount == 0
                                          ? '${info.label} \u00B7 no SY \u2014 place one here'
                                          : '${info.label} \u00B7 '
                                              '${info.capacity - info.used}'
                                              '/${info.capacity} HP remaining',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (info.isBlocked || (info.capacity == 0 && info.shipyardCount > 0))
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
                  Builder(builder: (_) {
                    final isSyExempt = entry.value.isShipyardExempt;
                    final isSyPurchase = entry.key == ShipType.shipyard;
                    final isUniquePurchase = entry.key == ShipType.un;
                    // Rule 8.2: one SY per hex per Economic Phase.
                    final syAlreadyQueued = isSyPurchase &&
                        selectedHexId != null &&
                        production.hasShipyardPurchaseInHex(selectedHexId!);
                    // Bug A: grey out ships whose hull size exceeds the
                    // remaining HP capacity of the selected shipyard hex.
                    // SY-exempt types skip capacity check (they don't use SY).
                    final hull = entry.value
                        .effectiveHullSize(facilitiesMode);
                    final remainingHp = selectedHexId == null
                        ? 0
                        : _remainingHpForHex(selectedHexId!);
                    // Colony-only hex (no existing SY): block non-exempt,
                    // non-SY ships — they need an existing shipyard.
                    final noSyAtHex = !isSyExempt &&
                        !isSyPurchase &&
                        selectedHexId != null &&
                        !syHexIds.contains(selectedHexId);
                    final overCapacity = !isSyExempt &&
                        !noSyAtHex &&
                        selectedHexId != null &&
                        !config.enableMultiTurnBuilds &&
                        hull > remainingHp;
                    final blocked =
                        overCapacity || syAlreadyQueued || noSyAtHex;
                    final dim = blocked
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                        : null;
                    // Blocking reason for display.
                    final String? blockReason = syAlreadyQueued
                        ? '${entry.value.name} (one SY per hex per turn)'
                        : noSyAtHex
                            ? '${entry.value.name} (no shipyard at hex)'
                            : overCapacity
                                ? '${entry.value.name} (needs $hull HP — '
                                    '$remainingHp HP left)'
                                : null;
                    final remaining = counter_pool.countersRemaining(
                        entry.key, shipCounters, production.shipPurchases);
                    final row = InkWell(
                      onTap: blocked
                          ? null
                          : () async {
                              if (isUniquePurchase) {
                                // PP02 §41.1.6: UN entries open the designer
                                // dialog first. The Save result becomes the
                                // design payload on the new ShipPurchase.
                                final design =
                                    await showUniqueShipDesignerDialog(ctx);
                                if (design == null) return;
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop((
                                  type: entry.key,
                                  hexId: selectedHexId,
                                  uniqueDesign: design,
                                ));
                                return;
                              }
                              Navigator.of(ctx).pop((
                                type: entry.key,
                                hexId: selectedHexId,
                                uniqueDesign: null,
                              ));
                            },
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
                                color: dim ?? theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              blockReason ?? (isUniquePurchase
                                  ? '${entry.value.name} \u2014 design first'
                                  : (remaining != null && remaining <= 2
                                      ? '${entry.value.name} ($remaining left)'
                                      : entry.value.name)),
                              style: TextStyle(
                                fontSize: 15,
                                color: dim ?? (remaining != null && remaining <= 2
                                    ? Colors.amber.shade700
                                    : null),
                              ),
                            ),
                          ),
                          Text(
                            isUniquePurchase ? '?CP' : '${unitCostFor(entry.key)}CP',
                            style: TextStyle(
                              fontSize: 14,
                              color: dim ?? theme.colorScheme.onSurface
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
                              isAlternateEmpire: isAlt,
                              onRuleTap: widget.onRuleTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    );
                    return row;
                  }),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        // Bug A + Bug F: when multi-turn builds are enabled, record the
        // totalHpNeeded so prepareForNextTurn can accumulate progress on
        // ships that can't complete this turn.
        final def = kShipDefinitions[result.type];
        // PP02 §41.1.6: For Unique Ships, the hull size comes from the
        // player-chosen design, not the static table.
        final hull = result.uniqueDesign?.hullSize ??
            (def?.effectiveHullSize(config.useFacilitiesCosts) ?? 0);
        final updated =
            List<ShipPurchase>.from(production.shipPurchases)
              ..add(ShipPurchase(
                type: result.type,
                shipyardHexId: result.hexId,
                totalHpNeeded:
                    config.enableMultiTurnBuilds ? hull : null,
                uniqueDesign: result.uniqueDesign,
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
            // Line 2: Facility (if enabled) + garrison
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (config.enableFacilities)
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
                // PP15: Garrison Ground Units count for the homeworld.
                _LabeledWorldControl(
                  label: 'Garrison',
                  helpText:
                      'Number of Ground Units (GU) garrisoned on the '
                      'homeworld (rules 21.x). GUs are tracked here because '
                      'they are not represented as ship counters on the '
                      'Ship Technology sheet.',
                  child: _GarrisonStepper(
                    value: world.garrisonGu,
                    onChanged: (v) =>
                        _updateWorld(index, (w) => w.copyWith(garrisonGu: v)),
                  ),
                ),
              ],
            ),
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
                // Editable colony name (2.5: edit-icon affordance)
                GestureDetector(
                  onTap: () => _showEditColonyNameDialog(context, index, world),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 60,
                      maxWidth: 120,
                      minHeight: 44,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              world.name,
                              style: labelStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Growth marker with +/- adjustment (4.4: 48x48 touch targets)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
                    icon: Icon(Icons.remove, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: world.growthMarkerLevel > 0
                        ? () => _updateWorld(index, (w) => w.copyWith(growthMarkerLevel: w.growthMarkerLevel - 1))
                        : null,
                  ),
                ),
                Text(growthLabel, style: dimStyle),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
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
                    onPressed: () => _confirmRemoveColony(index, world),
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
                // PP15: Garrison Ground Units count, with inline +/- controls.
                _LabeledWorldControl(
                  label: 'Garrison',
                  helpText:
                      'Number of Ground Units (GU) garrisoned on this '
                      'colony (rules 21.x). GUs are tracked here because '
                      'they are not represented as ship counters on the '
                      'Ship Technology sheet.',
                  child: _GarrisonStepper(
                    value: world.garrisonGu,
                    onChanged: (v) =>
                        _updateWorld(index, (w) => w.copyWith(garrisonGu: v)),
                  ),
                ),
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
    final taken = {for (final w in production.worlds) w.name};
    final defaultName = pickUnusedName(kPlanetNames, taken, fallbackPrefix: 'Colony');
    final updated = List<WorldState>.from(production.worlds)
      ..add(WorldState(
        id: 'world-${production.worlds.length + 1}',
        name: defaultName,
      ));
    widget.onProductionChanged(production.copyWith(worlds: updated));
  }

  void _removeColony(int index) {
    if (production.worlds[index].isHomeworld) return;
    final updated = List<WorldState>.from(production.worlds)..removeAt(index);
    widget.onProductionChanged(production.copyWith(worlds: updated));
  }

  // Wave 4.1: confirm removal of a colony before destroying its state.
  Future<void> _confirmRemoveColony(int index, WorldState world) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove colony '${world.name}'?"),
        content: const Text(
          'This will discard growth level, staged minerals, and facility. '
          'Cannot be undone via single undo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeColony(index);
    }
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
        child: Semantics(
          label: 'End turn, finalize turn ${widget.turnNumber}',
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.help_outline, size: 18),
                tooltip: 'How do cards work?',
                onPressed: () => _showCardHelpDialog(context),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
              ),
              TextButton.icon(
                onPressed: widget.playedCards.isEmpty
                    ? null
                    : () => _showCardHistoryDialog(context),
                icon: const Icon(Icons.history, size: 16),
                label: const Text(
                  'History',
                  style: TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Semantics(
                label: 'Draw card',
                child: TextButton.icon(
                  onPressed: () => _showDrawCardDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Draw'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
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
    final binding = cardModifiersFor(card.cardNumber);
    final complexNote = binding?.complexBehaviorNote;
    String? attachedWorldName;
    if (card.attachedWorldId != null) {
      for (final w in widget.production.worlds) {
        if (w.id == card.attachedWorldId) {
          attachedWorldName = w.name;
          break;
        }
      }
    }
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
              // PP04: tapping the title row opens the universal card
              // detail dialog with assigned modifiers + complex note.
              Expanded(
                child: InkWell(
                  onTap: entry == null
                      ? null
                      : () => showCardDetailDialog(
                            context,
                            card: entry,
                            assignedModifiers: card.assignedModifiers,
                            complexBehaviorNote: complexNote,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (attachedWorldName != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '\u{1F4CD} $attachedWorldName',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
          if (complexNote != null)
            ComplexBehaviorBanner(note: complexNote),
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

  static CardEntry? _lookupCardEntry(int cardNumber) =>
      lookupCardByNumber(cardNumber);

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
                          'scenarioModifier',
                          'empire',
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
                          final binding = cardModifiersFor(card.number);
                          final isComplex =
                              binding?.complexBehaviorNote != null;
                          return ListTile(
                            dense: true,
                            title: Text(
                              '#${card.number} ${card.name}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              isComplex
                                  ? '${card.type} \u00B7 Complex — '
                                      'see note after drawing'
                                  : '${card.type} \u00B7 ${card.description}',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // PP04: the info button is a "peek" at the
                            // full card text without committing to the
                            // draw. The row tap still selects the card
                            // for drawing as before.
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isComplex)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.warning_amber,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                  ),
                                  tooltip: 'Read full description',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  onPressed: () => showCardDetailDialog(
                                    ctx,
                                    card: card,
                                    complexBehaviorNote:
                                        binding?.complexBehaviorNote,
                                  ),
                                ),
                              ],
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
    final rawMods = binding?.modifiers ?? const <GameModifier>[];
    // Bug C: stamp the card's identity on each modifier snapshot so the
    // Play-as-event path can de-dup against the activeModifiers ledger.
    final sourceId = '${entry.type}:${entry.number}';
    final mods = [for (final m in rawMods) m.withSourceCardId(sourceId)];
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
    final composite = widget.onCardPlayedAsEvent;
    if (composite != null) {
      composite(index, card.assignedModifiers);
      return;
    }
    // Legacy fall-back path: two separate state mutations.
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
    // Build a unique-but-trackable sourceCardId so the home_page handler can
    // stamp the one-shot income modifier. The turn number keeps repeated
    // "for credits" plays of the same card in different turns distinct,
    // while still de-duping double-taps within a single turn.
    final typeLabel = entry?.type ?? 'unknown';
    final sourceId =
        'card:$typeLabel:${card.cardNumber}:credits:${widget.turnNumber}';
    final composite = widget.onCardPlayedForCredits;
    if (composite != null) {
      composite(index, result, sourceId);
      return;
    }
    // Legacy fall-back path.
    widget.onPlayCardForCredits?.call(name, result, sourceId);
    final updated = List<DrawnCard>.from(widget.drawnHand)..removeAt(index);
    widget.onDrawnHandChanged?.call(updated);
  }

  void _discardCard(int index) {
    final composite = widget.onCardDiscarded;
    if (composite != null) {
      composite(index);
      return;
    }
    final updated = List<DrawnCard>.from(widget.drawnHand)..removeAt(index);
    widget.onDrawnHandChanged?.call(updated);
  }

  void _showCardHistoryDialog(BuildContext context) {
    showCardHistoryDialog(
      context,
      playedCards: widget.playedCards,
      production: widget.production,
    );
  }

  void _showCardHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How cards work'),
        content: const SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpBullet(
                  'Crew cards represent officers — keep them drawn while '
                  'the officer is alive.',
                ),
                _HelpBullet(
                  'Mission cards are objectives — keep drawn until '
                  'completed. The app does not enforce mission completion — '
                  'discard manually when done.',
                ),
                _HelpBullet(
                  'Resource / Action cards may be played as events for '
                  'their modifier effect, or played for credits for a '
                  'one-time CP gain.',
                ),
                _HelpBullet(
                  "Scenario Modifier cards marked as 'complex' need manual "
                  'handling via Manual Override.',
                ),
                _HelpBullet(
                  'Planet Attributes are attached to colonies and discard '
                  'when the colony is destroyed.',
                ),
              ],
            ),
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
    final colonyPreview = _buildColonyChangePreview();
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
    );

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Turn?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Finalize turn ${widget.turnNumber} and advance to turn ${widget.turnNumber + 1}.\n'
              'Pending tech purchases will be applied, colonies will grow, '
              'and carry-overs will be computed.',
            ),
            if (colonyPreview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Colony changes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              for (final line in colonyPreview)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 1),
                  child: Text('• $line', style: monoStyle),
                ),
            ],
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
        if (config.strongHaptics) HapticFeedback.mediumImpact();
        widget.onEndTurn();
      }
    });
  }

  /// Build a list of human-readable lines describing what each colony's CP
  /// will be after [ProductionState.prepareForNextTurn] runs, without
  /// mutating any state. Used in the End Turn confirm dialog.
  List<String> _buildColonyChangePreview() {
    if (production.worlds.isEmpty) return const [];
    // Run prepareForNextTurn on a temp copy to get the projected worlds.
    final previewState = production.prepareForNextTurn(
      config,
      shipCounters,
      modifiers,
      abilities,
    );
    final previewById = {
      for (final w in previewState.worlds) w.id: w,
    };
    final lines = <String>[];
    // Compute the max colony name width for alignment.
    int maxNameLen = 0;
    for (final w in production.worlds) {
      if (w.name.length > maxNameLen) maxNameLen = w.name.length;
    }
    // Cap alignment width so the dialog doesn't get too wide.
    final padW = maxNameLen > 18 ? 18 : maxNameLen;
    String pad(String s) {
      if (s.length >= padW) return s;
      return s + ' ' * (padW - s.length);
    }

    for (final w in production.worlds) {
      final next = previewById[w.id];
      if (next == null) continue;
      final nameCol = pad(w.name);
      if (w.isHomeworld) {
        final curCp = w.homeworldValue;
        final nextCp = next.homeworldValue;
        if (curCp == nextCp) {
          lines.add('$nameCol: $curCp CP -> $nextCp CP');
        } else {
          lines.add('$nameCol: $curCp CP -> $nextCp CP (recovering)');
        }
      } else {
        final curLvl = w.growthMarkerLevel;
        final nextLvl = next.growthMarkerLevel;
        final curCp = w.cpValue;
        final nextCp = next.cpValue;
        final curLabel = 'Level $curLvl ($curCp CP)';
        final nextLabel = nextLvl >= 3
            ? 'MAX ($nextCp CP)'
            : 'Level $nextLvl ($nextCp CP)';
        final suffix = (curLvl == nextLvl && curLvl >= 3) ? ' (max)' : '';
        lines.add('$nameCol: $curLabel -> $nextLabel$suffix');
      }
    }
    return lines;
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

/// PP15: Compact +/- stepper for the colony Garrison GU count. Shows the
/// current value with a shield icon and clamps the result at zero.
class _GarrisonStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GarrisonStepper({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove, color: muted),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: muted),
            const SizedBox(width: 2),
            SizedBox(
              width: 32,
              child: Text(
                'GU $value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, color: muted),
            onPressed: () => onChanged(value + 1),
          ),
        ),
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

/// PP01: single bullet row used by `_showCardHelpDialog`.
class _HelpBullet extends StatelessWidget {
  final String text;
  const _HelpBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\u2022  ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
