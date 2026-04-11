import 'package:flutter/material.dart';

import '../data/card_manifest.dart';
import '../data/card_modifiers.dart';
import '../data/empire_advantages.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/game_modifier.dart';
import '../models/game_state.dart';
import '../models/production_state.dart';
import '../models/technology.dart';
import '../models/world.dart';
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
  late int _maintenanceIncrease;
  late int _maintenanceDecrease;
  late int _researchGrantsCp;
  late int _turnNumber;
  late Map<TechId, int> _techLevels;

  // World overrides
  late List<WorldState> _worlds;

  // Production spending
  late int _lpPlacedOnLc;
  late Map<TechId, int> _pendingTechPurchases;
  late List<ShipPurchase> _shipPurchases;

  // Accumulated research
  late Map<String, int> _accumulatedResearch;

  // Active modifiers
  late List<GameModifier> _activeModifiers;

  @override
  void initState() {
    super.initState();
    final prod = widget.gameState.production;
    _cpCarryOver = prod.cpCarryOver;
    _lpCarryOver = prod.lpCarryOver;
    _rpCarryOver = prod.rpCarryOver;
    _tpCarryOver = prod.tpCarryOver;
    _turnOrderBid = prod.turnOrderBid;
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

    // World overrides
    _worlds = List<WorldState>.from(prod.worlds);

    // Production spending
    _lpPlacedOnLc = prod.lpPlacedOnLc;
    _pendingTechPurchases = Map<TechId, int>.from(prod.pendingTechPurchases);
    _shipPurchases = List<ShipPurchase>.from(prod.shipPurchases);

    // Accumulated research
    _accumulatedResearch = Map<String, int>.from(prod.accumulatedResearch);

    // Active modifiers
    _activeModifiers = List<GameModifier>.from(widget.gameState.activeModifiers);
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
      maintenanceIncrease: _maintenanceIncrease,
      maintenanceDecrease: _maintenanceDecrease,
      researchGrantsCp: _researchGrantsCp,
      techState: newTech,
      worlds: _worlds,
      lpPlacedOnLc: _lpPlacedOnLc,
      pendingTechPurchases: _pendingTechPurchases,
      shipPurchases: _shipPurchases,
      accumulatedResearch: _accumulatedResearch,
    );

    return widget.gameState.copyWith(
      turnNumber: _turnNumber,
      production: newProd,
      activeModifiers: _activeModifiers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techs = _visibleTechs();
    final ea = widget.gameState.config.empireAdvantage;

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
                  // --- Empire Advantage Effects Display ---
                  if (ea != null) ...[
                    _buildEaEffectsSummary(theme, ea),
                    const SizedBox(height: 12),
                  ],

                  // --- Active Modifiers ---
                  _buildModifiersSection(theme),
                  const SizedBox(height: 12),

                  // --- Resources ---
                  const SectionHeader(title: 'Resources'),
                  const SizedBox(height: 4),
                  _row('CP Carry Over', _cpCarryOver, 0, 999, (v) => setState(() => _cpCarryOver = v)),
                  _row('LP Carry Over', _lpCarryOver, 0, 999, (v) => setState(() => _lpCarryOver = v)),
                  _row('RP Carry Over', _rpCarryOver, 0, 999, (v) => setState(() => _rpCarryOver = v)),
                  _row('TP Carry Over', _tpCarryOver, 0, 999, (v) => setState(() => _tpCarryOver = v)),
                  _row('Turn Order Bid', _turnOrderBid, 0, 999, (v) => setState(() => _turnOrderBid = v)),
                  _row('Maintenance Increase', _maintenanceIncrease, 0, 999, (v) => setState(() => _maintenanceIncrease = v)),
                  _row('Maintenance Decrease', _maintenanceDecrease, 0, 999, (v) => setState(() => _maintenanceDecrease = v)),
                  _row('Research Grants CP', _researchGrantsCp, 0, 999, (v) => setState(() => _researchGrantsCp = v)),

                  const SizedBox(height: 12),

                  // --- Production Spending ---
                  const SectionHeader(title: 'Production Spending'),
                  const SizedBox(height: 4),
                  _row('LP Placed on LC', _lpPlacedOnLc, 0, 999, (v) => setState(() => _lpPlacedOnLc = v)),

                  // Pending tech purchases
                  if (_pendingTechPurchases.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Pending Tech Purchases',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            )),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear All'),
                          onPressed: () => setState(() => _pendingTechPurchases = {}),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    for (final entry in _pendingTechPurchases.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_techDisplayNames[entry.key] ?? entry.key.name} -> Lv ${entry.value}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() {
                                _pendingTechPurchases = Map<TechId, int>.from(_pendingTechPurchases)
                                  ..remove(entry.key);
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // Ship purchases
                  if (_shipPurchases.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Ship Purchases',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            )),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear All'),
                          onPressed: () => setState(() => _shipPurchases = []),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    for (int i = 0; i < _shipPurchases.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_shipPurchases[i].quantity}x ${kShipDefinitions[_shipPurchases[i].type]?.abbreviation ?? _shipPurchases[i].type.name}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() {
                                _shipPurchases = List<ShipPurchase>.from(_shipPurchases)
                                  ..removeAt(i);
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 12),

                  // --- Worlds ---
                  const SectionHeader(title: 'Worlds'),
                  const SizedBox(height: 4),
                  for (int i = 0; i < _worlds.length; i++)
                    _buildWorldOverride(theme, i),

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

                  // --- Accumulated Research ---
                  if (_accumulatedResearch.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Accumulated Research',
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        onPressed: () => setState(() => _accumulatedResearch = {}),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final key in _accumulatedResearch.keys.toList())
                      _buildAccumulatedResearchRow(theme, key),
                    const SizedBox(height: 12),
                  ],

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

  // ---------------------------------------------------------------------------
  // Active Modifiers section
  // ---------------------------------------------------------------------------

  Widget _buildModifiersSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Active Modifiers',
          trailing: TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            onPressed: () => _showAddModifierDialog(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 4),

        if (_activeModifiers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No active modifiers',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

        for (int i = 0; i < _activeModifiers.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeModifiers[i].name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _activeModifiers[i].effectDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _activeModifiers = List<GameModifier>.from(_activeModifiers)
                      ..removeAt(i);
                  }),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Quick-add presets
        Text(
          'Quick Add',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final preset in kModifierPresets)
              ActionChip(
                label: Text(preset.label, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () => setState(() {
                  _activeModifiers = [
                    ..._activeModifiers,
                    ...preset.modifiers,
                  ];
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'From Catalog',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Pick...', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _showCatalogPicker(context),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Catalog picker dialog (cards with bound GameModifiers).
  // ---------------------------------------------------------------------------

  Future<void> _showCatalogPicker(BuildContext parentContext) async {
    // Pre-compute bindable cards: those with at least one modifier.
    final bindable = <CardEntry>[];
    for (final card in kAllCards) {
      if (cardHasModifiers(card.number)) bindable.add(card);
    }

    String query = '';
    await showDialog(
      context: parentContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            final q = query.toLowerCase();
            final filtered = q.isEmpty
                ? bindable
                : bindable
                    .where((c) =>
                        c.name.toLowerCase().contains(q) ||
                        c.description.toLowerCase().contains(q) ||
                        '#${c.number}'.contains(q))
                    .toList();
            return AlertDialog(
              title: const Text('Pick Card Modifier'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
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
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final card = filtered[i];
                          final binding = cardModifiersFor(card.number)!;
                          return ListTile(
                            dense: true,
                            title: Text(
                              '#${card.number} ${card.name}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              binding.modifiers
                                  .map((m) => m.effectDescription)
                                  .join(' • '),
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              // Bug: stamp each modifier with its card's
                              // sourceCardId (matching the "Apply this card"
                              // flow in rules_reference_page.dart) so the
                              // existing dedup check can suppress duplicate
                              // applications via this picker.
                              final sourceId =
                                  '${card.type}:${card.number}';
                              final existingIds = <String>{
                                for (final m in _activeModifiers)
                                  if (m.sourceCardId != null)
                                    m.sourceCardId!,
                              };
                              if (existingIds.contains(sourceId)) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(parentContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${card.name} already applied'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              final stamped = [
                                for (final m in binding.modifiers)
                                  m.withSourceCardId(sourceId),
                              ];
                              setState(() {
                                _activeModifiers = [
                                  ..._activeModifiers,
                                  ...stamped,
                                ];
                              });
                              Navigator.pop(ctx);
                            },
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
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddModifierDialog(BuildContext parentContext) {
    String name = '';
    String type = 'costMod';
    ShipType? shipType = ShipType.dd;
    int value = 0;
    bool isPercent = false;

    final typeLabels = {
      'costMod': 'Cost',
      'maintenanceMod': 'Maintenance',
      'incomeMod': 'Income',
      'techCostMod': 'Tech Cost',
    };

    // Ship types with their abbreviations for the dropdown.
    final shipTypes = ShipType.values.where((t) {
      final def = kShipDefinitions[t];
      return def != null;
    }).toList();

    showDialog(
      context: parentContext,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            final needsShipType = type == 'costMod' || type == 'maintenanceMod';
            return AlertDialog(
              title: const Text('Add Modifier'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Alien Tech Card',
                        isDense: true,
                      ),
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        isDense: true,
                      ),
                      items: typeLabels.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) => setInnerState(() => type = v!),
                    ),
                    if (needsShipType) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ShipType?>(
                        initialValue: shipType,
                        decoration: const InputDecoration(
                          labelText: 'Ship Type',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All (global)'),
                          ),
                          ...shipTypes.map((t) {
                            final def = kShipDefinitions[t]!;
                            return DropdownMenuItem(
                              value: t,
                              child: Text('${def.abbreviation} - ${def.name}'),
                            );
                          }),
                        ],
                        onChanged: (v) => setInnerState(() => shipType = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Value: ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: NumberInput(
                            value: value,
                            min: -99,
                            max: 999,
                            onChanged: (v) => setInnerState(() => value = v),
                          ),
                        ),
                      ],
                    ),
                    if (type == 'maintenanceMod') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Percentage', style: TextStyle(fontSize: 14)),
                          Switch(
                            value: isPercent,
                            onChanged: (v) => setInnerState(() => isPercent = v),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.isEmpty) name = 'Custom Modifier';
                    final mod = GameModifier(
                      name: name,
                      type: type,
                      shipType: needsShipType ? shipType : null,
                      value: value,
                      isPercent: isPercent,
                    );
                    setState(() {
                      _activeModifiers = [..._activeModifiers, mod];
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Empire Advantage effects summary
  // ---------------------------------------------------------------------------

  Widget _buildEaEffectsSummary(ThemeData theme, EmpireAdvantage ea) {
    final effects = <String>[];

    if (ea.hullSizeModifier != 0) {
      final sign = ea.hullSizeModifier > 0 ? '+' : '';
      effects.add('Hull size $sign${ea.hullSizeModifier}');
    }
    if (ea.maintenancePercent != 100) {
      effects.add('Maintenance ${ea.maintenancePercent}%');
    }
    if (ea.costModifiers.isNotEmpty) {
      final modStrs = ea.costModifiers.entries.map((e) {
        final def = kShipDefinitions[e.key];
        final abbr = def?.abbreviation ?? e.key.name;
        final sign = e.value > 0 ? '+' : '';
        return '$abbr $sign${e.value} CP';
      });
      effects.add('Cost: ${modStrs.join(', ')}');
    }
    if (ea.colonyShipCostModifier != 0) {
      final sign = ea.colonyShipCostModifier > 0 ? '+' : '';
      effects.add('Colony Ship $sign${ea.colonyShipCostModifier} CP');
    }
    if (ea.techCostMultiplier != 1.0) {
      effects.add('Tech cost x${ea.techCostMultiplier}');
    }
    if (ea.blockedTechs.isNotEmpty) {
      final names = ea.blockedTechs.map((t) => _techDisplayNames[t] ?? t.name);
      effects.add('Blocked: ${names.join(', ')}');
    }
    if (ea.startingTechOverrides.isNotEmpty) {
      final strs = ea.startingTechOverrides.entries.map((e) {
        return '${_techDisplayNames[e.key] ?? e.key.name} ${e.value}';
      });
      effects.add('Starting: ${strs.join(', ')}');
    }

    if (effects.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EA: ${ea.name} (#${ea.cardNumber})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            effects.join(' | '),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // World override rows
  // ---------------------------------------------------------------------------

  Widget _buildWorldOverride(ThemeData theme, int index) {
    final world = _worlds[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            world.name.isEmpty ? 'World ${index + 1}' : world.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          if (world.isHomeworld)
            _row('Homeworld Value', world.homeworldValue, 5, 30, (v) {
              // Snap to multiples of 5
              final snapped = (v / 5).round() * 5;
              setState(() {
                _worlds = List<WorldState>.from(_worlds);
                _worlds[index] = world.copyWith(homeworldValue: snapped.clamp(5, 30));
              });
            }),
          if (!world.isHomeworld)
            _row('Growth Marker', world.growthMarkerLevel, 0, 3, (v) {
              setState(() {
                _worlds = List<WorldState>.from(_worlds);
                _worlds[index] = world.copyWith(growthMarkerLevel: v);
              });
            }),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Blocked', style: TextStyle(fontSize: 14)),
                ),
                Switch(
                  value: world.isBlocked,
                  onChanged: (v) {
                    setState(() {
                      _worlds = List<WorldState>.from(_worlds);
                      _worlds[index] = world.copyWith(isBlocked: v);
                    });
                  },
                ),
              ],
            ),
          ),
          _row('Staged Mineral CP', world.stagedMineralCp, 0, 99, (v) {
            setState(() {
              _worlds = List<WorldState>.from(_worlds);
              _worlds[index] = world.copyWith(stagedMineralCp: v);
            });
          }),
          _row('Garrison GU', world.garrisonGu, 0, 99, (v) {
            setState(() {
              _worlds = List<WorldState>.from(_worlds);
              _worlds[index] = world.copyWith(garrisonGu: v);
            });
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Accumulated research row
  // ---------------------------------------------------------------------------

  Widget _buildAccumulatedResearchRow(ThemeData theme, String key) {
    final value = _accumulatedResearch[key] ?? 0;
    // Parse key format: "techId_targetLevel"
    final parts = key.split('_');
    final displayKey = parts.length >= 2
        ? '${parts.sublist(0, parts.length - 1).join('_')} Lv ${parts.last}'
        : key;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayKey,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          NumberInput(
            value: value,
            min: 0,
            max: 999,
            onChanged: (v) => setState(() {
              _accumulatedResearch = Map<String, int>.from(_accumulatedResearch);
              _accumulatedResearch[key] = v;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() {
              _accumulatedResearch = Map<String, int>.from(_accumulatedResearch)
                ..remove(key);
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generic row helper
  // ---------------------------------------------------------------------------

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
