// Top-level game state, saved game wrapper, and app state.

import 'alien_economy.dart';
import 'game_config.dart';
import 'game_modifier.dart';
import 'production_state.dart';
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

  const GameState({
    this.config = const GameConfig(),
    this.turnNumber = 1,
    this.production = const ProductionState(),
    this.shipCounters = const [],
    this.alienPlayers = const [],
    this.turnSummaries = const [],
    this.activeModifiers = const [],
  });

  GameState copyWith({
    GameConfig? config,
    int? turnNumber,
    ProductionState? production,
    List<ShipCounter>? shipCounters,
    List<AlienPlayer>? alienPlayers,
    List<TurnSummary>? turnSummaries,
    List<GameModifier>? activeModifiers,
  }) =>
      GameState(
        config: config ?? this.config,
        turnNumber: turnNumber ?? this.turnNumber,
        production: production ?? this.production,
        shipCounters: shipCounters ?? this.shipCounters,
        alienPlayers: alienPlayers ?? this.alienPlayers,
        turnSummaries: turnSummaries ?? this.turnSummaries,
        activeModifiers: activeModifiers ?? this.activeModifiers,
      );

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'turnNumber': turnNumber,
        'production': production.toJson(),
        'shipCounters': shipCounters.map((c) => c.toJson()).toList(),
        'alienPlayers': alienPlayers.map((a) => a.toJson()).toList(),
        'turnSummaries': turnSummaries.map((s) => s.toJson()).toList(),
        'activeModifiers': activeModifiers.map((m) => m.toJson()).toList(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        config: json['config'] != null
            ? GameConfig.fromJson(json['config'] as Map<String, dynamic>)
            : const GameConfig(),
        turnNumber: json['turnNumber'] as int? ?? 1,
        production: json['production'] != null
            ? ProductionState.fromJson(
                json['production'] as Map<String, dynamic>)
            : const ProductionState(),
        shipCounters: (json['shipCounters'] as List?)
                ?.map((c) =>
                    ShipCounter.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        alienPlayers: (json['alienPlayers'] as List?)
                ?.map((a) =>
                    AlienPlayer.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
        turnSummaries: (json['turnSummaries'] as List?)
                ?.map((s) =>
                    TurnSummary.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        activeModifiers: (json['activeModifiers'] as List?)
                ?.map((m) =>
                    GameModifier.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
      );
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
  }) =>
      SavedGame(
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

  const AppState({
    this.activeGameId,
    this.games = const [],
  });

  AppState copyWith({
    String? activeGameId,
    bool clearActiveGameId = false,
    List<SavedGame>? games,
  }) =>
      AppState(
        activeGameId:
            clearActiveGameId ? null : (activeGameId ?? this.activeGameId),
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
      games: (migrated['games'] as List?)
              ?.map(
                  (g) => SavedGame.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Migrate save data from [fromVersion] to the current version.
  /// Version 0 and 1 are identical (no migration needed).
  static Map<String, dynamic> _migrate(
      Map<String, dynamic> json, int fromVersion) {
    var data = json;
    // Future migrations go here as incremental steps:
    // if (fromVersion < 2) { data = _migrateV1toV2(data); }
    return data;
  }
}
