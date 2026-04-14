import 'dart:math';

import 'package:flutter/material.dart';

import '../data/counter_templates.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/game_config.dart';
import '../models/ship_counter.dart';
import '../models/technology.dart';
import '../tutorial/tutorial_targets.dart';
import '../widgets/combat_calculator_dialog.dart';
import '../widgets/counter_row.dart';
import '../widgets/section_header.dart';
import '../widgets/ship_info_dialog.dart';

/// The Ship Technology Sheet page.
///
/// Displays every individual ship counter grouped by type, with circleable
/// tech levels that are stamped when the counter is built.
class ShipTechPage extends StatefulWidget {
  final GameConfig config;
  final int turnNumber;
  final TechState techState;
  final List<ShipCounter> shipCounters;
  final bool showExperience;
  final Map<ShipType, int> shipSpecialAbilities;
  final ValueChanged<List<ShipCounter>> onCountersChanged;
  final ValueChanged<int>? onUpgradeCostIncurred;
  final void Function(String sectionId)? onRuleTap;
  final ValueChanged<String>? onLocateShip;
  final VoidCallback? onGoToProduction;

  /// Per-ship-type total quantity of queued purchases on the Production tab.
  /// Used to surface a "queued" badge on unbuilt counter rows so the player
  /// knows tapping Build will materialize a real purchase rather than
  /// manually stamp a fresh counter.
  final Map<ShipType, int> queuedShipPurchases;

  /// Optional callback that lets the page consume one queued purchase of the
  /// given type. Returns true if a purchase was consumed (in which case the
  /// counter should be stamped without confirmation), or false if there was
  /// no purchase to consume (the page falls back to the manual-override path).
  final bool Function(ShipType type)? onConsumeQueuedPurchase;

  const ShipTechPage({
    super.key,
    required this.config,
    required this.turnNumber,
    required this.techState,
    required this.shipCounters,
    required this.showExperience,
    this.shipSpecialAbilities = const {},
    required this.onCountersChanged,
    this.onUpgradeCostIncurred,
    this.onRuleTap,
    this.onLocateShip,
    this.onGoToProduction,
    this.queuedShipPurchases = const {},
    this.onConsumeQueuedPurchase,
  });

  @override
  State<ShipTechPage> createState() => _ShipTechPageState();
}

class _ShipTechPageState extends State<ShipTechPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Session-scoped suppression flag for the drift-confirmation dialog
  /// ("Don't ask again this session" checkbox). Not persisted.
  bool _suppressDriftConfirm = false;

  /// EA #34 Giant Race / EA #43 Insectoids hull-size modifier.
  int get _hullSizeModifier => widget.config.empireAdvantage?.hullSizeModifier ?? 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ordered ship types for display, matching the physical sheet layout.
  static const _displayOrder = <ShipType>[
    // Left column on physical sheet
    ShipType.flag,
    ShipType.dd,
    ShipType.ca,
    ShipType.bc,
    ShipType.bb,
    ShipType.dn,
    ShipType.tn,
    ShipType.un,
    ShipType.raider,
    // Right column on physical sheet (continuous scroll here)
    ShipType.scout,
    ShipType.fighter,
    ShipType.cv,
    ShipType.bv,
    ShipType.sw,
    ShipType.bdMb,
    ShipType.transport,
    // NOTE: ShipType.warSun intentionally excluded. The War Sun Empire
    // Advantage (#187) grants a one-time free Titan rather than a buildable
    // unit, and the legacy custom War Sun counter is no longer exposed
    // through the production UI. It is also never added to _visibleTypes(),
    // so listing it here only produced a ship type that could never render.
  ];

  /// Determine which ship types are visible given the current widget.config.
  Set<ShipType> _visibleTypes() {
    final visible = <ShipType>{
      // Always shown
      ShipType.flag,
      ShipType.dd,
      ShipType.ca,
      ShipType.bc,
      ShipType.bb,
      ShipType.dn,
      ShipType.scout,
    };

    // Determine which techs the config makes visible
    final techs = visibleTechs(
      facilitiesMode: widget.config.useFacilitiesCosts,
      closeEncountersOwned: widget.config.ownership.closeEncounters,
      replicatorsEnabled: widget.config.enableReplicators,
      advancedConEnabled: widget.config.enableAdvancedConstruction,
    );

    final hasFighters = techs.contains(TechId.fighters);
    final hasCloaking = techs.contains(TechId.cloaking);
    final hasMines = techs.contains(TechId.mines);
    final hasMineSweep = techs.contains(TechId.mineSweep);
    final hasBoarding = techs.contains(TechId.boarding);
    final hasMissileBoats = techs.contains(TechId.missileBoats);

    // Fighters and CV require Fighters tech or Close Encounters
    if (hasFighters || widget.config.ownership.closeEncounters) {
      visible.add(ShipType.fighter);
      visible.add(ShipType.cv);
    }

    // BV requires Advanced Construction
    if (widget.config.enableAdvancedConstruction) {
      visible.add(ShipType.bv);
    }

    // TN: show if ship size tech allows hull 4+ (Facilities mode has size 7)
    // In practice, TN is available in any game with large enough ship size tech.
    // Show it always for Facilities mode, or if Close Encounters / AGT owned.
    if (widget.config.enableFacilities ||
        widget.config.ownership.closeEncounters ||
        widget.config.ownership.allGoodThings) {
      visible.add(ShipType.tn);
    }

    // UN (Unique Ship): visible whenever Advanced Construction tech is
    // available. The PP02 designer dialog gates the actual purchase, but
    // the counter rows are shown so materialized UN counters surface here.
    if (techs.contains(TechId.advancedCon)) {
      visible.add(ShipType.un);
    }

    // Raider requires Cloaking tech visibility
    if (hasCloaking) {
      visible.add(ShipType.raider);
    }

    // SW: Minesweeper requires mine sweep tech
    if (hasMineSweep || hasMines) {
      visible.add(ShipType.sw);
    }

    // BD/MB: Boarding Ship / Missile Boat
    if (hasBoarding || hasMissileBoats || widget.config.enableFacilities) {
      visible.add(ShipType.bdMb);
    }

    // Transport always shown (needed for ground combat)
    visible.add(ShipType.transport);

    // Alternate empire: hide Titans, CVs, BVs (rule 24.1.1)
    if (widget.config.enableAlternateEmpire) {
      visible.remove(ShipType.tn);
      visible.remove(ShipType.cv);
      visible.remove(ShipType.bv);
    }

    // Empire Advantage: hide fighter-related types if fighters tech is blocked
    final blockedTechs = widget.config.empireAdvantage?.blockedTechs ?? const [];
    if (blockedTechs.contains(TechId.fighters)) {
      visible.remove(ShipType.fighter);
      visible.remove(ShipType.cv);
      visible.remove(ShipType.bv);
    }

    return visible;
  }

  /// Find the index of a counter in the widget.shipCounters list.
  int _indexOfCounter(ShipType type, int number) {
    return widget.shipCounters.indexWhere(
      (c) => c.type == type && c.number == number,
    );
  }

  /// Build a counter by stamping current tech levels.
  ///
  /// Smarter flow:
  ///   1. If the player has a queued purchase of this type on Production,
  ///      consume one and stamp the counter directly (no confirmation).
  ///   2. Otherwise, hard-block when the counter pool for this type is full.
  ///   3. Otherwise, ask the player to confirm a manual override stamp
  ///      (no CP deducted — for cases where the ship was paid for outside
  ///      the app).
  Future<void> _buildCounter(ShipType type, int number) async {
    final idx = _indexOfCounter(type, number);
    if (idx < 0) return;

    final hasQueued = (widget.queuedShipPurchases[type] ?? 0) > 0;

    if (hasQueued && widget.onConsumeQueuedPurchase != null) {
      final consumed = widget.onConsumeQueuedPurchase!(type);
      if (consumed) {
        _stampCounterAt(idx, type, number);
        return;
      }
      // Fall through (race / stale queue) — treat like manual stamp path.
    }

    // Counter pool guard.
    if (!_hasCounterStockFor(type)) {
      final def = kShipDefinitions[type];
      final abbr = def?.abbreviation ?? type.name.toUpperCase();
      final max = def?.maxCounters ?? 0;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content:
              Text('All $max $abbr counters are in use. Scrap one first.'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await _confirmManualStamp(context, type);
    if (confirmed == true) {
      _stampCounterAt(idx, type, number);
    }
  }

  void _stampCounterAt(int idx, ShipType type, int number) {
    final stamped = ShipCounter.stampFromTech(
      type,
      number,
      widget.techState,
      facilitiesMode: widget.config.useFacilitiesCosts,
      advancedMunitions: widget.shipSpecialAbilities[type] == 11,
      hullSizeModifier: _hullSizeModifier,
    );
    final updated = List<ShipCounter>.from(widget.shipCounters);
    updated[idx] = stamped;
    widget.onCountersChanged(updated);
  }

  bool _hasCounterStockFor(ShipType type) {
    final def = kShipDefinitions[type];
    if (def == null || def.maxCounters == 0) return true;
    final built = widget.shipCounters
        .where((c) => c.type == type && c.isBuilt)
        .length;
    return built < def.maxCounters;
  }

  Future<bool?> _confirmManualStamp(BuildContext context, ShipType type) {
    final def = kShipDefinitions[type];
    final abbr = def?.abbreviation ?? type.name.toUpperCase();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stamp without CP?'),
        content: Text(
          'This will mark an $abbr counter as built without deducting CP '
          'from your ledger. Use this only if the ship was already paid '
          'for on the tabletop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stamp anyway'),
          ),
        ],
      ),
    );
  }

  /// Upgrade a built counter to current tech levels.
  void _upgradeCounter(ShipType type, int number) {
    final idx = _indexOfCounter(type, number);
    if (idx < 0) return;

    final counter = widget.shipCounters[idx];
    final upgraded = counter.upgradeToTech(
      widget.techState,
      facilitiesMode: widget.config.useFacilitiesCosts,
      advancedMunitions: widget.shipSpecialAbilities[type] == 11,
      hullSizeModifier: _hullSizeModifier,
    );
    if (upgraded == null) return;

    final updated = List<ShipCounter>.from(widget.shipCounters);
    updated[idx] = upgraded;
    widget.onCountersChanged(updated);
    widget.onUpgradeCostIncurred?.call(counter.upgradeCost(facilitiesMode: widget.config.useFacilitiesCosts, hullSizeModifier: _hullSizeModifier));
  }

  /// Update a counter from a CounterUpdate payload.
  ///
  /// If the update would change a core A/D/T/M stat to a value that diverges
  /// from what the current tech state would stamp (i.e. the player is manually
  /// overriding away from canonical), prompt for confirmation via a
  /// Material 3 AlertDialog. Session-scoped "Don't ask again" is honored via
  /// [_suppressDriftConfirm]. The check is skipped when the proposed value
  /// MATCHES the stamped value (restoring to canonical).
  Future<void> _updateCounter(
      ShipType type, int number, CounterUpdate update) async {
    if (_indexOfCounter(type, number) < 0) return;

    // Drift check: only for A/D/T/M core stats. otherTechs / experience are
    // player-tracked values that have no tech-stamped counterpart.
    if (!_suppressDriftConfirm) {
      final stamped = ShipCounter.stampFromTech(
        type,
        number,
        widget.techState,
        facilitiesMode: widget.config.useFacilitiesCosts,
        advancedMunitions: widget.shipSpecialAbilities[type] == 11,
        hullSizeModifier: _hullSizeModifier,
      );
      final drifting = ShipTechDriftCheck.firstDriftingStat(update, stamped);
      if (drifting != null) {
        final proposed = ShipTechDriftCheck.proposedValueFor(update, drifting);
        final stampedValue =
            ShipTechDriftCheck.stampedValueFor(stamped, drifting);
        if (!mounted) return;
        final confirmed = await _confirmDriftOverride(
          context,
          statName: drifting,
          proposed: proposed,
          stamped: stampedValue,
        );
        if (confirmed != true) return;
      }
    }

    // Re-lookup index — the async dialog may have outlived a rebuild that
    // reordered counters.
    final curIdx = _indexOfCounter(type, number);
    if (curIdx < 0) return;
    final counter = widget.shipCounters[curIdx];
    final updated = List<ShipCounter>.from(widget.shipCounters);

    // Merge other techs if provided
    Map<String, int>? mergedOther;
    if (update.otherTechs != null) {
      mergedOther = Map<String, int>.from(counter.otherTechs);
      mergedOther.addAll(update.otherTechs!);
    }

    // Map experience int to enum
    ShipExperience? exp;
    if (update.experience != null) {
      exp = ShipExperience.values[
          update.experience!.clamp(0, ShipExperience.values.length - 1)];
    }

    updated[curIdx] = counter.copyWith(
      attack: update.attack,
      defense: update.defense,
      tactics: update.tactics,
      move: update.move,
      otherTechs: mergedOther,
      experience: exp,
    );
    widget.onCountersChanged(updated);
  }

  /// Show the drift confirmation dialog. Returns true if the user confirmed
  /// the override, false/null if cancelled. Updates [_suppressDriftConfirm]
  /// when the checkbox is set.
  Future<bool?> _confirmDriftOverride(
    BuildContext context, {
    required String statName,
    required int proposed,
    required int stamped,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool dontAskAgain = false;
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            title: const Text('Override tech value?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your current tech would set $statName to $stamped, but '
                  "you're changing it to $proposed. This is fine for "
                  'house rules or special abilities.',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: dontAskAgain,
                  onChanged: (v) =>
                      setLocalState(() => dontAskAgain = v ?? false),
                  title: const Text("Don't ask again this session"),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (dontAskAgain) {
                    _suppressDriftConfirm = true;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Override'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fm = widget.config.useFacilitiesCosts;
    final attLevel = widget.techState.getLevel(TechId.attack, facilitiesMode: fm);
    final defLevel = widget.techState.getLevel(TechId.defense, facilitiesMode: fm);
    final tacLevel = widget.techState.getLevel(TechId.tactics, facilitiesMode: fm);
    final movLevel = widget.techState.getLevel(TechId.move, facilitiesMode: fm);

    final visibleSet = _visibleTypes();
    final templates = buildCounterTemplates();

    // Group templates by type, filtered to visible types
    final grouped = <ShipType, List<CounterTemplate>>{};
    for (final t in templates) {
      if (!visibleSet.contains(t.type)) continue;
      grouped.putIfAbsent(t.type, () => []).add(t);
    }

    // Determine if any built counter needs upgrade (controls Upgrade All button).
    final fmUpgrade = widget.config.useFacilitiesCosts;
    final hasAnyUpgradable = widget.shipCounters.any((c) => c.isBuilt && c.needsUpgrade(
          widget.techState,
          facilitiesMode: fmUpgrade,
          advancedMunitions: widget.shipSpecialAbilities[c.type] == 11,
          hullSizeModifier: _hullSizeModifier,
        ));

    // Any built counters at all? Controls empty-state display.
    final hasAnyBuilt = widget.shipCounters.any((c) => c.isBuilt);

    return Column(
      key: TutorialTargets.shipTechPageRoot,
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SHIP TECHNOLOGY SHEET - Turn ${widget.turnNumber}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.upgrade, size: 18),
                    label: const Text('Upgrade All'),
                    onPressed: hasAnyUpgradable ? _upgradeAll : null,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.calculate, size: 22),
                    tooltip: 'Combat Calculator',
                    onPressed: () => showCombatCalculatorDialog(context),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Current Empire Tech:  '
                'Att[$attLevel]  Def[$defLevel]  '
                'Tac[$tacLevel]  Mov[$movLevel]',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              // Search field
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    hintText: 'Search counters (e.g. DD#3)',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    prefixIconConstraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ],
          ),
        ),
        // Scrollable body
        Expanded(
          child: hasAnyBuilt
              ? _ShipTechList(
                  items: _buildItems(context, grouped),
                )
              : _buildEmptyState(context),
        ),
      ],
    );
  }

  /// Empty-state widget shown when no counters are built.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No ships built yet. Build ships on the Production tab, then return here to stamp tech levels.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (widget.onGoToProduction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onGoToProduction,
                icon: const Icon(Icons.factory_outlined, size: 18),
                label: const Text('Go to Production'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Upgrade every built counter that needs an upgrade, in one pass.
  void _upgradeAll() {
    final fm = widget.config.useFacilitiesCosts;
    final updated = List<ShipCounter>.from(widget.shipCounters);
    var upgradedCount = 0;
    var totalCost = 0;

    for (var i = 0; i < updated.length; i++) {
      final c = updated[i];
      if (!c.isBuilt) continue;
      final advMun = widget.shipSpecialAbilities[c.type] == 11;
      if (!c.needsUpgrade(widget.techState,
          facilitiesMode: fm, advancedMunitions: advMun, hullSizeModifier: _hullSizeModifier)) {
        continue;
      }
      final cost = c.upgradeCost(facilitiesMode: fm, hullSizeModifier: _hullSizeModifier);
      final up = c.upgradeToTech(widget.techState,
          facilitiesMode: fm, advancedMunitions: advMun, hullSizeModifier: _hullSizeModifier);
      if (up == null) continue;
      updated[i] = up;
      upgradedCount++;
      totalCost += cost;
    }

    if (upgradedCount == 0) return;

    widget.onCountersChanged(updated);
    if (totalCost > 0) {
      widget.onUpgradeCostIncurred?.call(totalCost);
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Upgraded $upgradedCount ship${upgradedCount == 1 ? '' : 's'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Normalize a string for search comparison.
  /// Strips whitespace and '#' so both "DD #3" and "DD#3" match a "DD#3" query.
  String _normalize(String s) {
    final sb = StringBuffer();
    for (final ch in s.toLowerCase().codeUnits) {
      // Skip space (0x20), tab, #
      if (ch == 0x20 || ch == 0x09 || ch == 0x23) continue;
      sb.writeCharCode(ch);
    }
    return sb.toString();
  }

  /// Build the flat list of widgets: section headers + counter rows.
  List<Widget> _buildItems(BuildContext context, Map<ShipType, List<CounterTemplate>> grouped) {
    final items = <Widget>[];
    final normalizedQuery = _normalize(_searchQuery);
    final hasQuery = normalizedQuery.isNotEmpty;

    for (final shipType in _displayOrder) {
      final group = grouped[shipType];
      if (group == null || group.isEmpty) continue;

      final def = kShipDefinitions[shipType];
      final abbr = def?.abbreviation ?? shipType.name.toUpperCase();
      final name = def?.name ?? '';

      // If searching, pre-filter the group so sections with no matches are hidden.
      List<CounterTemplate> filteredGroup = group;
      if (hasQuery) {
        filteredGroup = group.where((t) {
          final labelMatch = _normalize(t.label).contains(normalizedQuery);
          final nameMatch = _normalize(name).contains(normalizedQuery);
          final abbrMatch = _normalize(abbr).contains(normalizedQuery);
          return labelMatch || nameMatch || abbrMatch;
        }).toList();
        if (filteredGroup.isEmpty) continue;
      }

      // Section header
      items.add(SectionHeader(
        title: abbr,
        subtitle: name,
        trailing: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: 'Ship info',
            onPressed: () => showShipInfoDialog(ctx, shipType, facilitiesMode: widget.config.useFacilitiesCosts, hullSizeModifier: _hullSizeModifier, onRuleTap: widget.onRuleTap),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ),
      ));

      // Counter rows
      // Show the queued-purchase badge on the FIRST unbuilt row of this
      // ship type so the player can clearly see "this is the next one
      // that will be materialized" without spamming the badge on every row.
      int queuedRemainingForThisType =
          widget.queuedShipPurchases[shipType] ?? 0;
      for (final template in filteredGroup) {
        final idx = _indexOfCounter(template.type, template.counterNumber);
        final counter = idx >= 0 ? widget.shipCounters[idx] : null;
        final isBuilt = counter?.isBuilt ?? false;
        final rowQueuedCount = (!isBuilt && queuedRemainingForThisType > 0)
            ? queuedRemainingForThisType
            : 0;
        if (!isBuilt && queuedRemainingForThisType > 0) {
          queuedRemainingForThisType = 0;
        }

        // Build OtherTechDisplay list from template + counter state
        final otherDisplays = template.otherSlots.map((slot) {
          final level = counter?.otherTechs[slot.label] ?? 0;
          return OtherTechDisplay(
            label: slot.label,
            levels: slot.levels,
            currentLevel: level,
          );
        }).toList();

        final canUpgrade = isBuilt &&
            counter != null &&
            counter.needsUpgrade(
              widget.techState,
              facilitiesMode: widget.config.useFacilitiesCosts,
              advancedMunitions: widget.shipSpecialAbilities[counter.type] == 11,
              hullSizeModifier: _hullSizeModifier,
            );

        // S.1: Detect stat drift between the counter's stamped levels and
        // what the current tech state would produce. If the four core
        // stats diverge in either direction (below OR above current tech),
        // the user has manually edited the stamp and we badge the row.
        bool hasManualOverride = false;
        if (isBuilt && counter != null) {
          final expected = ShipCounter.stampFromTech(
            counter.type,
            counter.number,
            widget.techState,
            facilitiesMode: widget.config.useFacilitiesCosts,
            advancedMunitions:
                widget.shipSpecialAbilities[counter.type] == 11,
            hullSizeModifier: _hullSizeModifier,
          );
          hasManualOverride = counter.attack != expected.attack ||
              counter.defense != expected.defense ||
              counter.tactics != expected.tactics ||
              counter.move != expected.move;
        }

        // PP02 §41.1.6: For materialized Unique Ship counters carrying a
        // design payload, prefer the player-chosen ship name over the
        // generic "UN#1" template label so the Ship Tech sheet reads
        // "Excalibur" instead of "Unique Ship".
        String rowLabel = template.label;
        if (shipType == ShipType.un &&
            counter != null &&
            counter.uniqueDesign != null &&
            counter.uniqueDesign!.name.isNotEmpty) {
          rowLabel = '${counter.uniqueDesign!.name} (#${template.counterNumber})';
        }

        items.add(CounterRow(
          key: ValueKey('${template.type.name}_${template.counterNumber}'),
          label: rowLabel,
          isBuilt: isBuilt,
          attack: counter?.attack ?? 0,
          defense: counter?.defense ?? 0,
          tactics: counter?.tactics ?? 0,
          move: counter?.move ?? 0,
          attLevels: template.attLevels,
          defLevels: template.defLevels,
          tacLevels: template.tacLevels,
          moveLevels: template.moveLevels,
          otherTechs: otherDisplays,
          experience: counter?.experience.index ?? 0,
          showExperience: widget.showExperience && template.hasExperience,
          onExperienceRoll: (isBuilt && _isQuickLearners && widget.showExperience && template.hasExperience)
              ? () => _showExperienceRollDialog(template.type, template.counterNumber)
              : null,
          strongHaptics: widget.config.strongHaptics,
          onBuild: () => _buildCounter(
            template.type,
            template.counterNumber,
          ),
          onChanged: isBuilt
              ? (update) {
                  // Fire-and-forget: _updateCounter may await a confirmation
                  // dialog on drift. CounterRow's ValueChanged<CounterUpdate>
                  // is a sync signature so the Future is intentionally dropped.
                  _updateCounter(
                    template.type,
                    template.counterNumber,
                    update,
                  );
                }
              : null,
          upgradeCost: canUpgrade ? counter.upgradeCost(facilitiesMode: widget.config.useFacilitiesCosts, hullSizeModifier: _hullSizeModifier) : null,
          onUpgrade: canUpgrade
              ? () => _upgradeCounter(
                    template.type,
                    template.counterNumber,
                  )
              : null,
          onDestroy: isBuilt
              ? () => _destroyCounter(
                    context,
                    template.type,
                    template.counterNumber,
                  )
              : null,
          onLocate: isBuilt && counter != null && widget.onLocateShip != null
              ? () => widget.onLocateShip!(counter.id)
              : null,
          onInfoTap: () => showShipInfoDialog(
            context,
            template.type,
            facilitiesMode: widget.config.useFacilitiesCosts,
            isAlternateEmpire: widget.config.enableAlternateEmpire,
            hullSizeModifier: _hullSizeModifier,
            onRuleTap: widget.onRuleTap,
          ),
          queuedCount: rowQueuedCount,
          hasManualOverride: hasManualOverride,
          poolFull: !isBuilt && !_hasCounterStockFor(template.type),
        ));
      }
    }

    return items;
  }

  /// Whether Quick Learners EA (#40) is the active empire advantage.
  bool get _isQuickLearners => widget.config.selectedEmpireAdvantage == 40;

  /// Show the Quick Learners experience-check dice-roll helper dialog.
  ///
  /// Entirely optional — the player can always set experience directly on the
  /// counter row circles. This is a convenience shortcut that rolls 2d10 and
  /// picks the best result, per the Quick Learners card text.
  Future<void> _showExperienceRollDialog(ShipType type, int number) async {
    if (!mounted) return;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _QuickLearnersRollDialog(),
    );
    if (result != null && result >= 1 && result <= 5) {
      _updateCounter(type, number, CounterUpdate(experience: result));
    }
  }

  void _destroyCounter(BuildContext context, ShipType type, int number) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Destroy Ship?'),
        content: const Text(
          'Mark this counter as destroyed/scrapped. '
          'It will return to unbuilt state and can be rebuilt later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Destroy'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
      final updated = widget.shipCounters.map((c) {
        if (c.type == type && c.number == number) {
          return ShipCounter(type: c.type, number: c.number);
        }
        return c;
      }).toList();
      widget.onCountersChanged(updated);
    });
  }
}

/// Pure-data helper for the drift-confirmation dialog on built-counter stat
/// edits (PP10). Exposed as a top-level class so it can be unit-tested
/// without instantiating the widget tree.
///
/// A [CounterUpdate] "drifts" when any core A/D/T/M field it carries has a
/// value that does not match the corresponding stat on the fresh
/// [ShipCounter.stampFromTech] result for the current tech state.
class ShipTechDriftCheck {
  ShipTechDriftCheck._();

  /// Returns the name of the first A/D/T/M stat in [update] that diverges
  /// from [stamped], or null if nothing drifts. Only inspects the four core
  /// tech-stamped stats; otherTechs/experience never drift (no canonical
  /// tech value to compare against).
  static String? firstDriftingStat(CounterUpdate update, ShipCounter stamped) {
    if (update.attack != null && update.attack != stamped.attack) {
      return 'Attack';
    }
    if (update.defense != null && update.defense != stamped.defense) {
      return 'Defense';
    }
    if (update.tactics != null && update.tactics != stamped.tactics) {
      return 'Tactics';
    }
    if (update.move != null && update.move != stamped.move) {
      return 'Move';
    }
    return null;
  }

  /// The proposed value in [update] for the given stat name.
  /// [statName] must be one of 'Attack', 'Defense', 'Tactics', 'Move'.
  static int proposedValueFor(CounterUpdate update, String statName) {
    switch (statName) {
      case 'Attack':
        return update.attack ?? 0;
      case 'Defense':
        return update.defense ?? 0;
      case 'Tactics':
        return update.tactics ?? 0;
      case 'Move':
        return update.move ?? 0;
    }
    return 0;
  }

  /// The stamped canonical value on [stamped] for the given stat name.
  static int stampedValueFor(ShipCounter stamped, String statName) {
    switch (statName) {
      case 'Attack':
        return stamped.attack;
      case 'Defense':
        return stamped.defense;
      case 'Tactics':
        return stamped.tactics;
      case 'Move':
        return stamped.move;
    }
    return 0;
  }
}

/// Trivial wrapper so the item list is built once per build, not per
/// itemBuilder invocation.
class _ShipTechList extends StatelessWidget {
  final List<Widget> items;

  const _ShipTechList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}

/// Quick Learners EA (#40) dice-roll dialog for experience checks.
///
/// Offers two paths:
///   - "Roll in app": generates 2d10, displays both, highlights the best,
///     and lets the user confirm applying the result as an experience level.
///   - "Enter manually": a simple text field for a physical dice result.
///
/// Returns an experience level (1-5) via Navigator.pop, or null on cancel.
/// The experience-level mapping follows the rulebook Military Academy table:
///   d10 result 1-2 = Green (1), 3-4 = Seasoned (2), 5-6 = Veteran (3),
///   7-8 = Elite (4), 9-10 = Legendary (5).
class _QuickLearnersRollDialog extends StatefulWidget {
  @override
  State<_QuickLearnersRollDialog> createState() =>
      _QuickLearnersRollDialogState();
}

class _QuickLearnersRollDialogState extends State<_QuickLearnersRollDialog> {
  static final _rng = Random();

  // Roll state
  int? _die1;
  int? _die2;
  bool _rolled = false;

  // Manual entry state
  bool _manualMode = false;
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  /// Map a d10 result (1-10) to an experience level (1-5).
  static int _d10ToExpLevel(int roll) {
    if (roll <= 2) return 1; // Green
    if (roll <= 4) return 2; // Seasoned
    if (roll <= 6) return 3; // Veteran
    if (roll <= 8) return 4; // Elite
    return 5; // Legendary
  }

  static const _expNames = ['', 'Green', 'Seasoned', 'Veteran', 'Elite', 'Legendary'];

  void _rollDice() {
    setState(() {
      _die1 = _rng.nextInt(10) + 1;
      _die2 = _rng.nextInt(10) + 1;
      _rolled = true;
    });
  }

  int get _bestRoll => max(_die1 ?? 0, _die2 ?? 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Quick Learners \u2014 Experience Check'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roll 2d10 and pick the best result, OR enter the '
              'result manually.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (!_manualMode) ...[
              if (!_rolled)
                Center(
                  child: FilledButton.icon(
                    onPressed: _rollDice,
                    icon: const Icon(Icons.casino, size: 18),
                    label: const Text('Roll in app'),
                  ),
                ),
              if (_rolled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dieChip(theme, 'Die 1', _die1!, _die1! >= _die2!),
                    const SizedBox(width: 12),
                    _dieChip(theme, 'Die 2', _die2!, _die2! > _die1!),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Best: $_bestRoll \u2192 ${_expNames[_d10ToExpLevel(_bestRoll)]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _manualMode = true;
                    _rolled = false;
                  }),
                  child: const Text('Enter manually instead'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Best d10 result (1-10)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _manualMode = false;
                  }),
                  child: const Text('Roll in app instead'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_rolled && !_manualMode)
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _d10ToExpLevel(_bestRoll)),
            child: Text('Apply ${_expNames[_d10ToExpLevel(_bestRoll)]}'),
          ),
        if (_manualMode)
          FilledButton(
            onPressed: () {
              final val = int.tryParse(_manualController.text);
              if (val == null || val < 1 || val > 10) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(
                    content: Text('Enter a number from 1 to 10.'),
                  ),
                );
                return;
              }
              Navigator.pop(context, _d10ToExpLevel(val));
            },
            child: const Text('Apply'),
          ),
      ],
    );
  }

  Widget _dieChip(ThemeData theme, String label, int value, bool isBest) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        )),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isBest
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBest
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: isBest ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isBest
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
