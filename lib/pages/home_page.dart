import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/scenarios.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/alien_economy.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../models/map_state.dart';
import '../models/production_state.dart';
import '../models/replicator_state.dart';
import '../models/ship_counter.dart';
import '../models/technology.dart';
import '../models/turn_summary.dart';
import '../models/world.dart';
import '../services/persistence_service.dart';
import '../widgets/new_game_wizard.dart';
import '../widgets/space_hockey_game.dart';
import '../widgets/starting_fleet_dialog.dart';
import '../widgets/vp_tracker.dart';
import 'alien_economy_page.dart';
import 'map_page.dart';
import 'production_page.dart';
import 'replicator_page.dart';
import 'rules_reference_page.dart';
import 'settings_page.dart';
import 'ship_tech_page.dart';

enum _TabId { production, map, shipTech, aliens, replicator, rules, settings }

class _TabDef {
  final _TabId id;
  final IconData icon;
  final String label;
  const _TabDef({required this.id, required this.icon, required this.label});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  final PersistenceService _persistence = PersistenceService();

  AppState _appState = const AppState();
  GameState _gameState = const GameState();
  String _gameName = 'New Game';
  String _activeGameId = '';
  bool _isLoading = true;
  int _currentTabIndex = 0;

  List<_TabDef> get _visibleTabs {
    final tabs = <_TabDef>[
      const _TabDef(id: _TabId.production, icon: Icons.grid_on, label: 'Production'),
      const _TabDef(id: _TabId.map, icon: Icons.map_outlined, label: 'Map'),
      const _TabDef(id: _TabId.shipTech, icon: Icons.shield, label: 'Ships'),
    ];
    if (_gameState.alienPlayers.isNotEmpty) {
      tabs.add(const _TabDef(id: _TabId.aliens, icon: Icons.smart_toy, label: 'Aliens'));
    }
    if (_gameState.config.enableReplicators) {
      tabs.add(const _TabDef(id: _TabId.replicator, icon: Icons.bug_report, label: 'Replicator'));
    }
    tabs.add(const _TabDef(id: _TabId.rules, icon: Icons.menu_book, label: 'Rules'));
    tabs.add(const _TabDef(id: _TabId.settings, icon: Icons.settings, label: 'Settings'));
    return tabs;
  }

  _TabId get _currentTabId {
    final tabs = _visibleTabs;
    final idx = _currentTabIndex.clamp(0, tabs.length - 1);
    return tabs[idx].id;
  }

  void _selectTab(_TabId id) {
    final tabs = _visibleTabs;
    final idx = tabs.indexWhere((t) => t.id == id);
    if (idx >= 0) setState(() => _currentTabIndex = idx);
  }

  final _rulesKey = GlobalKey<RulesReferencePageState>();

  final List<GameState> _undoHistory = [];
  final List<String> _undoDescriptions = [];
  static const int _maxUndoHistory = 20;
  bool _lastActionWasEndTurn = false;

  Timer? _saveDebounce;

  // Task 3D: Turn number wiggle on tab change
  late AnimationController _turnWiggleController;
  late Animation<double> _turnWiggle;

  @override
  void initState() {
    super.initState();
    _loadState();

    _turnWiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _turnWiggle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.017), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.017, end: -0.017), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.017, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _turnWiggleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _turnWiggleController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final appState = await _persistence.load();
    if (appState != null && appState.games.isNotEmpty) {
      final activeId = appState.activeGameId ?? appState.games.first.id;
      final activeSave = appState.games.firstWhere(
        (g) => g.id == activeId,
        orElse: () => appState.games.first,
      );
      setState(() {
        _appState = appState;
        _gameState = _syncedMapState(activeSave.state);
        _gameName = activeSave.name;
        _activeGameId = activeSave.id;
        _isLoading = false;
        _undoHistory.clear();
        _lastActionWasEndTurn = false;
      });
    } else {
      // Create a default new game
      _createNewGame();
    }
  }

  void _createNewGame() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final defaultState = GameState(
      config: const GameConfig(),
      turnNumber: 1,
      production: const ProductionState(
        worlds: [WorldState(name: 'Homeworld', isHomeworld: true, homeworldValue: 30)],
      ),
      mapState: GameMapState.initial(),
      shipCounters: createAllCounters(),
      alienPlayers: const [],
    );
    final saved = SavedGame(
      id: id,
      name: 'New Game',
      updatedAt: DateTime.now(),
      state: defaultState,
    );
    final games = [..._appState.games, saved];
    setState(() {
      _appState = _appState.copyWith(games: games, activeGameId: id);
      _gameState = defaultState;
      _gameName = 'New Game';
      _activeGameId = id;
      _isLoading = false;
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
    });
    _save();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartingFleetDialog();
    });
  }

  void _createNewGameFromWizard(NewGameResult result) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final scenario = scenarioById(result.config.scenarioId);
    final config = _normalizeConfigForScenario(result.config, scenario);
    final hwValue = config.enableFacilities ? 20 : 30;

    // Build starting tech state from scenario overrides
    TechState startTech = const TechState();
    for (final entry in result.startingTechOverrides.entries) {
      startTech = startTech.setLevel(entry.key, entry.value);
    }

    final newState = GameState(
      config: config,
      turnNumber: 1,
      production: ProductionState(
        worlds: [WorldState(name: 'Homeworld', isHomeworld: true, homeworldValue: hwValue)],
        techState: startTech,
      ),
      mapState: GameMapState.initial(),
      shipCounters: createAllCounters(),
      alienPlayers: [
        for (int i = 0; i < result.alienPlayerCount; i++)
          AlienPlayer(name: 'Alien ${i + 1}', color: ['Red', 'Blue', 'Yellow'][i % 3]),
      ],
    );

    // Apply starting fleet by stamping counters
    var counters = newState.shipCounters;
    if (result.startingFleet != null) {
      final updated = List<ShipCounter>.from(counters);
      for (final entry in result.startingFleet!.entries) {
        int built = 0;
        for (int i = 0; i < updated.length && built < entry.value; i++) {
          if (updated[i].type == entry.key && !updated[i].isBuilt) {
            updated[i] = ShipCounter.stampFromTech(
              entry.key,
              updated[i].number,
              startTech,
              facilitiesMode: config.useFacilitiesCosts,
            );
            built++;
          }
        }
      }
      counters = updated;
    }

    var finalState = newState.copyWith(shipCounters: counters);

    finalState = _applyScenarioState(
      finalState,
      config: config,
      scenario: scenario,
      forceReplicator: result.isReplicatorGame,
      syncVictoryPoints: true,
      syncReplicatorSetup: true,
    );

    final saved = SavedGame(
      id: id,
      name: result.gameName,
      updatedAt: DateTime.now(),
      state: finalState,
    );
    final games = [..._appState.games, saved];
    setState(() {
      _appState = _appState.copyWith(games: games, activeGameId: id);
      _gameState = finalState;
      _gameName = result.gameName;
      _activeGameId = id;
      _isLoading = false;
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
    });
    _save();
  }

  Future<void> _showStartingFleetDialog() async {
    final preset = await showStartingFleetDialog(context);
    if (preset == null || preset.isEmpty) return;

    final updatedCounters = applyFleetPreset(
      _gameState.shipCounters,
      preset,
      _gameState.production.techState,
      _gameState.config.useFacilitiesCosts,
    );
    _updateGameState(_gameState.copyWith(shipCounters: updatedCounters));
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  void _save() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () async {
      final games = _appState.games.map((g) {
        if (g.id == _activeGameId) {
          return g.copyWith(
            name: _gameName,
            state: _gameState,
            updatedAt: DateTime.now(),
          );
        }
        return g;
      }).toList();
      final newAppState = _appState.copyWith(
        games: games,
        activeGameId: _activeGameId,
      );
      _appState = newAppState;
      await _persistence.save(newAppState);
    });
  }

  void _updateGameState(GameState newState, [String? description]) {
    setState(() {
      _undoHistory.add(_gameState);
      _undoDescriptions.add(description ?? 'Change');
      if (_undoHistory.length > _maxUndoHistory) {
        _undoHistory.removeAt(0);
        _undoDescriptions.removeAt(0);
      }
      _lastActionWasEndTurn = false;
      _gameState = newState;
    });
    _save();
  }

  // ---------------------------------------------------------------------------
  // State mutation handlers
  // ---------------------------------------------------------------------------

  void _onProductionChanged(ProductionState production) {
    final nextState = _syncedMapState(_gameState.copyWith(production: production));
    _updateGameState(nextState, 'Production');
  }

  void _onCountersChanged(List<ShipCounter> counters) {
    final nextState = _syncedMapState(_gameState.copyWith(shipCounters: counters));
    _updateGameState(nextState, 'Ship Tech');
  }

  void _onUpgradeCost(int cost) {
    final newUpgrades = _gameState.production.upgradesCp + cost;
    _onProductionChanged(
        _gameState.production.copyWith(upgradesCp: newUpgrades));
  }

  void _onGameStateOverride(GameState newState) {
    _updateGameState(newState, 'Manual Override');
  }

  void _onAlienPlayersChanged(List<AlienPlayer> aliens) {
    _updateGameState(
        _gameState.copyWith(alienPlayers: aliens), 'Alien Economy');
  }

  void _onMapChanged(
    GameMapState mapState, {
    bool recordUndo = true,
    String? description,
  }) {
    final nextState = _syncedMapState(_gameState.copyWith(mapState: mapState));
    if (recordUndo) {
      _updateGameState(nextState, description ?? 'Map');
      return;
    }
    setState(() {
      _gameState = nextState;
    });
    _save();
  }

  GameState _syncedMapState(GameState state) {
    final validWorldNames = state.production.worlds.map((world) => world.name).toSet();
    final validShipIds = state.shipCounters
        .where((counter) => counter.isBuilt)
        .map(_shipCounterId)
        .toSet();

    final nextHexes = [
      for (final hex in state.mapState.hexes)
        if (hex.worldName != null && !validWorldNames.contains(hex.worldName))
          hex.copyWith(clearWorldName: true)
        else
          hex,
    ];

    final nextFleets = <FleetStackState>[];
    for (final fleet in state.mapState.fleets) {
      if (fleet.isEnemy) {
        nextFleets.add(fleet);
        continue;
      }
      final shipCounterIds = fleet.shipCounterIds
          .where(validShipIds.contains)
          .toList();
      if (shipCounterIds.isEmpty) continue;
      nextFleets.add(
        fleet.copyWith(
          shipCounterIds: shipCounterIds,
          composition: const {},
        ),
      );
    }

    final selectedFleetId = nextFleets.any((fleet) => fleet.id == state.mapState.selectedFleetId)
        ? state.mapState.selectedFleetId
        : null;

    return state.copyWith(
      mapState: state.mapState.copyWith(
        hexes: nextHexes,
        fleets: nextFleets,
        selectedFleetId: selectedFleetId,
        clearSelectedFleetId: selectedFleetId == null,
      ),
    );
  }

  static String _shipCounterId(ShipCounter counter) =>
      '${counter.type.name}:${counter.number}';

  void _onEndTurn() {
    final prod = _gameState.production;
    final config = _gameState.config;
    final counters = _gameState.shipCounters;
    final fm = config.useFacilitiesCosts;

    // Compute techs gained
    final techsGained = <String>[];
    for (final entry in prod.pendingTechPurchases.entries) {
      final currentLevel = prod.techState.getLevel(entry.key, facilitiesMode: fm);
      final newLevel = entry.value;
      if (newLevel > currentLevel) {
        techsGained.add('${_techDisplayName(entry.key)} $currentLevel -> $newLevel');
      }
    }

    // Compute ships built
    final shipsBuilt = <String>[];
    for (final purchase in prod.shipPurchases) {
      final def = kShipDefinitions[purchase.type];
      final abbr = def?.abbreviation ?? purchase.type.name.toUpperCase();
      shipsBuilt.add('${purchase.quantity}x $abbr');
    }

    // Colonies grown: non-homeworld, non-blocked, growthMarkerLevel < 3
    final coloniesGrown = prod.worlds
        .where((w) => !w.isHomeworld && !w.isBlocked && w.growthMarkerLevel < 3)
        .length;

    // Resource calculations
    final mods = _gameState.activeModifiers;
    final remainingCp = prod.remainingCp(config, counters, mods, _gameState.shipSpecialAbilities);
    final remainingRp = config.enableFacilities ? prod.remainingRp(config, mods) : 0;
    final cpLostToCap = math.max(0, remainingCp - 30);
    final rpLostToCap = config.enableFacilities ? math.max(0, remainingRp - 30) : 0;
    final cpCarryOver = remainingCp.clamp(0, 30);
    final rpCarryOver = config.enableFacilities ? remainingRp.clamp(0, 30) : 0;
    final maintenancePaid = prod.maintenanceTotal(counters, config, mods);

    final summary = TurnSummary(
      turnNumber: _gameState.turnNumber,
      completedAt: DateTime.now(),
      techsGained: techsGained,
      shipsBuilt: shipsBuilt,
      coloniesGrown: coloniesGrown,
      cpLostToCap: cpLostToCap,
      rpLostToCap: rpLostToCap,
      cpCarryOver: cpCarryOver,
      rpCarryOver: rpCarryOver,
      maintenancePaid: maintenancePaid,
    );

    final nextProduction = prod.prepareForNextTurn(config, counters, mods, _gameState.shipSpecialAbilities);
    _updateGameState(
      _gameState.copyWith(
        turnNumber: _gameState.turnNumber + 1,
        production: nextProduction,
        turnSummaries: [..._gameState.turnSummaries, summary],
      ),
      'End Turn ${_gameState.turnNumber}',
    );
    _lastActionWasEndTurn = true;
  }

  static String _techDisplayName(TechId id) {
    const names = <TechId, String>{
      TechId.shipSize: 'Ship Size',
      TechId.attack: 'Attack',
      TechId.defense: 'Defense',
      TechId.tactics: 'Tactics',
      TechId.move: 'Move',
      TechId.shipYard: 'Ship Yard',
      TechId.terraforming: 'Terraforming',
      TechId.exploration: 'Exploration',
      TechId.fighters: 'Fighters',
      TechId.pointDefense: 'Point Defense',
      TechId.cloaking: 'Cloaking',
      TechId.scanners: 'Scanners',
      TechId.mines: 'Mines',
      TechId.mineSweep: 'Mine Sweep',
      TechId.ground: 'Ground',
      TechId.boarding: 'Boarding',
      TechId.securityForces: 'Security Forces',
      TechId.missileBoats: 'Missile Boats',
      TechId.fastBcAbility: 'Fast BC',
      TechId.militaryAcad: 'Military Acad',
      TechId.supplyRange: 'Supply Range',
      TechId.advancedCon: 'Advanced Con',
      TechId.antiReplicator: 'Anti-Replicator',
      TechId.jammers: 'Jammers',
      TechId.tractorBeamBb: 'Tractor Beam (BB)',
      TechId.shieldProjDn: 'Shield Proj (DN)',
    };
    return names[id] ?? id.name;
  }

  void _undo() {
    if (_undoHistory.isEmpty) return;
    if (_lastActionWasEndTurn) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Undo End Turn?'),
          content: const Text('This will revert to the previous turn.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Undo'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) _performUndo();
      });
    } else {
      _performUndo();
    }
  }

  void _performUndo() {
    if (_undoHistory.isEmpty) return;
    setState(() {
      _gameState = _undoHistory.removeLast();
      _undoDescriptions.removeLast();
      _lastActionWasEndTurn = false;
    });
    _save();
  }

  void _navigateToRule(String sectionId) {
    _selectTab(_TabId.rules);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rulesKey.currentState?.jumpToSection(sectionId);
    });
  }

  void _onConfigChanged(GameConfig config) {
    // Check if EA was just selected and has starting tech overrides
    final ea = config.empireAdvantage;
    final oldEa = _gameState.config.empireAdvantage;
    final scenario = scenarioById(config.scenarioId);
    final normalizedConfig = _normalizeConfigForScenario(config, scenario);
    final scenarioChanged =
        normalizedConfig.scenarioId != _gameState.config.scenarioId;
    final replicatorModeChanged =
        normalizedConfig.enableReplicators != _gameState.config.enableReplicators;
    var nextState = _applyScenarioState(
      _gameState.copyWith(config: normalizedConfig),
      config: normalizedConfig,
      scenario: scenario,
      syncVictoryPoints: scenarioChanged,
      syncReplicatorSetup: scenarioChanged || replicatorModeChanged,
    );
    if (ea != null && ea != oldEa && ea.startingTechOverrides.isNotEmpty) {
      // Auto-apply starting tech overrides
      var newTechState = nextState.production.techState;
      for (final entry in ea.startingTechOverrides.entries) {
        final currentLevel = newTechState.getLevel(entry.key, facilitiesMode: normalizedConfig.useFacilitiesCosts);
        if (entry.value > currentLevel) {
          newTechState = newTechState.setLevel(entry.key, entry.value);
        }
      }
      final newProduction = nextState.production.copyWith(techState: newTechState);
      nextState = nextState.copyWith(production: newProduction);
      _updateGameState(nextState, 'Empire Advantage: ${ea.name}');
    } else {
      _updateGameState(nextState, 'Settings');
    }
  }

  GameState _applyScenarioState(
    GameState state, {
    required GameConfig config,
    ScenarioPreset? scenario,
    bool forceReplicator = false,
    bool syncVictoryPoints = false,
    bool syncReplicatorSetup = false,
  }) {
    var result = state;
    final vpConfig = scenario?.victoryPoints;
    if (syncVictoryPoints) {
      result = result.copyWith(victoryPoints: vpConfig?.startingPoints ?? 0);
    }

    final shouldHaveReplicator = forceReplicator || config.enableReplicators;
    if (shouldHaveReplicator && (syncReplicatorSetup || result.replicatorState == null)) {
      result = result.copyWith(
        replicatorState: ReplicatorState.fromScenario(
          config.scenarioId,
          difficulty: config.replicatorDifficulty,
        ),
      );
    } else if (result.replicatorState != null) {
      result = result.copyWith(clearReplicatorState: true);
    }
    return result;
  }

  GameConfig _normalizeConfigForScenario(
    GameConfig config,
    ScenarioPreset? scenario,
  ) {
    if (scenario?.replicatorSetup == null) return config;
    return config.copyWith(
      enableFacilities: false,
      enableShipExperience: false,
      enableReplicators: true,
      scenarioBlockedShips: [
        ...config.scenarioBlockedShips,
        if (!config.scenarioBlockedShips.contains(ShipType.decoy))
          ShipType.decoy,
      ],
    );
  }

  void _onGameNameChanged(String name) {
    setState(() {
      _gameName = name;
    });
    _save();
  }

  void _onNewGame() async {
    final result = await showNewGameWizard(context);
    if (result == null) return;
    _createNewGameFromWizard(result);
  }

  void _onLoadGame(String gameId) {
    final target = _appState.games.firstWhere(
      (g) => g.id == gameId,
      orElse: () => _appState.games.first,
    );
    setState(() {
      _activeGameId = target.id;
      _gameState = _syncedMapState(target.state);
      _gameName = target.name;
      _appState = _appState.copyWith(activeGameId: target.id);
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
    });
    _save();
  }

  void _onRenameGame(String gameId, String newName) {
    final games = _appState.games.map((g) {
      if (g.id == gameId) {
        return g.copyWith(name: newName);
      }
      return g;
    }).toList();
    setState(() {
      _appState = _appState.copyWith(games: games);
      if (gameId == _activeGameId) {
        _gameName = newName;
      }
    });
    _save();
  }

  void _onDeleteGame(String gameId) {
    final games = _appState.games.where((g) => g.id != gameId).toList();
    if (games.isEmpty) {
      // Don't allow deleting the last game; create a new one instead
      setState(() {
        _appState = _appState.copyWith(games: const []);
      });
      _createNewGame();
      return;
    }

    String newActiveId = _activeGameId;
    GameState newGameState = _gameState;
    String newGameName = _gameName;

    if (gameId == _activeGameId) {
      // Switch to the first remaining game
      final next = games.first;
      newActiveId = next.id;
      newGameState = next.state;
      newGameName = next.name;
    }

    setState(() {
      _appState = _appState.copyWith(games: games, activeGameId: newActiveId);
      _activeGameId = newActiveId;
      _gameState = newGameState;
      _gameName = newGameName;
    });
    _save();
  }

  void _onDuplicateGame() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final saved = SavedGame(
      id: id,
      name: '$_gameName (copy)',
      updatedAt: DateTime.now(),
      state: _gameState,
    );
    final games = [..._appState.games, saved];
    setState(() {
      _appState = _appState.copyWith(games: games, activeGameId: id);
      _activeGameId = id;
      _gameName = saved.name;
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
    });
    _save();
  }

  void _onResetGame() {
    final defaultState = GameState(
      config: _gameState.config,
      turnNumber: 1,
      production: const ProductionState(
        worlds: [WorldState(name: 'Homeworld', isHomeworld: true, homeworldValue: 30)],
      ),
      mapState: GameMapState.initial(),
      shipCounters: createAllCounters(),
      alienPlayers: const [],
    );
    setState(() {
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
      _gameState = _syncedMapState(defaultState);
    });
    _save();
  }

  void _onImportGame(GameState importedState) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final saved = SavedGame(
      id: id,
      name: 'Imported Game',
      updatedAt: DateTime.now(),
      state: importedState,
    );
    final games = [..._appState.games, saved];
    setState(() {
      _appState = _appState.copyWith(games: games, activeGameId: id);
      _activeGameId = id;
      _gameState = _syncedMapState(importedState);
      _gameName = 'Imported Game';
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
    });
    _save();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final prod = _gameState.production;
    final config = _gameState.config;
    final counters = _gameState.shipCounters;
    final activeMods = _gameState.activeModifiers;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_undoHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: _undoDescriptions.isNotEmpty
                  ? 'Undo: ${_undoDescriptions.last}'
                  : 'Undo',
              onPressed: _undo,
            ),
        ],
        title: GestureDetector(
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SpaceHockeyGame()),
            );
          },
          child: AnimatedBuilder(
            animation: _turnWiggleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _turnWiggle.value,
                child: child,
              );
            },
            child: Text(
              '$_gameName  \u2022  Turn ${_gameState.turnNumber}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: _ResourceBar(
            totalCp: prod.totalCp(config, activeMods),
            maintenance: prod.maintenanceTotal(counters, config, activeMods),
            remainingCp: prod.remainingCp(config, counters, activeMods, _gameState.shipSpecialAbilities),
            remainingRp: config.enableFacilities ? prod.remainingRp(config, activeMods) : null,
            remainingLp: config.enableLogistics ? prod.remainingLp(config, counters, activeMods) : null,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTabIndex.clamp(0, _visibleTabs.length - 1),
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          _turnWiggleController.forward(from: 0);
        },
        items: [
          for (final tab in _visibleTabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon, size: 24),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final scenario = scenarioById(_gameState.config.scenarioId);
    final vpConfig = scenario?.victoryPoints;
    final content = switch (_currentTabId) {
      _TabId.production => ProductionPage(
          config: _gameState.config,
          turnNumber: _gameState.turnNumber,
          production: _gameState.production,
          shipCounters: _gameState.shipCounters,
          activeModifiers: _gameState.activeModifiers,
          shipSpecialAbilities: _gameState.shipSpecialAbilities,
          onProductionChanged: _onProductionChanged,
          onEndTurn: _onEndTurn,
          onRuleTap: _navigateToRule,
          onGameStateOverride: _onGameStateOverride,
        ),
      _TabId.map => MapPage(
          state: _gameState.mapState.hexes.isEmpty
              ? GameMapState.initial(layoutPreset: _gameState.mapState.layoutPreset)
              : _gameState.mapState,
          productionWorlds: _gameState.production.worlds,
          shipCounters: _gameState.shipCounters,
          onChanged: _onMapChanged,
        ),
      _TabId.shipTech => ShipTechPage(
          config: _gameState.config,
          turnNumber: _gameState.turnNumber,
          techState: _gameState.production.techState.withPending(
            _gameState.production.pendingTechPurchases,
          ),
          shipCounters: _gameState.shipCounters,
          showExperience: _gameState.config.enableShipExperience,
          shipSpecialAbilities: _gameState.shipSpecialAbilities,
          onCountersChanged: _onCountersChanged,
          onUpgradeCostIncurred: _onUpgradeCost,
          onRuleTap: _navigateToRule,
        ),
      _TabId.aliens => AlienEconomyPage(
          alienPlayers: _gameState.alienPlayers,
          onAlienPlayersChanged: _onAlienPlayersChanged,
        ),
      _TabId.replicator => ReplicatorPage(
          state: _gameState.replicatorState ?? const ReplicatorState(),
          onChanged: (newState) {
            _updateGameState(
              _gameState.copyWith(replicatorState: newState),
              'Replicator',
            );
          },
          onEndTurn: () {
            final repState = _gameState.replicatorState ?? const ReplicatorState();
            final updated = repState.endTurn();
            _updateGameState(
              _gameState.copyWith(replicatorState: updated),
              'Replicator End Turn',
            );
          },
        ),
      _TabId.settings => SettingsPage(
          config: _gameState.config,
          gameName: _gameName,
          turnNumber: _gameState.turnNumber,
          savedGames: _appState.games,
          activeGameId: _activeGameId,
          turnSummaries: _gameState.turnSummaries,
          gameState: _gameState,
          shipSpecialAbilities: _gameState.shipSpecialAbilities,
          onConfigChanged: _onConfigChanged,
          onGameNameChanged: _onGameNameChanged,
          onNewGame: _onNewGame,
          onLoadGame: _onLoadGame,
          onRenameGame: _onRenameGame,
          onDeleteGame: _onDeleteGame,
          onDuplicateGame: _onDuplicateGame,
          onResetGame: _onResetGame,
          onSetupStartingFleet: _showStartingFleetDialog,
          onImportGame: _onImportGame,
          onSpecialAbilitiesChanged: (abilities) {
            _updateGameState(
              _gameState.copyWith(shipSpecialAbilities: abilities),
              'Special Abilities',
            );
          },
        ),
      _TabId.rules => RulesReferencePage(key: _rulesKey),
    };

    if (vpConfig == null) return content;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: VpTracker(
            vp: _gameState.victoryPoints,
            label: vpConfig.label,
            thresholdHint: vpConfig.lossText,
            lossThreshold: vpConfig.lossThreshold,
            onChanged: (value) {
              _updateGameState(
                _gameState.copyWith(victoryPoints: value.clamp(0, 99)),
                '${vpConfig.label} Tracker',
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: content),
      ],
    );
  }
}

// =============================================================================
// Persistent resource bar shown under the AppBar on all tabs
// Task 3C: pop animation on remaining CP changes
// Task 3E: pulse when negative
// =============================================================================

class _ResourceBar extends StatefulWidget {
  final int totalCp;
  final int maintenance;
  final int remainingCp;
  final int? remainingRp;
  final int? remainingLp;

  const _ResourceBar({
    required this.totalCp,
    required this.maintenance,
    required this.remainingCp,
    this.remainingRp,
    this.remainingLp,
  });

  @override
  State<_ResourceBar> createState() => _ResourceBarState();
}

class _ResourceBarState extends State<_ResourceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _popScale;
  int? _prevRemainingCp;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOut,
    ));
    _prevRemainingCp = widget.remainingCp;
  }

  @override
  void didUpdateWidget(_ResourceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingCp != _prevRemainingCp) {
      _popController.forward(from: 0);
    }
    _prevRemainingCp = widget.remainingCp;
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = TextStyle(
      fontSize: 14,
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );
    final dimMono = mono.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
    final warnMono = mono.copyWith(
      color: theme.colorScheme.error,
      fontWeight: FontWeight.bold,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text('CP ', style: dimMono),
          Text('${widget.totalCp}', style: mono),
          const SizedBox(width: 12),
          Text('Mnt ', style: dimMono),
          Text('${widget.maintenance}', style: mono),
          const SizedBox(width: 12),
          Text('Left ', style: dimMono),
          // Task 3C + 3E: animated remaining CP
          ScaleTransition(
            scale: _popScale,
            child: widget.remainingCp < 0
                ? _PulsingText(
                    text: '${widget.remainingCp}',
                    style: warnMono,
                  )
                : Text('${widget.remainingCp}', style: mono),
          ),
          if (widget.remainingCp > 30)
            Text(
              '(${widget.remainingCp - 30} lost)',
              style: mono.copyWith(color: theme.colorScheme.tertiary),
            ),
          if (widget.remainingRp != null) ...[
            const SizedBox(width: 12),
            Text('RP ', style: dimMono),
            Text('${widget.remainingRp}', style: mono),
            if (widget.remainingRp! > 30)
              Text(
                '(${widget.remainingRp! - 30} lost)',
                style: mono.copyWith(color: theme.colorScheme.tertiary),
              ),
          ],
          if (widget.remainingLp != null) ...[
            const SizedBox(width: 12),
            Text('LP ', style: dimMono),
            Text('${widget.remainingLp}', style: mono),
          ],
        ],
      ),
    );
  }
}

/// A text widget that pulses its opacity between 0.6 and 1.0.
class _PulsingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _PulsingText({required this.text, required this.style});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(widget.text, style: widget.style),
    );
  }
}
