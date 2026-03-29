import 'package:flutter/material.dart';

import '../data/alien_tables.dart';
import '../models/alien_economy.dart';
import '../services/dice_service.dart';
import '../widgets/alien_turn_row.dart';
import '../widgets/section_header.dart';

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
                        height: 36,
                        child: Text(
                          widget.alienPlayers[i].name.isEmpty
                              ? 'Alien ${i + 1}'
                              : widget.alienPlayers[i].name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.alienPlayers.length < 3)
                IconButton(
                  onPressed: _addAlien,
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add Alien',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (widget.alienPlayers.length > 1)
                IconButton(
                  onPressed: () => _removeAlien(_tabController.index),
                  icon: const Icon(Icons.remove, size: 18),
                  tooltip: 'Remove Current Alien',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

class _AlienPlayerView extends StatelessWidget {
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

  // ── Roll logic ──

  void _rollForTurn(int turn) {
    final def = getAlienEconDef(turn);
    final dieValues = dice.rollMultiple(def.econRolls);

    final rolls = <AlienEconRoll>[];
    for (final d in dieValues) {
      final outcome = def.resolveRoll(d);
      if (outcome != null) {
        rolls.add(AlienEconRoll(dieResult: d, outcome: outcome));
      }
    }

    // Fleet launch roll (separate)
    final launchRoll = dice.rollD10();
    final launched = def.fleetLaunches(launchRoll);

    final existing = _recordFor(turn);
    final record = AlienTurnRecord(
      turnNumber: turn,
      extraEcon: existing?.extraEcon ?? def.extraEcon,
      rolls: rolls,
      fleetLaunched: launched,
      notes: existing?.notes ?? '',
    );

    // Advance current turn
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No fleets yet.',
              style: TextStyle(
                fontSize: 11,
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
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('Name:', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 4),
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: player.name),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => onChanged(player.copyWith(name: v)),
            ),
          ),
          const SizedBox(width: 16),
          Text('Color:', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
          const SizedBox(width: 4),
          SizedBox(
            width: 100,
            child: TextField(
              controller: TextEditingController(text: player.color),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => onChanged(player.copyWith(color: v)),
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
          onTechNotesChanged: null,
          onDefenseNotesChanged: null,
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
      padding: const EdgeInsets.only(left: 40, bottom: 2),
      child: Text(
        parts.join('  '),
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // ── Fleet log ──

  Widget _buildFleetHeader(BuildContext context) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 4),
          SizedBox(width: 48, child: Text('CP', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 4),
          SizedBox(width: 52, child: Text('Raider?', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 4),
          Expanded(child: Text('Composition', style: style)),
          const SizedBox(width: 4),
          SizedBox(width: 48, child: Text('Turn', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 28), // delete button space
        ],
      ),
    );
  }

  Widget _buildFleetRow(BuildContext context, int index) {
    final fleet = player.fleets[index];
    final theme = Theme.of(context);
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
            width: 28,
            child: Text(
              fleet.fleetNumber.toString(),
              style: monoStyle.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          // CP
          SizedBox(
            width: 48,
            child: TextField(
              controller: TextEditingController(text: fleet.cp == 0 ? '' : fleet.cp.toString()),
              style: monoStyle,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                border: InputBorder.none,
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final cp = int.tryParse(v) ?? 0;
                _updateFleet(index, fleet.copyWith(cp: cp));
              },
            ),
          ),
          const SizedBox(width: 4),
          // Raider checkbox
          SizedBox(
            width: 52,
            child: Checkbox(
              value: fleet.isRaider,
              onChanged: (v) => _updateFleet(index, fleet.copyWith(isRaider: v ?? false)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          // Composition
          Expanded(
            child: TextField(
              controller: TextEditingController(text: fleet.composition),
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                border: InputBorder.none,
                hintText: 'e.g. 2xDD, 1xCA',
              ),
              onSubmitted: (v) => _updateFleet(index, fleet.copyWith(composition: v)),
            ),
          ),
          const SizedBox(width: 4),
          // Launch turn
          SizedBox(
            width: 48,
            child: TextField(
              controller: TextEditingController(
                text: fleet.launchTurn?.toString() ?? '',
              ),
              style: monoStyle,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                border: InputBorder.none,
                hintText: '-',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (v) {
                final lt = int.tryParse(v);
                _updateFleet(
                  index,
                  lt != null
                      ? fleet.copyWith(launchTurn: lt)
                      : fleet.copyWith(clearLaunchTurn: true),
                );
              },
            ),
          ),
          // Delete button
          SizedBox(
            width: 28,
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
              icon: Icon(Icons.close, size: 14, color: theme.colorScheme.error),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 14,
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

  // ── Tech list ──

  Widget _buildTechList(BuildContext context) {
    final theme = Theme.of(context);
    if (player.techsPurchased.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No techs purchased yet.',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (int i = 0; i < player.techsPurchased.length; i++)
          Chip(
            label: Text(
              player.techsPurchased[i],
              style: const TextStyle(fontSize: 11),
            ),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              final techs = List<String>.from(player.techsPurchased)..removeAt(i);
              onChanged(player.copyWith(techsPurchased: techs));
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
      ],
    );
  }

  void _showAddTechDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tech', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Attack 1, Mines, Defense 1',
            isDense: true,
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              final techs = [...player.techsPurchased, v.trim()];
              onChanged(player.copyWith(techsPurchased: techs));
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                final techs = [...player.techsPurchased, v];
                onChanged(player.copyWith(techsPurchased: techs));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Reference table ──

  Widget _buildReferenceTable(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final cellStyle = TextStyle(
      fontSize: 10,
      fontFamily: 'monospace',
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(36),
        1: FixedColumnWidth(32),
        2: FixedColumnWidth(44),
        3: FixedColumnWidth(44),
        4: FixedColumnWidth(44),
        5: FixedColumnWidth(44),
        6: FixedColumnWidth(44),
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
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  // ── Shared small button builder ──

  Widget _miniButton(BuildContext context, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 24,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 11),
        ),
        child: Text('+ $label'),
      ),
    );
  }
}
