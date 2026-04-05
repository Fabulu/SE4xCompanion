import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/map_state.dart';
import '../models/ship_counter.dart';
import '../models/world.dart';

typedef MapStateChanged = void Function(
  GameMapState state, {
  bool recordUndo,
  String? description,
});

class MapPage extends StatefulWidget {
  final GameMapState state;
  final List<WorldState> productionWorlds;
  final List<ShipCounter> shipCounters;
  final List<String> pipelineAssetIds;
  final String? focusShipId;
  final int focusRequestId;
  final MapStateChanged onChanged;

  const MapPage({
    super.key,
    required this.state,
    required this.productionWorlds,
    required this.shipCounters,
    this.pipelineAssetIds = const [],
    this.focusShipId,
    this.focusRequestId = 0,
    required this.onChanged,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<_MapCanvasState> _mapCanvasKey = GlobalKey<_MapCanvasState>();
  bool _pipelinePlacementMode = false;

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

  List<String> _availablePipelineAssets({String? excludeHexId}) {
    final placed = _state.placedPipelineIds(excludeHexId: excludeHexId);
    return widget.pipelineAssetIds
        .where((id) => !placed.contains(id))
        .toList()
      ..sort();
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

  void _addFriendlyFleet(HexCoord coord) {
    final availableShips = _availableShips();
    if (availableShips.isEmpty) return;
    final id = 'fleet-${DateTime.now().microsecondsSinceEpoch}';
    _apply(
      _state.copyWith(
        fleets: [
          ..._state.fleets,
          FleetStackState(
            id: id,
            coord: coord,
            owner: 'Player',
            label: 'Fleet',
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
    _apply(
      _state.copyWith(
        fleets: [
          ..._state.fleets,
          FleetStackState(
            id: id,
            coord: coord,
            owner: 'Enemy',
            label: 'Enemy Fleet',
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
    if (options.isEmpty) return;
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

  void _togglePipelineAt(MapHexState hex) {
    if (hex.pipelineIds.isNotEmpty) {
      _apply(
        _state.replaceHex(hex.copyWith(pipelineIds: const [])),
        description: 'Pipeline',
      );
      return;
    }
    final available = _availablePipelineAssets(excludeHexId: hex.coord.id);
    if (available.isEmpty) return;
    _apply(
      _state.replaceHex(hex.copyWith(pipelineIds: [available.first])),
      description: 'Pipeline',
    );
  }

  void _togglePipelineAtSelected() {
    setState(() => _pipelinePlacementMode = !_pipelinePlacementMode);
  }

  void _onHexTapped(HexCoord coord) {
    _selectHex(coord);
    if (_pipelinePlacementMode) {
      final hex = _state.hexAt(coord);
      if (hex != null) _togglePipelineAt(hex);
      return;
    }
    // Opening the inspector on tap restores the pre-regression behaviour:
    // one tap both selects the hex and surfaces its contents.
    _openInspector();
  }

  Future<void> _openInspector() async {
    final selectedHex = _state.selectedHex != null ? _state.hexAt(_state.selectedHex!) : null;
    if (selectedHex == null || !mounted) return;
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
              final latestHex =
                  _state.selectedHex != null ? _state.hexAt(_state.selectedHex!) : null;
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

  Future<void> _showShipInventory() async {
    final builtShips = widget.shipCounters.where((counter) => counter.isBuilt).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Built Ships'),
        content: SizedBox(
          width: 420,
          child: builtShips.isEmpty
              ? const Text('No built ships are currently in the ledger.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: builtShips.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ship = builtShips[index];
                    final fleetId = _state.fleetIdForShip(ship.id);
                    final fleet = fleetId == null ? null : _state.fleetById(fleetId);
                    final subtitle = fleet == null
                        ? 'Unassigned'
                        : '${fleet.label.isEmpty ? fleet.owner : fleet.label} @ ${fleet.coord.id}';
                    return ListTile(
                      dense: true,
                      selected: fleetId != null && fleetId == _state.selectedFleetId,
                      title: Text(ship.id),
                      subtitle: Text(subtitle),
                      trailing: fleet == null
                          ? const Icon(Icons.inventory_2_outlined, size: 18)
                          : const Icon(Icons.my_location, size: 18),
                      onTap: fleet == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _jumpToShip(ship.id);
                            },
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
    final availableWorlds = _availableWorlds(
      excludeHexId: selectedHex?.coord.id,
      includeWorldId: selectedHex?.worldId,
    );
    final availablePipelines =
        _availablePipelineAssets(excludeHexId: selectedHex?.coord.id);
    final builtShipCount = widget.shipCounters.where((counter) => counter.isBuilt).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<MapLayoutPreset>(
                          isExpanded: true,
                          value: _state.layoutPreset,
                          onChanged: (value) {
                            if (value != null) _changePreset(value);
                          },
                          items: const [
                            DropdownMenuItem(
                              value: MapLayoutPreset.standard4p,
                              child: Text('Standard 4P Map'),
                            ),
                            DropdownMenuItem(
                              value: MapLayoutPreset.special5p,
                              child: Text('Special 5P Map'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_state.hexes.length} hexes | ${_state.fleets.length} fleets'
                          '${selectedHex == null ? '' : ' | ${selectedHex.coord.id}'}',
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _ToolbarActionButton(
                        icon: Icons.public,
                        label: 'Place World',
                        onPressed: selectedHex == null ? null : () => _placeWorld(selectedHex),
                      ),
                      _ToolbarActionButton(
                        icon: Icons.directions_boat,
                        label: 'Add Fleet',
                        onPressed:
                            selectedHex == null ? null : () => _addFriendlyFleet(selectedHex.coord),
                      ),
                      _ToolbarActionButton(
                        icon: Icons.visibility_off,
                        label: 'Add Enemy',
                        onPressed:
                            selectedHex == null ? null : () => _addEnemyFleet(selectedHex.coord),
                      ),
                      _ToolbarActionButton(
                        icon: Icons.alt_route,
                        label: _pipelinePlacementMode ? 'Pipeline On' : 'Pipeline',
                        onPressed: _togglePipelineAtSelected,
                      ),
                      _ToolbarActionButton(
                        icon: Icons.tune,
                        label: 'Edit',
                        onPressed: selectedHex == null ? null : _openInspector,
                      ),
                      _AssetPill(label: 'Worlds', value: availableWorlds.length),
                      _AssetPill(
                        label: 'Ships',
                        value: builtShipCount,
                        onTap: _showShipInventory,
                      ),
                      _AssetPill(label: 'Pipelines', value: availablePipelines.length),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                    _MapCanvas(
                      key: _mapCanvasKey,
                      state: _state,
                      productionWorlds: widget.productionWorlds,
                      onHexTap: _onHexTapped,
                      onFleetTap: _selectFleet,
                      onFleetDrop: (fleetId, target) {
                        _apply(
                          _state.moveFleet(fleetId, target),
                          description: 'Move Fleet',
                        );
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'map-reset-viewport',
                        tooltip: 'Reset view',
                        onPressed: _resetViewport,
                        child: const Icon(Icons.center_focus_strong),
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
  final ValueChanged<HexCoord> onHexTap;
  final ValueChanged<String> onFleetTap;
  final void Function(String fleetId, HexCoord target) onFleetDrop;
  final void Function(double zoom, double panX, double panY, double rotation)
      onViewportChanged;

  const _MapCanvas({
    super.key,
    required this.state,
    required this.productionWorlds,
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

    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.2,
      maxScale: 6.0,
      constrained: false,
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
                    return Positioned(
                      left: pos.dx - minX + padding,
                      top: pos.dy - minY + padding,
                      child: DragTarget<String>(
                        onWillAcceptWithDetails: (_) => true,
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
                            ),
                            child: SizedBox(
                              width: metrics.hexWidth,
                              height: metrics.hexHeight,
                              child: Center(
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
                                              fontSize: 9,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
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
                    final selected = widget.state.selectedFleetId == fleet.id;
                    final marker = _FleetMarker(
                      fleet: fleet,
                      selected: selected,
                      onTap: () => widget.onFleetTap(fleet.id),
                    );
                    return Positioned(
                      left: pos.dx - minX + padding + 16,
                      top: pos.dy - minY + padding + 16,
                      child: Draggable<String>(
                        data: fleet.id,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _FleetMarker(
                            fleet: fleet,
                            selected: true,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hex ${hex.coord.id}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        // ── FLEETS FIRST ─────────────────────────────────────────────────────
        // Fleets on this hex are the primary thing players need to reach —
        // surfaced before hex metadata so it takes zero scrolling.
        Text('Fleets', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (fleets.isEmpty)
          const Text('No fleets on this hex.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fleet in fleets)
                ChoiceChip(
                  label: Text(fleet.label.isEmpty ? fleet.id : fleet.label),
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
            onChanged: (value) =>
                onFleetChanged(selectedFleet!.copyWith(facedown: value)),
          ),
          SwitchListTile(
            value: selectedFleet.inSupply,
            title: const Text('In Supply'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) =>
                onFleetChanged(selectedFleet!.copyWith(inSupply: value)),
          ),
          if (selectedFleet.isEnemy)
            _SyncedTextField(
              text: _formatComposition(selectedFleet.composition),
              decoration: const InputDecoration(labelText: 'Composition'),
              onChanged: (value) => onFleetChanged(
                selectedFleet!.copyWith(composition: _parseComposition(value)),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            Text('Assign Built Ships', style: Theme.of(context).textTheme.bodyMedium),
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
                      selected: selectedFleet.shipCounterIds.contains(counter.id),
                      onSelected: (checked) {
                        final ids = [...selectedFleet!.shipCounterIds];
                        if (checked) {
                          if (!ids.contains(counter.id)) ids.add(counter.id);
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
            decoration: const InputDecoration(labelText: 'Fleet Notes'),
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
        // ── HEX DETAILS ──────────────────────────────────────────────────────
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text('Hex Details', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _SyncedTextField(
          text: hex.label,
          decoration: const InputDecoration(labelText: 'Label'),
          onChanged: (value) => onHexChanged(hex.copyWith(label: value)),
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
          onChanged: (value) => onHexChanged(hex.copyWith(explored: value)),
        ),
        Card(
          child: ListTile(
            title: Text(world?.name ?? hex.worldId ?? 'No world placed'),
            subtitle: Text(
              hasWorldPlacement ? 'Ledger-backed world placement' : 'Static world placement from ledger',
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton(onPressed: onPlaceWorld, child: const Text('Place')),
                if (hasWorldPlacement)
                  TextButton(onPressed: onClearWorld, child: const Text('Unplace')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _StepperRow(
          label: 'Minerals',
          value: hex.minerals,
          onChanged: (value) => onHexChanged(hex.copyWith(minerals: value)),
        ),
        _StepperRow(
          label: 'Wrecks',
          value: hex.wrecks,
          onChanged: (value) => onHexChanged(hex.copyWith(wrecks: value)),
        ),
        _StepperRow(
          label: 'Mines',
          value: hex.mines,
          onChanged: (value) => onHexChanged(hex.copyWith(mines: value)),
        ),
        _StepperRow(
          label: 'Industry',
          value: hex.industryMarkers,
          onChanged: (value) =>
              onHexChanged(hex.copyWith(industryMarkers: value)),
        ),
        _StepperRow(
          label: 'Research',
          value: hex.researchMarkers,
          onChanged: (value) =>
              onHexChanged(hex.copyWith(researchMarkers: value)),
        ),
        if (hex.pipelineIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Pipelines: ${hex.pipelineIds.join(', ')}'),
          ),
        const SizedBox(height: 12),
        _SyncedTextField(
          text: hex.notes,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 2,
          onChanged: (value) => onHexChanged(hex.copyWith(notes: value)),
        ),
      ],
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
  final VoidCallback onTap;

  const _FleetMarker({
    required this.fleet,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = fleet.isEnemy ? Colors.redAccent : Colors.cyanAccent;
    final outOfSupply = !fleet.inSupply;
    final borderColor = selected
        ? Colors.amber
        : (outOfSupply ? Colors.orangeAccent : color);
    final textColor = outOfSupply ? color.withValues(alpha: 0.55) : color;
    final marker = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
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
    return GestureDetector(
      onTap: onTap,
      child: outOfSupply
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
          : marker,
    );
  }
}

class _AssetPill extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _AssetPill({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pill = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label: $value'),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
    return pill;
  }
}

class _ToolbarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ToolbarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
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

class _HexPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool selected;

  const _HexPainter({
    required this.fillColor,
    required this.borderColor,
    required this.selected,
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
        oldDelegate.selected != selected;
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
  if (hex.pipelineIds.isNotEmpty) parts.add('P${hex.pipelineIds.length}');
  if (hex.industryMarkers > 0) parts.add('I${hex.industryMarkers}');
  if (hex.researchMarkers > 0) parts.add('R${hex.researchMarkers}');
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
