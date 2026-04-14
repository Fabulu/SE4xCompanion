// Tutorial step model + the canonical 15-step script for the SE4X
// companion app walkthrough.

import 'package:flutter/widgets.dart';

import '../pages/home_tabs.dart';
import 'tutorial_targets.dart';

/// Where to place the popup card relative to the spotlight target.
enum TutorialAnchor { center, below, above, auto }

/// One step in the tutorial walkthrough.
class TutorialStep {
  /// Stable identifier (used for analytics / debugging).
  final String id;

  /// Title rendered at the top of the popup card.
  final String title;

  /// Body text rendered under the title. Plain text — no markdown.
  final String body;

  /// Single target widget the spotlight should highlight. Either this OR
  /// [targetKeys] should be set; if both are set, [targetKeys] wins.
  /// If both are null the popup is centered with no spotlight cutout.
  final GlobalKey? targetKey;

  /// Optional list of target widgets whose bounding rects are unioned to
  /// produce a single spotlight cutout. Used by `placeHomeworld` so the
  /// onboarding banner stays visible inside the cut.
  final List<GlobalKey>? targetKeys;

  /// Required tab. The controller will refuse to advance to a step whose
  /// `requiredTab` is not currently visible (e.g. the Aliens tab when the
  /// game has no alien players).
  final HomeTabId? requiredTab;

  /// Where to put the popup. `auto` picks below/above based on hole position.
  final TutorialAnchor anchor;

  /// When true, taps inside the spotlight cutout fall through to the
  /// underlying widget (used for `placeHomeworld` so the player can
  /// actually tap a hex). When false the entire screen is blocked.
  final bool allowTargetInteraction;

  /// When true, tapping outside the popup card dismisses the tutorial.
  final bool dismissibleByOutsideTap;

  /// Optional precondition predicate. If supplied and returns false, the
  /// step is auto-skipped by the controller.
  final bool Function()? precondition;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.body,
    this.targetKey,
    this.targetKeys,
    this.requiredTab,
    this.anchor = TutorialAnchor.auto,
    this.allowTargetInteraction = false,
    this.dismissibleByOutsideTap = false,
    this.precondition,
  });
}

/// The canonical 15-step tutorial script.
///
/// IMPORTANT: copy verbatim from the architect plan. Do not edit on a whim;
/// the wording was tuned for new SE4X players.
final List<TutorialStep> kTutorialSteps = <TutorialStep>[
  // 0
  TutorialStep(
    id: 'welcome',
    title: 'Welcome to SE4X Companion',
    body:
        'This app tracks your Space Empires 4X game state — production, '
        'tech, fleets, and the map. It does NOT play the game for you; '
        'you still play SE4X on your tabletop. Tap Next to take a quick '
        'tour of the main screens.',
    anchor: TutorialAnchor.center,
  ),
  // 1
  TutorialStep(
    id: 'scope',
    title: 'What this app does',
    body:
        'Each turn you will come here to spend your Construction Points '
        '(CP), buy tech, build ships, and hit End Turn. The Map tab tracks '
        'fleet positions and exploration. You still play combat and '
        'movement on the tabletop using the SE4X rulebook.',
    anchor: TutorialAnchor.center,
  ),
  // 2 — user-tap-driven intro to the Map tab
  TutorialStep(
    id: 'mapTab',
    title: 'The Map tab',
    body:
        'The Map tab shows your hex board. Tap the Map icon in the bottom '
        'bar to open it. Your first job is to place your Homeworld.',
    targetKey: TutorialTargets.mapTab,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.above,
  ),
  // 3 — homeworld placement (interactive)
  TutorialStep(
    id: 'placeHomeworld',
    title: 'Place your Homeworld',
    body:
        'Tap any hex on the map to plant your Homeworld. Your starting '
        'Shipyards will deploy on it automatically. Once placed, the '
        'tutorial will continue.',
    targetKeys: [TutorialTargets.homeworldBanner, TutorialTargets.mapCanvas],
    requiredTab: HomeTabId.map,
    allowTargetInteraction: true,
    anchor: TutorialAnchor.above,
  ),
  // 4 — Production: income / CP ledger (auto-switch)
  TutorialStep(
    id: 'income',
    title: 'Income & CP',
    body:
        'Each turn you collect Construction Points (CP) from your '
        'Homeworld and colonies. This panel — the CP ledger — shows how '
        'much you earned, how much maintenance costs, and how many CP '
        'you have left to spend.',
    targetKey: TutorialTargets.prodCpLedger,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.below,
  ),
  // 5 — Shipyards
  TutorialStep(
    id: 'shipyards',
    title: 'Shipyards',
    body:
        'Shipyards are where your ships get built. Each one can build up '
        'to a fixed number of hull points per turn (your Ship Yard tech '
        'sets that limit). Every ship you queue is assigned to a specific '
        'shipyard hex, so you always know where it will appear.',
    targetKey: TutorialTargets.prodShipyardsSection,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.auto,
  ),
  // 6 — Ship purchases
  TutorialStep(
    id: 'purchases',
    title: 'Ship Purchases',
    body:
        'This is where you queue up the ships you want to build. You can '
        'change the quantity, see the CP cost, and pick which shipyard '
        'builds each one. CP is actually deducted when you hit End Turn.',
    targetKey: TutorialTargets.prodPurchasesSection,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.auto,
  ),
  // 7 — Tech research
  TutorialStep(
    id: 'tech',
    title: 'Technology',
    body:
        'Spend CP here to raise your tech levels. Each row shows the cost '
        'of the next level and what it unlocks. Any tech you buy is '
        'applied when you end the turn. (Advanced games with the '
        'Facilities option spend Research Points instead of CP — if you '
        'have that turned on, you will see an RP ledger above.)',
    targetKey: TutorialTargets.prodTechSection,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.auto,
  ),
  // 8 — Maintenance
  TutorialStep(
    id: 'maintenance',
    title: 'Maintenance',
    body:
        'Ships you have already built cost a little CP every turn to '
        'keep running. This chip — labelled Mnt, short for Maintenance — '
        'shows the running total. Watch it so you do not build a fleet '
        'you cannot afford to keep.',
    targetKey: TutorialTargets.prodMaintenanceChip,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.below,
  ),
  // 9 — End Turn
  TutorialStep(
    id: 'endTurn',
    title: 'End Turn',
    body:
        'Once you are done spending CP, tap END TURN. A confirmation '
        'dialog will show what is about to happen \u2014 purchases become real '
        'ships, tech upgrades kick in, colonies grow, and the turn '
        'counter ticks forward. You can turn off the confirmation in '
        'Settings if you prefer a faster flow.',
    targetKey: TutorialTargets.prodEndTurnButton,
    requiredTab: HomeTabId.production,
    anchor: TutorialAnchor.above,
  ),
  // 10 — Ship Tech tab
  TutorialStep(
    id: 'shipTech',
    title: 'The Ships tab',
    body:
        'The Ships tab is your fleet ledger. Every ship counter you have '
        'built shows up here, along with the tech levels it was built '
        'with. Tap a counter to inspect it or scrap it.',
    targetKey: TutorialTargets.shipTechTab,
    anchor: TutorialAnchor.above,
  ),
  // 11 — Aliens tab (skipped if no alien players)
  TutorialStep(
    id: 'aliens',
    title: 'The Aliens tab',
    body:
        'In Solitaire mode, alien empires take their turns here. Tap '
        'through to roll their economy and fleet actions — the app '
        'handles all the solo-play lookup tables for you.',
    targetKey: TutorialTargets.aliensTab,
    anchor: TutorialAnchor.above,
  ),
  // 12 — Rules tab
  TutorialStep(
    id: 'rules',
    title: 'The Rules tab',
    body:
        'A searchable copy of the SE4X rulebook lives here. Many panels '
        'in the app link straight to the relevant rule, so you can always '
        'check what a button actually does.',
    targetKey: TutorialTargets.rulesTab,
    anchor: TutorialAnchor.above,
  ),
  // 13 — Settings tab
  TutorialStep(
    id: 'settings',
    title: 'The Settings tab',
    body:
        'Turn expansions and optional rules on or off here, and set up a '
        'new game. You can also save, load, or rename games — and replay '
        'this walkthrough any time from Settings -> Help.',
    targetKey: TutorialTargets.settingsTab,
    anchor: TutorialAnchor.above,
  ),
  // 14 — Done
  TutorialStep(
    id: 'done',
    title: 'You are ready',
    body:
        'That is the whole tour. Have fun playing Space Empires 4X — and '
        'if you ever want a refresher, you can replay this walkthrough '
        'any time from Settings -> Help.',
    anchor: TutorialAnchor.center,
  ),
];
