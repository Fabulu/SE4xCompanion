// Tutorial controller — drives step transitions and exposes state to the
// overlay widget. The HomePage owns the controller and wires it up to the
// game state, tab selection, and persistence.

import 'package:flutter/widgets.dart';

import '../models/game_state.dart';
import '../pages/home_tabs.dart';
import 'tutorial_steps.dart';

typedef TutorialStepVisible = bool Function(TutorialStep step);

class TutorialController extends ChangeNotifier {
  final List<TutorialStep> steps;

  /// Called by the controller when a step requires a specific tab to be
  /// visible. The HomePage should switch to that tab.
  final ValueChanged<HomeTabId> onRequestTab;

  /// Returns true when the player has placed their homeworld. Used by
  /// the placeHomeworld step to advance automatically.
  final bool Function() getHomeworldPlaced;

  /// Returns true if the supplied step is currently presentable
  /// (e.g. the aliens tab is in the visible tab list, or the precondition
  /// passes). The controller falls back to the step's [TutorialStep.precondition]
  /// when this callback is null.
  final TutorialStepVisible? isStepVisible;

  /// Called once when the tutorial finishes (either via finish/skip or
  /// after the last step). The HomePage uses this to persist seen=true.
  final VoidCallback? onFinished;

  bool _active = false;
  int _index = 0;

  TutorialController({
    required this.steps,
    required this.onRequestTab,
    required this.getHomeworldPlaced,
    this.isStepVisible,
    this.onFinished,
  });

  bool get isActive => _active;
  int get currentIndex => _index;
  TutorialStep? get currentStep =>
      _active && _index >= 0 && _index < steps.length ? steps[_index] : null;
  bool get isLastStep => _active && _index == steps.length - 1;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void start({int fromIndex = 0}) {
    if (steps.isEmpty) return;
    _active = true;
    _index = fromIndex.clamp(0, steps.length - 1);
    _ensureStepRequirements();
    _skipInvisibleForward();
    notifyListeners();
  }

  void next() {
    if (!_active) return;
    if (_index >= steps.length - 1) {
      finish();
      return;
    }
    _index++;
    _ensureStepRequirements();
    if (!_isVisible(steps[_index])) {
      // Recursive forward skip — keeps walking until we land on a
      // presentable step or run off the end.
      next();
      return;
    }
    notifyListeners();
  }

  void back() {
    if (!_active) return;
    if (_index <= 0) return;
    _index--;
    _ensureStepRequirements();
    if (!_isVisible(steps[_index])) {
      back();
      return;
    }
    notifyListeners();
  }

  void skip() {
    finish();
  }

  void finish() {
    if (!_active) return;
    _active = false;
    onFinished?.call();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // External event hooks
  // ---------------------------------------------------------------------------

  /// Called by HomePage whenever the game state changes. Used to auto-
  /// advance the placeHomeworld step the moment the player drops their
  /// homeworld onto the map.
  void onGameStateChanged(GameState state) {
    if (!_active) return;
    final step = currentStep;
    if (step == null) return;
    if (step.id == 'placeHomeworld' && getHomeworldPlaced()) {
      next();
    }
  }

  /// Called by HomePage whenever the user taps a bottom-nav tab. Used to
  /// advance "here is the X tab" steps as soon as the user actually opens
  /// the tab the spotlight points at.
  void onTabTapped(HomeTabId tab) {
    if (!_active) return;
    final step = currentStep;
    if (step == null) return;
    final tabIdForStep = _tabForUserTapStep(step.id);
    if (tabIdForStep != null && tabIdForStep == tab) {
      next();
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Steps whose intent is "here is a tab — go tap it". Maps step.id ->
  /// tab id the user must tap to advance.
  HomeTabId? _tabForUserTapStep(String id) {
    switch (id) {
      case 'mapTab':
        return HomeTabId.map;
      case 'shipTech':
        return HomeTabId.shipTech;
      case 'aliens':
        return HomeTabId.aliens;
      case 'rules':
        return HomeTabId.rules;
      case 'settings':
        return HomeTabId.settings;
      default:
        return null;
    }
  }

  /// Steps whose intent is "look at this thing on the Production page" —
  /// the controller force-switches to Production for these.
  static const Set<String> _autoSwitchProductionSteps = {
    'income',
    'tech',
    'purchases',
    'shipyards',
    'maintenance',
    'endTurn',
  };

  void _ensureStepRequirements() {
    final step = currentStep;
    if (step == null) return;
    if (_autoSwitchProductionSteps.contains(step.id)) {
      onRequestTab(HomeTabId.production);
    }
  }

  bool _isVisible(TutorialStep step) {
    if (step.precondition != null && !step.precondition!()) return false;
    if (isStepVisible != null && !isStepVisible!(step)) return false;
    return true;
  }

  void _skipInvisibleForward() {
    while (_active && _index < steps.length && !_isVisible(steps[_index])) {
      _index++;
    }
    if (_index >= steps.length) {
      finish();
    }
  }
}
