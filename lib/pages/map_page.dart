import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/sci_fi_names.dart';
import '../data/ship_definitions.dart';
import '../models/map_state.dart';
import '../models/ship_counter.dart';
import '../models/world.dart';
import '../tutorial/tutorial_targets.dart';
import '../util/combat_resolution.dart';
import '../widgets/combat_resolution_dialog.dart';

typedef MapStateChanged = void Function(
  GameMapState state, {
  bool recordUndo,
  String? description,
});

class MapPage extends StatefulWidget {
  final GameMapState state;
  final List<WorldState> productionWorlds;
  final List<ShipCounter> shipCounters;
  final String? focusShipId;
  final int focusRequestId;
  final int terraformingLevel;
  final int explorationLevel;
  final int playerMoveLevel;
  final Map<String, ({int used, int total})> shipyardCapacity;
  final VoidCallback? onColonizeCandidatesTapped;
  final MapStateChanged onChanged;
  final void Function(CombatResolution)? onResolveCombat;

  const MapPage({
    super.key,
    required this.state,
    required this.productionWorlds,
    required this.shipCounters,
    this.focusShipId,
    this.focusRequestId = 0,
    this.terraformingLevel = 0,
    this.explorationLevel = 0,
    this.playerMoveLevel = 0,
    this.shipyardCapacity = const {},
    this.onColonizeCandidatesTapped,
    required this.onChanged,
    this.onResolveCombat,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<_MapCanvasState> _mapCanvasKey = GlobalKey<_MapCanvasState>();

  @override
  void initState() {
    super.initState();
    _scheduleFocusIfNeeded();
  }

  void _scheduleFocusIfNeeded() {
    if (widget.focusShipId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.focusShipId == null) return;
      _jumpToShip(widget.focusShipId!);
    });
  }

  GameMapState get _state => widget.state.hexes.isEmpty
      ? widget.state.copyWith(
          hexes: GameMapState.initial(layoutPreset: widget.state.layoutPreset).hexes,
        )
      : widget.state;

  String _worldId(WorldState world) => world.id.isNotEmpty ? world.id : world.name;

  WorldState? _findWorld(String? worldId) {
    if (worldId == null || worldId.isEmpty) return null;
    for (final world in widget.productionWorlds) {
      if (_worldId(world) == worldId || world.name == worldId) return world;
    }
    return null;
  }

  List<WorldState> _availableWorlds({String? excludeHexId, String? includeWorldId}) {
    final placed = _state.placedWorldIds(excludeHexId: excludeHexId);
    return widget.productionWorlds.where((world) {
      final id = _worldId(world);
      return id == includeWorldId || !placed.contains(id);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<ShipCounter> _availableShips({String? fleetId}) {
    final currentFleet = fleetId == null ? null : _state.fleetById(fleetId);
    final currentIds = currentFleet?.shipCounterIds.toSet() ?? const <String>{};
    final assigned = _state.assignedFriendlyShipIds(excludeFleetId: fleetId);
    return widget.shipCounters.where((counter) {
      if (!counter.isBuilt) return false;
      if (currentIds.contains(counter.id)) return true;
      return !assigned.contains(counter.id);
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  void _apply(
    GameMapState next, {
    String? description,
    bool recordUndo = true,
    bool preserveViewport = true,
  }) {
    if (preserveViewport) {
      final viewport = _mapCanvasKey.currentState?.currentViewport;
      if (viewport != null) {
        next = next.copyWith(
          zoom: viewport.zoom,
          panX: viewport.panX,
          panY: viewport.panY,
          rotation: viewport.rotation,
        );
      }
    }
    widget.onChanged(next, description: description, recordUndo: recordUndo);
  }

  void _resetViewport() {
    _mapCanvasKey.currentState?.resetViewport(persistState: false);
    _apply(
      _state.copyWith(zoom: 1.0, panX: 0.0, panY: 0.0, rotation: 0.0),
      recordUndo: false,
      preserveViewport: false,
    );
  }

  void _selectHex(HexCoord coord) {
    _apply(
      _state.copyWith(selectedHex: coord, clearSelectedFleetId: true),
      recordUndo: false,
    );
  }

  void _selectFleet(String fleetId) {
    final fleet = _state.fleetById(fleetId);
    if (fleet == null) return;
    _apply(
      _state.copyWith(
        selectedHex: fleet.coord,
        selectedFleetId: fleetId,
      ),
      recordUndo: false,
    );
  }

  Future<void> _openCombatResolutionDialog(HexCoord coord) async {
    final callback = widget.onResolveCombat;
    if (callback == null) return;
    final fleetsAtHex = _state.fleetsAt(coord);
    if (fleetsAtHex.isEmpty) return;
    final result = await showCombatResolutionDialog(
      context,
      hex: coord,
      fleetsAtHex: fleetsAtHex,
      shipCounters: widget.shipCounters,
      mapState: _state,
      playerMoveLevel: widget.playerMoveLevel,
    );
    if (result != null) {
      callback(result);
    }
  }

  Future<void> _changePreset(MapLayoutPreset preset) async {
    if (preset == _state.layoutPreset) return;
    if (_state.hasAnyMeaningfulContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Map Layout?'),
          content: const Text('Switching layouts clears current map placements.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Change Layout'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    _apply(
      GameMapState.initial(layoutPreset: preset),
      description: 'Map Layout',
      preserveViewport: false,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _addFriendlyFleet(HexCoord coord) {
    final availableShips = _availableShips();
    if (availableShips.isEmpty) {
      _showSnack('No built ships available. Build ships in the Ships tab.');
      return;
    }
    final id = 'fleet-${DateTime.now().microsecondsSinceEpoch}';
    final taken = {for (final f in _state.fleets) f.label};
    final defaultLabel = pickUnusedName(kFleetNames, taken, fallbackPrefix: 'Fleet');
    _apply(
      _state.copyWith(
        fleets: [
          ..._state.fleets,
          FleetStackState(
            id: id,
            coord: coord,
            owner: 'Player',
            label: defaultLabel,
            shipCounterIds: [availableShips.first.id],
          ),
        ],
        selectedHex: coord,
        selectedFleetId: id,
      ),
      description: 'Fleet',
    );
  }

  void _addEnemyFleet(HexCoord coord) {
    final id = 'enemy-${DateTime.now().microsecondsSinceEpoch}';
    final taken = {for (final f in _state.fleets) f.label};
    final defaultLabel =
        pickUnusedName(kEnemyFleetNames, taken, fallbackPrefix: 'Enemy Fleet');
    _apply(
      _state.copyWith(
        fleets: [
          ..._state.fleets,
          FleetStackState(
            id: id,
            coord: coord,
            owner: 'Enemy',
            label: defaultLabel,
            isEnemy: true,
            composition: const {'Unknown': 1},
            facedown: true,
          ),
        ],
        selectedHex: coord,
        selectedFleetId: id,
      ),
      description: 'Enemy Fleet',
    );
  }

  Future<void> _placeWorld(MapHexState hex) async {
    final currentWorldId = hex.worldId;
    final options = _availableWorlds(
      excludeHexId: hex.coord.id,
      includeWorldId: currentWorldId,
    );
    if (options.isEmpty) {
      _showSnack('No worlds available to place. Create one in Production.');
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Place Ledger World'),
        children: [
          for (final world in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(_worldId(world)),
              child: Text(world.name),
            ),
        ],
      ),
    );
    if (selected == null) return;
    _apply(
      _state.replaceHex(hex.copyWith(worldId: selected)),
      description: 'Map World',
    );
  }

  /// Returns the homeworld WorldState if one exists in production, else null.
  WorldState? get _homeworld {
    for (final w in widget.productionWorlds) {
      if (w.isHomeworld) return w;
    }
    return null;
  }

  /// True iff the player has a homeworld and starting shipyard counters but
  /// no map hex yet hosts the homeworld. This is the new-game onboarding
  /// state — we show a tutorial banner and the next hex tap places the
  /// homeworld + auto-deploys the starting shipyards on it.
  bool get _needsHomeworldPlacement {
    final hw = _homeworld;
    if (hw == null) return false;
    final hwId = hw.id.isNotEmpty ? hw.id : hw.name;
    for (final hex in _state.hexes) {
      if (hex.worldId == hwId) return false;
    }
    // Only prompt if there's actually something to deploy — built SY
    // counters are the unmistakable signal that this is a fresh start.
    return widget.shipCounters
        .any((c) => c.type == ShipType.shipyard && c.isBuilt);
  }

  /// Counts built starting shipyards waiting to be deployed on the homeworld.
  int get _undeployedShipyardCount => widget.shipCounters
      .where((c) => c.type == ShipType.shipyard && c.isBuilt)
      .length;

  /// Places the homeworld on [coord] and auto-deploys the starting shipyards
  /// there. Used by the new-game tutorial flow.
  void _placeHomeworldAt(HexCoord coord) {
    final hw = _homeworld;
    if (hw == null) return;
    final hex = _state.hexAt(coord);
    if (hex == null) return;
    final hwId = hw.id.isNotEmpty ? hw.id : hw.name;
    final syCount = _undeployedShipyardCount;
    _apply(
      _state.replaceHex(hex.copyWith(
        worldId: hwId,
        shipyardCount: hex.shipyardCount + syCount,
        explored: true,
      )).copyWith(selectedHex: coord),
      description: 'Place Homeworld',
    );
    _showSnack(syCount > 0
        ? 'Homeworld placed at ${coord.id}. $syCount Shipyard${syCount == 1 ? '' : 's'} deployed.'
        : 'Homeworld placed at ${coord.id}.');
  }

  void _onHexTapped(HexCoord coord) {
    // Onboarding takeover: while the player has not yet placed their
    // homeworld, every hex tap is a homeworld placement action. This is the
    // tutorial flow that walks new players through SE4X setup.
    if (_needsHomeworldPlacement) {
      _placeHomeworldAt(coord);
      return;
    }
    // Two-step selection:
    // - First tap on a new hex → select only (info shows in the selection card).
    // - Second tap on the already-selected hex → open the detail inspector.
    final previouslySelected = _state.selectedHex;
    if (previouslySelected == coord) {
      _openInspector(forCoord: coord);
      return;
    }
    _selectHex(coord);
  }

  Future<void> _openInspector({HexCoord? forCoord}) async {
    // IMPORTANT: Resolve the target coord from the explicit parameter first.
    // Reading _state.selectedHex synchronously after _selectHex() yields a
    // stale value because MapPage's state is owned by HomePage and flows
    // back via widget.onChanged on the next frame. Passing coord explicitly
    // prevents the "actions go to the previously selected hex" bug.
    final targetCoord = forCoord ?? _state.selectedHex;
    if (targetCoord == null || !mounted) return;
    final selectedHex = _state.hexAt(targetCoord);
    if (selectedHex == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              // Prefer the explicitly requested coord; fall back to
              // _state.selectedHex only if that is newer/still valid.
              final effectiveCoord = _state.selectedHex ?? targetCoord;
              final latestHex = _state.hexAt(effectiveCoord);
              if (latestHex == null) return const SizedBox.shrink();
              final latestWorld = _findWorld(latestHex.worldId);
              final latestFleetId = _state.selectedFleetId;
              final latestFleet =
                  latestFleetId == null ? null : _state.fleetById(latestFleetId);
              final latestFleets = _state.fleetsAt(latestHex.coord);
              final latestShips = _availableShips(fleetId: latestFleet?.id);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            latestFleet == null
                                ? 'Hex ${latestHex.coord.id}'
                                : '${latestFleet.label.isEmpty ? latestFleet.owner : latestFleet.label} · ${latestHex.coord.id}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _HexInspector(
                      key: ValueKey('inspector-${latestHex.coord.id}-${latestFleetId ?? 'none'}'),
                      hex: latestHex,
                      world: latestWorld,
                      fleets: latestFleets,
                      selectedFleetId: latestFleetId,
                      availableShips: latestShips,
                      onHexChanged: (hex) {
                        _apply(_state.replaceHex(hex), description: 'Map Hex');
                        setSheetState(() {});
                      },
                      onPlaceWorld: () async {
                        await _placeWorld(latestHex);
                        if (context.mounted) setSheetState(() {});
                      },
                      onClearWorld: () {
                        _apply(
                          _state.replaceHex(latestHex.copyWith(clearWorldId: true)),
                          description: 'Map World',
                        );
                        setSheetState(() {});
                      },
                      onFleetSelected: (fleetId) {
                        _selectFleet(fleetId);
                        setSheetState(() {});
                      },
                      onFleetDeleted: (id) {
                        _apply(_state.removeFleet(id), description: 'Map Fleet');
                        setSheetState(() {});
                      },
                      onFleetChanged: (fleet) {
                        _apply(_state.replaceFleet(fleet), description: 'Map Fleet');
                        setSheetState(() {});
                      },
                      onFleetShipsChanged: (fleetId, shipIds) {
                        _apply(
                          _state.assignFleetShips(fleetId, shipIds),
                          description: 'Map Fleet',
                        );
                        setSheetState(() {});
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Global overflow menu handler for the floating top-right button on
  /// the map canvas. Replaces the old header-bar overflow popup.
  void _handleOverflowMenu({
    required BuildContext context,
    required String value,
    required bool hasSelection,
    required MapHexState? selected,
  }) {
    switch (value) {
      case 'layout':
        _showLayoutPicker();
        break;
      case 'inventory':
        _showInventorySheet();
        break;
      case 'reset_view':
        _resetViewport();
        break;
      case 'add_enemy':
        if (hasSelection && selected != null) {
          _addEnemyFleet(selected.coord);
        }
        break;
      case 'map_stats':
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Map Stats'),
            content: Text(
              '${_state.hexes.length} hex${_state.hexes.length == 1 ? '' : 'es'}\n'
              '${_state.fleets.length} fleet${_state.fleets.length == 1 ? '' : 's'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showLayoutPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Map layout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: Icon(
                _state.layoutPreset == MapLayoutPreset.standard4p
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('Standard 4P Map'),
              onTap: () {
                Navigator.of(ctx).pop();
                _changePreset(MapLayoutPreset.standard4p);
              },
            ),
            ListTile(
              leading: Icon(
                _state.layoutPreset == MapLayoutPreset.special5p
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('Special 5P Map'),
              onTap: () {
                Navigator.of(ctx).pop();
                _changePreset(MapLayoutPreset.special5p);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Unified inventory sheet: ships and unplaced worlds.
  /// Replaces the old two-pill + dialog split in the header toolbar.
  Future<void> _showInventorySheet() async {
    if (!mounted) return;
    final builtShips =
        widget.shipCounters.where((counter) => counter.isBuilt).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final unplacedWorlds = _availableWorlds();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // ── Ships ──
                _InventorySectionHeader(
                  icon: Icons.directions_boat,
                  label: 'Built Ships',
                  count: builtShips.length,
                ),
                if (builtShips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No built ships in the ledger.'),
                  )
                else
                  ...builtShips.map((ship) {
                    final fleetId = _state.fleetIdForShip(ship.id);
                    final fleet =
                        fleetId == null ? null : _state.fleetById(fleetId);
                    final subtitle = fleet == null
                        ? 'Unassigned'
                        : '${fleet.label.isEmpty ? fleet.owner : fleet.label} @ ${fleet.coord.id}';
                    return ListTile(
                      dense: true,
                      selected: fleetId != null &&
                          fleetId == _state.selectedFleetId,
                      title: Text(ship.id),
                      subtitle: Text(subtitle),
                      trailing: fleet == null
                          ? const Icon(Icons.inventory_2_outlined, size: 18)
                          : const Icon(Icons.my_location, size: 18),
                      onTap: fleet == null
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop();
                              _jumpToShip(ship.id);
                            },
                    );
                  }),
                const SizedBox(height: 12),
                // ── Worlds ──
                _InventorySectionHeader(
                  icon: Icons.public,
                  label: 'Worlds available',
                  count: unplacedWorlds.length,
                ),
                if (unplacedWorlds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('All worlds are placed on the map.'),
                  )
                else
                  ...unplacedWorlds.map((w) => ListTile(
                        dense: true,
                        leading: Icon(
                          w.isHomeworld ? Icons.flag : Icons.public,
                          size: 18,
                        ),
                        title: Text(w.name.isEmpty ? '(unnamed)' : w.name),
                        subtitle: Text(
                          w.isHomeworld
                              ? 'Homeworld'
                              : 'Colony L${w.growthMarkerLevel}',
                        ),
                      )),
              ],
            );
          },
        );
      },
    );
  }

  void _jumpToShip(String shipId) {
    final fleetId = _state.fleetIdForShip(shipId);
    if (fleetId == null) return;
    final fleet = _state.fleetById(fleetId);
    if (fleet == null) return;
    _selectFleet(fleetId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapCanvasKey.currentState?.focusHex(
        fleet.coord,
        targetZoom: 1.6,
      );
    });
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusShipId != null &&
        widget.focusRequestId != oldWidget.focusRequestId) {
      _scheduleFocusIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedHex =
        _state.selectedHex != null ? _state.hexAt(_state.selectedHex!) : null;
    final builtShipCount =
        widget.shipCounters.where((counter) => counter.isBuilt).length;

    // Find fleets that contain a built Colony Ship on a colonizable hex.
    // These get a green pulse marker on the canvas and drive the
    // "Ready to colonize" chip in the toolbar.
    final builtColonyShipIds = <String>{
      for (final c in widget.shipCounters)
        if (c.isBuilt && c.type == ShipType.colonyShip) c.id,
    };
    final colonizeCandidates = builtColonyShipIds.isEmpty
        ? const <ColonizeCandidate>[]
        : _state.findColonizeCandidates(
            candidateShipIds: builtColonyShipIds,
            terraformingLevel: widget.terraformingLevel,
          );
    final colonizeReadyFleetIds = <String>{
      for (final c in colonizeCandidates) c.fleetId,
    };

    final theme = Theme.of(context);
    // Capture the current selection in a local so nested closures have a
    // stable non-null reference (Dart flow analysis can't promote
    // `selectedHex` across closure boundaries).
    final selected = selectedHex;
    final needsHomeworldPlacement = _needsHomeworldPlacement;
    final undeployedSy = _undeployedShipyardCount;
    return Column(
      children: [
        if (needsHomeworldPlacement)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: KeyedSubtree(
              key: TutorialTargets.homeworldBanner,
              child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome — place your Homeworld',
                          style:
                              theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          undeployedSy > 0
                              ? 'Tap any hex on the map to plant your '
                                  'Homeworld there. Your $undeployedSy '
                                  'starting Shipyard'
                                  '${undeployedSy == 1 ? '' : 's'} will '
                                  'auto-deploy on it.'
                              : 'Tap any hex on the map to plant your '
                                  'Homeworld there.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        // ── Selection card (only when a hex is selected) ──
        // When no hex is selected, NO chrome is rendered above the map
        // canvas — this is intentional. Global actions live in the
        // floating overflow button on the map canvas itself.
        if (!needsHomeworldPlacement && selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
            child: _SelectionCard(
              hex: selected,
              world: _findWorld(selected.worldId),
              fleetCount: _state.fleetsAt(selected.coord).length,
              colonizeReadyHere:
                  colonizeCandidates.any((c) => c.coord == selected.coord),
              onPlaceWorld: () => _placeWorld(selected),
              onAddFleet: () => _addFriendlyFleet(selected.coord),
              onOpenInspector: () => _openInspector(forCoord: selected.coord),
              onAddEnemy: () => _addEnemyFleet(selected.coord),
              onResolveCombat: widget.onResolveCombat == null
                  ? null
                  : () => _openCombatResolutionDialog(selected.coord),
              onDismissSelection: () {
                _apply(
                  _state.copyWith(
                    clearSelectedHex: true,
                    clearSelectedFleetId: true,
                  ),
                  recordUndo: false,
                );
              },
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A1226),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    KeyedSubtree(
                      key: TutorialTargets.mapCanvas,
                      child: _MapCanvas(
                      key: _mapCanvasKey,
                      state: _state,
                      productionWorlds: widget.productionWorlds,
                      shipCounters: widget.shipCounters,
                      playerMoveLevel: widget.playerMoveLevel,
                      colonizeReadyFleetIds: colonizeReadyFleetIds,
                      shipyardCapacity: widget.shipyardCapacity,
                      onHexTap: _onHexTapped,
                      onFleetTap: _selectFleet,
                      onFleetDrop: (fleetId, target) {
                        final fleet = _state.fleetById(fleetId);
                        if (fleet == null) return;
                        final allowance = _state.fleetMoveAllowance(
                          fleet,
                          widget.shipCounters,
                          widget.playerMoveLevel,
                        );
                        final next = _state.moveFleetWithAllowance(
                          fleetId,
                          target,
                          allowance: allowance,
                          shipCounters: widget.shipCounters,
                          explorationLevel: widget.explorationLevel,
                        );
                        if (identical(next, _state)) {
                          // Move rejected (already moved this turn, out of
                          // range, or same hex) — surface a small hint so
                          // the drop silently failing doesn't feel broken.
                          if (fleet.hasMovedThisTurn) {
                            _showSnack('Fleet already moved this turn.');
                          } else if (fleet.coord != target) {
                            _showSnack('Out of range (allowance $allowance).');
                          }
                          return;
                        }
                        _apply(next, description: 'Move Fleet');
                      },
                      onViewportChanged: (zoom, panX, panY, rotation) {
                        _apply(
                          _state.copyWith(
                            zoom: zoom,
                            panX: panX,
                            panY: panY,
                            rotation: rotation,
                          ),
                          recordUndo: false,
                        );
                      },
                    ),
                    ),
                    // Top-right: reset view + global overflow.
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!needsHomeworldPlacement)
                            _OverflowMenuButton(
                              onSelected: (value) => _handleOverflowMenu(
                                context: context,
                                value: value,
                                hasSelection: selected != null,
                                selected: selected,
                              ),
                              hasSelection: selected != null,
                            ),
                          const SizedBox(width: 4),
                          Semantics(
                            button: true,
                            label: 'Reset map view',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _resetViewport,
                              child: Container(
                                width: 48,
                                height: 48,
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: ExcludeSemantics(
                                  child: FloatingActionButton.small(
                                    heroTag: 'map-reset-viewport',
                                    tooltip: 'Reset view',
                                    onPressed: _resetViewport,
                                    child:
                                        const Icon(Icons.center_focus_strong),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom-right: stacked FAB column.
                    if (!needsHomeworldPlacement)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (colonizeCandidates.isNotEmpty) ...[
                              _ColonizeReadyFab(
                                count: colonizeCandidates.length,
                                onTap: widget.onColonizeCandidatesTapped,
                              ),
                              const SizedBox(height: 10),
                            ],
                            _InventoryFab(
                              shipCount: builtShipCount,
                              onTap: _showInventorySheet,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCanvas extends StatefulWidget {
  final GameMapState state;
  final List<WorldState> productionWorlds;
  final List<ShipCounter> shipCounters;
  final int playerMoveLevel;
  final Set<String> colonizeReadyFleetIds;
  final Map<String, ({int used, int total})> shipyardCapacity;
  final ValueChanged<HexCoord> onHexTap;
  final ValueChanged<String> onFleetTap;
  final void Function(String fleetId, HexCoord target) onFleetDrop;
  final void Function(double zoom, double panX, double panY, double rotation)
      onViewportChanged;

  const _MapCanvas({
    super.key,
    required this.state,
    required this.productionWorlds,
    this.shipCounters = const [],
    this.playerMoveLevel = 0,
    this.colonizeReadyFleetIds = const {},
    this.shipyardCapacity = const {},
    required this.onHexTap,
    required this.onFleetTap,
    required this.onFleetDrop,
    required this.onViewportChanged,
  });

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  late final TransformationController _controller;
  bool _syncing = false;
  double _appliedZoom = 1.0;
  double _appliedPanX = 0.0;
  double _appliedPanY = 0.0;
  double _appliedRotation = 0.0;
  double _gestureStartRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _syncFromState();
  }

  @override
  void didUpdateWidget(covariant _MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.layoutPreset != widget.state.layoutPreset ||
        !_viewportMatches(
          widget.state.zoom,
          widget.state.panX,
          widget.state.panY,
          widget.state.rotation,
        )) {
      _syncFromState();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _worldId(WorldState world) => world.id.isNotEmpty ? world.id : world.name;

  WorldState? _findWorld(String? worldId) {
    if (worldId == null || worldId.isEmpty) return null;
    for (final world in widget.productionWorlds) {
      if (_worldId(world) == worldId || world.name == worldId) return world;
    }
    return null;
  }

  void _syncFromState() {
    _syncing = true;
    _controller.value = _matrixForViewport(
      widget.state.zoom,
      widget.state.panX,
      widget.state.panY,
    );
    _appliedZoom = widget.state.zoom;
    _appliedPanX = widget.state.panX;
    _appliedPanY = widget.state.panY;
    _appliedRotation = widget.state.rotation;
    _syncing = false;
  }

  bool _viewportMatches(double zoom, double panX, double panY, double rotation) {
    return (zoom - _appliedZoom).abs() < 0.0001 &&
        (panX - _appliedPanX).abs() < 0.5 &&
        (panY - _appliedPanY).abs() < 0.5 &&
        (rotation - _appliedRotation).abs() < 0.0001;
  }

  Matrix4 _matrixForViewport(double zoom, double panX, double panY) {
    final matrix = Matrix4.identity()..scaleByDouble(zoom, zoom, 1, 1);
    matrix.setTranslationRaw(panX, panY, 0);
    return matrix;
  }

  void _emitViewport() {
    if (_syncing) return;
    final matrix = _controller.value;
    _appliedZoom = matrix.getMaxScaleOnAxis();
    _appliedPanX = matrix.getTranslation().x;
    _appliedPanY = matrix.getTranslation().y;
    widget.onViewportChanged(
      _appliedZoom,
      _appliedPanX,
      _appliedPanY,
      _appliedRotation,
    );
  }

  _MapViewport get currentViewport => _MapViewport(
        zoom: _appliedZoom,
        panX: _appliedPanX,
        panY: _appliedPanY,
        rotation: _appliedRotation,
      );

  void resetViewport({bool persistState = true}) {
    _syncing = true;
    _controller.value = Matrix4.identity();
    _appliedZoom = 1.0;
    _appliedPanX = 0.0;
    _appliedPanY = 0.0;
    _appliedRotation = 0.0;
    _syncing = false;
    if (mounted) setState(() {});
    if (persistState) {
      widget.onViewportChanged(1.0, 0.0, 0.0, 0.0);
    }
  }

  void focusHex(
    HexCoord coord, {
    double targetZoom = 1.4,
    bool persistState = true,
  }) {
    final metrics = _layoutMetrics();
    final target = metrics.positions[coord.id];
    final viewportSize = context.size;
    if (target == null || viewportSize == null) return;
    final boardCenter = Offset(metrics.width / 2, metrics.height / 2);
    final rotatedCenter = _rotatePoint(
      Offset(
        target.dx - metrics.minX + metrics.padding + metrics.hexWidth / 2,
        target.dy - metrics.minY + metrics.padding + metrics.hexHeight / 2,
      ),
      boardCenter,
      _appliedRotation,
    );
    final hexCenter = Offset(
      rotatedCenter.dx,
      rotatedCenter.dy,
    );
    final panX = viewportSize.width / 2 - hexCenter.dx * targetZoom;
    final panY = viewportSize.height / 2 - hexCenter.dy * targetZoom;

    _syncing = true;
    _controller.value = _matrixForViewport(targetZoom, panX, panY);
    _appliedZoom = targetZoom;
    _appliedPanX = panX;
    _appliedPanY = panY;
    _syncing = false;
    if (persistState) {
      widget.onViewportChanged(targetZoom, panX, panY, _appliedRotation);
    }
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) {
    if (angle == 0) return point;
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  MapLayoutMetrics _layoutMetrics() {
    return computeLayoutMetrics(widget.state.hexes);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _layoutMetrics();
    final positions = metrics.positions;
    final minX = metrics.minX;
    final minY = metrics.minY;
    final padding = metrics.padding;
    final width = metrics.width;
    final height = metrics.height;
    final fanOffsets = _fleetFanOutOffsets(widget.state.fleets);

    // Compute the reachable set for the currently-selected friendly fleet
    // (if any). We derive this in build() rather than storing it so the
    // highlight always reflects the latest map state and selection.
    Set<HexCoord> reachableHexes = const {};
    final selectedFleetId = widget.state.selectedFleetId;
    if (selectedFleetId != null) {
      final selectedFleet = widget.state.fleetById(selectedFleetId);
      if (selectedFleet != null &&
          !selectedFleet.isEnemy &&
          !selectedFleet.hasMovedThisTurn) {
        final allowance = widget.state.fleetMoveAllowance(
          selectedFleet,
          widget.shipCounters,
          widget.playerMoveLevel,
        );
        reachableHexes =
            widget.state.reachableHexes(selectedFleet, allowance);
      }
    }

    // Give the user scroll leeway past the map edges so the outer hexes
    // aren't pinned hard against the viewport. The 5P map in particular
    // is much larger than the 4P map and needs a generous margin so you
    // can pan a peripheral hex towards the center for inspection.
    final boundaryLeeway = widget.state.layoutPreset == MapLayoutPreset.special5p
        ? 320.0
        : 200.0;
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.2,
      maxScale: 6.0,
      constrained: false,
      boundaryMargin: EdgeInsets.all(boundaryLeeway),
      onInteractionStart: (_) {
        _gestureStartRotation = _appliedRotation;
      },
      onInteractionUpdate: (details) {
        if (details.pointerCount < 2) return;
        setState(() {
          _appliedRotation = _gestureStartRotation + details.rotation;
        });
      },
      onInteractionEnd: (_) => _emitViewport(),
      child: SizedBox(
        width: width,
        height: height,
        child: Transform.rotate(
          angle: _appliedRotation,
          child: Stack(
            children: [
              for (final hex in widget.state.hexes)
                Builder(
                  builder: (context) {
                    final pos = positions[hex.coord.id]!;
                    final world = _findWorld(hex.worldId);
                    final selected = widget.state.selectedHex == hex.coord;
                    final isReachable = reachableHexes.contains(hex.coord);
                    return Positioned(
                      left: pos.dx - minX + padding,
                      top: pos.dy - minY + padding,
                      child: DragTarget<String>(
                        onWillAcceptWithDetails: (details) {
                          // Validate the dragged fleet can reach this hex.
                          // We derive the allowance directly from the fleet
                          // being dragged (not the selected one) so a user
                          // can drag any fleet without having to tap-select
                          // it first. The selected-fleet reachable ring is
                          // purely a visual hint — this is the authoritative
                          // pre-drop check.
                          final fleetId = details.data;
                          final dragged = widget.state.fleetById(fleetId);
                          if (dragged == null) return false;
                          if (dragged.hasMovedThisTurn) return false;
                          if (dragged.coord == hex.coord) return false;
                          final allowance = widget.state.fleetMoveAllowance(
                            dragged,
                            widget.shipCounters,
                            widget.playerMoveLevel,
                          );
                          return dragged.coord.distanceTo(hex.coord) <=
                              allowance;
                        },
                        onAcceptWithDetails: (details) =>
                            widget.onFleetDrop(details.data, hex.coord),
                        builder: (context, candidateData, rejectedData) => GestureDetector(
                          key: ValueKey('hex-${hex.coord.id}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onHexTap(hex.coord),
                          child: CustomPaint(
                            painter: _HexPainter(
                              fillColor: _terrainColor(hex, hasWorld: world != null),
                              borderColor: selected ? Colors.amber : Colors.white54,
                              selected: selected,
                              reachable: isReachable,
                            ),
                            child: SizedBox(
                              width: metrics.hexWidth,
                              height: metrics.hexHeight,
                              child: Stack(
                                children: [
                                  Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              hex.label.isEmpty ? hex.coord.id : hex.label,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: hex.label.isEmpty ? 9 : 10,
                                                fontWeight:
                                                    selected ? FontWeight.w700 : FontWeight.w500,
                                              ),
                                            ),
                                            if (world != null)
                                              Text(
                                                _worldSummary(world),
                                                style: const TextStyle(
                                                  color: Colors.lightGreenAccent,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            if (_tokenSummary(hex).isNotEmpty)
                                              Text(
                                                _tokenSummary(hex),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Shipyard capacity bar overlay
                                  if (widget.shipyardCapacity[hex.coord.id]
                                          case final cap?
                                      when cap.total > 0)
                                    Positioned(
                                      left: metrics.hexWidth * 0.15,
                                      right: metrics.hexWidth * 0.15,
                                      bottom: metrics.hexHeight * 0.17,
                                      child: IgnorePointer(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(2.0),
                                          child: SizedBox(
                                            height: 4,
                                            child: LinearProgressIndicator(
                                              value: (cap.used / cap.total).clamp(0.0, 1.0),
                                              backgroundColor: Colors.white12,
                                              valueColor: AlwaysStoppedAnimation(
                                                (cap.used / cap.total) < 0.5
                                                    ? const Color(0xFF4CAF50)
                                                    : (cap.used / cap.total) < 0.85
                                                        ? const Color(0xFFFFC107)
                                                        : const Color(0xFFEF5350),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              for (final fleet in widget.state.fleets)
                if (positions.containsKey(fleet.coord.id))
                Builder(
                  builder: (context) {
                    final pos = positions[fleet.coord.id]!;
                    final fanOffset = fanOffsets[fleet.id] ?? Offset.zero;
                    final selected = widget.state.selectedFleetId == fleet.id;
                    final colonizeReady =
                        widget.colonizeReadyFleetIds.contains(fleet.id);
                    final marker = _FleetMarker(
                      fleet: fleet,
                      selected: selected,
                      colonizeReady: colonizeReady,
                      onTap: () => widget.onFleetTap(fleet.id),
                    );
                    return Positioned(
                      left: pos.dx - minX + padding + 16 + fanOffset.dx,
                      top: pos.dy - minY + padding + 16 + fanOffset.dy,
                      child: Draggable<String>(
                        data: fleet.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _FleetMarker(
                            fleet: fleet,
                            selected: true,
                            colonizeReady: colonizeReady,
                            onTap: () {},
                          ),
                        ),
                        childWhenDragging: Opacity(opacity: 0.3, child: marker),
                        child: Container(
                          key: ValueKey('fleet-${fleet.id}'),
                          child: marker,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapViewport {
  final double zoom;
  final double panX;
  final double panY;
  final double rotation;

  const _MapViewport({
    required this.zoom,
    required this.panX,
    required this.panY,
    required this.rotation,
  });
}

class MapLayoutMetrics {
  final Map<String, Offset> positions;
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final double padding;
  final double width;
  final double height;
  final double hexWidth;
  final double hexHeight;

  const MapLayoutMetrics({
    required this.positions,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.padding,
    required this.width,
    required this.height,
    required this.hexWidth,
    required this.hexHeight,
  });
}

@visibleForTesting
MapLayoutMetrics computeLayoutMetrics(
  List<MapHexState> hexes, {
  double hexRadius = 34.0,
  double padding = 88.0,
}) {
  final positions = <String, Offset>{};
  double minX = double.infinity;
  double maxX = double.negativeInfinity;
  double minY = double.infinity;
  double maxY = double.negativeInfinity;

  final xSpacing = hexRadius * math.sqrt(3);
  final ySpacing = hexRadius * 1.5;

  if (hexes.isEmpty) {
    return MapLayoutMetrics(
      positions: positions,
      minX: 0,
      minY: 0,
      maxX: 0,
      maxY: 0,
      padding: padding,
      width: padding * 2 + xSpacing,
      height: padding * 2 + hexRadius * 2,
      hexWidth: xSpacing,
      hexHeight: hexRadius * 2,
    );
  }

  final minR = hexes.map((h) => h.coord.r).reduce(math.min);

  for (final hex in hexes) {
    final rowIndex = hex.coord.r - minR;
    final shift = rowIndex.isOdd ? 0.5 : 0.0;
    final x = xSpacing * (hex.coord.q + shift);
    final y = ySpacing * rowIndex;
    positions[hex.coord.id] = Offset(x, y);
    minX = math.min(minX, x);
    maxX = math.max(maxX, x);
    minY = math.min(minY, y);
    maxY = math.max(maxY, y);
  }

  final width = (maxX - minX) + padding * 2 + xSpacing;
  final height = (maxY - minY) + padding * 2 + hexRadius * 2;
  return MapLayoutMetrics(
    positions: positions,
    minX: minX,
    minY: minY,
    maxX: maxX,
    maxY: maxY,
    padding: padding,
    width: width,
    height: height,
    hexWidth: xSpacing,
    hexHeight: hexRadius * 2,
  );
}

/// Computes per-fleet pixel offsets so fleets sharing a hex fan out around
/// the hex centre instead of overlapping on a single +16,+16 stack.
///
/// Arrangement:
///   • 1 fleet  → no offset.
///   • 2 fleets → horizontal pair (±12, 0).
///   • 3 fleets → equilateral triangle (radius ≈ 14).
///   • 4+       → evenly spaced ring (radius ≈ 16).
///
/// Deterministic in fleet-list order: the i-th fleet at a hex always lands
/// at the same slot, keeping drag-and-drop stable between rebuilds.
@visibleForTesting
Map<String, Offset> fleetFanOutOffsets(List<FleetStackState> fleets) =>
    _fleetFanOutOffsets(fleets);

Map<String, Offset> _fleetFanOutOffsets(List<FleetStackState> fleets) {
  // Group fleet IDs by hex id, preserving input order.
  final byHex = <String, List<String>>{};
  for (final f in fleets) {
    byHex.putIfAbsent(f.coord.id, () => []).add(f.id);
  }
  final out = <String, Offset>{};
  for (final ids in byHex.values) {
    final n = ids.length;
    if (n == 1) {
      out[ids[0]] = Offset.zero;
      continue;
    }
    if (n == 2) {
      out[ids[0]] = const Offset(-12, 0);
      out[ids[1]] = const Offset(12, 0);
      continue;
    }
    if (n == 3) {
      const radius = 14.0;
      // Triangle: top, bottom-left, bottom-right.
      for (var i = 0; i < 3; i++) {
        final angle = -math.pi / 2 + i * (2 * math.pi / 3);
        out[ids[i]] = Offset(
          radius * math.cos(angle),
          radius * math.sin(angle),
        );
      }
      continue;
    }
    // 4+ fleets: even ring around the centre.
    const radius = 16.0;
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / n);
      out[ids[i]] = Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
    }
  }
  return out;
}

class _HexInspector extends StatelessWidget {
  final MapHexState hex;
  final WorldState? world;
  final List<FleetStackState> fleets;
  final String? selectedFleetId;
  final List<ShipCounter> availableShips;
  final ValueChanged<MapHexState> onHexChanged;
  final VoidCallback onPlaceWorld;
  final VoidCallback onClearWorld;
  final ValueChanged<String> onFleetSelected;
  final ValueChanged<String> onFleetDeleted;
  final ValueChanged<FleetStackState> onFleetChanged;
  final void Function(String fleetId, List<String> shipIds) onFleetShipsChanged;

  const _HexInspector({
    super.key,
    required this.hex,
    required this.world,
    required this.fleets,
    required this.selectedFleetId,
    required this.availableShips,
    required this.onHexChanged,
    required this.onPlaceWorld,
    required this.onClearWorld,
    required this.onFleetSelected,
    required this.onFleetDeleted,
    required this.onFleetChanged,
    required this.onFleetShipsChanged,
  });

  @override
  Widget build(BuildContext context) {
    FleetStackState? selectedFleet;
    if (selectedFleetId != null) {
      for (final fleet in fleets) {
        if (fleet.id == selectedFleetId) {
          selectedFleet = fleet;
          break;
        }
      }
    }
    final hasWorldPlacement = hex.worldId != null && hex.worldId!.isNotEmpty;

    final theme = Theme.of(context);
    final subtleStyle = TextStyle(
      fontSize: 11,
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final helpStyle = TextStyle(
      fontSize: 11,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      height: 1.3,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hex ${hex.coord.id}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        // ── GROUP: TERRAIN & EXPLORATION ────────────────────────────────────
        _InspectorGroup(
          title: 'Terrain & Exploration',
          children: [
            _SyncedTextField(
              text: hex.label,
              decoration: const InputDecoration(labelText: 'Label'),
              onChanged: (value) =>
                  onHexChanged(hex.copyWith(label: value)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HexTerrain>(
              initialValue: hex.terrain,
              decoration: const InputDecoration(labelText: 'Terrain'),
              items: [
                for (final terrain in HexTerrain.values)
                  DropdownMenuItem(
                    value: terrain,
                    child: Text(_terrainLabel(terrain)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onHexChanged(hex.copyWith(terrain: value));
              },
            ),
            SwitchListTile(
              value: hex.explored,
              title: const Text('Explored'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) =>
                  onHexChanged(hex.copyWith(explored: value)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── GROUP: WORLD ────────────────────────────────────────────────────
        _InspectorGroup(
          title: 'World',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(world?.name ?? hex.worldId ?? 'No world placed'),
              subtitle: Text(
                hasWorldPlacement
                    ? 'Ledger-backed world placement'
                    : 'No world placed at this hex',
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: onPlaceWorld,
                    child: const Text('Place'),
                  ),
                  if (hasWorldPlacement)
                    TextButton(
                      onPressed: onClearWorld,
                      child: const Text('Unplace'),
                    ),
                ],
              ),
            ),
            // PP15: Garrison Ground Units display. Read-only here — actual
            // edits are wired into the Production page colony rows so the
            // map inspector stays free of world-edit plumbing.
            if (world != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Tooltip(
                  message:
                      'Adjust the Garrison count from the Production tab '
                      'colony row, or via Manual Override.',
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Garrison: ${world!.garrisonGu} GU',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── GROUP: ECONOMY ──────────────────────────────────────────────────
        _InspectorGroup(
          title: 'Economy',
          children: [
            _StepperRow(
              label: 'Shipyards',
              value: hex.shipyardCount,
              onChanged: (value) =>
                  onHexChanged(hex.copyWith(shipyardCount: value)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
              child: Text(
                'Each Shipyard provides HP of ship-build capacity per '
                'Economic Phase (scales with Shipyard tech). Ships can only '
                'be built at hexes with at least one Shipyard. Normally this '
                'counter increments automatically when a queued SY purchase '
                'is materialized at End Turn.',
                style: helpStyle,
              ),
            ),
            _StepperRow(
              label: 'Wrecks',
              value: hex.wrecks,
              onChanged: (value) =>
                  onHexChanged(hex.copyWith(wrecks: value)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
              child: Text(
                'Wrecks feed the Replicator — salvage them for earlier RP '
                'gains.',
                style: helpStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── GROUP: FLEETS ───────────────────────────────────────────────────
        // Note: "Add Friendly Fleet" / "Add Enemy Fleet" buttons are on the
        // map selection card, which remains visible when the inspector is
        // open. No need to duplicate them here.
        _InspectorGroup(
          title: 'Fleets',
          children: [
            if (fleets.isEmpty)
              const Text('No fleets on this hex.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final fleet in fleets)
                    ChoiceChip(
                      label: Text(
                        fleet.label.isEmpty ? fleet.id : fleet.label,
                      ),
                      selected: fleet.id == selectedFleetId,
                      onSelected: (_) => onFleetSelected(fleet.id),
                    ),
                ],
              ),
            if (selectedFleet != null) ...[
              const SizedBox(height: 12),
              _SyncedTextField(
                text: selectedFleet.owner,
                decoration: const InputDecoration(labelText: 'Owner'),
                onChanged: (value) =>
                    onFleetChanged(selectedFleet!.copyWith(owner: value)),
              ),
              const SizedBox(height: 12),
              _SyncedTextField(
                text: selectedFleet.label,
                decoration: const InputDecoration(labelText: 'Fleet Name'),
                onChanged: (value) =>
                    onFleetChanged(selectedFleet!.copyWith(label: value)),
              ),
              SwitchListTile(
                value: selectedFleet.facedown,
                title: const Text('Facedown'),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => onFleetChanged(
                  selectedFleet!.copyWith(facedown: value),
                ),
              ),
              SwitchListTile(
                value: selectedFleet.inSupply,
                title: const Text('In Supply'),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => onFleetChanged(
                  selectedFleet!.copyWith(inSupply: value),
                ),
              ),
              if (selectedFleet.isEnemy)
                _SyncedTextField(
                  text: _formatComposition(selectedFleet.composition),
                  decoration:
                      const InputDecoration(labelText: 'Composition'),
                  onChanged: (value) => onFleetChanged(
                    selectedFleet!
                        .copyWith(composition: _parseComposition(value)),
                  ),
                )
              else ...[
                const SizedBox(height: 8),
                Text(
                  'Assign Built Ships',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (availableShips.isEmpty)
                  const Text('No built ships are currently available.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final counter in availableShips)
                        FilterChip(
                          label: Text(counter.id),
                          selected: selectedFleet.shipCounterIds
                              .contains(counter.id),
                          onSelected: (checked) {
                            final ids = [
                              ...selectedFleet!.shipCounterIds,
                            ];
                            if (checked) {
                              if (!ids.contains(counter.id)) {
                                ids.add(counter.id);
                              }
                            } else {
                              ids.remove(counter.id);
                            }
                            onFleetShipsChanged(selectedFleet.id, ids);
                          },
                        ),
                    ],
                  ),
              ],
              const SizedBox(height: 8),
              _SyncedTextField(
                text: selectedFleet.notes,
                decoration:
                    const InputDecoration(labelText: 'Fleet Notes'),
                maxLines: 2,
                onChanged: (value) =>
                    onFleetChanged(selectedFleet!.copyWith(notes: value)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onFleetDeleted(selectedFleet!.id),
                  child: const Text('Delete Fleet'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // ── GROUP: COSMETIC MARKERS (collapsed by default) ─────────────────
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            childrenPadding:
                const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              'Cosmetic Markers',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Does not affect economy',
              style: subtleStyle,
            ),
            children: [
              Tooltip(
                message:
                    'Mineral CP income comes from colony staging on the '
                    'Production tab.',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CompactCosmeticStepper(
                          label: 'Minerals',
                          value: hex.minerals,
                          onChanged: (value) => onHexChanged(
                            hex.copyWith(minerals: value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactCosmeticStepper(
                          label: 'Mines',
                          value: hex.mines,
                          onChanged: (value) => onHexChanged(
                            hex.copyWith(mines: value),
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
        const SizedBox(height: 12),

        // ── GROUP: NOTES ───────────────────────────────────────────────────
        _InspectorGroup(
          title: 'Notes',
          children: [
            _SyncedTextField(
              text: hex.notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              onChanged: (value) =>
                  onHexChanged(hex.copyWith(notes: value)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Always-expanded inspector section: rounded card at
/// `surfaceContainerHighest` with a compact primary-colored title header and
/// 12px padding. Used by `_HexInspector` to group related fields visually
/// without the overhead of an `ExpansionTile`.
class _InspectorGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InspectorGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// TextField wrapper that preserves the editing controller across parent
/// rebuilds, so typing does not reset the cursor to position 0 (which would
/// make each new character insert at the beginning and appear right-to-left).
class _SyncedTextField extends StatefulWidget {
  final String text;
  final InputDecoration decoration;
  final int? maxLines;
  final ValueChanged<String> onChanged;

  const _SyncedTextField({
    required this.text,
    required this.decoration,
    this.maxLines,
    required this.onChanged,
  });

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external text in only when the user isn't actively editing this
    // field, so their cursor/selection is not clobbered mid-typing.
    if (!_focusNode.hasFocus && widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}

Map<String, int> _parseComposition(String value) {
  final composition = <String, int>{};
  for (final part in value.split(',')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final pieces = trimmed.split(':');
    final key = pieces.first.trim();
    final count = pieces.length > 1 ? int.tryParse(pieces[1].trim()) ?? 1 : 1;
    composition[key] = count;
  }
  return composition;
}

String _formatComposition(Map<String, int> composition) {
  return composition.entries.map((entry) => '${entry.key}:${entry.value}').join(', ');
}

class _FleetMarker extends StatelessWidget {
  final FleetStackState fleet;
  final bool selected;
  final bool colonizeReady;
  final VoidCallback onTap;

  const _FleetMarker({
    required this.fleet,
    required this.selected,
    this.colonizeReady = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = fleet.isEnemy ? Colors.redAccent : Colors.cyanAccent;
    final outOfSupply = !fleet.inSupply;
    // Fleets that have already moved this turn render at reduced opacity
    // and pick up a small green check badge so the player can tell at a
    // glance which stacks still have a move left.
    final movedThisTurn = fleet.hasMovedThisTurn;
    final borderColor = selected
        ? Colors.amber
        : (outOfSupply ? Colors.orangeAccent : color);
    final baseTextColor = outOfSupply ? color.withValues(alpha: 0.55) : color;
    final textColor = movedThisTurn
        ? baseTextColor.withValues(alpha: 0.55)
        : baseTextColor;
    final marker = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: movedThisTurn ? 0.6 : 0.82,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
          width: selected ? 2 : (outOfSupply ? 1.6 : 1.2),
          style: outOfSupply ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Text(
        fleet.label.isEmpty ? fleet.owner : fleet.label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          decoration:
              outOfSupply ? TextDecoration.lineThrough : TextDecoration.none,
          decorationColor: Colors.orangeAccent,
          decorationThickness: 2,
        ),
      ),
    );
    final body = outOfSupply
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(opacity: 0.75, child: marker),
              Positioned(
                top: -3,
                right: -3,
                child: Tooltip(
                  message: 'Out of supply',
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          )
        : marker;
    // The painted marker is roughly 22dp tall — below the 48dp accessibility
    // minimum. Wrap it in a transparent, tap-forwarding container so the
    // effective tap and long-press area is 48dp without changing the visual
    // footprint of the marker itself.
    final labelText = fleet.label.isEmpty ? fleet.owner : fleet.label;
    final allegiance = fleet.isEnemy ? 'Enemy' : 'Friendly';
    final supply = outOfSupply ? ', out of supply' : '';
    final semanticLabel =
        '$allegiance fleet: $labelText at ${fleet.coord.id}$supply';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
      message: 'Drag to move fleet',
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              body,
              Positioned(
                bottom: -2,
                right: -2,
                child: Icon(
                  Icons.drag_indicator,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              if (colonizeReady)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Tooltip(
                    message: 'Colony Ship ready to colonize this hex',
                    child: _ColonizePulseIndicator(),
                  ),
                ),
              if (movedThisTurn)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Tooltip(
                    message: 'Already moved this turn',
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Small pulsing green dot overlaid on fleet markers that contain a Colony
/// Ship sitting on a colonizable hex. Signals "you can colonize here now".
class _ColonizePulseIndicator extends StatefulWidget {
  @override
  State<_ColonizePulseIndicator> createState() =>
      _ColonizePulseIndicatorState();
}

class _ColonizePulseIndicatorState extends State<_ColonizePulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale = 0.9 + 0.4 * t;
        final alpha = 0.55 + 0.45 * (1 - t);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: alpha),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.6 * alpha),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '\u{1F331}',
                style: TextStyle(fontSize: 8),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Inline chip rendered inside the selection card when the selected hex
/// has a Colony Ship ready to colonize. Non-interactive (the FAB version
/// below handles taps).
class _ColonizeReadyChip extends StatelessWidget {
  final int count;
  final bool inline;

  const _ColonizeReadyChip({required this.count, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final label = inline ? 'Ready to colonize' : 'Ready to colonize: $count';
    final visual = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, size: 12, color: Colors.greenAccent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    return Semantics(label: label, child: visual);
  }
}

/// Floating action button exposing the global inventory sheet (ships and
/// worlds). Rendered bottom-right on the map canvas.
class _InventoryFab extends StatelessWidget {
  final int shipCount;
  final VoidCallback onTap;

  const _InventoryFab({required this.shipCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open inventory',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton.small(
            heroTag: 'map-inventory-fab',
            tooltip: 'Inventory',
            onPressed: onTap,
            child: const Icon(Icons.inventory_2_outlined),
          ),
          if (shipCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
                child: Text(
                  '$shipCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating action button that signals how many Colony Ships are ready to
/// colonize. Tapping forwards to the colonize-now dialog.
class _ColonizeReadyFab extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;

  const _ColonizeReadyFab({required this.count, this.onTap});

  @override
  State<_ColonizeReadyFab> createState() => _ColonizeReadyFabState();
}

class _ColonizeReadyFabState extends State<_ColonizeReadyFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final alpha = 0.55 + 0.45 * (1 - _pulse.value);
        final bg = Color.lerp(
          theme.colorScheme.tertiary,
          theme.colorScheme.tertiary.withValues(alpha: 0.4),
          _pulse.value,
        )!;
        return Semantics(
          button: true,
          label: 'Ready to colonize: ${widget.count}',
          child: FloatingActionButton.extended(
            heroTag: 'map-colonize-fab',
            onPressed: widget.onTap,
            backgroundColor: bg.withValues(alpha: alpha),
            foregroundColor: theme.colorScheme.onTertiary,
            icon: const Icon(Icons.eco),
            label: Text('Ready to colonize: ${widget.count}'),
          ),
        );
      },
    );
  }
}

/// Section header for the inventory sheet.
class _InventorySectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _InventorySectionHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Overflow menu (3-dot) button rendered as a small floating button on the
/// map canvas. Replaces the old header-bar popup.
class _OverflowMenuButton extends StatelessWidget {
  final bool hasSelection;
  final ValueChanged<String> onSelected;

  const _OverflowMenuButton({
    required this.hasSelection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: PopupMenuButton<String>(
        tooltip: 'More actions',
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        icon: const Icon(Icons.more_vert),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'layout',
            child: Row(
              children: [
                Icon(Icons.map, size: 18),
                SizedBox(width: 8),
                Text('Map layout\u2026'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'inventory',
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18),
                SizedBox(width: 8),
                Text('Inventory\u2026'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'reset_view',
            child: Row(
              children: [
                Icon(Icons.center_focus_strong, size: 18),
                SizedBox(width: 8),
                Text('Reset view'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'add_enemy',
            enabled: hasSelection,
            child: Row(
              children: [
                const Icon(Icons.visibility_off, size: 18),
                const SizedBox(width: 8),
                Text(hasSelection ? 'Add Enemy' : 'Add Enemy (select a hex first)'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'map_stats',
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text('Map stats'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich info card for the currently selected hex. Replaces the old
/// horizontal-scrolling toolbar strip. Lays out terrain/world info and
/// per-hex tokens as Wrap'd chips, and keeps the contextual action
/// buttons (Place World / Add Fleet / Edit) adjacent to them.
class _SelectionCard extends StatelessWidget {
  final MapHexState hex;
  final WorldState? world;
  final int fleetCount;
  final bool colonizeReadyHere;
  final VoidCallback onPlaceWorld;
  final VoidCallback onAddFleet;
  final VoidCallback onOpenInspector;
  final VoidCallback onAddEnemy;
  final VoidCallback? onResolveCombat;
  final VoidCallback onDismissSelection;

  const _SelectionCard({
    required this.hex,
    required this.world,
    required this.fleetCount,
    required this.colonizeReadyHere,
    required this.onPlaceWorld,
    required this.onAddFleet,
    required this.onOpenInspector,
    required this.onAddEnemy,
    required this.onDismissSelection,
    this.onResolveCombat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terrainLabel = _terrainLabel(hex.terrain);
    final subtitle = world != null
        ? (world!.name.isNotEmpty ? world!.name : terrainLabel)
        : terrainLabel;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.my_location,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Hex ${hex.coord.id}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Place World',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onPlaceWorld,
                icon: const Icon(Icons.public),
              ),
              IconButton(
                tooltip: 'Add Enemy Fleet',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onAddEnemy,
                icon: const Icon(Icons.visibility_off),
              ),
              IconButton(
                tooltip: fleetCount > 0
                    ? 'Resolve Combat'
                    : 'Resolve Combat (no fleets here)',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed:
                    (fleetCount > 0 && onResolveCombat != null) ? onResolveCombat : null,
                icon: const Icon(Icons.military_tech),
              ),
              IconButton(
                tooltip: 'Clear selection',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onDismissSelection,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (colonizeReadyHere)
                const _ColonizeReadyChip(
                  count: 1,
                  inline: true,
                ),
              if (fleetCount > 0)
                _InfoChip(
                  icon: Icons.directions_boat,
                  label: '$fleetCount',
                  tooltip: '$fleetCount fleet(s) in this hex',
                ),
              if (hex.explored)
                const _InfoChip(icon: Icons.visibility, label: 'Explored'),
              if (hex.minerals > 0)
                _InfoChip(icon: Icons.diamond, label: 'M${hex.minerals}'),
              if (hex.wrecks > 0)
                _InfoChip(icon: Icons.broken_image, label: 'W${hex.wrecks}'),
              if (hex.mines > 0)
                _InfoChip(icon: Icons.report, label: 'Mi${hex.mines}'),
              if (hex.shipyardCount > 0)
                _InfoChip(
                  icon: Icons.construction,
                  label: 'SY${hex.shipyardCount}',
                  tooltip:
                      '${hex.shipyardCount} Shipyard${hex.shipyardCount == 1 ? '' : 's'} '
                      '(SY) \u2014 enables ship production at this hex.',
                ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                onPressed: onAddFleet,
                icon: const Icon(Icons.directions_boat, size: 16),
                label: const Text('Add Fleet'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onOpenInspector,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Edit Hex\u2026'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  const _InfoChip({required this.icon, required this.label, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurface),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
    return tooltip == null ? visual : Tooltip(message: tooltip!, child: visual);
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$value'),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Compact, visually-demoted stepper used exclusively for cosmetic markers
/// (minerals, mines) in the collapsed "Cosmetic Markers" section of the hex
/// inspector. Smaller buttons, smaller font, italic gray label, tighter
/// padding — distinct from rules-relevant `_StepperRow` instances.
class _CompactCosmeticStepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _CompactCosmeticStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final labelStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
      color: mutedColor,
      fontStyle: FontStyle.italic,
    );
    final valueStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
      color: mutedColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        Flexible(
          child: Text(
            '$label:',
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: Icon(Icons.remove, color: mutedColor),
          ),
        ),
        SizedBox(
          width: 16,
          child: Text(
            '$value',
            style: valueStyle,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value + 1),
            icon: Icon(Icons.add, color: mutedColor),
          ),
        ),
      ],
    );
  }
}

class _HexPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool selected;
  final bool reachable;

  const _HexPainter({
    required this.fillColor,
    required this.borderColor,
    required this.selected,
    this.reachable = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, Paint()..color = fillColor);

    // Reachability highlight: translucent teal wash + solid teal border.
    // Painted under the terrain border so a selected hex still reads as
    // the primary selection. Teal reads well against the dark deep-space
    // blues and is visually distinct from selection amber + enemy red.
    if (reachable) {
      canvas.drawPath(
        path,
        Paint()..color = const Color(0x3326A69A),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF26A69A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.selected != selected ||
        oldDelegate.reachable != reachable;
  }
}

Color _terrainColor(MapHexState hex, {required bool hasWorld}) {
  if (hasWorld) return const Color(0xFF1E4F2B);
  return switch (hex.terrain) {
    HexTerrain.deepSpace => const Color(0xFF14213D),
    HexTerrain.asteroid => const Color(0xFF4A4E69),
    HexTerrain.nebula => const Color(0xFF3A506B),
    HexTerrain.blackHole => const Color(0xFF111111),
    HexTerrain.supernova => const Color(0xFF7F1D1D),
    HexTerrain.foldInSpace => const Color(0xFF5A189A),
  };
}

String _worldSummary(WorldState world) {
  if (world.isHomeworld) return '${world.name} HW';
  return world.name;
}

String _tokenSummary(MapHexState hex) {
  final parts = <String>[];
  if (hex.minerals > 0) parts.add('M${hex.minerals}');
  if (hex.wrecks > 0) parts.add('W${hex.wrecks}');
  if (hex.mines > 0) parts.add('Mi${hex.mines}');
  if (hex.shipyardCount > 0) parts.add('SY${hex.shipyardCount}');
  return parts.join(' ');
}

String _terrainLabel(HexTerrain terrain) => switch (terrain) {
      HexTerrain.deepSpace => 'Deep Space',
      HexTerrain.asteroid => 'Asteroid',
      HexTerrain.nebula => 'Nebula',
      HexTerrain.blackHole => 'Black Hole',
      HexTerrain.supernova => 'Supernova',
      HexTerrain.foldInSpace => 'Fold in Space',
    };
