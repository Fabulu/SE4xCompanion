import 'package:flutter/material.dart';

import '../data/counter_templates.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/game_config.dart';
import '../models/ship_counter.dart';
import '../models/technology.dart';
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
  });

  @override
  State<ShipTechPage> createState() => _ShipTechPageState();
}

class _ShipTechPageState extends State<ShipTechPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

    // UN: unique ships, show in Facilities/AGT
    if (widget.config.enableFacilities || widget.config.ownership.allGoodThings) {
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
  void _buildCounter(ShipType type, int number) {
    final idx = _indexOfCounter(type, number);
    if (idx < 0) return;

    final stamped = ShipCounter.stampFromTech(
      type,
      number,
      widget.techState,
      facilitiesMode: widget.config.useFacilitiesCosts,
      advancedMunitions: widget.shipSpecialAbilities[type] == 11,
    );

    final updated = List<ShipCounter>.from(widget.shipCounters);
    updated[idx] = stamped;
    widget.onCountersChanged(updated);
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
    );
    if (upgraded == null) return;

    final updated = List<ShipCounter>.from(widget.shipCounters);
    updated[idx] = upgraded;
    widget.onCountersChanged(updated);
    widget.onUpgradeCostIncurred?.call(counter.upgradeCost(facilitiesMode: widget.config.useFacilitiesCosts));
  }

  /// Update a counter from a CounterUpdate payload.
  void _updateCounter(ShipType type, int number, CounterUpdate update) {
    final idx = _indexOfCounter(type, number);
    if (idx < 0) return;

    final counter = widget.shipCounters[idx];
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

    updated[idx] = counter.copyWith(
      attack: update.attack,
      defense: update.defense,
      tactics: update.tactics,
      move: update.move,
      otherTechs: mergedOther,
      experience: exp,
    );
    widget.onCountersChanged(updated);
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
        ));

    // Any built counters at all? Controls empty-state display.
    final hasAnyBuilt = widget.shipCounters.any((c) => c.isBuilt);

    return Column(
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
          facilitiesMode: fm, advancedMunitions: advMun)) {
        continue;
      }
      final cost = c.upgradeCost(facilitiesMode: fm);
      final up = c.upgradeToTech(widget.techState,
          facilitiesMode: fm, advancedMunitions: advMun);
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
            onPressed: () => showShipInfoDialog(ctx, shipType, facilitiesMode: widget.config.useFacilitiesCosts, onRuleTap: widget.onRuleTap),
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
      for (final template in filteredGroup) {
        final idx = _indexOfCounter(template.type, template.counterNumber);
        final counter = idx >= 0 ? widget.shipCounters[idx] : null;
        final isBuilt = counter?.isBuilt ?? false;

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
            );

        items.add(CounterRow(
          key: ValueKey('${template.type.name}_${template.counterNumber}'),
          label: template.label,
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
          strongHaptics: widget.config.strongHaptics,
          onBuild: () => _buildCounter(
            template.type,
            template.counterNumber,
          ),
          onChanged: isBuilt
              ? (update) => _updateCounter(
                    template.type,
                    template.counterNumber,
                    update,
                  )
              : null,
          upgradeCost: canUpgrade ? counter.upgradeCost(facilitiesMode: widget.config.useFacilitiesCosts) : null,
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
        ));
      }
    }

    return items;
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
