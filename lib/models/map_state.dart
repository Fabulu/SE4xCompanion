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
  final String? worldName;
  final int minerals;
  final int wrecks;
  final int mines;
  final int pipelines;
  final int industryMarkers;
  final int researchMarkers;
  final String notes;

  const MapHexState({
    required this.coord,
    this.terrain = HexTerrain.deepSpace,
    this.explored = false,
    this.label = '',
    this.worldName,
    this.minerals = 0,
    this.wrecks = 0,
    this.mines = 0,
    this.pipelines = 0,
    this.industryMarkers = 0,
    this.researchMarkers = 0,
    this.notes = '',
  });

  MapHexState copyWith({
    HexCoord? coord,
    HexTerrain? terrain,
    bool? explored,
    String? label,
    String? worldName,
    bool clearWorldName = false,
    int? minerals,
    int? wrecks,
    int? mines,
    int? pipelines,
    int? industryMarkers,
    int? researchMarkers,
    String? notes,
  }) =>
      MapHexState(
        coord: coord ?? this.coord,
        terrain: terrain ?? this.terrain,
        explored: explored ?? this.explored,
        label: label ?? this.label,
        worldName: clearWorldName ? null : (worldName ?? this.worldName),
        minerals: minerals ?? this.minerals,
        wrecks: wrecks ?? this.wrecks,
        mines: mines ?? this.mines,
        pipelines: pipelines ?? this.pipelines,
        industryMarkers: industryMarkers ?? this.industryMarkers,
        researchMarkers: researchMarkers ?? this.researchMarkers,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'coord': coord.toJson(),
        'terrain': terrain.name,
        'explored': explored,
        'label': label,
        'worldName': worldName,
        'minerals': minerals,
        'wrecks': wrecks,
        'mines': mines,
        'pipelines': pipelines,
        'industryMarkers': industryMarkers,
        'researchMarkers': researchMarkers,
        'notes': notes,
      };

  factory MapHexState.fromJson(Map<String, dynamic> json) => MapHexState(
        coord: HexCoord.fromJson(
          json['coord'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        ),
        terrain: _terrainFromName(json['terrain'] as String?),
        explored: json['explored'] as bool? ?? false,
        label: json['label'] as String? ?? '',
        worldName: json['worldName'] as String?,
        minerals: json['minerals'] as int? ?? 0,
        wrecks: json['wrecks'] as int? ?? 0,
        mines: json['mines'] as int? ?? 0,
        pipelines: json['pipelines'] as int? ?? 0,
        industryMarkers: json['industryMarkers'] as int? ?? 0,
        researchMarkers: json['researchMarkers'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
      );

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

  const GameMapState({
    this.layoutPreset = MapLayoutPreset.standard4p,
    this.hexes = const [],
    this.fleets = const [],
    this.selectedHex,
    this.selectedFleetId,
    this.zoom = 1.0,
    this.panX = 0,
    this.panY = 0,
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
      hexes.any((hex) => hex.worldName != null && hex.worldName!.isNotEmpty);

  bool get hasAnyMeaningfulContent =>
      fleets.isNotEmpty ||
      hexes.any((hex) =>
          hex.worldName != null ||
          hex.label.isNotEmpty ||
          hex.explored ||
          hex.terrain != HexTerrain.deepSpace ||
          hex.minerals > 0 ||
          hex.wrecks > 0 ||
          hex.mines > 0 ||
          hex.pipelines > 0 ||
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
      };

  factory GameMapState.fromJson(Map<String, dynamic> json) {
    final layoutPreset = _presetFromName(json['layoutPreset'] as String?);
    final storedHexes = (json['hexes'] as List?)
            ?.map((hex) => MapHexState.fromJson(hex as Map<String, dynamic>))
            .toList() ??
        const <MapHexState>[];
    final defaultsById = {
      for (final hex in defaultHexesFor(layoutPreset)) hex.coord.id: hex,
    };
    for (final hex in storedHexes) {
      defaultsById[hex.coord.id] = hex;
    }

    return GameMapState(
      layoutPreset: layoutPreset,
      hexes: defaultsById.values.toList()
        ..sort((a, b) {
          final r = a.coord.r.compareTo(b.coord.r);
          return r != 0 ? r : a.coord.q.compareTo(b.coord.q);
        }),
      fleets: (json['fleets'] as List?)
              ?.map((fleet) =>
                  FleetStackState.fromJson(fleet as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedHex: json['selectedHex'] != null
          ? HexCoord.fromJson(json['selectedHex'] as Map<String, dynamic>)
          : null,
      selectedFleetId: json['selectedFleetId'] as String?,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      panX: (json['panX'] as num?)?.toDouble() ?? 0,
      panY: (json['panY'] as num?)?.toDouble() ?? 0,
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
      MapLayoutPreset.standard4p => _hexesFromRows(
          const [4, 6, 8, 10, 11, 10, 11, 10, 11, 10, 8, 6, 4],
          rowShift: const [2, 1, 0, -1, -1, -1, -2, -1, -1, -1, 0, 1, 2],
        ),
      MapLayoutPreset.special5p => _hexesFromRows(
          const [3, 4, 5, 6, 7, 8, 9, 10, 11, 10, 9, 8, 7, 6, 5, 4, 3],
        ),
    };
  }

  static List<MapHexState> _hexesFromRows(
    List<int> rowLengths, {
    List<int>? rowShift,
  }) {
    final hexes = <MapHexState>[];
    final centerRow = rowLengths.length ~/ 2;
    for (int rowIndex = 0; rowIndex < rowLengths.length; rowIndex++) {
      final length = rowLengths[rowIndex];
      final r = rowIndex - centerRow;
      final shift = rowShift != null && rowIndex < rowShift.length
          ? rowShift[rowIndex]
          : 0;
      final qStart = -((length - 1) ~/ 2) + shift;
      for (int i = 0; i < length; i++) {
        hexes.add(
          MapHexState(coord: HexCoord(qStart + i, r)),
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
