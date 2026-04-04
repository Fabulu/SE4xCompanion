// Competitive scenario presets from the AGT Competitive Scenario Book.
// Only production-relevant parameters are encoded here (not map layout).

import 'ship_definitions.dart';
import 'tech_costs.dart';

class VictoryPointConfig {
  final int startingPoints;
  final int lossThreshold;
  final String label;
  final String lossText;

  const VictoryPointConfig({
    this.startingPoints = 0,
    required this.lossThreshold,
    this.label = 'Victory Points',
    required this.lossText,
  });
}

class ReplicatorScenarioConfig {
  final String mapLabel;

  const ReplicatorScenarioConfig({
    required this.mapLabel,
  });
}

class ScenarioPreset {
  final String id;
  final String name;
  final String section;
  final String description;
  final int playerCount;
  final String? role; // 'allied', 'solo', null for symmetric

  /// Starting fleet override (null = use standard 3SC/3CS/1MR/4SY).
  final Map<ShipType, int>? startingFleet;

  /// Starting tech overrides applied at game creation.
  final Map<TechId, int> startingTechOverrides;

  /// Multiplier on ship build costs (1.0 = normal, 1.5 = 2v1 allied).
  final double shipCostMultiplier;

  /// Multiplier on tech purchase costs (1.0 = normal).
  final double techCostMultiplier;

  /// Multiplier on non-homeworld colony income (2.0 = 3v1 solo).
  final double colonyIncomeMultiplier;

  /// Extra colony growth steps per turn (0 = normal, 2 = handicap).
  final int colonyGrowthBonus;

  /// Techs blocked by this scenario.
  final List<TechId> blockedTechs;

  /// Ship types blocked by this scenario.
  final List<ShipType> blockedShipTypes;

  /// Optional VP track metadata for solo / co-op scenarios.
  final VictoryPointConfig? victoryPoints;

  /// Optional Replicator setup metadata.
  final ReplicatorScenarioConfig? replicatorSetup;

  const ScenarioPreset({
    required this.id,
    required this.name,
    required this.section,
    required this.description,
    required this.playerCount,
    this.role,
    this.startingFleet,
    this.startingTechOverrides = const {},
    this.shipCostMultiplier = 1.0,
    this.techCostMultiplier = 1.0,
    this.colonyIncomeMultiplier = 1.0,
    this.colonyGrowthBonus = 0,
    this.blockedTechs = const [],
    this.blockedShipTypes = const [],
    this.victoryPoints,
    this.replicatorSetup,
  });
}

ScenarioPreset? scenarioById(String? id) {
  if (id == null) return null;
  for (final scenario in kScenarios) {
    if (scenario.id == id) return scenario;
  }
  return null;
}

/// Standard starting fleet (1.1.1).
const kStandardScenarioFleet = {
  ShipType.scout: 3,
  ShipType.colonyShip: 3,
  ShipType.miner: 1,
  ShipType.shipyard: 4,
};

const List<ScenarioPreset> kScenarios = [
  // ── Standard Scenarios ──

  ScenarioPreset(
    id: 'standard_2p',
    name: 'Standard',
    section: '2.1-2.4',
    description: 'Standard setup. 30 CP Homeworld, 3 Scouts, 3 Colony Ships, 1 Miner, 4 Shipyards.',
    playerCount: 2,
  ),

  ScenarioPreset(
    id: 'standard_3p',
    name: '3-Player Standard',
    section: '3.1',
    description: 'Standard 3-player setup. Recommended to use Non-Player Aliens.',
    playerCount: 3,
  ),

  ScenarioPreset(
    id: 'standard_4p',
    name: '4-Player Standard',
    section: '4.1',
    description: 'Standard 4-player setup.',
    playerCount: 4,
  ),

  // ── Special 2-Player ──

  ScenarioPreset(
    id: 'knife_fight',
    name: 'Knife Fight',
    section: '2.9',
    description: 'Close quarters. Start with Ship Size 3 and Move 2. 4 Scouts, 4 Colony Ships.',
    playerCount: 2,
    startingFleet: {
      ShipType.scout: 4,
      ShipType.colonyShip: 4,
      ShipType.miner: 1,
      ShipType.shipyard: 4,
    },
    startingTechOverrides: {
      TechId.shipSize: 3,
      TechId.move: 2,
    },
  ),

  ScenarioPreset(
    id: 'quick_start',
    name: 'Quick Start',
    section: '1.1.11',
    description: 'All home planets pre-colonized. No Colony Ships. Faster early game.',
    playerCount: 2,
    startingFleet: {
      ShipType.scout: 3,
      ShipType.miner: 1,
      ShipType.shipyard: 4,
    },
  ),

  // ── Team Scenarios ──

  ScenarioPreset(
    id: '3p_2v1_allied',
    name: '3P 2v1 (Allied Side)',
    section: '3.3',
    description: 'Uneasy Alliance. All ships and tech cost 1.5x (rounded up). Maintenance normal.',
    playerCount: 3,
    role: 'allied',
    shipCostMultiplier: 1.5,
    techCostMultiplier: 1.5,
  ),

  ScenarioPreset(
    id: '3p_2v1_solo',
    name: '3P 2v1 (Solo Side)',
    section: '3.3',
    description: 'Solo player vs two allies. Normal costs.',
    playerCount: 3,
    role: 'solo',
  ),

  ScenarioPreset(
    id: '4p_3v1_solo',
    name: '4P 3v1 (Solo Side)',
    section: '4.5',
    description: 'Solo vs three Blood Brothers. Double colony income (except Homeworld). Draw 3 EAs, pick 1.',
    playerCount: 4,
    role: 'solo',
    colonyIncomeMultiplier: 2.0,
  ),

  ScenarioPreset(
    id: '4p_3v1_team',
    name: '4P 3v1 (Team Side)',
    section: '4.5',
    description: 'Blood Brothers team of 3. Start with Terraforming 1 and Scanners 1 free.',
    playerCount: 4,
    role: 'allied',
    startingTechOverrides: {
      TechId.terraforming: 1,
      TechId.scanners: 1,
    },
  ),

  // ── Quick Conquest ──

  ScenarioPreset(
    id: 'quick_conquest',
    name: 'Quick Conquest',
    section: '7.1',
    description: 'No Mines or Minesweepers. Uses Technology Head Start card. First to destroy a Homeworld wins.',
    playerCount: 4,
    blockedTechs: [TechId.mines, TechId.mineSweep],
    blockedShipTypes: [ShipType.mine, ShipType.sw],
  ),

  // ── Handicap ──

  ScenarioPreset(
    id: 'handicap',
    name: 'Handicap (Weaker Player)',
    section: '1.1.12',
    description: 'Colonies grow 2 extra steps per turn. Use for less experienced players.',
    playerCount: 2,
    colonyGrowthBonus: 2,
  ),

  // ── Solo: Doomsday Machine ──

  ScenarioPreset(
    id: 'dm_small_easy',
    name: 'DM Small - Easy',
    section: '2.7',
    description: 'Solo. Small map, 3 DMs. Arrive turns 7/9/11 at ratings 1/3/5.',
    playerCount: 1,
  ),

  ScenarioPreset(
    id: 'dm_small_normal',
    name: 'DM Small - Normal',
    section: '2.7',
    description: 'Solo. Small map, 3 DMs. Arrive turns 7/9/10 at ratings 2/4/6.',
    playerCount: 1,
  ),

  ScenarioPreset(
    id: 'dm_small_hard',
    name: 'DM Small - Hard',
    section: '2.7',
    description: 'Solo. Small map, 3 DMs. Arrive turns 6/8/10 at ratings 1/3/5.',
    playerCount: 1,
  ),

  ScenarioPreset(
    id: 'dm_large_easy',
    name: 'DM Large - Easy',
    section: '2.8',
    description: 'Solo. Large map, 3 DMs. Arrive turns 8/10/12 at ratings 5/7/9.',
    playerCount: 1,
  ),

  ScenarioPreset(
    id: 'dm_large_normal',
    name: 'DM Large - Normal',
    section: '2.8',
    description: 'Solo. Large map, 3 DMs. Arrive turns 8/10/11 at ratings 6/8/10.',
    playerCount: 1,
  ),

  // ── Coop: Doomsday Machine ──

  ScenarioPreset(
    id: 'dm_coop_2p_easy',
    name: 'DM Coop 2P - Easy',
    section: '8.0',
    description: 'Coop 2P. 5 DMs arrive turns 6/8/7/10/12. VP track: 10 = loss.',
    playerCount: 2,
    victoryPoints: VictoryPointConfig(
      lossThreshold: 10,
      label: 'DM VP',
      lossText: '10 = loss',
    ),
  ),

  ScenarioPreset(
    id: 'dm_coop_2p_normal',
    name: 'DM Coop 2P - Normal',
    section: '8.0',
    description: 'Coop 2P. 5 DMs arrive turns 6/8/7/10/12 at higher ratings. VP track.',
    playerCount: 2,
    victoryPoints: VictoryPointConfig(
      lossThreshold: 10,
      label: 'DM VP',
      lossText: '10 = loss',
    ),
  ),

  // ── Solo: Alien Empire VP ──

  ScenarioPreset(
    id: 'alien_vp_easy',
    name: 'Alien Empire VP - Easy',
    section: '6.0',
    description: 'Solo vs 2 APs. VP track: 10 AP VP = loss. Start with Terra 1 + Explore 1.',
    playerCount: 1,
    startingTechOverrides: {TechId.terraforming: 1, TechId.exploration: 1},
    victoryPoints: VictoryPointConfig(
      lossThreshold: 10,
      label: 'Alien VP',
      lossText: '10 alien VP = loss',
    ),
  ),

  ScenarioPreset(
    id: 'alien_vp_normal',
    name: 'Alien Empire VP - Normal',
    section: '6.0',
    description: 'Solo vs 2 APs. VP track: 10 AP VP = loss. 10 CP/roll. Start with Terra 1 + Explore 1.',
    playerCount: 1,
    startingTechOverrides: {TechId.terraforming: 1, TechId.exploration: 1},
    victoryPoints: VictoryPointConfig(
      lossThreshold: 10,
      label: 'Alien VP',
      lossText: '10 alien VP = loss',
    ),
  ),

  // ── Solo: Replicator ──

  ScenarioPreset(
    id: 'replicator_standard',
    name: 'Replicator - Standard',
    section: '7.13',
    description: 'Solo vs Replicators. Standard map. 4 Colony Ships, 4 SY, 3 SC, 1 Miner.',
    playerCount: 1,
    startingFleet: {
      ShipType.scout: 3,
      ShipType.colonyShip: 4,
      ShipType.miner: 1,
      ShipType.shipyard: 4,
    },
    blockedShipTypes: [ShipType.decoy],
    replicatorSetup: ReplicatorScenarioConfig(
      mapLabel: 'Standard',
    ),
  ),

  ScenarioPreset(
    id: 'replicator_large',
    name: 'Replicator - Large',
    section: '7.14',
    description: 'Solo vs Replicators. Large map. Same starting forces.',
    playerCount: 1,
    startingFleet: {
      ShipType.scout: 3,
      ShipType.colonyShip: 4,
      ShipType.miner: 1,
      ShipType.shipyard: 4,
    },
    blockedShipTypes: [ShipType.decoy],
    replicatorSetup: ReplicatorScenarioConfig(
      mapLabel: 'Large',
    ),
  ),
];
