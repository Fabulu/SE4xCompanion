import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/map_state.dart';
import '../models/production_state.dart';
import '../models/ship_counter.dart';
import '../models/world.dart';

typedef MapStateChanged = void Function(
  GameMapState state, {
  bool recordUndo,
  String? description,
});

enum _MapMode { select, fleet, enemy, pipeline }

class MapPage extends StatefulWidget {
  final GameMapState state;
  final List<WorldState> productionWorlds;
  final List<ShipCounter> shipCounters;
  final List<PipelineAsset> pipelineAssets;
  final MapStateChanged onChanged;

  const MapPage({
    super.key,
    required this.state,
    required this.productionWorlds,
    required this.shipCounters,
    this.pipelineAssets = const [],
    required this.onChanged,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  _MapMode _mode = _MapMode.select;
  bool _inspectorExpanded = false;

  @override
  void initState() {
    super.initState();
    _inspectorExpanded = widget.state.selectedHex != null || widget.state.selectedFleetId != null;
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadSelection =
        oldWidget.state.selectedHex != null || oldWidget.state.selectedFleetId != null;
    final hasSelection = widget.state.selectedHex != null || widget.state.selectedFleetId != null;
    if (!hadSelection && hasSelection && !_inspectorExpanded) {
      setState(() => _inspectorExpanded = true);
    }
  }

  GameMapState get _state => widget.state.hexes.isEmpty
      ? GameMapState.initial(layoutPreset: widget.state.layoutPreset)
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

  List<PipelineAsset> _availablePipelineAssets({String? excludeHexId}) {
    final placed = _state.placedPipelineIds(excludeHexId: excludeHexId);
    return widget.pipelineAssets
        .where((asset) => !placed.contains(asset.id))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  void _apply(GameMapState next, {String? description, bool recordUndo = true}) {
    widget.onChanged(next, description: description, recordUndo: recordUndo);
  }

  void _selectHex(HexCoord coord) {
    setState(() => _inspectorExpanded = true);
    _apply(
      _state.copyWith(selectedHex: coord, clearSelectedFleetId: true),
      recordUndo: false,
    );
  }

  void _selectFleet(String fleetId) {
    final fleet = _state.fleetById(fleetId);
    if (fleet == null) return;
    setState(() => _inspectorExpanded = true);
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
      _state.replaceHex(hex.copyWith(pipelineIds: [available.first.id])),
      description: 'Pipeline',
    );
  }

  void _onHexTapped(HexCoord coord) {
    final hex = _state.hexAt(coord);
    if (hex == null) return;
    switch (_mode) {
      case _MapMode.select:
        _selectHex(coord);
      case _MapMode.fleet:
        _selectHex(coord);
        _addFriendlyFleet(coord);
      case _MapMode.enemy:
        _selectHex(coord);
        _addEnemyFleet(coord);
      case _MapMode.pipeline:
        _selectHex(coord);
        _togglePipelineAt(hex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedHex =
        _state.selectedHex != null ? _state.hexAt(_state.selectedHex!) : null;
    final selectedWorld = _findWorld(selectedHex?.worldId);
    final selectedFleetId = _state.selectedFleetId;
    final selectedFleet =
        selectedFleetId == null ? null : _state.fleetById(selectedFleetId);
    final fleetsOnHex =
        selectedHex == null ? const <FleetStackState>[] : _state.fleetsAt(selectedHex.coord);
    final availableWorlds = _availableWorlds(
      excludeHexId: selectedHex?.coord.id,
      includeWorldId: selectedHex?.worldId,
    );
    final availableShips = _availableShips(fleetId: selectedFleet?.id);
    final availablePipelines =
        _availablePipelineAssets(excludeHexId: selectedHex?.coord.id);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<MapLayoutPreset>(
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
              for (final mode in _MapMode.values)
                ChoiceChip(
                  label: Text(switch (mode) {
                    _MapMode.select => 'Select',
                    _MapMode.fleet => 'Fleet',
                    _MapMode.enemy => 'Enemy',
                    _MapMode.pipeline => 'Pipeline',
                  }),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                ),
              FilledButton.tonalIcon(
                onPressed: selectedHex == null ? null : () => _placeWorld(selectedHex),
                icon: const Icon(Icons.public),
                label: const Text('Place World'),
              ),
              FilledButton.tonalIcon(
                onPressed: selectedHex == null ? null : () => _addFriendlyFleet(selectedHex.coord),
                icon: const Icon(Icons.directions_boat),
                label: const Text('Add Fleet'),
              ),
              FilledButton.tonalIcon(
                onPressed: selectedHex == null ? null : () => _addEnemyFleet(selectedHex.coord),
                icon: const Icon(Icons.visibility_off),
                label: const Text('Add Enemy'),
              ),
              Text('${_state.hexes.length} hexes | ${_state.fleets.length} fleets'),
              if (selectedHex != null) Text('Selected ${selectedHex.coord.id}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _AssetPill(label: 'Worlds', value: availableWorlds.length),
                  _AssetPill(label: 'Ships', value: availableShips.length),
                  _AssetPill(label: 'Pipelines', value: availablePipelines.length),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sheetHeight = _inspectorExpanded
                    ? math.max(280.0, math.min(constraints.maxHeight * 0.46, 560.0))
                    : 76.0;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1226),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _MapCanvas(
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
                            onViewportChanged: (zoom, panX, panY) {
                              _apply(
                                _state.copyWith(zoom: zoom, panX: panX, panY: panY),
                                recordUndo: false,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: sheetHeight,
                        child: _MapInspectorPanel(
                          expanded: _inspectorExpanded,
                          selectedHex: selectedHex,
                          selectedWorld: selectedWorld,
                          fleetsOnHex: fleetsOnHex,
                          selectedFleetId: selectedFleetId,
                          availableShips: availableShips,
                          onToggleExpanded: () =>
                              setState(() => _inspectorExpanded = !_inspectorExpanded),
                          onHexChanged: (hex) =>
                              _apply(_state.replaceHex(hex), description: 'Map Hex'),
                          onPlaceWorld: selectedHex == null ? null : () => _placeWorld(selectedHex),
                          onClearWorld: selectedHex == null
                              ? null
                              : () => _apply(
                                    _state.replaceHex(selectedHex.copyWith(clearWorldId: true)),
                                    description: 'Map World',
                                  ),
                          onFleetSelected: _selectFleet,
                          onFleetDeleted: (id) =>
                              _apply(_state.removeFleet(id), description: 'Map Fleet'),
                          onFleetChanged: (fleet) =>
                              _apply(_state.replaceFleet(fleet), description: 'Map Fleet'),
                          onFleetShipsChanged: (fleetId, shipIds) => _apply(
                            _state.assignFleetShips(fleetId, shipIds),
                            description: 'Map Fleet',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
  final void Function(double zoom, double panX, double panY) onViewportChanged;

  const _MapCanvas({
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

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _syncFromState();
  }

  @override
  void didUpdateWidget(covariant _MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.zoom != widget.state.zoom ||
        oldWidget.state.panX != widget.state.panX ||
        oldWidget.state.panY != widget.state.panY) {
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
    _controller.value = Matrix4.identity()
      ..translateByDouble(widget.state.panX, widget.state.panY, 0, 1)
      ..scaleByDouble(widget.state.zoom, widget.state.zoom, 1, 1);
    _syncing = false;
  }

  void _emitViewport() {
    if (_syncing) return;
    final matrix = _controller.value;
    widget.onViewportChanged(
      matrix.getMaxScaleOnAxis(),
      matrix.getTranslation().x,
      matrix.getTranslation().y,
    );
  }

  @override
  Widget build(BuildContext context) {
    const hexRadius = 34.0;
    final positions = <String, Offset>{};
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final hex in widget.state.hexes) {
      final x = hexRadius * math.sqrt(3) * (hex.coord.q + hex.coord.r / 2);
      final y = hexRadius * 1.5 * hex.coord.r;
      positions[hex.coord.id] = Offset(x, y);
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    const padding = 88.0;
    final width = (maxX - minX) + padding * 2 + hexRadius * math.sqrt(3);
    final height = (maxY - minY) + padding * 2 + hexRadius * 2;

    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.25,
      maxScale: 4.0,
      constrained: false,
      onInteractionEnd: (_) => _emitViewport(),
      child: SizedBox(
        width: width,
        height: height,
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
                            width: hexRadius * math.sqrt(3),
                            height: hexRadius * 2,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
    );
  }
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hex ${hex.coord.id}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: hex.label),
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
            title: Text(world?.name ?? 'No world placed'),
            subtitle: Text(world == null ? 'Static world placement from ledger' : 'Ledger-backed world'),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton(onPressed: onPlaceWorld, child: const Text('Place')),
                if (world != null)
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
        TextField(
          controller: TextEditingController(text: hex.notes),
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 2,
          onChanged: (value) => onHexChanged(hex.copyWith(notes: value)),
        ),
        const SizedBox(height: 16),
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
          TextField(
            controller: TextEditingController(text: selectedFleet.owner),
            decoration: const InputDecoration(labelText: 'Owner'),
            onChanged: (value) =>
                onFleetChanged(selectedFleet!.copyWith(owner: value)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: selectedFleet.label),
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
            TextField(
              controller: TextEditingController(
                text: _formatComposition(selectedFleet.composition),
              ),
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
          TextField(
            controller: TextEditingController(text: selectedFleet.notes),
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
      ],
    );
  }
}

class _MapInspectorPanel extends StatelessWidget {
  final bool expanded;
  final MapHexState? selectedHex;
  final WorldState? selectedWorld;
  final List<FleetStackState> fleetsOnHex;
  final String? selectedFleetId;
  final List<ShipCounter> availableShips;
  final VoidCallback onToggleExpanded;
  final ValueChanged<MapHexState> onHexChanged;
  final VoidCallback? onPlaceWorld;
  final VoidCallback? onClearWorld;
  final ValueChanged<String> onFleetSelected;
  final ValueChanged<String> onFleetDeleted;
  final ValueChanged<FleetStackState> onFleetChanged;
  final void Function(String fleetId, List<String> shipIds) onFleetShipsChanged;

  const _MapInspectorPanel({
    required this.expanded,
    required this.selectedHex,
    required this.selectedWorld,
    required this.fleetsOnHex,
    required this.selectedFleetId,
    required this.availableShips,
    required this.onToggleExpanded,
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
    final hex = selectedHex;
    final theme = Theme.of(context);
    final shellColor = theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: shellColor,
      elevation: 10,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: expanded ? null : onToggleExpanded,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hex == null
                          ? 'Select a hex to edit terrain, ledger worlds, tokens, and fleets.'
                          : 'Hex ${hex.coord.id}${selectedFleetId == null ? '' : ' • Fleet selected'}',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: expanded ? 'Collapse inspector' : 'Expand inspector',
                    onPressed: onToggleExpanded,
                    icon: Icon(expanded ? Icons.expand_more : Icons.expand_less),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: expanded
                    ? hex == null
                        ? const Center(
                            key: ValueKey('empty'),
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Tap a hex to inspect terrain, worlds, tokens, and fleets.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _HexInspector(
                            key: const ValueKey('inspector'),
                            hex: hex,
                            world: selectedWorld,
                            fleets: fleetsOnHex,
                            selectedFleetId: selectedFleetId,
                            availableShips: availableShips,
                            onHexChanged: onHexChanged,
                            onPlaceWorld: onPlaceWorld!,
                            onClearWorld: onClearWorld!,
                            onFleetSelected: onFleetSelected,
                            onFleetDeleted: onFleetDeleted,
                            onFleetChanged: onFleetChanged,
                            onFleetShipsChanged: onFleetShipsChanged,
                          )
                    : Center(
                        key: const ValueKey('collapsed'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            hex == null
                                ? 'Collapsed. Tap to expand.'
                                : 'Selected ${hex.coord.id}. Tap to expand.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.amber : color,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Text(
          fleet.label.isEmpty ? fleet.owner : fleet.label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AssetPill extends StatelessWidget {
  final String label;
  final int value;

  const _AssetPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
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
