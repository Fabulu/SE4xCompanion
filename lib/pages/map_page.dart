import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ship_definitions.dart';
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
  final MapStateChanged onChanged;

  const MapPage({
    super.key,
    required this.state,
    required this.productionWorlds,
    required this.shipCounters,
    required this.onChanged,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GameMapState get _state =>
      widget.state.hexes.isEmpty ? GameMapState.initial(layoutPreset: widget.state.layoutPreset) : widget.state;

  WorldState? _findWorld(String? name) {
    if (name == null) return null;
    for (final world in widget.productionWorlds) {
      if (world.name == name) return world;
    }
    return null;
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
    widget.onChanged(GameMapState.initial(layoutPreset: preset), description: 'Map Layout');
  }

  Future<void> _placeWorld(MapHexState hex) async {
    final placed = _state.hexes.map((h) => h.worldName).whereType<String>().toSet();
    final options = widget.productionWorlds
        .where((w) => w.name == hex.worldName || !placed.contains(w.name))
        .toList();
    if (options.isEmpty) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Place Ledger World'),
        children: [
          for (final world in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(world.name),
              child: Text(world.name),
            ),
        ],
      ),
    );
    if (selected == null) return;
    widget.onChanged(_state.replaceHex(hex.copyWith(worldName: selected)), description: 'Map World');
  }

  void _addFriendlyFleet(HexCoord coord) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    widget.onChanged(
      _state.copyWith(
        fleets: [
          ..._state.fleets,
          FleetStackState(id: id, coord: coord, owner: 'Player', label: 'Fleet'),
        ],
        selectedFleetId: id,
      ),
      description: 'Fleet',
    );
  }

  void _addEnemyFleet(HexCoord coord) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    widget.onChanged(
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
        selectedFleetId: id,
      ),
      description: 'Enemy Fleet',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedHex = _state.selectedHex != null ? _state.hexAt(_state.selectedHex!) : null;
    final fleets = selectedHex != null ? _state.fleetsAt(selectedHex.coord) : const <FleetStackState>[];

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
                  DropdownMenuItem(value: MapLayoutPreset.standard4p, child: Text('Standard 4P Map')),
                  DropdownMenuItem(value: MapLayoutPreset.special5p, child: Text('Special 5P Map')),
                ],
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
              FilledButton.tonalIcon(
                onPressed: selectedHex == null ? null : () => _placeWorld(selectedHex),
                icon: const Icon(Icons.public),
                label: const Text('Place World'),
              ),
              Text('${_state.hexes.length} hexes • ${_state.fleets.length} fleets'),
              if (selectedHex != null) Text('Selected ${selectedHex.coord.id}'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 6, 12),
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
                      shipCounters: widget.shipCounters,
                      onHexTap: (coord) => widget.onChanged(
                        _state.copyWith(selectedHex: coord, clearSelectedFleetId: true),
                        recordUndo: false,
                      ),
                      onViewportChanged: (zoom, panX, panY) => widget.onChanged(
                        _state.copyWith(zoom: zoom, panX: panX, panY: panY),
                        recordUndo: false,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(6, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: selectedHex == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Select a hex to edit terrain, ledger worlds, tokens, and fleets.'),
                          ),
                        )
                      : _HexInspector(
                          hex: selectedHex,
                          world: _findWorld(selectedHex.worldName),
                          fleets: fleets,
                          allFleets: _state.fleets,
                          shipCounters: widget.shipCounters,
                          selectedFleetId: _state.selectedFleetId,
                          onHexChanged: (hex) =>
                              widget.onChanged(_state.replaceHex(hex), description: 'Map Hex'),
                          onFleetSelected: (id) => widget.onChanged(
                            _state.copyWith(selectedFleetId: id),
                            recordUndo: false,
                          ),
                          onFleetDeleted: (id) => widget.onChanged(
                            _state.copyWith(
                              fleets: _state.fleets.where((fleet) => fleet.id != id).toList(),
                              clearSelectedFleetId: _state.selectedFleetId == id,
                            ),
                            description: 'Map Fleet',
                          ),
                          onFleetChanged: (updated) => widget.onChanged(
                            _state.copyWith(
                              fleets: [
                                for (final fleet in _state.fleets)
                                  if (fleet.id == updated.id) updated else fleet,
                              ],
                              selectedFleetId: updated.id,
                            ),
                            description: 'Map Fleet',
                          ),
                        ),
                ),
              ),
            ],
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
  final ValueChanged<HexCoord> onHexTap;
  final void Function(double zoom, double panX, double panY) onViewportChanged;

  const _MapCanvas({
    required this.state,
    required this.productionWorlds,
    required this.shipCounters,
    required this.onHexTap,
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
      final offset = Offset(x, y);
      positions[hex.coord.id] = offset;
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
      minScale: 0.4,
      maxScale: 3.0,
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
                  final world = _findWorld(hex.worldName);
                  final selected = widget.state.selectedHex == hex.coord;
                  final fleets = widget.state.fleetsAt(hex.coord);
                  return Positioned(
                    left: pos.dx - minX + padding,
                    top: pos.dy - minY + padding,
                    child: GestureDetector(
                      key: ValueKey('hex-${hex.coord.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onHexTap(hex.coord),
                      child: CustomPaint(
                        painter: _HexPainter(
                          fillColor: _terrainColor(hex, world != null),
                          borderColor: selected ? Colors.amber : Colors.white54,
                          selected: selected,
                        ),
                        child: SizedBox(
                          width: hexRadius * math.sqrt(3),
                          height: hexRadius * 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  hex.label.isEmpty ? hex.coord.id : hex.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: hex.label.isEmpty ? 9 : 10,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                                    textAlign: TextAlign.center,
                                  ),
                                if (fleets.isNotEmpty)
                                  Text(
                                    _fleetBadge(fleets),
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  WorldState? _findWorld(String? name) {
    if (name == null) return null;
    for (final world in widget.productionWorlds) {
      if (world.name == name) return world;
    }
    return null;
  }

  static String _worldSummary(WorldState world) {
    final value = world.isHomeworld ? world.homeworldValue : world.cpValue;
    final facility = world.facility == null ? '' : ' ${_facilityLabel(world.facility!)}';
    final blocked = world.isBlocked ? ' B' : '';
    return world.isHomeworld ? 'HW $value$facility$blocked' : '$value$facility$blocked';
  }

  static String _facilityLabel(FacilityType facility) {
    return switch (facility) {
      FacilityType.industrial => 'IC',
      FacilityType.research => 'RC',
      FacilityType.logistics => 'LC',
      FacilityType.temporal => 'TC',
    };
  }

  static String _tokenSummary(MapHexState hex) {
    final parts = <String>[];
    if (hex.minerals > 0) parts.add('M${hex.minerals}');
    if (hex.wrecks > 0) parts.add('W${hex.wrecks}');
    if (hex.mines > 0) parts.add('Mi${hex.mines}');
    if (hex.pipelines > 0) parts.add('P${hex.pipelines}');
    if (hex.industryMarkers > 0) parts.add('I${hex.industryMarkers}');
    if (hex.researchMarkers > 0) parts.add('R${hex.researchMarkers}');
    return parts.join(' ');
  }

  static String _fleetBadge(List<FleetStackState> fleets) {
    int enemyCount = 0;
    int playerShips = 0;
    for (final fleet in fleets) {
      if (fleet.isEnemy) {
        enemyCount++;
      } else {
        playerShips += fleet.shipCounterIds.length;
      }
    }
    final parts = <String>[];
    if (playerShips > 0) parts.add('${playerShips}P');
    if (enemyCount > 0) parts.add('${enemyCount}E');
    return parts.join(' ');
  }

  static Color _terrainColor(MapHexState hex, bool hasWorld) {
    final base = switch (hex.terrain) {
      HexTerrain.deepSpace => hex.explored ? const Color(0xFF101935) : const Color(0xFF05080F),
      HexTerrain.asteroid => const Color(0xFF5A4A38),
      HexTerrain.nebula => const Color(0xFF433164),
      HexTerrain.blackHole => const Color(0xFF161616),
      HexTerrain.supernova => const Color(0xFF7B2D1E),
      HexTerrain.foldInSpace => const Color(0xFF16546B),
    };
    return hasWorld ? Color.alphaBlend(const Color(0x2500FF66), base) : base;
  }
}

class _HexInspector extends StatelessWidget {
  final MapHexState hex;
  final WorldState? world;
  final List<FleetStackState> fleets;
  final List<FleetStackState> allFleets;
  final List<ShipCounter> shipCounters;
  final String? selectedFleetId;
  final ValueChanged<MapHexState> onHexChanged;
  final ValueChanged<String> onFleetSelected;
  final ValueChanged<String> onFleetDeleted;
  final ValueChanged<FleetStackState> onFleetChanged;

  const _HexInspector({
    required this.hex,
    required this.world,
    required this.fleets,
    required this.allFleets,
    required this.shipCounters,
    required this.selectedFleetId,
    required this.onHexChanged,
    required this.onFleetSelected,
    required this.onFleetDeleted,
    required this.onFleetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentWorld = world;
    final selectedFleet = selectedFleetId == null
        ? null
        : fleets.cast<FleetStackState?>().firstWhere(
              (fleet) => fleet?.id == selectedFleetId,
              orElse: () => null,
            );
    final availableShips = _availableFriendlyShips(selectedFleet);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hex ${hex.coord.id}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: hex.label,
          decoration: const InputDecoration(labelText: 'Label'),
          onChanged: (value) => onHexChanged(hex.copyWith(label: value)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<HexTerrain>(
          initialValue: hex.terrain,
          decoration: const InputDecoration(labelText: 'Terrain'),
          items: [
            for (final terrain in HexTerrain.values)
              DropdownMenuItem(value: terrain, child: Text(_terrainLabel(terrain))),
          ],
          onChanged: (value) {
            if (value != null) onHexChanged(hex.copyWith(terrain: value));
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Explored'),
          value: hex.explored,
          onChanged: (value) => onHexChanged(hex.copyWith(explored: value)),
        ),
        if (currentWorld != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(currentWorld.name),
            subtitle: Text(_MapCanvasState._worldSummary(currentWorld)),
            trailing: TextButton(
              onPressed: () => onHexChanged(hex.copyWith(clearWorldName: true)),
              child: const Text('Remove'),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No ledger world placed in this hex.'),
          ),
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
          label: 'Pipelines',
          value: hex.pipelines,
          onChanged: (value) => onHexChanged(hex.copyWith(pipelines: value)),
        ),
        _StepperRow(
          label: 'Industry markers',
          value: hex.industryMarkers,
          onChanged: (value) => onHexChanged(hex.copyWith(industryMarkers: value)),
        ),
        _StepperRow(
          label: 'Research markers',
          value: hex.researchMarkers,
          onChanged: (value) => onHexChanged(hex.copyWith(researchMarkers: value)),
        ),
        TextFormField(
          initialValue: hex.notes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Hex notes'),
          onChanged: (value) => onHexChanged(hex.copyWith(notes: value)),
        ),
        const SizedBox(height: 18),
        Text('Fleets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (fleets.isEmpty)
          const Text('No fleets in this hex.')
        else
          ...fleets.map(
            (fleet) => Card(
              child: ListTile(
                selected: fleet.id == selectedFleetId,
                title: Text(fleet.label.isEmpty ? 'Unnamed Fleet' : fleet.label),
                subtitle: Text(_fleetSummary(fleet, shipCounters)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onFleetDeleted(fleet.id),
                ),
                onTap: () => onFleetSelected(fleet.id),
              ),
            ),
          ),
        if (selectedFleet != null) ...[
          const SizedBox(height: 10),
          TextFormField(
            initialValue: selectedFleet.owner,
            decoration: const InputDecoration(labelText: 'Fleet owner'),
            onChanged: (value) => onFleetChanged(selectedFleet.copyWith(owner: value)),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: selectedFleet.label,
            decoration: const InputDecoration(labelText: 'Fleet label'),
            onChanged: (value) => onFleetChanged(selectedFleet.copyWith(label: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enemy / Manual Fleet'),
            value: selectedFleet.isEnemy,
            onChanged: (value) => onFleetChanged(
              selectedFleet.copyWith(
                isEnemy: value,
                shipCounterIds: value ? const [] : selectedFleet.shipCounterIds,
                composition: value ? selectedFleet.composition : const {},
                owner: value ? 'Enemy' : selectedFleet.owner,
                facedown: value || selectedFleet.facedown,
              ),
            ),
          ),
          if (selectedFleet.isEnemy)
            TextFormField(
              initialValue: _formatComposition(selectedFleet.composition),
              decoration: const InputDecoration(labelText: 'Composition'),
              onChanged: (value) =>
                  onFleetChanged(selectedFleet.copyWith(composition: _parseComposition(value))),
            )
          else ...[
            Text('Assign Built Ships', style: Theme.of(context).textTheme.titleSmall),
            if (availableShips.isEmpty && selectedFleet.shipCounterIds.isEmpty)
              const Text('No unassigned built ships available.')
            else
              ...availableShips.map(
                (counter) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_shipLabel(counter)),
                  value: selectedFleet.shipCounterIds.contains(_counterId(counter)),
                  onChanged: (checked) {
                    final ids = List<String>.from(selectedFleet.shipCounterIds);
                    final id = _counterId(counter);
                    if (checked == true && !ids.contains(id)) ids.add(id);
                    if (checked != true) ids.remove(id);
                    onFleetChanged(selectedFleet.copyWith(shipCounterIds: ids));
                  },
                ),
              ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Facedown'),
            value: selectedFleet.facedown,
            onChanged: (value) => onFleetChanged(selectedFleet.copyWith(facedown: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('In Supply'),
            value: selectedFleet.inSupply,
            onChanged: (value) => onFleetChanged(selectedFleet.copyWith(inSupply: value)),
          ),
          TextFormField(
            initialValue: selectedFleet.notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Fleet notes'),
            onChanged: (value) => onFleetChanged(selectedFleet.copyWith(notes: value)),
          ),
        ],
      ],
    );
  }

  List<ShipCounter> _availableFriendlyShips(FleetStackState? selectedFleet) {
    final assignedElsewhere = <String>{};
    for (final fleet in allFleets) {
      if (fleet.isEnemy) continue;
      if (selectedFleet != null && fleet.id == selectedFleet.id) continue;
      assignedElsewhere.addAll(fleet.shipCounterIds);
    }
    return shipCounters
        .where((counter) => counter.isBuilt)
        .where((counter) => !assignedElsewhere.contains(_counterId(counter)))
        .toList();
  }

  static String _terrainLabel(HexTerrain terrain) {
    return switch (terrain) {
      HexTerrain.deepSpace => 'Deep Space',
      HexTerrain.asteroid => 'Asteroid',
      HexTerrain.nebula => 'Nebula',
      HexTerrain.blackHole => 'Black Hole',
      HexTerrain.supernova => 'Supernova',
      HexTerrain.foldInSpace => 'Fold in Space',
    };
  }

  static String _fleetSummary(FleetStackState fleet, List<ShipCounter> shipCounters) {
    final parts = <String>[
      if (fleet.owner.isNotEmpty) fleet.owner,
      fleet.isEnemy ? _formatComposition(fleet.composition) : _friendlyComposition(fleet, shipCounters),
      fleet.facedown ? 'Facedown' : 'Faceup',
      fleet.inSupply ? 'In Supply' : 'Out of Supply',
    ];
    return parts.where((part) => part.isNotEmpty).join(' • ');
  }

  static String _friendlyComposition(FleetStackState fleet, List<ShipCounter> shipCounters) {
    final counts = <String, int>{};
    final byId = {for (final counter in shipCounters) _counterId(counter): counter};
    for (final id in fleet.shipCounterIds) {
      final counter = byId[id];
      if (counter == null) continue;
      final label = _shipAbbrev(counter.type);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return _formatComposition(counts);
  }

  static String _formatComposition(Map<String, int> composition) {
    if (composition.isEmpty) return '';
    final keys = composition.keys.toList()..sort();
    return keys.map((key) => '${composition[key]} $key').join(', ');
  }

  static Map<String, int> _parseComposition(String text) {
    final result = <String, int>{};
    for (final rawPart in text.split(',')) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(part);
      if (match == null) continue;
      final count = int.tryParse(match.group(1) ?? '');
      final label = (match.group(2) ?? '').trim();
      if (count == null || count <= 0 || label.isEmpty) continue;
      result[label] = count;
    }
    return result;
  }

  static String _counterId(ShipCounter counter) => '${counter.type.name}:${counter.number}';
  static String _shipLabel(ShipCounter counter) => '${_shipAbbrev(counter.type)} #${counter.number}';
  static String _shipAbbrev(ShipType type) =>
      kShipDefinitions[type]?.abbreviation ?? type.name.toUpperCase();
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
          onPressed: value > 0 ? () => onChanged((value - 1).clamp(0, 99)) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          onPressed: value < 99 ? () => onChanged((value + 1).clamp(0, 99)) : null,
          icon: const Icon(Icons.add_circle_outline),
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
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height * 0.75)
      ..lineTo(0, size.height * 0.25)
      ..close();
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.2 : 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.selected != selected;
  }
}
