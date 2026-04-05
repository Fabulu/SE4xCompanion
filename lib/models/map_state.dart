enum MapLayoutPreset { standard4p, special5p }

enum HexTerrain {
  deepSpace,
  asteroid,
  nebula,
  blackHole,
  supernova,
  foldInSpace,
}

class HexCoord {
  final int q;
  final int r;

  const HexCoord(this.q, this.r);

  String get id => '$q,$r';

  HexCoord copyWith({int? q, int? r}) =>
      HexCoord(q ?? this.q, r ?? this.r);

  int distanceTo(HexCoord other) {
    final dq = (q - other.q).abs();
    final dr = (r - other.r).abs();
    final ds = (q + r - other.q - other.r).abs();
    return [dq, dr, ds].reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'q': q,
        'r': r,
      };

  factory HexCoord.fromJson(Map<String, dynamic> json) => HexCoord(
        json['q'] as int? ?? 0,
        json['r'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is HexCoord && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);
}

class MapHexState {
  final HexCoord coord;
  final HexTerrain terrain;
  final bool explored;
  final String label;
  final String? worldId;
  final int minerals;
  final int wrecks;
  final int mines;
  final List<String> pipelineIds;
  final int industryMarkers;
  final int researchMarkers;
  final String notes;
  final String? legacyWorldName;

  const MapHexState({
    required this.coord,
    this.terrain = HexTerrain.deepSpace,
    this.explored = false,
    this.label = '',
    this.worldId,
    this.minerals = 0,
    this.wrecks = 0,
    this.mines = 0,
    this.pipelineIds = const [],
    this.industryMarkers = 0,
    this.researchMarkers = 0,
    this.notes = '',
    this.legacyWorldName,
  });

  MapHexState copyWith({
    HexCoord? coord,
    HexTerrain? terrain,
    bool? explored,
    String? label,
    String? worldId,
    bool clearWorldId = false,
    int? minerals,
    int? wrecks,
    int? mines,
    List<String>? pipelineIds,
    int? industryMarkers,
    int? researchMarkers,
    String? notes,
  }) =>
      MapHexState(
        coord: coord ?? this.coord,
        terrain: terrain ?? this.terrain,
        explored: explored ?? this.explored,
        label: label ?? this.label,
        worldId: clearWorldId ? null : (worldId ?? this.worldId),
        minerals: minerals ?? this.minerals,
        wrecks: wrecks ?? this.wrecks,
        mines: mines ?? this.mines,
        pipelineIds: pipelineIds ?? this.pipelineIds,
        industryMarkers: industryMarkers ?? this.industryMarkers,
        researchMarkers: researchMarkers ?? this.researchMarkers,
        notes: notes ?? this.notes,
        legacyWorldName: null,
      );

  Map<String, dynamic> toJson() => {
        'coord': coord.toJson(),
        'terrain': terrain.name,
        'explored': explored,
        'label': label,
        'worldId': worldId,
        'minerals': minerals,
        'wrecks': wrecks,
        'mines': mines,
        'pipelineIds': pipelineIds,
        'industryMarkers': industryMarkers,
        'researchMarkers': researchMarkers,
        'notes': notes,
      };

  factory MapHexState.fromJson(Map<String, dynamic> json) {
    final coord = HexCoord.fromJson(
      json['coord'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final storedPipelineIds = (json['pipelineIds'] as List?)
        ?.map((id) => id as String)
        .toList();
    final legacyPipelineCount = json['pipelines'] as int? ?? 0;
    final pipelineIds = storedPipelineIds ??
        [
          for (int i = 0; i < legacyPipelineCount; i++)
            'legacy-pipeline-${coord.id}-${i + 1}',
        ];

    return MapHexState(
      coord: coord,
      terrain: _terrainFromName(json['terrain'] as String?),
      explored: json['explored'] as bool? ?? false,
      label: json['label'] as String? ?? '',
      worldId: json['worldId'] as String?,
      minerals: json['minerals'] as int? ?? 0,
      wrecks: json['wrecks'] as int? ?? 0,
      mines: json['mines'] as int? ?? 0,
      pipelineIds: pipelineIds,
      industryMarkers: json['industryMarkers'] as int? ?? 0,
      researchMarkers: json['researchMarkers'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      legacyWorldName: json['worldId'] == null
          ? json['worldName'] as String?
          : null,
    );
  }

  static HexTerrain _terrainFromName(String? name) {
    if (name == null) return HexTerrain.deepSpace;
    for (final terrain in HexTerrain.values) {
      if (terrain.name == name) return terrain;
    }
    return HexTerrain.deepSpace;
  }
}

class FleetStackState {
  final String id;
  final String owner;
  final String label;
  final HexCoord coord;
  final bool isEnemy;
  final List<String> shipCounterIds;
  final Map<String, int> composition;
  final bool facedown;
  final bool inSupply;
  final String notes;

  const FleetStackState({
    required this.id,
    required this.coord,
    this.owner = '',
    this.label = '',
    this.isEnemy = false,
    this.shipCounterIds = const [],
    this.composition = const {},
    this.facedown = false,
    this.inSupply = true,
    this.notes = '',
  });

  bool get isFriendly => !isEnemy;

  bool containsShipId(String shipId) => shipCounterIds.contains(shipId);

  FleetStackState copyWith({
    String? id,
    String? owner,
    String? label,
    HexCoord? coord,
    bool? isEnemy,
    List<String>? shipCounterIds,
    Map<String, int>? composition,
    bool? facedown,
    bool? inSupply,
    String? notes,
  }) =>
      FleetStackState(
        id: id ?? this.id,
        owner: owner ?? this.owner,
        label: label ?? this.label,
        coord: coord ?? this.coord,
        isEnemy: isEnemy ?? this.isEnemy,
        shipCounterIds: shipCounterIds ?? this.shipCounterIds,
        composition: composition ?? this.composition,
        facedown: facedown ?? this.facedown,
        inSupply: inSupply ?? this.inSupply,
        notes: notes ?? this.notes,
      );

  FleetStackState movedTo(HexCoord coord) => copyWith(coord: coord);

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'label': label,
        'isEnemy': isEnemy,
        'shipCounterIds': shipCounterIds,
        'composition': composition,
        'coord': coord.toJson(),
        'facedown': facedown,
        'inSupply': inSupply,
        'notes': notes,
      };

  factory FleetStackState.fromJson(Map<String, dynamic> json) => FleetStackState(
        id: json['id'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
        label: json['label'] as String? ?? '',
        coord: HexCoord.fromJson(
          json['coord'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        ),
        isEnemy: json['isEnemy'] as bool? ?? false,
        shipCounterIds: (json['shipCounterIds'] as List?)
                ?.map((id) => id as String)
                .toList() ??
            const [],
        composition: (json['composition'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
        facedown: json['facedown'] as bool? ?? false,
        inSupply: json['inSupply'] as bool? ?? true,
        notes: json['notes'] as String? ?? '',
      );
}

class GameMapState {
  final MapLayoutPreset layoutPreset;
  final List<MapHexState> hexes;
  final List<FleetStackState> fleets;
  final HexCoord? selectedHex;
  final String? selectedFleetId;
  final double zoom;
  final double panX;
  final double panY;
  final double rotation;

  const GameMapState({
    this.layoutPreset = MapLayoutPreset.standard4p,
    this.hexes = const [],
    this.fleets = const [],
    this.selectedHex,
    this.selectedFleetId,
    this.zoom = 1.0,
    this.panX = 0,
    this.panY = 0,
    this.rotation = 0,
  });

  factory GameMapState.standard4p() =>
      GameMapState.createDefault(MapLayoutPreset.standard4p);

  factory GameMapState.special5p() =>
      GameMapState.createDefault(MapLayoutPreset.special5p);

  factory GameMapState.createDefault(MapLayoutPreset preset) => GameMapState(
        layoutPreset: preset,
        hexes: defaultHexesFor(preset),
      );

  factory GameMapState.initial({
    MapLayoutPreset layoutPreset = MapLayoutPreset.standard4p,
  }) {
    return GameMapState.createDefault(layoutPreset);
  }

  MapHexState? hexAt(HexCoord coord) {
    for (final hex in hexes) {
      if (hex.coord == coord) return hex;
    }
    return null;
  }

  FleetStackState? fleetById(String id) {
    for (final fleet in fleets) {
      if (fleet.id == id) return fleet;
    }
    return null;
  }

  bool get hasAnyPlacedWorld =>
      hexes.any((hex) => hex.worldId != null && hex.worldId!.isNotEmpty);

  bool get hasAnyMeaningfulContent =>
      fleets.isNotEmpty ||
      hexes.any((hex) =>
          hex.worldId != null ||
          hex.label.isNotEmpty ||
          hex.explored ||
          hex.terrain != HexTerrain.deepSpace ||
          hex.minerals > 0 ||
          hex.wrecks > 0 ||
          hex.mines > 0 ||
          hex.pipelineIds.isNotEmpty ||
          hex.industryMarkers > 0 ||
          hex.researchMarkers > 0 ||
          hex.notes.isNotEmpty);

  List<FleetStackState> fleetsAt(HexCoord coord) => fleets
      .where((fleet) => fleet.coord == coord)
      .toList();

  GameMapState replaceHex(MapHexState updated) {
    final nextHexes = [
      for (final hex in hexes)
        if (hex.coord.q == updated.coord.q && hex.coord.r == updated.coord.r)
          updated
        else
          hex,
    ];
    return copyWith(hexes: nextHexes);
  }

  GameMapState replaceFleet(FleetStackState updated) => copyWith(
        fleets: [
          for (final fleet in fleets)
            if (fleet.id == updated.id) updated else fleet,
        ],
      );

  GameMapState removeFleet(String fleetId) => copyWith(
        fleets: fleets.where((fleet) => fleet.id != fleetId).toList(),
        clearSelectedFleetId: selectedFleetId == fleetId,
      );

  GameMapState moveFleet(String fleetId, HexCoord coord) {
    final fleet = fleetById(fleetId);
    if (fleet == null) return this;
    return replaceFleet(fleet.movedTo(coord));
  }

  String? fleetIdForShip(String shipId) {
    for (final fleet in fleets) {
      if (fleet.isEnemy) continue;
      if (fleet.containsShipId(shipId)) return fleet.id;
    }
    return null;
  }

  Set<String> assignedFriendlyShipIds({String? excludeFleetId}) {
    final ids = <String>{};
    for (final fleet in fleets) {
      if (fleet.isEnemy || fleet.id == excludeFleetId) continue;
      ids.addAll(fleet.shipCounterIds);
    }
    return ids;
  }

  Set<String> placedWorldIds({String? excludeHexId}) {
    final ids = <String>{};
    for (final hex in hexes) {
      if (hex.coord.id == excludeHexId) continue;
      final worldId = hex.worldId;
      if (worldId != null && worldId.isNotEmpty) {
        ids.add(worldId);
      }
    }
    return ids;
  }

  Set<String> placedPipelineIds({String? excludeHexId}) {
    final ids = <String>{};
    for (final hex in hexes) {
      if (hex.coord.id == excludeHexId) continue;
      ids.addAll(hex.pipelineIds);
    }
    return ids;
  }

  GameMapState assignFleetShips(String fleetId, List<String> shipIds) {
    final assignedElsewhere = assignedFriendlyShipIds(excludeFleetId: fleetId);
    final nextIds = <String>[];
    for (final shipId in shipIds) {
      if (assignedElsewhere.contains(shipId) || nextIds.contains(shipId)) {
        continue;
      }
      nextIds.add(shipId);
    }
    final fleet = fleetById(fleetId);
    if (fleet == null) return this;
    return replaceFleet(
      fleet.copyWith(
        shipCounterIds: nextIds,
        composition: const {},
      ),
    );
  }

  GameMapState migrateLegacyWorldNames(Map<String, String> worldIdByName) {
    var changed = false;
    final nextHexes = [
      for (final hex in hexes)
        if (hex.worldId == null &&
            hex.legacyWorldName != null &&
            worldIdByName.containsKey(hex.legacyWorldName))
          () {
            changed = true;
            return hex.copyWith(worldId: worldIdByName[hex.legacyWorldName]);
          }()
        else
          hex,
    ];
    return changed ? copyWith(hexes: nextHexes) : this;
  }

  GameMapState sanitizeAgainstLedger({
    required Set<String> validWorldIds,
    required Set<String> validShipIds,
    required Set<String> validPipelineIds,
  }) {
    final seenWorldIds = <String>{};
    final seenPipelineIds = <String>{};
    final nextHexes = <MapHexState>[];
    for (final hex in hexes) {
      final worldId = hex.worldId;
      final normalizedWorldId = worldId != null &&
              worldId.isNotEmpty &&
              validWorldIds.contains(worldId) &&
              !seenWorldIds.contains(worldId)
          ? worldId
          : null;
      if (normalizedWorldId != null) {
        seenWorldIds.add(normalizedWorldId);
      }

      final pipelineIds = <String>[];
      for (final id in hex.pipelineIds) {
        if (!validPipelineIds.contains(id) ||
            seenPipelineIds.contains(id) ||
            pipelineIds.contains(id)) {
          continue;
        }
        seenPipelineIds.add(id);
        pipelineIds.add(id);
      }

      nextHexes.add(
        hex.copyWith(
          worldId: normalizedWorldId,
          clearWorldId: normalizedWorldId == null,
          pipelineIds: pipelineIds,
        ),
      );
    }

    final seenShipIds = <String>{};
    final nextFleets = <FleetStackState>[];
    for (final fleet in fleets) {
      if (fleet.isEnemy) {
        nextFleets.add(fleet);
        continue;
      }
      final nextShipIds = <String>[];
      for (final shipId in fleet.shipCounterIds) {
        if (!validShipIds.contains(shipId) ||
            seenShipIds.contains(shipId) ||
            nextShipIds.contains(shipId)) {
          continue;
        }
        seenShipIds.add(shipId);
        nextShipIds.add(shipId);
      }
      if (nextShipIds.isEmpty) {
        continue;
      }
      nextFleets.add(
        fleet.copyWith(
          shipCounterIds: nextShipIds,
          composition: const {},
        ),
      );
    }

    final selectedFleetId = nextFleets.any((fleet) => fleet.id == this.selectedFleetId)
        ? this.selectedFleetId
        : null;

    return copyWith(
      hexes: nextHexes,
      fleets: nextFleets,
      selectedFleetId: selectedFleetId,
      clearSelectedFleetId: selectedFleetId == null,
    );
  }

  GameMapState copyWith({
    MapLayoutPreset? layoutPreset,
    List<MapHexState>? hexes,
    List<FleetStackState>? fleets,
    HexCoord? selectedHex,
    bool clearSelectedHex = false,
    String? selectedFleetId,
    bool clearSelectedFleetId = false,
    double? zoom,
    double? panX,
    double? panY,
    double? rotation,
  }) =>
      GameMapState(
        layoutPreset: layoutPreset ?? this.layoutPreset,
        hexes: hexes ?? this.hexes,
        fleets: fleets ?? this.fleets,
        selectedHex:
            clearSelectedHex ? null : (selectedHex ?? this.selectedHex),
        selectedFleetId: clearSelectedFleetId
            ? null
            : (selectedFleetId ?? this.selectedFleetId),
        zoom: zoom ?? this.zoom,
        panX: panX ?? this.panX,
        panY: panY ?? this.panY,
        rotation: rotation ?? this.rotation,
      );

  Map<String, dynamic> toJson() => {
        'layoutPreset': layoutPreset.name,
        'hexes': hexes.map((hex) => hex.toJson()).toList(),
        'fleets': fleets.map((fleet) => fleet.toJson()).toList(),
        if (selectedHex != null) 'selectedHex': selectedHex!.toJson(),
        'selectedFleetId': selectedFleetId,
        'zoom': zoom,
        'panX': panX,
        'panY': panY,
        'rotation': rotation,
      };

  factory GameMapState.fromJson(Map<String, dynamic> json) {
    final layoutPreset = _presetFromName(json['layoutPreset'] as String?);
    final storedHexes = (json['hexes'] as List?)
            ?.map((hex) => MapHexState.fromJson(hex as Map<String, dynamic>))
            .toList() ??
        const <MapHexState>[];
    // Canonical coord set for the active preset. Any persisted hex or fleet
    // sitting outside this set is an orphan from a prior layout revision and
    // gets dropped silently so rendering never hits a phantom/missing coord.
    final validCoordIds = <String>{
      for (final hex in defaultHexesFor(layoutPreset)) hex.coord.id,
    };
    final defaultsById = {
      for (final hex in defaultHexesFor(layoutPreset)) hex.coord.id: hex,
    };
    for (final hex in storedHexes) {
      if (!validCoordIds.contains(hex.coord.id)) continue;
      defaultsById[hex.coord.id] = hex;
    }

    final storedFleets = (json['fleets'] as List?)
            ?.map((fleet) =>
                FleetStackState.fromJson(fleet as Map<String, dynamic>))
            .toList() ??
        const <FleetStackState>[];
    final sanitizedFleets = [
      for (final fleet in storedFleets)
        if (validCoordIds.contains(fleet.coord.id)) fleet,
    ];

    final storedSelectedHex = json['selectedHex'] != null
        ? HexCoord.fromJson(json['selectedHex'] as Map<String, dynamic>)
        : null;
    final selectedHex = (storedSelectedHex != null &&
            validCoordIds.contains(storedSelectedHex.id))
        ? storedSelectedHex
        : null;

    final storedSelectedFleetId = json['selectedFleetId'] as String?;
    final selectedFleetId = (storedSelectedFleetId != null &&
            sanitizedFleets.any((f) => f.id == storedSelectedFleetId))
        ? storedSelectedFleetId
        : null;

    return GameMapState(
      layoutPreset: layoutPreset,
      hexes: defaultsById.values.toList()
        ..sort((a, b) {
          final r = a.coord.r.compareTo(b.coord.r);
          return r != 0 ? r : a.coord.q.compareTo(b.coord.q);
        }),
      fleets: sanitizedFleets,
      selectedHex: selectedHex,
      selectedFleetId: selectedFleetId,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      panX: (json['panX'] as num?)?.toDouble() ?? 0,
      panY: (json['panY'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  static MapLayoutPreset _presetFromName(String? name) {
    if (name == null) return MapLayoutPreset.standard4p;
    for (final preset in MapLayoutPreset.values) {
      if (preset.name == name) return preset;
    }
    return MapLayoutPreset.standard4p;
  }

  static List<MapHexState> defaultHexesFor(MapLayoutPreset preset) {
    return switch (preset) {
      MapLayoutPreset.standard4p => _hexesFromRows(const [
          _RowSpec(start: 3, length: 12),
          _RowSpec(start: 3, length: 12),
          _RowSpec(start: 2, length: 12),
          _RowSpec(start: 2, length: 12),
          _RowSpec(start: 1, length: 12),
          _RowSpec(start: 1, length: 12),
          _RowSpec(start: 0, length: 12),
          _RowSpec(start: 0, length: 12),
          _RowSpec(start: -1, length: 12),
          _RowSpec(start: -1, length: 12),
          _RowSpec(start: -2, length: 12),
          _RowSpec(start: -2, length: 12),
        ]),
      MapLayoutPreset.special5p => _hexesFromRows(const [
          _RowSpec(start: -1, length: 3),
          _RowSpec(start: -2, length: 5),
          _RowSpec(start: -3, length: 8),
          _RowSpec(start: -5, length: 10),
          _RowSpec(start: -5, length: 12),
          _RowSpec(start: -7, length: 14),
          _RowSpec(start: -7, length: 15),
          _RowSpec(start: -8, length: 16),
          _RowSpec(start: -8, length: 16),
          _RowSpec(start: -8, length: 15),
          _RowSpec(start: -7, length: 15),
          _RowSpec(start: -7, length: 14),
          _RowSpec(start: -6, length: 13),
          _RowSpec(start: -6, length: 12),
          _RowSpec(start: -6, length: 13),
          _RowSpec(start: -6, length: 12),
          _RowSpec(start: -5, length: 11),
          _RowSpec(start: -5, length: 10),
        ]),
    };
  }

  static List<MapHexState> _hexesFromRows(List<_RowSpec> rows) {
    final hexes = <MapHexState>[];
    final centerRow = rows.length ~/ 2;
    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final r = rowIndex - centerRow;
      for (int i = 0; i < row.length; i++) {
        hexes.add(
          MapHexState(coord: HexCoord(row.start + i, r)),
        );
      }
    }
    return hexes;
  }

  List<int> get rowLengths {
    final counts = <int, int>{};
    for (final hex in hexes) {
      counts[hex.coord.r] = (counts[hex.coord.r] ?? 0) + 1;
    }
    final rows = counts.keys.toList()..sort();
    return [for (final row in rows) counts[row]!];
  }
}

class _RowSpec {
  final int start;
  final int length;

  const _RowSpec({
    required this.start,
    required this.length,
  });
}
