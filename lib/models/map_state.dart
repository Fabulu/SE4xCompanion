import 'ship_counter.dart';

enum MapLayoutPreset { standard4p, special5p }

enum HexTerrain {
  deepSpace,
  asteroid,
  nebula,
  blackHole,
  supernova,
  foldInSpace,
}

/// Terrain colonization rules (rule 4.4 / 9.7):
/// - Deep space planets are always colonizable.
/// - Asteroid belts require Terraforming 1.
/// - Nebulae require Terraforming 2.
/// - Black holes, supernovae, and folds-in-space are never colonizable.
extension HexTerrainColonization on HexTerrain {
  bool isColonizable(int terraformingLevel) {
    switch (this) {
      case HexTerrain.deepSpace:
        return true;
      case HexTerrain.asteroid:
        return terraformingLevel >= 1;
      case HexTerrain.nebula:
        return terraformingLevel >= 2;
      case HexTerrain.blackHole:
      case HexTerrain.supernova:
      case HexTerrain.foldInSpace:
        return false;
    }
  }

  String get displayName {
    switch (this) {
      case HexTerrain.deepSpace:
        return 'Deep Space';
      case HexTerrain.asteroid:
        return 'Asteroid Belt';
      case HexTerrain.nebula:
        return 'Nebula';
      case HexTerrain.blackHole:
        return 'Black Hole';
      case HexTerrain.supernova:
        return 'Supernova';
      case HexTerrain.foldInSpace:
        return 'Fold-in-Space';
    }
  }
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
  final int shipyardCount;
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
    this.shipyardCount = 0,
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
    int? shipyardCount,
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
        shipyardCount: shipyardCount ?? this.shipyardCount,
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
        'shipyardCount': shipyardCount,
        'notes': notes,
      };

  factory MapHexState.fromJson(Map<String, dynamic> json) {
    final coord = HexCoord.fromJson(
      json['coord'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    // pipelineIds removed: legacy 'pipelineIds' / 'pipelines' keys are
    // silently ignored on load. Pipeline income is tracked exclusively by
    // ProductionState.pipelineConnectedColonies (Layer 2).

    return MapHexState(
      coord: coord,
      terrain: _terrainFromName(json['terrain'] as String?),
      explored: json['explored'] as bool? ?? false,
      label: json['label'] as String? ?? '',
      worldId: json['worldId'] as String?,
      minerals: json['minerals'] as int? ?? 0,
      wrecks: json['wrecks'] as int? ?? 0,
      mines: json['mines'] as int? ?? 0,
      // Legacy 'industryMarkers' / 'researchMarkers' keys are silently
      // dropped — they never affected economy.
      shipyardCount: json['shipyardCount'] as int? ?? 0,
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
  final bool hasMovedThisTurn;

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
    this.hasMovedThisTurn = false,
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
    bool? hasMovedThisTurn,
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
        hasMovedThisTurn: hasMovedThisTurn ?? this.hasMovedThisTurn,
      );

  FleetStackState movedTo(HexCoord coord) => copyWith(coord: coord);

  /// Returns a copy of this fleet with the moved-this-turn flag set.
  FleetStackState markMoved() => copyWith(hasMovedThisTurn: true);

  /// Returns a copy of this fleet with the moved-this-turn flag cleared.
  FleetStackState clearMoveFlag() => copyWith(hasMovedThisTurn: false);

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
        'hasMovedThisTurn': hasMovedThisTurn,
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
        hasMovedThisTurn: json['hasMovedThisTurn'] as bool? ?? false,
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

  /// Moves [fleetId] to [coord] and auto-reveals the destination hex per
  /// rule 6.1 (Exploration Procedure): when a unit enters/shares a hex with
  /// an unexplored System marker, it is explored and flipped face-up.
  ///
  /// If the owning player's [explorationLevel] is >= 1, Exploration 1 tech
  /// (rule 9.8) additionally reveals adjacent unexplored hexes. Higher
  /// levels extend the reveal ring out to [explorationLevel] hexes from
  /// the destination. Enemy fleet moves (isEnemy == true) never reveal —
  /// only the moving player owns the exploration knowledge.
  ///
  /// This is the low-level "force move" entry point — it does NOT enforce
  /// movement allowance or the "already moved this turn" flag. For the
  /// validated drag-drop path used by the map UI, see
  /// [moveFleetWithAllowance].
  GameMapState moveFleet(
    String fleetId,
    HexCoord coord, {
    int explorationLevel = 0,
  }) {
    final fleet = fleetById(fleetId);
    if (fleet == null) return this;
    final moved = replaceFleet(fleet.movedTo(coord));
    if (fleet.isEnemy) {
      return moved;
    }
    return moved._revealAround(coord, explorationLevel);
  }

  /// Returns the lowest [ShipCounter.move] value across the ships that are
  /// actually present in [fleet]. Returns null if the fleet has no ships
  /// (in which case callers typically fall back to the player's Move tech
  /// level — see [fleetMoveAllowance]). Ships with a non-positive move
  /// value are skipped so an unbuilt/zeroed counter can't collapse the
  /// whole fleet to zero.
  int? slowestShipMoveInFleet(
    FleetStackState fleet,
    List<ShipCounter> shipCounters,
  ) {
    if (fleet.shipCounterIds.isEmpty) return null;
    int? minMove;
    for (final id in fleet.shipCounterIds) {
      ShipCounter? match;
      for (final c in shipCounters) {
        if (c.id == id) {
          match = c;
          break;
        }
      }
      if (match == null) continue;
      final m = match.move;
      if (m <= 0) continue;
      if (minMove == null || m < minMove) minMove = m;
    }
    return minMove;
  }

  /// Returns the effective move allowance for [fleet]: the slowest ship in
  /// the fleet, or [playerMoveLevel] when the fleet has no ships to sample
  /// (an empty fleet is a hypothetical — use the player's tech level as a
  /// sensible fallback).
  int fleetMoveAllowance(
    FleetStackState fleet,
    List<ShipCounter> shipCounters,
    int playerMoveLevel,
  ) {
    return slowestShipMoveInFleet(fleet, shipCounters) ?? playerMoveLevel;
  }

  /// Returns the set of hex coordinates reachable by [fleet] given the
  /// [allowance]. Walks every hex on the map and includes those within
  /// Chebyshev distance <= allowance. Excludes the fleet's current hex.
  ///
  /// This is deliberately a flat distance check — no terrain blocking,
  /// no enemy interception, no pathfinding. Per SE4X simplification: deep
  /// space and most terrains allow passage, and the rules enforcement for
  /// the rest happens at a higher layer.
  Set<HexCoord> reachableHexes(FleetStackState fleet, int allowance) {
    final result = <HexCoord>{};
    if (allowance <= 0) return result;
    for (final hex in hexes) {
      if (hex.coord == fleet.coord) continue;
      if (fleet.coord.distanceTo(hex.coord) <= allowance) {
        result.add(hex.coord);
      }
    }
    return result;
  }

  /// Validated drag-drop entry point for fleet moves.
  ///
  /// Enforces:
  ///   - Fleet cannot have already moved this turn.
  ///   - Destination must be within [allowance] hexes of the fleet's
  ///     current position (Chebyshev distance).
  ///
  /// On a successful move, the fleet is marked as moved-this-turn and
  /// delegated to [moveFleet] for auto-reveal. On a rejected move, the
  /// state is returned unchanged.
  GameMapState moveFleetWithAllowance(
    String fleetId,
    HexCoord target, {
    required int allowance,
    required List<ShipCounter> shipCounters,
    int explorationLevel = 0,
  }) {
    final fleet = fleetById(fleetId);
    if (fleet == null) return this;
    if (fleet.hasMovedThisTurn) return this;
    if (fleet.coord == target) return this;
    if (fleet.coord.distanceTo(target) > allowance) return this;
    // Mark as moved before delegating to base moveFleet so the flipped
    // flag survives the subsequent replaceFleet(fleet.movedTo(...)) call.
    final markedFleet = fleet.copyWith(hasMovedThisTurn: true);
    final intermediate = replaceFleet(markedFleet);
    return intermediate.moveFleet(
      fleetId,
      target,
      explorationLevel: explorationLevel,
    );
  }

  /// Clears the moved-this-turn flag on every fleet. Called at end-turn
  /// so the next turn starts with all fleets free to move again.
  GameMapState clearAllFleetMoveFlags() {
    if (fleets.every((f) => !f.hasMovedThisTurn)) return this;
    return copyWith(
      fleets: [for (final f in fleets) f.copyWith(hasMovedThisTurn: false)],
    );
  }

  /// Flips [center] to explored, plus any hex within [explorationRange]
  /// hexes of it. A range of 0 only reveals the center hex (rule 6.1).
  GameMapState _revealAround(HexCoord center, int explorationRange) {
    final range = explorationRange < 0 ? 0 : explorationRange;
    var changed = false;
    final nextHexes = <MapHexState>[];
    for (final hex in hexes) {
      if (!hex.explored && hex.coord.distanceTo(center) <= range) {
        nextHexes.add(hex.copyWith(explored: true));
        changed = true;
      } else {
        nextHexes.add(hex);
      }
    }
    if (!changed) return this;
    return copyWith(hexes: nextHexes);
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

  /// Find friendly ship IDs from [candidateShipIds] that sit on a colonizable
  /// hex without an existing world, given the current [terraformingLevel].
  List<ColonizeCandidate> findColonizeCandidates({
    required Set<String> candidateShipIds,
    required int terraformingLevel,
  }) {
    if (candidateShipIds.isEmpty) return const [];
    final occupiedCoordIds = <String>{
      for (final hex in hexes)
        if (hex.worldId != null && hex.worldId!.isNotEmpty) hex.coord.id,
    };
    final out = <ColonizeCandidate>[];
    for (final fleet in fleets) {
      if (fleet.isEnemy) continue;
      final hex = hexAt(fleet.coord);
      if (hex == null) continue;
      if (occupiedCoordIds.contains(hex.coord.id)) continue;
      if (!hex.terrain.isColonizable(terraformingLevel)) continue;
      for (final shipId in fleet.shipCounterIds) {
        if (!candidateShipIds.contains(shipId)) continue;
        out.add(ColonizeCandidate(
          shipId: shipId,
          fleetId: fleet.id,
          coord: hex.coord,
          terrain: hex.terrain,
        ));
      }
    }
    return out;
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
  }) {
    final seenWorldIds = <String>{};
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

      nextHexes.add(
        hex.copyWith(
          worldId: normalizedWorldId,
          clearWorldId: normalizedWorldId == null,
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
    final rawHexList = json['hexes'] as List?;
    final storedHexes = rawHexList
            ?.map((hex) => MapHexState.fromJson(hex as Map<String, dynamic>))
            .toList() ??
        const <MapHexState>[];
    // One-time legacy migration: if no stored hex has shipyardCount key, seed
    // any HW-bearing hex with a starting shipyard of 1.
    final hasAnyShipyardKey = rawHexList != null &&
        rawHexList.any((h) => h is Map<String, dynamic> && h.containsKey('shipyardCount'));
    final migratedHexes = hasAnyShipyardKey
        ? storedHexes
        : [
            for (final hex in storedHexes)
              hex.worldId != null && hex.worldId!.isNotEmpty
                  ? hex.copyWith(shipyardCount: 1)
                  : hex,
          ];
    // Canonical coord set for the active preset. Any persisted hex or fleet
    // sitting outside this set is an orphan from a prior layout revision and
    // gets dropped silently so rendering never hits a phantom/missing coord.
    final validCoordIds = <String>{
      for (final hex in defaultHexesFor(layoutPreset)) hex.coord.id,
    };
    final defaultsById = {
      for (final hex in defaultHexesFor(layoutPreset)) hex.coord.id: hex,
    };
    for (final hex in migratedHexes) {
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

/// Result of [GameMapState.findColonizeCandidates]: one friendly ship sitting
/// on a colonizable hex that has no world on it yet.
class ColonizeCandidate {
  final String shipId;
  final String fleetId;
  final HexCoord coord;
  final HexTerrain terrain;

  const ColonizeCandidate({
    required this.shipId,
    required this.fleetId,
    required this.coord,
    required this.terrain,
  });
}

class _RowSpec {
  final int start;
  final int length;

  const _RowSpec({
    required this.start,
    required this.length,
  });
}
