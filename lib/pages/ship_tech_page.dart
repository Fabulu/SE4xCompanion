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
class ShipTechPage extends StatelessWidget {
  final GameConfig config;
  final int turnNumber;
  final TechState techState;
  final List<ShipCounter> shipCounters;
  final bool showExperience;
  final ValueChanged<List<ShipCounter>> onCountersChanged;
  final ValueChanged<int>? onUpgradeCostIncurred;

  const ShipTechPage({
    super.key,
    required this.config,
    required this.turnNumber,
    required this.techState,
    required this.shipCounters,
    required this.showExperience,
    required this.onCountersChanged,
    this.onUpgradeCostIncurred,
  });

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
  ];

  /// Determine which ship types are visible given the current config.
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
      facilitiesMode: config.useFacilitiesCosts,
      closeEncountersOwned: config.ownership.closeEncounters,
      replicatorsEnabled: config.enableReplicators,
      advancedConEnabled: config.enableAdvancedConstruction,
    );

    final hasFighters = techs.contains(TechId.fighters);
    final hasCloaking = techs.contains(TechId.cloaking);
    final hasMines = techs.contains(TechId.mines);
    final hasMineSweep = techs.contains(TechId.mineSweep);
    final hasBoarding = techs.contains(TechId.boarding);
    final hasMissileBoats = techs.contains(TechId.missileBoats);

    // Fighters and CV require Fighters tech or Close Encounters
    if (hasFighters || config.ownership.closeEncounters) {
      visible.add(ShipType.fighter);
      visible.add(ShipType.cv);
    }

    // BV requires Advanced Construction
    if (config.enableAdvancedConstruction) {
      visible.add(ShipType.bv);
    }

    // TN: show if ship size tech allows hull 4+ (Facilities mode has size 7)
    // In practice, TN is available in any game with large enough ship size tech.
    // Show it always for Facilities mode, or if Close Encounters / AGT owned.
    if (config.enableFacilities ||
        config.ownership.closeEncounters ||
        config.ownership.allGoodThings) {
      visible.add(ShipType.tn);
    }

    // UN: unique ships, show in Facilities/AGT
    if (config.enableFacilities || config.ownership.allGoodThings) {
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
    if (hasBoarding || hasMissileBoats || config.enableFacilities) {
      visible.add(ShipType.bdMb);
    }

    // Transport always shown (needed for ground combat)
    visible.add(ShipType.transport);

    return visible;
  }

  /// Find the index of a counter in the shipCounters list.
  int _indexOfCounter(ShipType type, int number) {
    return shipCounters.indexWhere(
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
      techState,
      facilitiesMode: config.useFacilitiesCosts,
    );

    final updated = List<ShipCounter>.from(shipCounters);
    updated[idx] = stamped;
    onCountersChanged(updated);
  }

  /// Upgrade a built counter to current tech levels.
  void _upgradeCounter(ShipType type, int number) {
    final idx = _indexOfCounter(type, number);
    if (idx < 0) return;

    final counter = shipCounters[idx];
    final upgraded = counter.upgradeToTech(
      techState,
      facilitiesMode: config.useFacilitiesCosts,
    );
    if (upgraded == null) return;

    final updated = List<ShipCounter>.from(shipCounters);
    updated[idx] = upgraded;
    onCountersChanged(updated);
    onUpgradeCostIncurred?.call(counter.upgradeCost);
  }

  /// Update a counter from a CounterUpdate payload.
  void _updateCounter(ShipType type, int number, CounterUpdate update) {
    final idx = _indexOfCounter(type, number);
    if (idx < 0) return;

    final counter = shipCounters[idx];
    final updated = List<ShipCounter>.from(shipCounters);

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
    onCountersChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fm = config.useFacilitiesCosts;
    final attLevel = techState.getLevel(TechId.attack, facilitiesMode: fm);
    final defLevel = techState.getLevel(TechId.defense, facilitiesMode: fm);
    final tacLevel = techState.getLevel(TechId.tactics, facilitiesMode: fm);
    final movLevel = techState.getLevel(TechId.move, facilitiesMode: fm);

    final visibleSet = _visibleTypes();
    final templates = buildCounterTemplates();

    // Group templates by type, filtered to visible types
    final grouped = <ShipType, List<CounterTemplate>>{};
    for (final t in templates) {
      if (!visibleSet.contains(t.type)) continue;
      grouped.putIfAbsent(t.type, () => []).add(t);
    }

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
                      'SHIP TECHNOLOGY SHEET - Turn $turnNumber',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
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
            ],
          ),
        ),
        // Scrollable body
        Expanded(
          child: _ShipTechList(
            items: _buildItems(context, grouped),
          ),
        ),
      ],
    );
  }

  /// Build the flat list of widgets: section headers + counter rows.
  List<Widget> _buildItems(BuildContext context, Map<ShipType, List<CounterTemplate>> grouped) {
    final items = <Widget>[];

    for (final shipType in _displayOrder) {
      final group = grouped[shipType];
      if (group == null || group.isEmpty) continue;

      final def = kShipDefinitions[shipType];
      final abbr = def?.abbreviation ?? shipType.name.toUpperCase();
      final name = def?.name ?? '';

      // Section header
      items.add(SectionHeader(
        title: abbr,
        subtitle: name,
        trailing: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: 'Ship info',
            onPressed: () => showShipInfoDialog(ctx, shipType),
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
      for (final template in group) {
        final idx = _indexOfCounter(template.type, template.counterNumber);
        final counter = idx >= 0 ? shipCounters[idx] : null;
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
              techState,
              facilitiesMode: config.useFacilitiesCosts,
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
          showExperience: showExperience && template.hasExperience,
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
          upgradeCost: canUpgrade ? counter.upgradeCost : null,
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
      final updated = shipCounters.map((c) {
        if (c.type == type && c.number == number) {
          return ShipCounter(type: c.type, number: c.number);
        }
        return c;
      }).toList();
      onCountersChanged(updated);
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
