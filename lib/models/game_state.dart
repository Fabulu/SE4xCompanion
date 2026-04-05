// Top-level game state, saved game wrapper, and app state.

import '../data/ship_definitions.dart';
import 'alien_economy.dart';
import 'drawn_card.dart';
import 'game_config.dart';
import 'game_modifier.dart';
import 'map_state.dart';
import 'production_state.dart';
import 'replicator_player_state.dart';
import 'replicator_state.dart';
import 'ship_counter.dart';
import 'turn_summary.dart';

class GameState {
  final GameConfig config;
  final int turnNumber;
  final ProductionState production;
  final List<ShipCounter> shipCounters;
  final List<AlienPlayer> alienPlayers;
  final List<TurnSummary> turnSummaries;
  final List<GameModifier> activeModifiers;

  /// Cards the player has drawn and is holding in hand (T3-C).
  /// Unlike `activeModifiers` (one-shot application), these persist as
  /// real card state until played or discarded.
  final List<DrawnCard> drawnHand;

  /// Alternate Empire: random special abilities per ship type (Rule 24.2/24.3).
  final Map<ShipType, int> shipSpecialAbilities;

  /// Victory Points for solo/coop scenarios (DM VP, Alien VP).
  final int victoryPoints;

  /// Replicator opponent state (null when not a replicator game).
  final ReplicatorState? replicatorState;

  /// Player-controlled Replicator economy state.
  final ReplicatorPlayerState? replicatorPlayerState;

  /// Manual board state for the native map tab.
  final GameMapState mapState;

  const GameState({
    this.config = const GameConfig(),
    this.turnNumber = 1,
    this.production = const ProductionState(),
    this.shipCounters = const [],
    this.alienPlayers = const [],
    this.turnSummaries = const [],
    this.activeModifiers = const [],
    this.drawnHand = const [],
    this.shipSpecialAbilities = const {},
    this.victoryPoints = 0,
    this.replicatorState,
    this.replicatorPlayerState,
    this.mapState = const GameMapState(
      layoutPreset: MapLayoutPreset.standard4p,
      hexes: [],
    ),
  });

  GameState copyWith({
    GameConfig? config,
    int? turnNumber,
    ProductionState? production,
    List<ShipCounter>? shipCounters,
    List<AlienPlayer>? alienPlayers,
    List<TurnSummary>? turnSummaries,
    List<GameModifier>? activeModifiers,
    List<DrawnCard>? drawnHand,
    Map<ShipType, int>? shipSpecialAbilities,
    int? victoryPoints,
    ReplicatorState? replicatorState,
    ReplicatorPlayerState? replicatorPlayerState,
    GameMapState? mapState,
    bool clearReplicatorState = false,
    bool clearReplicatorPlayerState = false,
  }) => GameState(
    config: config ?? this.config,
    turnNumber: turnNumber ?? this.turnNumber,
    production: production ?? this.production,
    shipCounters: shipCounters ?? this.shipCounters,
    alienPlayers: alienPlayers ?? this.alienPlayers,
    turnSummaries: turnSummaries ?? this.turnSummaries,
    activeModifiers: activeModifiers ?? this.activeModifiers,
    drawnHand: drawnHand ?? this.drawnHand,
    shipSpecialAbilities: shipSpecialAbilities ?? this.shipSpecialAbilities,
    victoryPoints: victoryPoints ?? this.victoryPoints,
    replicatorState: clearReplicatorState
        ? null
        : (replicatorState ?? this.replicatorState),
    replicatorPlayerState: clearReplicatorPlayerState
        ? null
        : (replicatorPlayerState ?? this.replicatorPlayerState),
    mapState: mapState ?? this.mapState,
  );

  Map<String, dynamic> toJson() => {
    'config': config.toJson(),
    'turnNumber': turnNumber,
    'production': production.toJson(),
    'shipCounters': shipCounters.map((c) => c.toJson()).toList(),
    'alienPlayers': alienPlayers.map((a) => a.toJson()).toList(),
    'turnSummaries': turnSummaries.map((s) => s.toJson()).toList(),
    'activeModifiers': activeModifiers.map((m) => m.toJson()).toList(),
    'drawnHand': drawnHand.map((c) => c.toJson()).toList(),
    'shipSpecialAbilities': shipSpecialAbilities.map(
      (k, v) => MapEntry(k.name, v),
    ),
    'victoryPoints': victoryPoints,
    if (replicatorState != null) 'replicatorState': replicatorState!.toJson(),
    if (replicatorPlayerState != null)
      'replicatorPlayerState': replicatorPlayerState!.toJson(),
    'mapState': mapState.hexes.isEmpty
        ? GameMapState.initial(layoutPreset: mapState.layoutPreset).toJson()
        : mapState.toJson(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawAbilities =
        json['shipSpecialAbilities'] as Map<String, dynamic>? ?? {};
    final abilities = <ShipType, int>{};
    for (final e in rawAbilities.entries) {
      final type = _shipTypeFromName(e.key);
      if (type != null) abilities[type] = e.value as int;
    }

    final production = json['production'] != null
        ? ProductionState.fromJson(json['production'] as Map<String, dynamic>)
        : const ProductionState();
    final rawMapState = json['mapState'] != null
        ? GameMapState.fromJson(json['mapState'] as Map<String, dynamic>)
        : GameMapState.initial();
    final legacyPipelineIds = {
      for (final hex in rawMapState.hexes) ...hex.pipelineIds,
    };
    final normalizedProduction =
        production.pipelineConnectedColonies == 0 &&
            legacyPipelineIds.isNotEmpty
        ? production.copyWith(
            pipelineConnectedColonies: legacyPipelineIds.length,
          )
        : production;
    final shipCounters =
        (json['shipCounters'] as List?)
            ?.map((c) => ShipCounter.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const <ShipCounter>[];
    final worldIdByName = {
      for (final world in normalizedProduction.worlds) world.name: world.id,
    };
    final validWorldIds = normalizedProduction.worlds
        .map((world) => world.id)
        .toSet();
    final validShipIds = shipCounters
        .where((counter) => counter.isBuilt)
        .map((counter) => counter.id)
        .toSet();
    final validPipelineIds = normalizedProduction.pipelineAssetIds.toSet();
    final mapState = rawMapState
        .migrateLegacyWorldNames(worldIdByName)
        .sanitizeAgainstLedger(
          validWorldIds: validWorldIds,
          validShipIds: validShipIds,
          validPipelineIds: validPipelineIds,
        );

    return GameState(
      config: json['config'] != null
          ? GameConfig.fromJson(json['config'] as Map<String, dynamic>)
          : const GameConfig(),
      turnNumber: json['turnNumber'] as int? ?? 1,
      production: normalizedProduction,
      shipCounters: shipCounters,
      alienPlayers:
          (json['alienPlayers'] as List?)
              ?.map((a) => AlienPlayer.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      turnSummaries:
          (json['turnSummaries'] as List?)
              ?.map((s) => TurnSummary.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      activeModifiers:
          (json['activeModifiers'] as List?)
              ?.map((m) => GameModifier.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      drawnHand:
          (json['drawnHand'] as List?)
              ?.map((c) => DrawnCard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      shipSpecialAbilities: abilities,
      victoryPoints: json['victoryPoints'] as int? ?? 0,
      replicatorState: json['replicatorState'] != null
          ? ReplicatorState.fromJson(
              json['replicatorState'] as Map<String, dynamic>,
            )
          : null,
      replicatorPlayerState: json['replicatorPlayerState'] != null
          ? ReplicatorPlayerState.fromJson(
              json['replicatorPlayerState'] as Map<String, dynamic>,
            )
          : null,
      mapState: mapState,
    );
  }

  /// Whether the most recently committed turn carries a full
  /// [ProductionState] snapshot and can therefore be reopened.
  bool get canReopenLastTurn =>
      turnSummaries.isNotEmpty &&
      turnSummaries.last.productionSnapshot != null;

  /// Return a copy of this state with the most recently committed turn
  /// reopened: the last [TurnSummary] is popped, [production] is restored
  /// from its snapshot, and [turnNumber] rewinds to that turn.
  ///
  /// When the summary carries a full [TurnSummary.gameStateSnapshot] we
  /// additionally restore `drawnHand`, `activeModifiers`, and
  /// `shipCounters` to their end-of-turn state, so card plays,
  /// modifier application, and T3-A materialization performed during
  /// the committed turn all roll back in sync. Legacy summaries only
  /// carry [TurnSummary.productionSnapshot]; in that case we fall back
  /// to restoring only production + turnNumber.
  ///
  /// Returns `this` unchanged when [canReopenLastTurn] is false.
  GameState reopenLastTurn() {
    if (!canReopenLastTurn) return this;
    final last = turnSummaries.last;
    final gss = last.gameStateSnapshot;
    final nextSummaries = turnSummaries.sublist(0, turnSummaries.length - 1);

    if (gss == null) {
      // Legacy path: only production + turnNumber are restored.
      return copyWith(
        production: last.productionSnapshot,
        turnSummaries: nextSummaries,
        turnNumber: last.turnNumber,
      );
    }

    // Full snapshot path: restore production, drawnHand, activeModifiers,
    // shipCounters from the snapshot. The ProductionState in the
    // snapshot map takes precedence; fall back to productionSnapshot.
    ProductionState restoredProduction = last.productionSnapshot ?? production;
    final rawProd = gss['production'];
    if (rawProd is Map<String, dynamic>) {
      restoredProduction = ProductionState.fromJson(rawProd);
    } else if (rawProd is Map) {
      restoredProduction =
          ProductionState.fromJson(Map<String, dynamic>.from(rawProd));
    }

    List<DrawnCard> restoredDrawnHand = drawnHand;
    final rawDrawn = gss['drawnHand'];
    if (rawDrawn is List) {
      restoredDrawnHand = rawDrawn
          .map((c) => c is Map<String, dynamic>
              ? DrawnCard.fromJson(c)
              : DrawnCard.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    }

    List<GameModifier> restoredModifiers = activeModifiers;
    final rawMods = gss['activeModifiers'];
    if (rawMods is List) {
      restoredModifiers = rawMods
          .map((m) => m is Map<String, dynamic>
              ? GameModifier.fromJson(m)
              : GameModifier.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    List<ShipCounter> restoredCounters = shipCounters;
    final rawCounters = gss['shipCounters'];
    if (rawCounters is List) {
      restoredCounters = rawCounters
          .map((c) => c is Map<String, dynamic>
              ? ShipCounter.fromJson(c)
              : ShipCounter.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    }

    return copyWith(
      production: restoredProduction,
      drawnHand: restoredDrawnHand,
      activeModifiers: restoredModifiers,
      shipCounters: restoredCounters,
      turnSummaries: nextSummaries,
      turnNumber: last.turnNumber,
    );
  }

  static ShipType? _shipTypeFromName(String name) {
    for (final t in ShipType.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

class SavedGame {
  final String id;
  final String name;
  final DateTime updatedAt;
  final GameState state;
  final bool isArchived;

  const SavedGame({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.state = const GameState(),
    this.isArchived = false,
  });

  SavedGame copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    GameState? state,
    bool? isArchived,
  }) => SavedGame(
    id: id ?? this.id,
    name: name ?? this.name,
    updatedAt: updatedAt ?? this.updatedAt,
    state: state ?? this.state,
    isArchived: isArchived ?? this.isArchived,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'updatedAt': updatedAt.toIso8601String(),
    'state': state.toJson(),
    'isArchived': isArchived,
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    state: json['state'] != null
        ? GameState.fromJson(json['state'] as Map<String, dynamic>)
        : const GameState(),
    isArchived: json['isArchived'] as bool? ?? false,
  );
}

class AppState {
  final String? activeGameId;
  final List<SavedGame> games;

  const AppState({this.activeGameId, this.games = const []});

  AppState copyWith({
    String? activeGameId,
    bool clearActiveGameId = false,
    List<SavedGame>? games,
  }) => AppState(
    activeGameId: clearActiveGameId
        ? null
        : (activeGameId ?? this.activeGameId),
    games: games ?? this.games,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'activeGameId': activeGameId,
    'games': games.map((g) => g.toJson()).toList(),
  };

  factory AppState.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 0;
    final migrated = _migrate(json, version);
    return AppState(
      activeGameId: migrated['activeGameId'] as String?,
      games:
          (migrated['games'] as List?)
              ?.map((g) => SavedGame.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Migrate save data from [fromVersion] to the current version.
  /// Version 0 and 1 are identical (no migration needed).
  static Map<String, dynamic> _migrate(
    Map<String, dynamic> json,
    int fromVersion,
  ) {
    var data = json;
    // Future migrations go here as incremental steps:
    // if (fromVersion < 2) { data = _migrateV1toV2(data); }
    return data;
  }
}
