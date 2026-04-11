// Centralized GlobalKey registry used by the tutorial overlay to locate
// widgets in the live widget tree. Each key is attached via a layout-
// transparent KeyedSubtree from the relevant page so the tutorial can
// compute a target rect without altering the existing widget hierarchy.

import 'package:flutter/widgets.dart';

class TutorialTargets {
  // Bottom navigation tab icons
  static final GlobalKey productionTab = GlobalKey(debugLabel: 'tut.productionTab');
  static final GlobalKey mapTab = GlobalKey(debugLabel: 'tut.mapTab');
  static final GlobalKey shipTechTab = GlobalKey(debugLabel: 'tut.shipTechTab');
  static final GlobalKey aliensTab = GlobalKey(debugLabel: 'tut.aliensTab');
  static final GlobalKey rulesTab = GlobalKey(debugLabel: 'tut.rulesTab');
  static final GlobalKey settingsTab = GlobalKey(debugLabel: 'tut.settingsTab');

  // Map page
  static final GlobalKey mapCanvas = GlobalKey(debugLabel: 'tut.mapCanvas');
  static final GlobalKey homeworldBanner = GlobalKey(debugLabel: 'tut.homeworldBanner');

  // Production page sections
  static final GlobalKey prodCpLedger = GlobalKey(debugLabel: 'tut.prodCpLedger');
  static final GlobalKey prodTechSection = GlobalKey(debugLabel: 'tut.prodTechSection');
  static final GlobalKey prodShipyardsSection = GlobalKey(debugLabel: 'tut.prodShipyardsSection');
  static final GlobalKey prodPurchasesSection = GlobalKey(debugLabel: 'tut.prodPurchasesSection');
  static final GlobalKey prodMaintenanceChip = GlobalKey(debugLabel: 'tut.prodMaintenanceChip');
  static final GlobalKey prodEndTurnButton = GlobalKey(debugLabel: 'tut.prodEndTurnButton');

  // Other page roots
  static final GlobalKey shipTechPageRoot = GlobalKey(debugLabel: 'tut.shipTechPageRoot');
  static final GlobalKey aliensPageRoot = GlobalKey(debugLabel: 'tut.aliensPageRoot');
  static final GlobalKey rulesPageRoot = GlobalKey(debugLabel: 'tut.rulesPageRoot');
  static final GlobalKey settingsPageRoot = GlobalKey(debugLabel: 'tut.settingsPageRoot');
}
