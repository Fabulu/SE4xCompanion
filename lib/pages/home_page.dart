import 'package:flutter/material.dart';

import '../models/alien_economy.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../models/production_state.dart';
import '../models/ship_counter.dart';
import '../models/world.dart';
import '../services/persistence_service.dart';
import 'alien_economy_page.dart';
import 'production_page.dart';
import 'settings_page.dart';
import 'ship_tech_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PersistenceService _persistence = PersistenceService();

  AppState _appState = const AppState();
  GameState _gameState = const GameState();
  String _gameName = 'New Game';
  String _activeGameId = '';
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
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
        _gameState = activeSave.state;
        _gameName = activeSave.name;
        _activeGameId = activeSave.id;
        _isLoading = false;
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
    });
    _save();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    // Update the active game in the games list
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
  }

  void _updateGameState(GameState newState) {
    setState(() {
      _gameState = newState;
    });
    _save();
  }

  // ---------------------------------------------------------------------------
  // State mutation handlers
  // ---------------------------------------------------------------------------

  void _onProductionChanged(ProductionState production) {
    _updateGameState(_gameState.copyWith(production: production));
  }

  void _onCountersChanged(List<ShipCounter> counters) {
    _updateGameState(_gameState.copyWith(shipCounters: counters));
  }

  void _onAlienPlayersChanged(List<AlienPlayer> aliens) {
    _updateGameState(_gameState.copyWith(alienPlayers: aliens));
  }

  void _onEndTurn() {
    final nextProduction = _gameState.production.prepareForNextTurn(
      _gameState.config,
      _gameState.shipCounters,
    );
    _updateGameState(_gameState.copyWith(
      turnNumber: _gameState.turnNumber + 1,
      production: nextProduction,
    ));
  }

  void _onConfigChanged(GameConfig config) {
    // When config changes, keep existing production data but let computations
    // re-derive based on the new config. No data is lost.
    _updateGameState(_gameState.copyWith(config: config));
  }

  void _onGameNameChanged(String name) {
    setState(() {
      _gameName = name;
    });
    _save();
  }

  void _onNewGame() {
    _createNewGame();
  }

  void _onLoadGame(String gameId) {
    final target = _appState.games.firstWhere(
      (g) => g.id == gameId,
      orElse: () => _appState.games.first,
    );
    setState(() {
      _activeGameId = target.id;
      _gameState = target.state;
      _gameName = target.name;
      _appState = _appState.copyWith(activeGameId: target.id);
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
      shipCounters: createAllCounters(),
      alienPlayers: const [],
    );
    _updateGameState(defaultState);
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _gameName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Turn ${_gameState.turnNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on, size: 20),
            label: 'Production',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield, size: 20),
            label: 'Ship Tech',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy, size: 20),
            label: 'Aliens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 20),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return ProductionPage(
          config: _gameState.config,
          turnNumber: _gameState.turnNumber,
          production: _gameState.production,
          shipCounters: _gameState.shipCounters,
          onProductionChanged: _onProductionChanged,
          onEndTurn: _onEndTurn,
        );
      case 1:
        return ShipTechPage(
          config: _gameState.config,
          turnNumber: _gameState.turnNumber,
          techState: _gameState.production.techState,
          shipCounters: _gameState.shipCounters,
          showExperience: _gameState.config.enableShipExperience,
          onCountersChanged: _onCountersChanged,
        );
      case 2:
        return AlienEconomyPage(
          alienPlayers: _gameState.alienPlayers,
          onAlienPlayersChanged: _onAlienPlayersChanged,
        );
      case 3:
        return SettingsPage(
          config: _gameState.config,
          gameName: _gameName,
          turnNumber: _gameState.turnNumber,
          savedGames: _appState.games,
          activeGameId: _activeGameId,
          onConfigChanged: _onConfigChanged,
          onGameNameChanged: _onGameNameChanged,
          onNewGame: _onNewGame,
          onLoadGame: _onLoadGame,
          onRenameGame: _onRenameGame,
          onDeleteGame: _onDeleteGame,
          onDuplicateGame: _onDuplicateGame,
          onResetGame: _onResetGame,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
