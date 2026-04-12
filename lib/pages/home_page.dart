import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/card_lookup.dart';
import '../data/card_manifest.dart';
import '../data/card_modifiers.dart';
import '../data/empire_advantages.dart';
import '../data/scenarios.dart';
import '../data/sci_fi_names.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/alien_economy.dart';
import '../models/drawn_card.dart';
import '../models/game_config.dart';
import '../models/game_modifier.dart';
import '../models/game_state.dart';
import '../models/map_state.dart';
import '../models/production_state.dart';
import '../models/replicator_player_state.dart';
import '../models/research_event.dart';
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
import '../tutorial/tutorial_controller.dart';
import '../tutorial/tutorial_overlay.dart';
import '../tutorial/tutorial_steps.dart';
import '../tutorial/tutorial_targets.dart';
import '../util/combat_resolution.dart';
import '../util/planet_attribute_picker.dart';
import '../util/scenario_auto_draw.dart';
import '../widgets/planet_attribute_prompt.dart';
import 'alien_economy_page.dart';
import 'home_tabs.dart';
import 'map_page.dart';
import 'production_page.dart';
import 'replicator_page.dart';
import 'replicator_player_page.dart';
import 'rules_reference_page.dart';
import 'settings_page.dart';
import 'ship_tech_page.dart';

class _TabDef {
  final HomeTabId id;
  final IconData icon;
  final String label;
  const _TabDef({required this.id, required this.icon, required this.label});
}

class HomePage extends StatefulWidget {
  /// PP18: shared text-scale notifier owned by the root Se4XApp state.
  /// HomePage pushes AppState.textScale into this notifier whenever it
  /// loads or mutates, and the MaterialApp.builder callback listens to
  /// it to apply a MediaQuery.textScaler override at the tree root.
  final ValueNotifier<double>? textScaleNotifier;

  const HomePage({super.key, this.textScaleNotifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final PersistenceService _persistence = PersistenceService();

  AppState _appState = const AppState();
  GameState _gameState = const GameState();
  String _gameName = 'New Game';
  String _activeGameId = '';
  bool _isLoading = true;
  int _currentTabIndex = 0;
  String? _mapFocusShipId;
  int _mapFocusRequestId = 0;

  List<_TabDef> get _visibleTabs {
    final tabs = <_TabDef>[
      _gameState.config.playerControlsReplicators
          ? const _TabDef(
              id: HomeTabId.production,
              icon: Icons.bug_report,
              label: 'Replicator',
            )
          : const _TabDef(
              id: HomeTabId.production,
              icon: Icons.grid_on,
              label: 'Production',
            ),
      const _TabDef(id: HomeTabId.map, icon: Icons.map_outlined, label: 'Map'),
      if (!_gameState.config.playerControlsReplicators)
        const _TabDef(id: HomeTabId.shipTech, icon: Icons.shield, label: 'Ships'),
    ];
    if (_gameState.alienPlayers.isNotEmpty) {
      tabs.add(
        const _TabDef(
          id: HomeTabId.aliens,
          icon: Icons.smart_toy,
          label: 'Aliens',
        ),
      );
    }
    if (_gameState.config.enableReplicators &&
        !_gameState.config.playerControlsReplicators) {
      tabs.add(
        const _TabDef(
          id: HomeTabId.replicator,
          icon: Icons.bug_report,
          label: 'Replicator',
        ),
      );
    }
    tabs.add(
      const _TabDef(id: HomeTabId.rules, icon: Icons.menu_book, label: 'Rules'),
    );
    tabs.add(
      const _TabDef(
        id: HomeTabId.settings,
        icon: Icons.settings,
        label: 'Settings',
      ),
    );
    return tabs;
  }

  HomeTabId get _currentTabId {
    final tabs = _visibleTabs;
    final idx = _currentTabIndex.clamp(0, tabs.length - 1);
    return tabs[idx].id;
  }

  void _selectTab(HomeTabId id) {
    final tabs = _visibleTabs;
    final idx = tabs.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      setState(() => _currentTabIndex = idx);
      _tutorialController.onTabTapped(id);
    }
  }

  // QW-1: Material spec caps a fixed BottomNavigationBar at 5 items. When we
  // exceed that, show the first 4 as primary items and fold the rest into a
  // "More" overflow sheet.
  static const int _kMaxPrimaryTabs = 5;

  /// Map a tab id to the matching tutorial-target GlobalKey, or null when
  /// the tab does not need a tutorial anchor.
  GlobalKey? _tutorialKeyForTab(HomeTabId id) {
    switch (id) {
      case HomeTabId.production:
        return TutorialTargets.productionTab;
      case HomeTabId.map:
        return TutorialTargets.mapTab;
      case HomeTabId.shipTech:
        return TutorialTargets.shipTechTab;
      case HomeTabId.aliens:
        return TutorialTargets.aliensTab;
      case HomeTabId.rules:
        return TutorialTargets.rulesTab;
      case HomeTabId.settings:
        return TutorialTargets.settingsTab;
      case HomeTabId.replicator:
        return null;
    }
  }

  Widget _wrapTabIcon(HomeTabId id, IconData icon) {
    final key = _tutorialKeyForTab(id);
    final iconWidget = Icon(icon, size: 24);
    if (key == null) return iconWidget;
    return KeyedSubtree(key: key, child: iconWidget);
  }

  Widget _buildBottomNav() {
    final tabs = _visibleTabs;
    if (tabs.length <= _kMaxPrimaryTabs) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTabIndex.clamp(0, tabs.length - 1),
        onTap: (index) {
          final tappedTab = tabs[index];
          setState(() => _currentTabIndex = index);
          _turnWiggleController.forward(from: 0);
          _tutorialController.onTabTapped(tappedTab.id);
        },
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(
              icon: _wrapTabIcon(tab.id, tab.icon),
              label: tab.label,
            ),
        ],
      );
    }

    // Split: first 4 tabs as primary, rest under "More".
    const int primaryCount = _kMaxPrimaryTabs - 1; // 4
    final primary = tabs.sublist(0, primaryCount);
    final overflow = tabs.sublist(primaryCount);
    final currentIdx = _currentTabIndex.clamp(0, tabs.length - 1);
    final isOverflowActive = currentIdx >= primaryCount;
    // Active overflow tab so we can highlight "More" with the overflow tab's
    // icon/label when the user is on one of those pages.
    final activeOverflowTab = isOverflowActive ? tabs[currentIdx] : null;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: isOverflowActive ? primaryCount : currentIdx,
      onTap: (index) {
        if (index == primaryCount) {
          _showMoreTabsSheet(overflow);
        } else {
          final tappedTab = primary[index];
          setState(() => _currentTabIndex = index);
          _turnWiggleController.forward(from: 0);
          _tutorialController.onTabTapped(tappedTab.id);
        }
      },
      items: [
        for (final tab in primary)
          BottomNavigationBarItem(
            icon: _wrapTabIcon(tab.id, tab.icon),
            label: tab.label,
          ),
        BottomNavigationBarItem(
          icon: Icon(
            activeOverflowTab?.icon ?? Icons.more_horiz,
            size: 24,
          ),
          label: activeOverflowTab?.label ?? 'More',
        ),
      ],
    );
  }

  void _showMoreTabsSheet(List<_TabDef> overflow) {
    final tabs = _visibleTabs;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tab in overflow)
                ListTile(
                  leading: Icon(tab.icon),
                  title: Text(tab.label),
                  selected: _currentTabId == tab.id,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final idx = tabs.indexWhere((t) => t.id == tab.id);
                    if (idx >= 0) {
                      setState(() => _currentTabIndex = idx);
                      _turnWiggleController.forward(from: 0);
                      _tutorialController.onTabTapped(tab.id);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _locateShipOnMap(String shipId) {
    final fleetId = _gameState.mapState.fleetIdForShip(shipId);
    if (fleetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$shipId is not currently placed on the map.')),
      );
      return;
    }
    final tabs = _visibleTabs;
    final idx = tabs.indexWhere((t) => t.id == HomeTabId.map);
    setState(() {
      if (idx >= 0) _currentTabIndex = idx;
      _mapFocusShipId = shipId;
      _mapFocusRequestId += 1;
    });
    _turnWiggleController.forward(from: 0);
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

  // Tutorial
  late final TutorialController _tutorialController;
  OverlayEntry? _tutorialEntry;

  @override
  void initState() {
    super.initState();

    _tutorialController = TutorialController(
      steps: kTutorialSteps,
      onRequestTab: _selectTab,
      getHomeworldPlaced: () {
        for (final hex in _gameState.mapState.hexes) {
          final wid = hex.worldId;
          if (wid == null || wid.isEmpty) continue;
          for (final w in _gameState.production.worlds) {
            final id = w.id.isNotEmpty ? w.id : w.name;
            if (w.isHomeworld && id == wid) return true;
          }
        }
        return false;
      },
      isStepVisible: _isTutorialStepVisible,
      onFinished: _persistTutorialSeen,
    );
    _tutorialController.addListener(_onTutorialControllerChanged);

    _loadState();

    _turnWiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _turnWiggle =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: 0.017), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.017, end: -0.017), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -0.017, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _turnWiggleController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _turnWiggleController.dispose();
    _removeTutorialOverlay();
    _tutorialController.removeListener(_onTutorialControllerChanged);
    _tutorialController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tutorial wiring
  // ---------------------------------------------------------------------------

  bool _isTutorialStepVisible(TutorialStep step) {
    if (step.id == 'aliens' && _gameState.alienPlayers.isEmpty) return false;
    // If a step requires a specific tab, that tab must be in the live
    // visible tab list (e.g. shipTech is hidden in player-replicator games).
    if (step.requiredTab != null) {
      final visible = _visibleTabs.any((t) => t.id == step.requiredTab);
      if (!visible) return false;
    }
    return true;
  }

  void _onTutorialControllerChanged() {
    if (!mounted) return;
    if (_tutorialController.isActive) {
      _installTutorialOverlay();
    } else {
      _removeTutorialOverlay();
    }
  }

  void _installTutorialOverlay() {
    if (_tutorialEntry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _tutorialEntry = OverlayEntry(
      builder: (_) => TutorialOverlay(
        controller: _tutorialController,
        config: _gameState.config,
      ),
    );
    overlay.insert(_tutorialEntry!);
  }

  void _removeTutorialOverlay() {
    _tutorialEntry?.remove();
    _tutorialEntry = null;
  }

  void _persistTutorialSeen() {
    if (_appState.tutorial.seen) return;
    final newAppState = _appState.copyWith(
      tutorial: _appState.tutorial.copyWith(seen: true),
    );
    setState(() {
      _appState = newAppState;
    });
    // Best-effort save; the tutorial flag is stored at the AppState level
    // so we bypass the regular game-save debounce.
    _persistence.save(_appState);
  }

  void _replayTutorial() {
    _tutorialController.start(fromIndex: 0);
  }

  Future<void> _loadState() async {
    final appState = await _persistence.load();
    if (appState != null && appState.games.isNotEmpty) {
      final activeId = appState.activeGameId ?? appState.games.first.id;
      final activeSave = appState.games.firstWhere(
        (g) => g.id == activeId,
        orElse: () => appState.games.first,
      );
      final hadTutorialSeen = appState.tutorial.seen;
      setState(() {
        _appState = appState;
        _gameState = _syncedMapState(activeSave.state);
        _gameName = activeSave.name;
        _activeGameId = activeSave.id;
        _isLoading = false;
        _undoHistory.clear();
        _lastActionWasEndTurn = false;
      });
      _syncTextScaleNotifier();
      // Existing user with prior saves but no tutorial seen flag: show a
      // one-time snack pointing them at Settings -> Help, and persist
      // tutorial.seen = true so the snack only fires once.
      if (!hadTutorialSeen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'New: replay tutorial available in Settings -> Help',
              ),
              duration: Duration(seconds: 5),
            ),
          );
          _persistTutorialSeen();
        });
      }
    } else {
      setState(() {
        _appState = const AppState();
        _gameState = const GameState();
        _gameName = 'New Game';
        _activeGameId = '';
        _isLoading = false;
        _undoHistory.clear();
        _undoDescriptions.clear();
        _lastActionWasEndTurn = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openNewGameWizard();
      });
    }
  }

  void _createNewGameFromWizard(NewGameResult result, {String? replaceGameId}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final scenario = scenarioById(result.config.scenarioId);
    final baseConfig = _normalizeConfigForScenario(result.config, scenario);
    final normalizedEa = _normalizeEmpireAdvantageForMode(baseConfig);
    final config =
        normalizedEa == null && baseConfig.selectedEmpireAdvantage != null
        ? baseConfig.copyWith(clearEmpireAdvantage: true)
        : baseConfig;
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
        worlds: [
          WorldState(
            id: 'world-1',
            name: 'Homeworld',
            isHomeworld: true,
            homeworldValue: hwValue,
          ),
        ],
        techState: startTech,
      ),
      mapState: GameMapState.initial(),
      shipCounters: config.playerControlsReplicators
          ? _createReplicatorStartingForces(startTech, config.useFacilitiesCosts)
          : createAllCounters(),
      replicatorPlayerState: config.playerControlsReplicators
          ? ReplicatorPlayerState.initial(
              empireAdvantageCardNumber: config.selectedEmpireAdvantage,
            )
          : null,
      alienPlayers: () {
        // Pick distinct sci-fi alien faction names from the curated pool.
        final taken = <String>{};
        return [
          for (int i = 0; i < result.alienPlayerCount; i++)
            () {
              final name = pickUnusedName(kAlienNames, taken,
                  fallbackPrefix: 'Alien');
              taken.add(name);
              return AlienPlayer(
                name: name,
                color: ['Red', 'Blue', 'Yellow'][i % 3],
              );
            }(),
        ];
      }(),
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

    // PP01: auto-draw any scenario modifier cards (e.g. Technology Head
    // Start for Quick Conquest) so the player starts with them face-up
    // in hand. No-op for scenarios whose scenarioModifierCards is empty.
    finalState = applyScenarioAutoDrawnCards(finalState, scenario);

    final saved = SavedGame(
      id: id,
      name: result.gameName,
      updatedAt: DateTime.now(),
      state: finalState,
    );
    final priorGameCount = replaceGameId == null
        ? _appState.games.length
        : _appState.games.where((g) => g.id != replaceGameId).length;
    final games = replaceGameId == null
        ? [..._appState.games, saved]
        : [..._appState.games.where((game) => game.id != replaceGameId), saved];
    // If the player has starting shipyards but no homeworld placed, jump
    // straight to the Map tab so the onboarding banner is the first thing
    // they see in a fresh game.
    final needsOnboarding = finalState.shipCounters
        .any((c) => c.type == ShipType.shipyard && c.isBuilt);
    final mapTabIndex = _visibleTabs.indexWhere((t) => t.id == HomeTabId.map);
    setState(() {
      _appState = _appState.copyWith(games: games, activeGameId: id);
      _gameState = finalState;
      _gameName = result.gameName;
      _activeGameId = id;
      _isLoading = false;
      _undoHistory.clear();
      _undoDescriptions.clear();
      _lastActionWasEndTurn = false;
      if (needsOnboarding && mapTabIndex >= 0) {
        _currentTabIndex = mapTabIndex;
      }
    });
    _save();
    // Auto-start the tutorial only when this is the user's brand-new
    // first game AND they have not seen the tutorial yet.
    if (priorGameCount == 0 && !_appState.tutorial.seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tutorialController.start(fromIndex: 0);
      });
    }
  }

  Future<void> _openNewGameWizard({String? replaceGameId}) async {
    final result = await showNewGameWizard(context);
    if (!mounted || result == null) {
      return;
    }
    _createNewGameFromWizard(result, replaceGameId: replaceGameId);
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
    final nextState = _syncedMapState(
      _gameState.copyWith(production: production.ensureWorldIds()),
    );
    _updateGameState(nextState, 'Production');
  }

  void _onCountersChanged(List<ShipCounter> counters) {
    final nextState = _syncedMapState(
      _gameState.copyWith(shipCounters: counters),
    );
    _updateGameState(nextState, 'Ship Tech');
  }

  void _onUpgradeCost(int cost) {
    final newUpgrades = _gameState.production.upgradesCp + cost;
    _onProductionChanged(
      _gameState.production.copyWith(upgradesCp: newUpgrades),
    );
  }

  /// Consume one queued ship purchase of [type] from Production. Returns true
  /// if a purchase was found and decremented (or removed when its quantity hit
  /// zero); false if no matching purchase was queued.
  ///
  /// Used by the Ship Tech tab "Build" button so the player can stamp counters
  /// for ships they already paid for in the Production queue, without
  /// double-charging or going through a manual override.
  bool _consumeQueuedShipPurchase(ShipType type) {
    final purchases =
        List<ShipPurchase>.from(_gameState.production.shipPurchases);
    // Prefer "ready to materialize" purchases (totalHpNeeded == null OR
    // buildProgressHp >= totalHpNeeded), then fall back to first match.
    int idx = purchases.indexWhere((p) =>
        p.type == type &&
        (p.totalHpNeeded == null ||
            p.buildProgressHp >= (p.totalHpNeeded ?? 0)));
    if (idx < 0) {
      idx = purchases.indexWhere((p) => p.type == type);
    }
    if (idx < 0) return false;
    final p = purchases[idx];
    if (p.quantity > 1) {
      final newQty = p.quantity - 1;
      final hull = kShipDefinitions[p.type]
              ?.effectiveHullSize(_gameState.config.useFacilitiesCosts) ??
          0;
      final newTotalHp =
          p.totalHpNeeded == null ? null : hull * newQty;
      purchases[idx] = p.copyWith(quantity: newQty, totalHpNeeded: newTotalHp);
    } else {
      purchases.removeAt(idx);
    }
    _onProductionChanged(
      _gameState.production.copyWith(shipPurchases: purchases),
    );
    return true;
  }

  void _onGameStateOverride(GameState newState) {
    _updateGameState(newState, 'Manual Override');
  }

  void _onApplyCardModifiers(
      String cardName, List<GameModifier> modifiers) {
    if (modifiers.isEmpty) return;
    final deduped = _dedupCardModifiers(modifiers);
    if (deduped.isEmpty) {
      _showAlreadyAppliedSnack(cardName);
      return;
    }
    _updateGameState(
      _gameState.copyWith(
        activeModifiers: [..._gameState.activeModifiers, ...deduped],
      ),
      'Apply card: $cardName',
    );
  }

  /// Bug C: drop any modifiers whose [GameModifier.sourceCardId] is already
  /// present in the active ledger. Returns the survivors.
  List<GameModifier> _dedupCardModifiers(List<GameModifier> incoming) {
    final existingIds = <String>{
      for (final m in _gameState.activeModifiers)
        if (m.sourceCardId != null) m.sourceCardId!,
    };
    final out = <GameModifier>[];
    for (final m in incoming) {
      final id = m.sourceCardId;
      if (id != null && existingIds.contains(id)) continue;
      out.add(m);
      if (id != null) existingIds.add(id);
    }
    return out;
  }

  void _showAlreadyAppliedSnack(String cardName) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$cardName already applied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onActiveModifiersChanged(List<GameModifier> modifiers) {
    _updateGameState(
      _gameState.copyWith(activeModifiers: modifiers),
      'Update modifiers',
    );
  }

  void _onDrawnHandChanged(List<DrawnCard> hand) {
    _updateGameState(
      _gameState.copyWith(drawnHand: hand),
      'Update hand',
    );
  }

  /// Played a drawn card as an event: append its modifiers to the active
  /// modifier ledger (same path as the Apply-from-catalog flow). The hand
  /// is updated separately by [_onDrawnHandChanged].
  void _onPlayCardAsEvent(String cardName, List<GameModifier> modifiers) {
    if (modifiers.isEmpty) return;
    final deduped = _dedupCardModifiers(modifiers);
    if (deduped.isEmpty) {
      _showAlreadyAppliedSnack(cardName);
      return;
    }
    _updateGameState(
      _gameState.copyWith(
        activeModifiers: [..._gameState.activeModifiers, ...deduped],
      ),
      'Play card: $cardName',
    );
  }

  /// Played a drawn card for credits: add a one-shot `+N CP` income modifier
  /// stamped with the card's name so it shows up in the active-modifier chips.
  ///
  /// [sourceCardId] carries a per-turn identity
  /// (`card:<type>:<number>:credits:<turn>`) so that double-tapping
  /// "Play for credits" on the same card in the same turn does not
  /// double-stack via the standard dedup pipeline.
  void _onPlayCardForCredits(
      String cardName, int cpGained, String sourceCardId) {
    if (cpGained <= 0) return;
    final alreadyApplied = _gameState.activeModifiers
        .any((m) => m.sourceCardId == sourceCardId);
    if (alreadyApplied) {
      _showAlreadyAppliedSnack('$cardName (credits)');
      return;
    }
    final mod = GameModifier(
      name: '$cardName (credits)',
      type: 'incomeMod',
      value: cpGained,
      sourceCardId: sourceCardId,
    );
    _updateGameState(
      _gameState.copyWith(
        activeModifiers: [..._gameState.activeModifiers, mod],
      ),
      'Play card for credits: $cardName',
    );
  }

  /// PP01: composite card-play handlers. Each collapses the three
  /// previously-separate mutations (hand, active ledger / income, played
  /// history) into a single `_updateGameState` call so that undo pops one
  /// step per card play.

  void _onCardPlayedAsEvent(int index, List<GameModifier> modifiers) {
    if (index < 0 || index >= _gameState.drawnHand.length) return;
    final card = _gameState.drawnHand[index];
    final entry = _lookupCardEntryById(card.cardNumber);
    final name = entry?.name ?? 'Card #${card.cardNumber}';
    final deduped = _dedupCardModifiers(modifiers);
    if (modifiers.isNotEmpty && deduped.isEmpty) {
      _showAlreadyAppliedSnack(name);
      return;
    }
    final stamped = card.copyWith(disposition: 'event');
    final newHand = List<DrawnCard>.from(_gameState.drawnHand)..removeAt(index);
    final newPlayed = [..._gameState.playedCards, stamped];
    _updateGameState(
      _gameState.copyWith(
        drawnHand: newHand,
        playedCards: newPlayed,
        activeModifiers: [..._gameState.activeModifiers, ...deduped],
      ),
      'Play card: $name',
    );
  }

  void _onCardPlayedForCredits(
    int index,
    int cpGained,
    String sourceCardId,
  ) {
    if (index < 0 || index >= _gameState.drawnHand.length) return;
    if (cpGained <= 0) return;
    final card = _gameState.drawnHand[index];
    final entry = _lookupCardEntryById(card.cardNumber);
    final name = entry?.name ?? 'Card #${card.cardNumber}';
    final alreadyApplied = _gameState.activeModifiers
        .any((m) => m.sourceCardId == sourceCardId);
    if (alreadyApplied) {
      _showAlreadyAppliedSnack('$name (credits)');
      return;
    }
    final mod = GameModifier(
      name: '$name (credits)',
      type: 'incomeMod',
      value: cpGained,
      sourceCardId: sourceCardId,
    );
    final stamped =
        card.copyWith(disposition: 'credits', cpGained: cpGained);
    final newHand = List<DrawnCard>.from(_gameState.drawnHand)..removeAt(index);
    final newPlayed = [..._gameState.playedCards, stamped];
    _updateGameState(
      _gameState.copyWith(
        drawnHand: newHand,
        playedCards: newPlayed,
        activeModifiers: [..._gameState.activeModifiers, mod],
      ),
      'Play card for credits: $name',
    );
  }

  void _onCardDiscarded(int index) {
    if (index < 0 || index >= _gameState.drawnHand.length) return;
    final card = _gameState.drawnHand[index];
    final entry = _lookupCardEntryById(card.cardNumber);
    final name = entry?.name ?? 'Card #${card.cardNumber}';
    final stamped = card.copyWith(disposition: 'discarded');
    final newHand = List<DrawnCard>.from(_gameState.drawnHand)..removeAt(index);
    final newPlayed = [..._gameState.playedCards, stamped];
    _updateGameState(
      _gameState.copyWith(
        drawnHand: newHand,
        playedCards: newPlayed,
      ),
      'Discard card: $name',
    );
  }

  CardEntry? _lookupCardEntryById(int cardNumber) =>
      lookupCardByNumber(cardNumber);

  /// PP01: after colonizing one or more new worlds, walk each colony and
  /// ask the player whether to attach a Planet Attribute card. Picks are
  /// appended to `drawnHand` with `attachedWorldId` set.
  Future<void> _promptPlanetAttributesForNewColonies(
    List<({String worldId, String worldName, HexCoord coord})> newColonies,
  ) async {
    for (final colony in newColonies) {
      if (!mounted) return;
      final result = await showPlanetAttributePrompt(
        context,
        worldName: colony.worldName,
      );
      if (!mounted) return;
      if (result == null || result == PlanetAttributePromptResult.skip) {
        continue;
      }
      int? cardNumber;
      if (result == PlanetAttributePromptResult.random) {
        final excluded = <int>{
          for (final c in _gameState.drawnHand) c.cardNumber,
          for (final c in _gameState.playedCards) c.cardNumber,
        };
        cardNumber = pickRandomPlanetAttribute(excluded);
      } else {
        // pick
        cardNumber = await _pickPlanetAttributeDialog();
      }
      if (!mounted) return;
      if (cardNumber == null) continue;
      final entry = _lookupCardEntryById(cardNumber);
      if (entry == null) continue;
      final binding = cardModifiersFor(cardNumber);
      final sourceId = '${entry.type}:$cardNumber:${colony.worldId}';
      final mods = <GameModifier>[
        for (final m in (binding?.modifiers ?? const <GameModifier>[]))
          m.withSourceCardId(sourceId),
      ];
      final drawn = DrawnCard(
        cardNumber: cardNumber,
        drawnOnTurn: _gameState.turnNumber,
        isFaceUp: true,
        assignedModifiers: mods,
        attachedWorldId: colony.worldId,
      );
      _updateGameState(
        _gameState.copyWith(
          drawnHand: [..._gameState.drawnHand, drawn],
        ),
        'Attach attribute: ${colony.worldName}',
      );
    }
  }

  Future<int?> _pickPlanetAttributeDialog() async {
    final alreadyDrawn = <int>{
      for (final c in _gameState.drawnHand) c.cardNumber,
      for (final c in _gameState.playedCards) c.cardNumber,
    };
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick Planet Attribute'),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: ListView.builder(
            itemCount: kPlanetAttributes.length,
            itemBuilder: (_, i) {
              final card = kPlanetAttributes[i];
              final taken = alreadyDrawn.contains(card.number);
              return ListTile(
                dense: true,
                title: Text(
                  '#${card.number} ${card.name}',
                  style: TextStyle(
                    fontSize: 13,
                    color: taken
                        ? Theme.of(ctx).colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            )
                        : null,
                  ),
                ),
                subtitle: Text(
                  card.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: taken
                    ? const Icon(Icons.check, size: 14)
                    : null,
                onTap: () => Navigator.pop(ctx, card.number),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _onAlienPlayersChanged(List<AlienPlayer> aliens) {
    _updateGameState(
      _gameState.copyWith(alienPlayers: aliens),
      'Alien Economy',
    );
  }

  void _onReplicatorPlayerChanged(ReplicatorPlayerState state) {
    _updateGameState(
      _gameState.copyWith(replicatorPlayerState: state),
      'Replicator Economy',
    );
  }

  void _onReplicatorPlayerWorldsChanged(List<WorldState> worlds) {
    _updateGameState(
      _gameState.copyWith(
        production: _gameState.production.copyWith(worlds: worlds),
      ),
      'Replicator Colonies',
    );
  }

  void _onMapChanged(
    GameMapState mapState, {
    bool recordUndo = true,
    String? description,
  }) {
    final nextState = _syncedMapState(_gameState.copyWith(mapState: mapState));
    if (recordUndo) {
      _updateGameState(nextState, description ?? 'Map');
      _tutorialController.onGameStateChanged(_gameState);
      return;
    }
    setState(() {
      _gameState = nextState;
    });
    _save();
    _tutorialController.onGameStateChanged(_gameState);
  }

  void _resolveCombat(CombatResolution resolution) {
    if (resolution.isEmpty && (resolution.combatLogNote ?? '').isEmpty) {
      return;
    }
    var nextState = applyCombatResolution(_gameState, resolution);
    final note = resolution.combatLogNote;
    if (note != null && note.isNotEmpty) {
      nextState = nextState.copyWith(
        combatLog: [...nextState.combatLog, note],
      );
    }
    final undoDesc = note != null && note.isNotEmpty
        ? 'Resolve Combat (${resolution.destroyedShipCounterIds.length} destroyed, '
            '${resolution.retreats.length} retreats) — $note'
        : 'Resolve Combat (${resolution.destroyedShipCounterIds.length} destroyed, '
            '${resolution.retreats.length} retreats)';
    _updateGameState(nextState, undoDesc);
  }

  GameState _syncedMapState(GameState state) {
    final normalizedProduction = state.production.ensureWorldIds();
    final validWorldIds = normalizedProduction.worlds
        .map((world) => world.id)
        .toSet();
    final validShipIds = state.shipCounters
        .where((counter) => counter.isBuilt)
        .map((counter) => counter.id)
        .toSet();

    return state.copyWith(
      production: normalizedProduction,
      mapState: state.mapState.sanitizeAgainstLedger(
        validWorldIds: validWorldIds,
        validShipIds: validShipIds,
      ),
    );
  }

  /// Mid-turn trigger to colonize Colony Ships now instead of waiting for
  /// End Turn. Reuses the same dialog + apply flow as [_onEndTurn], just
  /// without advancing the turn.
  void _openColonizeNowDialog() {
    if (!mounted) return;
    final candidates = _findColonyShipColonizeCandidates();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('No Colony Ships are on a colonizable hex.'),
        ),
      );
      return;
    }
    _promptColonyShipColonization(candidates).then((decisions) async {
      if (!mounted || decisions == null) return;
      final newColonies = _applyColonyShipColonization(decisions);
      if (newColonies.isNotEmpty) {
        await _promptPlanetAttributesForNewColonies(newColonies);
      }
    });
  }

  void _onEndTurn() {
    // PP13: optional "Are you sure?" gate before any End Turn flow runs.
    if (!_appState.confirmEndTurn) {
      _runEndTurnFlow();
      return;
    }
    () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('End the turn?'),
          content: const Text(
            'This will materialize all queued purchases, complete tech research, '
            'and advance to the next turn. You can undo afterwards if needed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End Turn'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (ok != true) return;
      _runEndTurnFlow();
    }();
  }

  void _runEndTurnFlow() {
    if (_gameState.config.playerControlsReplicators) {
      _finishEndTurn();
      return;
    }
    final candidates = _findColonyShipColonizeCandidates();
    if (candidates.isEmpty) {
      _finishEndTurn();
      return;
    }
    _promptColonyShipColonization(candidates).then((decisions) async {
      if (!mounted) return;
      if (decisions == null) {
        // User cancelled dialog — treat as skip all, still end the turn.
        _finishEndTurn();
        return;
      }
      final newColonies = _applyColonyShipColonization(decisions);
      if (newColonies.isNotEmpty) {
        await _promptPlanetAttributesForNewColonies(newColonies);
      }
      if (!mounted) return;
      _finishEndTurn();
    });
  }

  void _onConfirmEndTurnChanged(bool value) {
    if (_appState.confirmEndTurn == value) return;
    final newAppState = _appState.copyWith(confirmEndTurn: value);
    setState(() {
      _appState = newAppState;
    });
    // Persist immediately; this is an app-level preference, not part
    // of the per-game save debounce.
    _persistence.save(newAppState);
  }

  /// PP18: update the global text-scale preference. Pushes the new
  /// value into the shared [ValueNotifier] so the MaterialApp builder
  /// rewraps the tree with a MediaQuery.textScaler override, and
  /// persists it immediately as an app-level preference.
  void _onTextScaleChanged(double value) {
    if ((_appState.textScale - value).abs() < 0.0001) return;
    final newAppState = _appState.copyWith(textScale: value);
    setState(() {
      _appState = newAppState;
    });
    widget.textScaleNotifier?.value = value;
    _persistence.save(newAppState);
  }

  /// PP18: push the persisted AppState.textScale into the shared
  /// notifier. Called whenever [_appState] is restored from disk so
  /// the root MaterialApp builder picks up the user's saved scale on
  /// app launch.
  void _syncTextScaleNotifier() {
    final notifier = widget.textScaleNotifier;
    if (notifier == null) return;
    if ((notifier.value - _appState.textScale).abs() > 0.0001) {
      notifier.value = _appState.textScale;
    }
  }

  /// A Colony Ship built + parked on a friendly fleet at a colonizable hex
  /// that doesn't yet hold a world.
  List<_ColonyShipCandidate> _findColonyShipColonizeCandidates() {
    final terraforming = _gameState.production.techState.getLevel(
      TechId.terraforming,
      facilitiesMode: _gameState.config.useFacilitiesCosts,
    );
    final builtColonyShips = <String, ShipCounter>{
      for (final c in _gameState.shipCounters)
        if (c.isBuilt && c.type == ShipType.colonyShip) c.id: c,
    };
    if (builtColonyShips.isEmpty) return const [];
    final raw = _gameState.mapState.findColonizeCandidates(
      candidateShipIds: builtColonyShips.keys.toSet(),
      terraformingLevel: terraforming,
    );
    return [
      for (final c in raw)
        if (builtColonyShips[c.shipId] != null)
          _ColonyShipCandidate(
            counter: builtColonyShips[c.shipId]!,
            fleetId: c.fleetId,
            coord: c.coord,
            terrain: c.terrain,
          ),
    ];
  }

  Future<Map<String, bool>?> _promptColonyShipColonization(
    List<_ColonyShipCandidate> candidates,
  ) {
    final decisions = <String, bool>{
      for (final c in candidates) c.counter.id: true,
    };
    return showDialog<Map<String, bool>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Colony Ships ready to colonize'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setSt(() {
                        for (final c in candidates) {
                          decisions[c.counter.id] = true;
                        }
                      }),
                      child: const Text('Colonize All'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setSt(() {
                        for (final c in candidates) {
                          decisions[c.counter.id] = false;
                        }
                      }),
                      child: const Text('Skip All'),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final c in candidates)
                          CheckboxListTile(
                            dense: true,
                            value: decisions[c.counter.id] ?? false,
                            onChanged: (v) => setSt(
                              () => decisions[c.counter.id] = v ?? false,
                            ),
                            title: Text(
                              'CS #${c.counter.number} @ '
                              '[${c.coord.q},${c.coord.r}]',
                            ),
                            subtitle: Text(c.terrain.displayName),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel End Turn'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, decisions),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  List<({String worldId, String worldName, HexCoord coord})>
      _applyColonyShipColonization(Map<String, bool> decisions) {
    final candidates = _findColonyShipColonizeCandidates();
    if (candidates.isEmpty) return const [];
    final candidateByShipId = {for (final c in candidates) c.counter.id: c};
    final newColonies =
        <({String worldId, String worldName, HexCoord coord})>[];

    var nextMap = _gameState.mapState;
    var nextProduction = _gameState.production;
    final nextCounters = List<ShipCounter>.from(_gameState.shipCounters);

    final existingWorldIds = nextProduction.worlds.map((w) => w.id).toSet();
    int nextSuffix = 1;
    String mintWorldId() {
      String id;
      do {
        id = 'world-cs-${DateTime.now().microsecondsSinceEpoch}-$nextSuffix';
        nextSuffix++;
      } while (existingWorldIds.contains(id));
      existingWorldIds.add(id);
      return id;
    }

    final usedCoordIds = <String>{
      for (final h in nextMap.hexes)
        if (h.worldId != null && h.worldId!.isNotEmpty) h.coord.id,
    };

    final worlds = List<WorldState>.from(nextProduction.worlds);
    for (final entry in decisions.entries) {
      if (entry.value != true) continue;
      final candidate = candidateByShipId[entry.key];
      if (candidate == null) continue;
      if (usedCoordIds.contains(candidate.coord.id)) continue;

      final newWorldId = mintWorldId();
      final worldName = 'Colony [${candidate.coord.q},${candidate.coord.r}]';
      worlds.add(
        WorldState(
          id: newWorldId,
          name: worldName,
          growthMarkerLevel: 0,
        ),
      );
      usedCoordIds.add(candidate.coord.id);
      newColonies.add((
        worldId: newWorldId,
        worldName: worldName,
        coord: candidate.coord,
      ));

      // Stamp worldId onto the hex.
      final hex = nextMap.hexAt(candidate.coord);
      if (hex != null) {
        nextMap = nextMap.replaceHex(hex.copyWith(worldId: newWorldId));
      }

      // Remove the CS counter from its fleet and retire (unbuild) it.
      final fleet = nextMap.fleetById(candidate.fleetId);
      if (fleet != null) {
        final remainingShipIds = fleet.shipCounterIds
            .where((id) => id != candidate.counter.id)
            .toList();
        if (remainingShipIds.isEmpty) {
          nextMap = nextMap.removeFleet(fleet.id);
        } else {
          nextMap = nextMap.replaceFleet(
            fleet.copyWith(
              shipCounterIds: remainingShipIds,
              composition: const {},
            ),
          );
        }
      }
      for (int i = 0; i < nextCounters.length; i++) {
        if (nextCounters[i].id == candidate.counter.id) {
          nextCounters[i] = ShipCounter(
            type: nextCounters[i].type,
            number: nextCounters[i].number,
          );
          break;
        }
      }
    }

    nextProduction = nextProduction.copyWith(worlds: worlds);
    _updateGameState(
      _gameState.copyWith(
        production: nextProduction,
        mapState: nextMap,
        shipCounters: nextCounters,
      ),
      'Colonize Colony Ships',
    );
    return newColonies;
  }

  void _finishEndTurn() {
    if (_gameState.config.playerControlsReplicators) {
      final playerState =
          _gameState.replicatorPlayerState ??
          ReplicatorPlayerState.initial(
            empireAdvantageCardNumber:
                _gameState.config.selectedEmpireAdvantage,
          );
      final nextWorlds = _gameState.production.worlds.map((world) {
        if (world.isHomeworld && world.homeworldValue < 30) {
          return world.copyWith(
            homeworldValue: (world.homeworldValue + 5).clamp(0, 30),
          );
        }
        if (!world.isHomeworld && world.growthMarkerLevel < 3) {
          return world.copyWith(
            growthMarkerLevel: (world.growthMarkerLevel + 1).clamp(0, 3),
          );
        }
        return world;
      }).toList();
      final nextTurn = _gameState.turnNumber + 1;
      _updateGameState(
        _gameState.copyWith(
          turnNumber: nextTurn,
          replicatorPlayerState: playerState.endTurn(nextTurnNumber: nextTurn),
          production: _gameState.production.copyWith(worlds: nextWorlds),
          mapState: _gameState.mapState.clearAllFleetMoveFlags(),
        ),
        'Replicator End Turn',
      );
      _lastActionWasEndTurn = true;
      return;
    }

    var prod = _gameState.production;
    final config = _gameState.config;
    final counters = _gameState.shipCounters;
    final fm = config.useFacilitiesCosts;

    // Bug F: advance multi-turn build progress before snapshot + materialize.
    // Each assigned shipyard hex contributes its per-turn HP budget toward
    // the purchases assigned to it. Partial progress persists across turns.
    prod = prod.applyBuildProgress(
      config,
      _gameState.mapState,
      facilitiesMode: fm,
    );

    // Compute techs gained
    final techsGained = <String>[];
    for (final entry in prod.pendingTechPurchases.entries) {
      final currentLevel = prod.techState.getLevel(
        entry.key,
        facilitiesMode: fm,
      );
      final newLevel = entry.value;
      if (newLevel > currentLevel) {
        techsGained.add(
          '${_techDisplayName(entry.key)} $currentLevel -> $newLevel',
        );
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
    final remainingCp = prod.remainingCp(
      config,
      counters,
      mods,
      _gameState.shipSpecialAbilities,
    );
    final remainingRp = config.enableFacilities
        ? prod.remainingRp(config, mods)
        : 0;
    final cpLostToCap = math.max(0, remainingCp - 30);
    final rpLostToCap = config.enableFacilities
        ? math.max(0, remainingRp - 30)
        : 0;
    final cpCarryOver = remainingCp.clamp(0, 30);
    final rpCarryOver = config.enableFacilities ? remainingRp.clamp(0, 30) : 0;
    final maintenancePaid = prod.maintenanceTotal(counters, config, mods);

    // Build the research audit log: whatever events were recorded this
    // turn (grant rolls, reassignments) plus synthesized TechPurchasedEvents
    // for every pending purchase that will be applied by prepareForNextTurn.
    final researchLog = <ResearchEvent>[
      ...prod.researchLog,
      ...prod.emitPendingTechPurchaseEvents(config, mods),
    ];

    // Capture a symmetric pre-commit snapshot of the GameState fields
    // that can mutate during a turn so reopenLastTurn() restores them
    // all in lockstep (T3-A ship materialization, card plays, modifier
    // application).
    final gameStateSnapshot = <String, dynamic>{
      'production': prod.toJson(),
      'drawnHand':
          _gameState.drawnHand.map((c) => c.toJson()).toList(),
      'playedCards':
          _gameState.playedCards.map((c) => c.toJson()).toList(),
      'activeModifiers':
          _gameState.activeModifiers.map((m) => m.toJson()).toList(),
      'shipCounters':
          _gameState.shipCounters.map((c) => c.toJson()).toList(),
    };

    final summary = TurnSummary(
      turnNumber: _gameState.turnNumber,
      completedAt: DateTime.now(),
      productionSnapshot: prod,
      gameStateSnapshot: gameStateSnapshot,
      researchLog: researchLog,
      techsGained: techsGained,
      shipsBuilt: shipsBuilt,
      coloniesGrown: coloniesGrown,
      cpLostToCap: cpLostToCap,
      rpLostToCap: rpLostToCap,
      cpCarryOver: cpCarryOver,
      rpCarryOver: rpCarryOver,
      maintenancePaid: maintenancePaid,
    );

    // Materialize completed ship purchases into stamped ShipCounters before
    // rolling the turn over. In RAW (no multi-turn queue) every purchase is
    // treated as completed; with multi-turn builds enabled, partially-built
    // purchases are left in place by materializeCompletedPurchases.
    final materialized = prod.materializeCompletedPurchases(
      prod.techState,
      counters,
      facilitiesMode: fm,
      shipSpecialAbilities: _gameState.shipSpecialAbilities,
    );
    final prodAfterBuild = materialized.state;
    final countersAfterBuild = materialized.counters;

    // Apply shipyard increments to the map (WP-2: BUG-1 fix).
    var mapAfterBuild = _gameState.mapState;
    for (final entry in materialized.shipyardIncrements.entries) {
      final parts = entry.key.split(',');
      if (parts.length != 2) continue;
      final q = int.tryParse(parts[0]);
      final r = int.tryParse(parts[1]);
      if (q == null || r == null) continue;
      final coord = HexCoord(q, r);
      final hex = mapAfterBuild.hexAt(coord);
      if (hex != null) {
        mapAfterBuild = mapAfterBuild.replaceHex(
          hex.copyWith(shipyardCount: hex.shipyardCount + entry.value),
        );
      }
    }

    // PP09: fleet movement resets between turns. Every fleet gets a fresh
    // move allowance, so clear the hasMovedThisTurn flag on every stack
    // before committing the new game state.
    mapAfterBuild = mapAfterBuild.clearAllFleetMoveFlags();

    final nextProduction = prodAfterBuild.prepareForNextTurn(
      config,
      countersAfterBuild,
      mods,
      _gameState.shipSpecialAbilities,
    );
    _updateGameState(
      _gameState.copyWith(
        turnNumber: _gameState.turnNumber + 1,
        production: nextProduction,
        shipCounters: countersAfterBuild,
        mapState: mapAfterBuild,
        turnSummaries: [..._gameState.turnSummaries, summary],
      ),
      'End Turn ${_gameState.turnNumber}',
    );
    _lastActionWasEndTurn = true;
  }

  /// Starting forces for a player-controlled Replicator empire (RAW 40.1.3):
  /// 1 Flagship + 5 Type 0 (Scout) ships, all pre-built.
  static List<ShipCounter> _createReplicatorStartingForces(
    TechState tech,
    bool facilitiesMode,
  ) {
    final counters = createAllCounters();
    final updated = List<ShipCounter>.from(counters);
    int scoutsBuilt = 0;
    bool flagshipBuilt = false;
    for (int i = 0; i < updated.length; i++) {
      final c = updated[i];
      if (c.isBuilt) continue;
      if (c.type == ShipType.flag && !flagshipBuilt) {
        updated[i] = ShipCounter.stampFromTech(
          ShipType.flag,
          c.number,
          tech,
          facilitiesMode: facilitiesMode,
        );
        flagshipBuilt = true;
      } else if (c.type == ShipType.scout && scoutsBuilt < 5) {
        updated[i] = ShipCounter.stampFromTech(
          ShipType.scout,
          c.number,
          tech,
          facilitiesMode: facilitiesMode,
        );
        scoutsBuilt++;
      }
      if (flagshipBuilt && scoutsBuilt >= 5) break;
    }
    return updated;
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

  /// Reopen the most recently committed turn: pop its [TurnSummary] and
  /// restore the pre-commit [ProductionState] from the snapshot.
  ///
  /// Only available when the last turn summary carries a full snapshot
  /// (all summaries committed since T2-C do). The turn counter is rolled
  /// back by one so the player lands back in the Economic Phase they just
  /// finished.
  void _reopenLastTurn() {
    if (!_gameState.canReopenLastTurn) return;
    final restoredTurn = _gameState.turnSummaries.last.turnNumber;
    _updateGameState(
      _gameState.reopenLastTurn(),
      'Reopen Turn $restoredTurn',
    );
    _lastActionWasEndTurn = false;
  }

  void _navigateToRule(String sectionId) {
    _selectTab(HomeTabId.rules);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rulesKey.currentState?.jumpToSection(sectionId);
    });
  }

  void _onConfigChanged(GameConfig config) {
    // Check if EA was just selected and has starting tech overrides
    final oldEa = _gameState.config.empireAdvantage;
    final scenario = scenarioById(config.scenarioId);
    final normalizedConfig = _normalizeConfigForScenario(config, scenario);
    final normalizedEa = _normalizeEmpireAdvantageForMode(normalizedConfig);
    final effectiveConfig =
        normalizedEa == null && normalizedConfig.selectedEmpireAdvantage != null
        ? normalizedConfig.copyWith(clearEmpireAdvantage: true)
        : normalizedConfig;
    final scenarioChanged =
        effectiveConfig.scenarioId != _gameState.config.scenarioId;
    final replicatorModeChanged =
        effectiveConfig.enableReplicators !=
            _gameState.config.enableReplicators ||
        effectiveConfig.playerControlsReplicators !=
            _gameState.config.playerControlsReplicators;
    var nextState = _applyScenarioState(
      _gameState.copyWith(config: effectiveConfig),
      config: effectiveConfig,
      scenario: scenario,
      syncVictoryPoints: scenarioChanged,
      syncReplicatorSetup: scenarioChanged || replicatorModeChanged,
    );
    final effectiveEa = effectiveConfig.empireAdvantage;
    if (effectiveConfig.playerControlsReplicators) {
      final currentRepPlayer =
          nextState.replicatorPlayerState ??
          ReplicatorPlayerState.fromEmpireAdvantage(effectiveEa);
      nextState = nextState.copyWith(
        replicatorPlayerState: currentRepPlayer.copyWith(
          empireAdvantageCardNumber: effectiveEa?.isReplicator == true
              ? effectiveEa!.cardNumber
              : null,
          clearEmpireAdvantage: effectiveEa?.isReplicator != true,
        ),
      );
    }
    if (effectiveEa != null &&
        effectiveEa != oldEa &&
        effectiveEa.startingTechOverrides.isNotEmpty) {
      // Auto-apply starting tech overrides
      var newTechState = nextState.production.techState;
      for (final entry in effectiveEa.startingTechOverrides.entries) {
        final currentLevel = newTechState.getLevel(
          entry.key,
          facilitiesMode: effectiveConfig.useFacilitiesCosts,
        );
        if (entry.value > currentLevel) {
          newTechState = newTechState.setLevel(entry.key, entry.value);
        }
      }
      final newProduction = nextState.production.copyWith(
        techState: newTechState,
      );
      nextState = nextState.copyWith(production: newProduction);
      _updateGameState(nextState, 'Empire Advantage: ${effectiveEa.name}');
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

    final shouldHaveReplicator =
        !config.playerControlsReplicators &&
        (forceReplicator || config.enableReplicators);
    if (shouldHaveReplicator &&
        (syncReplicatorSetup || result.replicatorState == null)) {
      result = result.copyWith(
        replicatorState: ReplicatorState.fromScenario(
          config.scenarioId,
          difficulty: config.replicatorDifficulty,
        ),
      );
    } else if (result.replicatorState != null) {
      result = result.copyWith(clearReplicatorState: true);
    }

    if (config.playerControlsReplicators &&
        (syncReplicatorSetup || result.replicatorPlayerState == null)) {
      result = result.copyWith(
        replicatorPlayerState: ReplicatorPlayerState.initial(
          empireAdvantageCardNumber: config.selectedEmpireAdvantage,
        ),
      );
    } else if (!config.playerControlsReplicators &&
        result.replicatorPlayerState != null) {
      result = result.copyWith(clearReplicatorPlayerState: true);
    }
    return result;
  }

  GameConfig _normalizeConfigForScenario(
    GameConfig config,
    ScenarioPreset? scenario,
  ) {
    var result = config;
    if (result.playerControlsReplicators) {
      result = result.copyWith(
        enableFacilities: false,
        enableLogistics: false,
        enableTemporal: false,
        enableShipExperience: false,
        enableAlternateEmpire: false,
        enableReplicators: false,
      );
    }
    if (scenario?.replicatorSetup == null) return result;
    return result.copyWith(
      enableFacilities: false,
      enableShipExperience: false,
      enableReplicators: true,
      playerControlsReplicators: false,
      scenarioBlockedShips: [
        ...result.scenarioBlockedShips,
        if (!result.scenarioBlockedShips.contains(ShipType.decoy))
          ShipType.decoy,
      ],
    );
  }

  EmpireAdvantage? _normalizeEmpireAdvantageForMode(GameConfig config) {
    final ea = config.empireAdvantage;
    if (ea == null) return null;
    if (config.playerControlsReplicators) {
      return ea.isReplicator ? ea : null;
    }
    return ea.isReplicator ? null : ea;
  }

  void _onGameNameChanged(String name) {
    setState(() {
      _gameName = name;
    });
    _save();
  }

  void _onNewGame() async {
    await _openNewGameWizard();
  }

  /// PP11: open a bottom-sheet "game library" launched from the app-bar
  /// title. Lets the user switch the active game or start a new one
  /// without leaving the current tab.
  Future<void> _openGameLibrarySheet() async {
    if (!mounted) return;
    final games = _appState.games;
    final activeId = _activeGameId;
    final selected = await showModalBottomSheet<_GameLibrarySheetResult>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        final sorted = [...games]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Text(
                  'Game Library',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (sorted.isEmpty)
                const ListTile(
                  dense: true,
                  title: Text('No saved games yet.'),
                ),
              for (final g in sorted)
                ListTile(
                  leading: Icon(
                    g.id == activeId
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: g.id == activeId
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Turn ${g.state.turnNumber} '
                    '\u2022 ${_formatUpdatedAt(g.updatedAt)}',
                  ),
                  selected: g.id == activeId,
                  onTap: () => Navigator.of(sheetCtx).pop(
                    _GameLibrarySheetResult.load(g.id),
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New Game'),
                onTap: () => Navigator.of(sheetCtx).pop(
                  const _GameLibrarySheetResult.newGame(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    switch (selected.action) {
      case _GameLibrarySheetAction.load:
        final id = selected.gameId;
        if (id != null && id != _activeGameId) {
          _onLoadGame(id);
        }
        break;
      case _GameLibrarySheetAction.newGame:
        await _openNewGameWizard();
        break;
    }
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '${m}m ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '${h}h ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '${d}d ago';
    }
    final y = updatedAt.year.toString().padLeft(4, '0');
    final mo = updatedAt.month.toString().padLeft(2, '0');
    final d = updatedAt.day.toString().padLeft(2, '0');
    return '$y-$mo-$d';
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
      // Keep the existing game until the wizard returns a replacement.
      _openNewGameWizard(replaceGameId: gameId);
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
        worlds: [
          WorldState(
            id: 'world-1',
            name: 'Homeworld',
            isHomeworld: true,
            homeworldValue: 30,
          ),
        ],
      ),
      mapState: GameMapState.initial(),
      shipCounters: createAllCounters(),
      replicatorPlayerState: _gameState.config.playerControlsReplicators
          ? ReplicatorPlayerState.fromEmpireAdvantage(
              _gameState.config.empireAdvantage,
            )
          : null,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prod = _gameState.production;
    final config = _gameState.config;
    final counters = _gameState.shipCounters;
    final activeMods = _gameState.activeModifiers;
    final repPlayer =
        _gameState.replicatorPlayerState ??
        ReplicatorPlayerState.initial(
          empireAdvantageCardNumber: config.selectedEmpireAdvantage,
        );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            _performUndo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            _performUndo,
      },
      child: Focus(
        autofocus: true,
        child: _buildScaffold(
          prod: prod,
          config: config,
          counters: counters,
          activeMods: activeMods,
          repPlayer: repPlayer,
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required ProductionState prod,
    required GameConfig config,
    required List<ShipCounter> counters,
    required List<GameModifier> activeMods,
    required ReplicatorPlayerState repPlayer,
  }) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Wave 5.4: hand-size chip visible on every tab. Tapping jumps to
          // the Production tab (where the Cards section lives).
          if (_gameState.drawnHand.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Tooltip(
                message:
                    '${_gameState.drawnHand.length} card'
                    '${_gameState.drawnHand.length == 1 ? '' : 's'} in hand '
                    '\u2014 tap to open Cards',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectTab(HomeTabId.production),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.style_outlined, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${_gameState.drawnHand.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_undoHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: _undoDescriptions.isNotEmpty
                  ? 'Undo: ${_undoDescriptions.last} '
                      '(${_undoHistory.length} available)'
                  : 'Undo (${_undoHistory.length} available)',
              onPressed: _undo,
            ),
        ],
        title: GestureDetector(
          onTap: _openGameLibrarySheet,
          onLongPress: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SpaceHockeyGame()));
          },
          child: AnimatedBuilder(
            animation: _turnWiggleController,
            builder: (context, child) {
              return Transform.rotate(angle: _turnWiggle.value, child: child);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '$_gameName  \u2022  Turn ${_gameState.turnNumber}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: config.playerControlsReplicators
              ? _ReplicatorPlayerResourceBar(
                  state: repPlayer,
                  turnNumber: _gameState.turnNumber,
                  worlds: _gameState.production.worlds,
                )
              : _ResourceBar(
                  totalCp: prod.totalCp(
                    config,
                    activeMods,
                    _gameState.mapState,
                    counters,
                  ),
                  maintenance: prod.maintenanceTotal(
                    counters,
                    config,
                    activeMods,
                  ),
                  remainingCp: prod.remainingCp(
                    config,
                    counters,
                    activeMods,
                    _gameState.shipSpecialAbilities,
                  ),
                  remainingRp: config.enableFacilities
                      ? prod.remainingRp(config, activeMods)
                      : null,
                  remainingLp: config.enableLogistics
                      ? prod.remainingLp(config, counters, activeMods)
                      : null,
                ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final scenario = scenarioById(_gameState.config.scenarioId);
    final vpConfig = scenario?.victoryPoints;
    final content = switch (_currentTabId) {
      HomeTabId.production =>
        _gameState.config.playerControlsReplicators
            ? ReplicatorPlayerPage(
                turnNumber: _gameState.turnNumber,
                state:
                    _gameState.replicatorPlayerState ??
                    ReplicatorPlayerState.initial(
                      empireAdvantageCardNumber:
                          _gameState.config.selectedEmpireAdvantage,
                    ),
                worlds: _gameState.production.worlds,
                onChanged: _onReplicatorPlayerChanged,
                onWorldsChanged: _onReplicatorPlayerWorldsChanged,
                onEndTurn: _onEndTurn,
              )
            : ProductionPage(
                config: _gameState.config,
                turnNumber: _gameState.turnNumber,
                production: _gameState.production,
                shipCounters: _gameState.shipCounters,
                activeModifiers: _gameState.activeModifiers,
                shipSpecialAbilities: _gameState.shipSpecialAbilities,
                mapState: _gameState.mapState,
                onProductionChanged: _onProductionChanged,
                onEndTurn: _onEndTurn,
                onRuleTap: _navigateToRule,
                onGameStateOverride: _onGameStateOverride,
                onActiveModifiersChanged: _onActiveModifiersChanged,
                onLocateShip: _locateShipOnMap,
                drawnHand: _gameState.drawnHand,
                playedCards: _gameState.playedCards,
                onDrawnHandChanged: _onDrawnHandChanged,
                onPlayCardAsEvent: _onPlayCardAsEvent,
                onPlayCardForCredits: _onPlayCardForCredits,
                onCardPlayedAsEvent: _onCardPlayedAsEvent,
                onCardPlayedForCredits: _onCardPlayedForCredits,
                onCardDiscarded: _onCardDiscarded,
                turnSummaries: _gameState.turnSummaries,
              ),
      HomeTabId.map => () {
        // Pre-compute shipyard capacity data for the hex map overlay.
        final syCapacity = <String, ({int used, int total})>{};
        final fm = _gameState.config.useFacilitiesCosts;
        final tech = _gameState.production.techState;
        final mods = _gameState.activeModifiers;
        for (final hex in _gameState.mapState.hexes) {
          if (hex.shipyardCount <= 0) continue;
          final total = _gameState.production.shipyardCapacityForHex(
            hex.coord, _gameState.mapState, tech,
            facilitiesMode: fm, modifiers: mods,
          );
          final used = _gameState.production.hullPointsSpentInHex(
            hex.coord, facilitiesMode: fm,
          );
          syCapacity[hex.coord.id] = (used: used, total: total);
        }
        return MapPage(
          state: _gameState.mapState.hexes.isEmpty
              ? GameMapState.initial(
                  layoutPreset: _gameState.mapState.layoutPreset,
                )
              : _gameState.mapState,
          productionWorlds: _gameState.production.worlds,
          shipCounters: _gameState.shipCounters,
          focusShipId: _mapFocusShipId,
          focusRequestId: _mapFocusRequestId,
          terraformingLevel: _gameState.production.techState.getLevel(
            TechId.terraforming,
            facilitiesMode: _gameState.config.useFacilitiesCosts,
          ),
          explorationLevel: _gameState.production.techState.getLevel(
            TechId.exploration,
            facilitiesMode: _gameState.config.useFacilitiesCosts,
          ),
          playerMoveLevel: _gameState.production.techState.getLevel(
            TechId.move,
            facilitiesMode: _gameState.config.useFacilitiesCosts,
          ),
          shipyardCapacity: syCapacity,
          onColonizeCandidatesTapped: _openColonizeNowDialog,
          onChanged: _onMapChanged,
          onResolveCombat: _resolveCombat,
          combatLog: _gameState.combatLog,
          onClearCombatLog: () => _updateGameState(
            _gameState.copyWith(combatLog: []),
            'Clear combat log',
          ),
        );
      }(),
      HomeTabId.shipTech => () {
        // Aggregate queued ship purchases by type so the Ship Tech "Build"
        // button can show a "queued" badge and consume the purchase instead
        // of forcing a manual-override stamp.
        final queuedByType = <ShipType, int>{};
        for (final p in _gameState.production.shipPurchases) {
          queuedByType[p.type] = (queuedByType[p.type] ?? 0) + p.quantity;
        }
        return ShipTechPage(
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
          onLocateShip: _locateShipOnMap,
          onGoToProduction: () => _selectTab(HomeTabId.production),
          queuedShipPurchases: queuedByType,
          onConsumeQueuedPurchase: _consumeQueuedShipPurchase,
        );
      }(),
      HomeTabId.aliens => AlienEconomyPage(
        alienPlayers: _gameState.alienPlayers,
        onAlienPlayersChanged: _onAlienPlayersChanged,
      ),
      HomeTabId.replicator => ReplicatorPage(
        state: _gameState.replicatorState ?? const ReplicatorState(),
        onChanged: (newState) {
          _updateGameState(
            _gameState.copyWith(replicatorState: newState),
            'Replicator',
          );
        },
        onEndTurn: () {
          final repState =
              _gameState.replicatorState ?? const ReplicatorState();
          final updated = repState.endTurn();
          _updateGameState(
            _gameState.copyWith(replicatorState: updated),
            'Replicator End Turn',
          );
        },
      ),
      HomeTabId.settings => SettingsPage(
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
        onReopenLastTurn: _reopenLastTurn,
        onReplayTutorial: _replayTutorial,
        confirmEndTurn: _appState.confirmEndTurn,
        onConfirmEndTurnChanged: _onConfirmEndTurnChanged,
        textScale: _appState.textScale,
        onTextScaleChanged: _onTextScaleChanged,
      ),
      HomeTabId.rules => RulesReferencePage(
          key: _rulesKey,
          onApplyCardModifiers: _onApplyCardModifiers,
          activeModifiers: _gameState.activeModifiers,
        ),
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
// PP11: Game library bottom-sheet result envelope
// =============================================================================

enum _GameLibrarySheetAction { load, newGame }

class _GameLibrarySheetResult {
  final _GameLibrarySheetAction action;
  final String? gameId;

  const _GameLibrarySheetResult.load(String id)
      : action = _GameLibrarySheetAction.load,
        gameId = id;

  const _GameLibrarySheetResult.newGame()
      : action = _GameLibrarySheetAction.newGame,
        gameId = null;
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
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));
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
          KeyedSubtree(
            key: TutorialTargets.prodMaintenanceChip,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mnt ', style: dimMono),
                Text('${widget.maintenance}', style: mono),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('Left ', style: dimMono),
          // Task 3C + 3E: animated remaining CP
          ScaleTransition(
            scale: _popScale,
            child: widget.remainingCp < 0
                ? _PulsingText(text: '${widget.remainingCp}', style: warnMono)
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

class _ReplicatorPlayerResourceBar extends StatelessWidget {
  final ReplicatorPlayerState state;
  final int turnNumber;
  final List<WorldState> worlds;

  const _ReplicatorPlayerResourceBar({
    required this.state,
    required this.turnNumber,
    required this.worlds,
  });

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('CP ', style: mono),
            Text('${state.cpPool}', style: mono),
            const SizedBox(width: 14),
            Text('RP ', style: mono),
            Text('${state.rpTotal}', style: mono),
            const SizedBox(width: 14),
            Text('Move ', style: mono),
            Text('${state.moveLevel}', style: mono),
            const SizedBox(width: 14),
            Text('Hulls ', style: mono),
            Text(
              '${state.hullProductionThisTurn(worlds, turnNumber)}',
              style: mono,
            ),
            const Spacer(),
            Text(
              state.empireAdvantage?.name ?? 'Replicator Player',
              style: mono,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
    _opacity = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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

class _ColonyShipCandidate {
  final ShipCounter counter;
  final String fleetId;
  final HexCoord coord;
  final HexTerrain terrain;

  const _ColonyShipCandidate({
    required this.counter,
    required this.fleetId,
    required this.coord,
    required this.terrain,
  });
}
