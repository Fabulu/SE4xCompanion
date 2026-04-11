import 'package:flutter/material.dart';

import '../data/alien_tables.dart';
import '../data/ship_definitions.dart';
import '../models/alien_economy.dart';
import '../models/game_config.dart';
import '../services/dice_service.dart';
import '../tutorial/tutorial_targets.dart';
import '../widgets/alien_turn_row.dart';
import '../widgets/animated_dice.dart';
import '../widgets/section_header.dart';

// ── Standard solitaire alien tech list ──
const List<String> kAlienTechOptions = [
  'Attack 1',
  'Attack 2',
  'Attack 3',
  'Defense 1',
  'Defense 2',
  'Tactics 1',
  'Move 2',
  'Move 3',
  'Cloaking 1',
  'Scanners 1',
  'Fighters 1',
  'Point Defense 1',
  'Mines 1',
  'Mine Sweep 1',
  'Ground 2',
  'Security 1',
];

// ── Color options for alien player color picker ──
const Map<String, Color> _kColorOptions = {
  'Red': Color(0xFFF44336),
  'Green': Color(0xFF4CAF50),
  'Blue': Color(0xFF2196F3),
  'Yellow': Color(0xFFFFEB3B),
  'Purple': Color(0xFF9C27B0),
  'Orange': Color(0xFFFF9800),
};

// ── Ship types for the alien fleet composition picker ──
//
// PP03 (Findings A.1 + A.2):
// Previously this file hardcoded alien ship CP costs (DD=9, SW=5, etc.)
// that drifted from the canonical `kShipDefinitions` table. Per the SSB
// rules (§4.6, §4.6.1 "AP Fleet Building") the Alien Player purchases
// ships the same way a human player does — so their CP costs should
// follow the *same* `effectiveBuildCost(...)` pipeline the player uses,
// driven by the active [GameConfig] (Alternate Empire + Facilities/AGT).
//
// The picker still tracks ship classes by a short abbreviation string
// (for backward-compat with existing saved `composition` strings like
// "2xDD, 1xCA") — but costs are now looked up through [alienShipCost]
// so there is a single source of truth.

/// Ship rows shown in the fleet composition picker.
///
/// The `abbreviation` is the picker/display code used in the saved
/// composition string; `type` is the canonical [ShipType] used to look
/// up the build cost from [kShipDefinitions].
class _ShipTypeRow {
  final String abbreviation;
  final String name;
  final ShipType type;

  const _ShipTypeRow(this.abbreviation, this.name, this.type);
}

const List<_ShipTypeRow> _kShipTypes = [
  _ShipTypeRow('SC', 'Scout', ShipType.scout),
  _ShipTypeRow('DD', 'Destroyer', ShipType.dd),
  _ShipTypeRow('CA', 'Cruiser', ShipType.ca),
  _ShipTypeRow('BC', 'Battlecruiser', ShipType.bc),
  _ShipTypeRow('BB', 'Battleship', ShipType.bb),
  _ShipTypeRow('DN', 'Dreadnought', ShipType.dn),
  _ShipTypeRow('Raider', 'Raider', ShipType.raider),
  _ShipTypeRow('Fighter', 'Fighter', ShipType.fighter),
  _ShipTypeRow('CV', 'Carrier', ShipType.cv),
  _ShipTypeRow('Transport', 'Transport', ShipType.transport),
  _ShipTypeRow('Mine', 'Mine', ShipType.mine),
  _ShipTypeRow('SW', 'Minesweeper', ShipType.sw),
];

/// Returns the CP cost the Alien Player pays to build one ship of [type]
/// under the given [config]. When [config] is null, base-game (non-AGT,
/// non-alternate-empire) costs are used — this matches the default
/// [GameConfig] and gives a stable answer for unit tests and legacy call
/// sites that do not yet pipe in the active game config.
///
/// Per SSB §4.6 "AP Fleet Building" the Alien Player buys ships the same
/// way the human player does, so its costs follow the canonical
/// [ShipDefinition.effectiveBuildCost] pipeline.
int alienShipCost(ShipType type, [GameConfig? config]) {
  final def = kShipDefinitions[type];
  if (def == null) return 0;
  final cfg = config ?? const GameConfig();
  return def.effectiveBuildCost(
    cfg.enableAlternateEmpire,
    facilitiesMode: cfg.useFacilitiesCosts,
  );
}

/// Sum the CP cost of a composition map like {"DD": 2, "CA": 1}.
///
/// Ship-class keys that don't match a known picker row are ignored
/// (returning 0 CP for that entry).
int alienCompositionCp(Map<String, int> quantities, [GameConfig? config]) {
  int total = 0;
  for (final row in _kShipTypes) {
    final qty = quantities[row.abbreviation] ?? 0;
    if (qty > 0) total += qty * alienShipCost(row.type, config);
  }
  return total;
}

/// Parse a saved composition string (e.g. "2xDD, 1xCA") into a quantities
/// map. Tolerant of loose whitespace and mixed separators; unknown tokens
/// are ignored so malformed saves degrade gracefully to 0.
Map<String, int> parseAlienComposition(String composition) {
  final result = <String, int>{};
  if (composition.isEmpty) return result;
  final parts = composition.split(RegExp(r'[,;]\s*'));
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    // Match patterns like "2xDD", "1 x CA", "3 DD", "DD".
    final match = RegExp(r'^(\d+)\s*[xX]?\s*(.+)$').firstMatch(trimmed);
    if (match != null) {
      final qty = int.tryParse(match.group(1)!) ?? 1;
      final type = match.group(2)!.trim();
      for (final row in _kShipTypes) {
        if (row.abbreviation.toLowerCase() == type.toLowerCase()) {
          result[row.abbreviation] = (result[row.abbreviation] ?? 0) + qty;
          break;
        }
      }
    }
  }
  return result;
}

/// Parse a saved composition string and return its total CP under [config].
/// Used by the fleet row to render a live, always-in-sync CP column.
int alienCompositionCpFromString(String composition, [GameConfig? config]) {
  if (composition.isEmpty) return 0;
  return alienCompositionCp(parseAlienComposition(composition), config);
}

/// Full-page alien economy tracker for 1-3 solitaire alien opponents.
///
/// Manages turn-by-turn economy rolls, fleet logs, and tech tracking
/// for each alien player. Replaces the paper alien economy sheet.
class AlienEconomyPage extends StatelessWidget {
  final List<AlienPlayer> alienPlayers;
  final ValueChanged<List<AlienPlayer>> onAlienPlayersChanged;

  const AlienEconomyPage({
    super.key,
    required this.alienPlayers,
    required this.onAlienPlayersChanged,
  });

  @override
  Widget build(BuildContext context) {
    // If no aliens yet, show a prompt to add one.
    if (alienPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No alien players yet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addAlien(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Alien Player'),
            ),
          ],
        ),
      );
    }

    return _AlienEconomyBody(
      key: TutorialTargets.aliensPageRoot,
      alienPlayers: alienPlayers,
      onAlienPlayersChanged: onAlienPlayersChanged,
    );
  }

  void _addAlien() {
    final index = alienPlayers.length + 1;
    onAlienPlayersChanged([
      ...alienPlayers,
      AlienPlayer(name: 'Alien $index'),
    ]);
  }
}

class _AlienEconomyBody extends StatefulWidget {
  final List<AlienPlayer> alienPlayers;
  final ValueChanged<List<AlienPlayer>> onAlienPlayersChanged;

  const _AlienEconomyBody({
    super.key,
    required this.alienPlayers,
    required this.onAlienPlayersChanged,
  });

  @override
  State<_AlienEconomyBody> createState() => _AlienEconomyBodyState();
}

class _AlienEconomyBodyState extends State<_AlienEconomyBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DiceService _dice = DiceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.alienPlayers.length,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_AlienEconomyBody old) {
    super.didUpdateWidget(old);
    if (old.alienPlayers.length != widget.alienPlayers.length) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: widget.alienPlayers.length,
        vsync: this,
        initialIndex: oldIndex.clamp(0, (widget.alienPlayers.length - 1).clamp(0, 99)),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  void _updatePlayer(int index, AlienPlayer player) {
    final list = List<AlienPlayer>.from(widget.alienPlayers);
    list[index] = player;
    widget.onAlienPlayersChanged(list);
  }

  void _addAlien() {
    final idx = widget.alienPlayers.length + 1;
    widget.onAlienPlayersChanged([
      ...widget.alienPlayers,
      AlienPlayer(name: 'Alien $idx'),
    ]);
  }

  void _removeAlien(int index) {
    final list = List<AlienPlayer>.from(widget.alienPlayers)..removeAt(index);
    widget.onAlienPlayersChanged(list);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar + add/remove controls
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (int i = 0; i < widget.alienPlayers.length; i++)
                      Tab(
                        height: 44,
                        child: Text(
                          widget.alienPlayers[i].name.isEmpty
                              ? 'Alien ${i + 1}'
                              : widget.alienPlayers[i].name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.alienPlayers.length < 3)
                IconButton(
                  onPressed: _addAlien,
                  icon: const Icon(Icons.add, size: 24),
                  tooltip: 'Add Alien',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              if (widget.alienPlayers.length > 1)
                IconButton(
                  onPressed: () => _removeAlien(_tabController.index),
                  icon: const Icon(Icons.remove, size: 24),
                  tooltip: 'Remove Current Alien',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
            ],
          ),
        ),

        // Per-alien body
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (int i = 0; i < widget.alienPlayers.length; i++)
                _AlienPlayerView(
                  player: widget.alienPlayers[i],
                  playerIndex: i,
                  dice: _dice,
                  onChanged: (p) => _updatePlayer(i, p),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Per-alien view: turn table, fleet log, tech list, reference
// ═══════════════════════════════════════════════════════════════════

class _AlienPlayerView extends StatefulWidget {
  final AlienPlayer player;
  final int playerIndex;
  final DiceService dice;
  final ValueChanged<AlienPlayer> onChanged;

  const _AlienPlayerView({
    required this.player,
    required this.playerIndex,
    required this.dice,
    required this.onChanged,
  });

  @override
  State<_AlienPlayerView> createState() => _AlienPlayerViewState();
}

class _AlienPlayerViewState extends State<_AlienPlayerView>
    with TickerProviderStateMixin {
  AlienPlayer get player => widget.player;
  DiceService get dice => widget.dice;
  ValueChanged<AlienPlayer> get onChanged => widget.onChanged;

  // ── Turn record helpers ──

  AlienTurnRecord? _recordFor(int turn) {
    for (final r in player.turnRecords) {
      if (r.turnNumber == turn) return r;
    }
    return null;
  }

  List<AlienTurnRecord> _updatedRecords(int turn, AlienTurnRecord record) {
    final list = List<AlienTurnRecord>.from(player.turnRecords);
    final idx = list.indexWhere((r) => r.turnNumber == turn);
    if (idx >= 0) {
      list[idx] = record;
    } else {
      list.add(record);
    }
    return list;
  }

  // ── Roll logic with animated dice (Sub-task C) ──

  Future<void> _rollForTurn(int turn) async {
    final def = getAlienEconDef(turn);
    final dieValues = dice.rollMultiple(def.econRolls);
    final launchRoll = dice.rollD10();

    // Show animated dice dialog
    if (!mounted) return;
    await _showAnimatedRollDialog(
      context: context,
      econDieValues: dieValues,
      launchDieValue: launchRoll,
      def: def,
      turn: turn,
    );
  }

  Future<void> _showAnimatedRollDialog({
    required BuildContext context,
    required List<int> econDieValues,
    required int launchDieValue,
    required AlienEconTurnDef def,
    required int turn,
  }) async {
    final diceController = AnimatedDiceController();
    final launchDiceController = AnimatedDiceController();
    bool resolved = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Kick off the economy dice animation
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await diceController.roll(econDieValues, this);

          // After econ dice land, roll the fleet launch die if applicable
          if (def.fleetLaunchRange != '-') {
            await Future.delayed(const Duration(milliseconds: 300));
            await launchDiceController.roll([launchDieValue], this);
          }
        });

        return AlertDialog(
          title: Text('Turn $turn Economy Roll',
              style: const TextStyle(fontSize: 16)),
          content: SizedBox(
            width: 320,
            child: ListenableBuilder(
              listenable: Listenable.merge([diceController, launchDiceController]),
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Economy Rolls:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    AnimatedDiceDisplay(controller: diceController),
                    if (diceController.showTotal) ...[
                      const SizedBox(height: 8),
                      _buildOutcomeSummary(econDieValues, def),
                    ],
                    if (def.fleetLaunchRange != '-') ...[
                      const SizedBox(height: 16),
                      const Text('Fleet Launch Roll:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      AnimatedDiceDisplay(controller: launchDiceController),
                      if (launchDiceController.showTotal) ...[
                        const SizedBox(height: 4),
                        Text(
                          def.fleetLaunches(launchDieValue)
                              ? 'Fleet LAUNCHES! (need ${def.fleetLaunchRange})'
                              : 'No launch (need ${def.fleetLaunchRange})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: def.fleetLaunches(launchDieValue)
                                ? Colors.green
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
          actions: [
            ListenableBuilder(
              listenable: Listenable.merge([diceController, launchDiceController]),
              builder: (context, _) {
                final econDone = !diceController.isRolling &&
                    diceController.dice.isNotEmpty;
                final launchDone = def.fleetLaunchRange == '-' ||
                    (!launchDiceController.isRolling &&
                        launchDiceController.dice.isNotEmpty);
                final allDone = econDone && launchDone;

                return TextButton(
                  onPressed: allDone
                      ? () {
                          if (!resolved) {
                            resolved = true;
                            _applyRollResults(
                                turn, def, econDieValues, launchDieValue);
                          }
                          diceController.disposeControllers();
                          launchDiceController.disposeControllers();
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  child: const Text('Apply'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutcomeSummary(List<int> dieValues, AlienEconTurnDef def) {
    final parts = <String>[];
    for (final d in dieValues) {
      final outcome = def.resolveRoll(d);
      if (outcome != null) {
        final label = switch (outcome) {
          AlienEconOutcomeType.econ => 'Econ',
          AlienEconOutcomeType.fleet => 'Fleet',
          AlienEconOutcomeType.tech => 'Tech',
          AlienEconOutcomeType.def => 'Def',
        };
        parts.add('$d\u2192$label');
      }
    }
    return Text(
      parts.join('  '),
      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
    );
  }

  void _applyRollResults(
      int turn, AlienEconTurnDef def, List<int> dieValues, int launchRoll) {
    final rolls = <AlienEconRoll>[];
    for (final d in dieValues) {
      final outcome = def.resolveRoll(d);
      if (outcome != null) {
        rolls.add(AlienEconRoll(dieResult: d, outcome: outcome));
      }
    }

    final launched = def.fleetLaunches(launchRoll);

    final existing = _recordFor(turn);
    final record = AlienTurnRecord(
      turnNumber: turn,
      extraEcon: existing?.extraEcon ?? def.extraEcon,
      rolls: rolls,
      fleetLaunched: launched,
      notes: existing?.notes ?? '',
    );

    final newTurn = turn < 20 ? turn + 1 : turn;
    onChanged(player.copyWith(
      currentTurn: newTurn,
      turnRecords: _updatedRecords(turn, record),
    ));
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    // Show turns 1..max(currentTurn+2, 10) so there is always look-ahead.
    final maxVisible = (player.currentTurn + 2).clamp(10, 20);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // Header: name + color
        _buildNameColorRow(context),
        const SizedBox(height: 8),

        // ── Turn Table ──
        SectionHeader(
          title: 'ALIEN ECONOMY',
          subtitle: player.name,
        ),
        const AlienTurnHeader(),
        for (int t = 1; t <= maxVisible; t++) _buildTurnRow(context, t),
        const SizedBox(height: 16),

        // ── Fleet Log ──
        SectionHeader(
          title: 'FLEET LOG',
          trailing: _miniButton(context, 'Add Fleet', () {
            final fleets = List<AlienFleetEntry>.from(player.fleets)
              ..add(AlienFleetEntry(fleetNumber: player.fleets.length + 1));
            onChanged(player.copyWith(fleets: fleets));
          }),
        ),
        _buildFleetHeader(context),
        for (int i = 0; i < player.fleets.length; i++) _buildFleetRow(context, i),
        if (player.fleets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No fleets yet.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        const SizedBox(height: 16),

        // ── Techs Purchased ──
        SectionHeader(
          title: 'ALIEN TECHS PURCHASED',
          trailing: _miniButton(context, 'Add Tech', () => _showAddTechDialog(context)),
        ),
        _buildTechList(context),
        const SizedBox(height: 16),

        // ── Reference Table ──
        const SectionHeader(title: 'REFERENCE: Economy Roll Results'),
        _buildReferenceTable(context),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Name / color row ──

  Widget _buildNameColorRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text('Name:', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: _AlienNameField(
              initialValue: player.name,
              onCommitted: (v) => onChanged(player.copyWith(name: v)),
            ),
          ),
          const SizedBox(width: 16),
          Text('Color:', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: DropdownButton<String>(
              value: _kColorOptions.containsKey(player.color) ? player.color : _kColorOptions.keys.first,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final entry in _kColorOptions.entries)
                  DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(entry.key, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(player.copyWith(color: v));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Turn rows ──

  Widget _buildTurnRow(BuildContext context, int turn) {
    final record = _recordFor(turn);
    final isCurrent = turn == player.currentTurn;
    final isPast = record != null && record.rolls.isNotEmpty;
    final def = getAlienEconDef(turn);

    // Build roll results for AlienTurnRow
    List<AlienRollResult>? results;
    if (isPast) {
      results = record.rolls.map((r) {
        final label = switch (r.outcome) {
          AlienEconOutcomeType.econ => 'Econ',
          AlienEconOutcomeType.fleet => 'Fleet',
          AlienEconOutcomeType.tech => 'Tech',
          AlienEconOutcomeType.def => 'Def',
        };
        return AlienRollResult(dieValue: r.dieResult, outcome: label);
      }).toList();
    }

    // Build fleet/tech/def note strings from results
    String fleetNotes = '';
    String techNotes = '';
    String defenseNotes = '';
    if (isPast) {
      // Show launch indicator in fleet notes
      if (record.fleetLaunched) {
        fleetNotes = 'L';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AlienTurnRow(
          turnNumber: turn,
          econRolls: def.econRolls,
          results: results,
          extraEcon: record?.extraEcon ?? def.extraEcon,
          fleetNotes: fleetNotes,
          techNotes: techNotes,
          defenseNotes: defenseNotes,
          isCurrent: isCurrent,
          onRoll: isCurrent && !isPast ? () => _rollForTurn(turn) : null,
          onExtraEconChanged: isCurrent || isPast
              ? (v) {
                  final rec = record ??
                      AlienTurnRecord(turnNumber: turn, extraEcon: v);
                  onChanged(player.copyWith(
                    turnRecords: _updatedRecords(turn, rec.copyWith(extraEcon: v)),
                  ));
                }
              : null,
          onFleetNotesChanged: isCurrent
              ? (v) {
                  final rec = record ?? AlienTurnRecord(turnNumber: turn);
                  onChanged(player.copyWith(
                    turnRecords: _updatedRecords(turn, rec.copyWith(notes: v)),
                  ));
                }
              : null,
        ),
        // If this turn was rolled, show a summary line
        if (isPast)
          _buildRollSummary(context, record, def),
      ],
    );
  }

  Widget _buildRollSummary(
      BuildContext context, AlienTurnRecord record, AlienEconTurnDef def) {
    final theme = Theme.of(context);
    final parts = <String>[];
    for (final r in record.rolls) {
      final label = switch (r.outcome) {
        AlienEconOutcomeType.econ => 'E',
        AlienEconOutcomeType.fleet => 'F',
        AlienEconOutcomeType.tech => 'T',
        AlienEconOutcomeType.def => 'D',
      };
      parts.add('${r.dieResult}\u2192$label');
    }
    if (def.fleetLaunchRange != '-') {
      parts.add(record.fleetLaunched ? 'Launch:Y' : 'Launch:N');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 44, bottom: 4),
      child: Text(
        parts.join('  '),
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // ── Fleet log ──

  Widget _buildFleetHeader(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: 52, child: Text('CP', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: 52, child: Text('Raider?', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(child: Text('Composition', style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 52, child: Text('Turn', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 40), // delete button space
        ],
      ),
    );
  }

  Widget _buildFleetRow(BuildContext context, int index) {
    final fleet = player.fleets[index];
    final theme = Theme.of(context);
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Fleet number
          SizedBox(
            width: 32,
            child: Text(
              fleet.fleetNumber.toString(),
              style: monoStyle.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // CP — derived from composition (PP03 Finding A.2: single source
          // of truth). The saved `fleet.cp` is kept in sync by the picker
          // on Apply; we display the live computed value here so the field
          // cannot drift even if a stale cp was loaded from disk.
          SizedBox(
            width: 52,
            child: Text(
              alienCompositionCpFromString(fleet.composition).toString(),
              textAlign: TextAlign.center,
              style: monoStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          // Raider checkbox
          SizedBox(
            width: 52,
            child: Checkbox(
              value: fleet.isRaider,
              onChanged: (v) => _updateFleet(index, fleet.copyWith(isRaider: v ?? false)),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              visualDensity: VisualDensity.standard,
            ),
          ),
          const SizedBox(width: 8),
          // Composition (Sub-task B: button that opens picker)
          Expanded(
            child: InkWell(
              onTap: () => _showFleetCompositionPicker(context, index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(
                  fleet.composition.isEmpty ? 'Tap to set...' : fleet.composition,
                  style: TextStyle(
                    fontSize: 14,
                    color: fleet.composition.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Launch turn
          SizedBox(
            width: 64,
            child: DropdownButton<int?>(
              value: fleet.launchTurn,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: monoStyle,
              hint: Text('-', style: monoStyle),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('-', style: monoStyle),
                ),
                for (int t = 1; t <= 20; t++)
                  DropdownMenuItem<int?>(
                    value: t,
                    child: Text(t.toString(), style: monoStyle),
                  ),
              ],
              onChanged: (v) {
                _updateFleet(
                  index,
                  v != null
                      ? fleet.copyWith(launchTurn: v)
                      : fleet.copyWith(clearLaunchTurn: true),
                );
              },
            ),
          ),
          // Delete button
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () {
                final fleets = List<AlienFleetEntry>.from(player.fleets)..removeAt(index);
                // Renumber
                final renumbered = [
                  for (int i = 0; i < fleets.length; i++)
                    fleets[i].copyWith(fleetNumber: i + 1),
                ];
                onChanged(player.copyWith(fleets: renumbered));
              },
              icon: Icon(Icons.close, size: 20, color: theme.colorScheme.error),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              splashRadius: 20,
              tooltip: 'Remove fleet',
            ),
          ),
        ],
      ),
    );
  }

  void _updateFleet(int index, AlienFleetEntry fleet) {
    final fleets = List<AlienFleetEntry>.from(player.fleets);
    fleets[index] = fleet;
    onChanged(player.copyWith(fleets: fleets));
  }

  // ── Fleet Composition Picker (Sub-task B) ──

  void _showFleetCompositionPicker(BuildContext context, int fleetIndex) {
    final fleet = player.fleets[fleetIndex];
    // Parse existing composition into quantities
    final quantities = parseAlienComposition(fleet.composition);

    showDialog(
      context: context,
      builder: (ctx) => _FleetCompositionDialog(
        initialQuantities: quantities,
        onApply: (newQuantities) {
          final compositionStr = _formatComposition(newQuantities);
          // PP03 Finding A.2: write the computed CP back in lock-step with
          // the composition so the two can never drift out of sync even
          // when older callers read `fleet.cp` directly.
          final derivedCp = alienCompositionCp(newQuantities);
          _updateFleet(
            fleetIndex,
            fleet.copyWith(composition: compositionStr, cp: derivedCp),
          );
        },
      ),
    );
  }

  /// Format a quantities map into a composition string.
  static String _formatComposition(Map<String, int> quantities) {
    final parts = <String>[];
    for (final st in _kShipTypes) {
      final qty = quantities[st.abbreviation] ?? 0;
      if (qty > 0) {
        parts.add('${qty}x${st.abbreviation}');
      }
    }
    return parts.join(', ');
  }

  // ── Tech list ──

  Widget _buildTechList(BuildContext context) {
    final theme = Theme.of(context);
    if (player.techsPurchased.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No techs purchased yet.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (int i = 0; i < player.techsPurchased.length; i++)
          Chip(
            label: Text(
              player.techsPurchased[i],
              style: const TextStyle(fontSize: 14),
            ),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              final techs = List<String>.from(player.techsPurchased)..removeAt(i);
              onChanged(player.copyWith(techsPurchased: techs));
            },
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
      ],
    );
  }

  // ── Sub-task A: Selectable tech list dialog ──

  void _showAddTechDialog(BuildContext context) {
    final purchased = Set<String>.from(player.techsPurchased);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Alien Tech', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: kAlienTechOptions.length,
            itemBuilder: (context, index) {
              final tech = kAlienTechOptions[index];
              final alreadyPurchased = purchased.contains(tech);

              return ListTile(
                dense: true,
                enabled: !alreadyPurchased,
                title: Text(
                  tech,
                  style: TextStyle(
                    fontSize: 15,
                    color: alreadyPurchased
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3)
                        : null,
                  ),
                ),
                trailing: alreadyPurchased
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      )
                    : null,
                onTap: alreadyPurchased
                    ? null
                    : () {
                        final techs = [...player.techsPurchased, tech];
                        onChanged(player.copyWith(techsPurchased: techs));
                        Navigator.of(ctx).pop();
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ── Reference table ──

  Widget _buildReferenceTable(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final cellStyle = TextStyle(
      fontSize: 13,
      fontFamily: 'monospace',
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(42),
        1: FixedColumnWidth(38),
        2: FixedColumnWidth(50),
        3: FixedColumnWidth(50),
        4: FixedColumnWidth(50),
        5: FixedColumnWidth(50),
        6: FixedColumnWidth(50),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          children: [
            _refCell('Turn', headerStyle),
            _refCell('Rolls', headerStyle),
            _refCell('Econ', headerStyle),
            _refCell('Fleet', headerStyle),
            _refCell('Tech', headerStyle),
            _refCell('Def', headerStyle),
            _refCell('Launch', headerStyle),
          ],
        ),
        for (final def in kAlienEconSchedule)
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            children: [
              _refCell(def.turn.toString(), cellStyle),
              _refCell(def.econRolls.toString(), cellStyle),
              _refCell(def.econRange, cellStyle),
              _refCell(def.fleetRange, cellStyle),
              _refCell(def.techRange, cellStyle),
              _refCell(def.defRange, cellStyle),
              _refCell(def.fleetLaunchRange, cellStyle),
            ],
          ),
      ],
    );
  }

  Widget _refCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  // ── Shared small button builder ──

  Widget _miniButton(BuildContext context, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(48, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(fontSize: 14),
        ),
        child: Text('+ $label'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Fleet Composition Picker Dialog (Sub-task B)
// ═══════════════════════════════════════════════════════════════════

class _FleetCompositionDialog extends StatefulWidget {
  final Map<String, int> initialQuantities;
  final ValueChanged<Map<String, int>> onApply;

  const _FleetCompositionDialog({
    required this.initialQuantities,
    required this.onApply,
  });

  @override
  State<_FleetCompositionDialog> createState() =>
      _FleetCompositionDialogState();
}

class _FleetCompositionDialogState extends State<_FleetCompositionDialog> {
  late Map<String, int> _quantities;

  @override
  void initState() {
    super.initState();
    _quantities = Map<String, int>.from(widget.initialQuantities);
  }

  // Per-ship CP cost via canonical [kShipDefinitions]. Picker still uses
  // base-game (default GameConfig) costs — wiring the active GameConfig in
  // from the caller is a follow-up (PP03 scope is limited to this file).
  int _costFor(_ShipTypeRow row) => alienShipCost(row.type);

  int get _totalCp => alienCompositionCp(_quantities);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Fleet Composition', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total CP header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total CP: $_totalCp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Ship type list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _kShipTypes.length,
                itemBuilder: (context, index) {
                  final st = _kShipTypes[index];
                  final qty = _quantities[st.abbreviation] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        // Ship name and abbreviation
                        SizedBox(
                          width: 130,
                          child: Text(
                            '${st.name} (${st.abbreviation})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        // CP cost
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${_costFor(st)}CP',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        // - button
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            onPressed: qty > 0
                                ? () {
                                    setState(() {
                                      _quantities[st.abbreviation] = qty - 1;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                          ),
                        ),
                        // Quantity
                        SizedBox(
                          width: 32,
                          child: Text(
                            qty.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: qty > 0
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        // + button
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _quantities[st.abbreviation] = qty + 1;
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(_quantities);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Name input that saves on submit (Enter) AND on blur (focus loss).
/// Ensures user edits are not lost when tapping elsewhere without hitting Enter.
class _AlienNameField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onCommitted;

  const _AlienNameField({
    required this.initialValue,
    required this.onCommitted,
  });

  @override
  State<_AlienNameField> createState() => _AlienNameFieldState();
}

class _AlienNameFieldState extends State<_AlienNameField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late String _lastCommitted;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastCommitted = widget.initialValue;
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_AlienNameField old) {
    super.didUpdateWidget(old);
    // Sync from parent if the canonical value changed externally and we're not editing.
    if (widget.initialValue != _lastCommitted && !_focusNode.hasFocus) {
      _lastCommitted = widget.initialValue;
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final v = _controller.text;
    if (v == _lastCommitted) return;
    _lastCommitted = v;
    widget.onCommitted(v);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 15),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      onSubmitted: (_) => _commit(),
    );
  }
}
