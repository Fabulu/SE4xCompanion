import 'package:flutter/material.dart';

import '../models/replicator_player_state.dart';
import '../models/world.dart';
import '../widgets/number_input.dart';
import '../widgets/section_header.dart';

class ReplicatorPlayerPage extends StatelessWidget {
  final int turnNumber;
  final ReplicatorPlayerState state;
  final List<WorldState> worlds;
  final ValueChanged<ReplicatorPlayerState> onChanged;
  final ValueChanged<List<WorldState>> onWorldsChanged;
  final VoidCallback onEndTurn;

  const ReplicatorPlayerPage({
    super.key,
    required this.turnNumber,
    required this.state,
    required this.worlds,
    required this.onChanged,
    required this.onWorldsChanged,
    required this.onEndTurn,
  });

  @override
  Widget build(BuildContext context) {
    final fullColonies = state.fullColonyCount(worlds);
    final homeworldFull = state.homeworldIsFull(worlds);
    final totalProduction = state.hullProductionThisTurn(worlds, turnNumber);
    final extraHomeworldHulls = state.homeworldExtraHullProduction(
      worlds,
      turnNumber,
    );
    final depletionDue =
        turnNumber >= state.depletionThresholdPhase &&
        worlds.any((w) => !w.isHomeworld);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Replicator Player - Turn $turnNumber',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            // Wave 2.4: Player-controlled mode badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.tertiary,
                  width: 1,
                ),
              ),
              child: Text(
                'PLAYER MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(label: 'CP', value: '${state.cpPool}'),
            _StatChip(label: 'RP', value: '${state.rpTotal}/15'),
            _StatChip(label: 'Move', value: '${state.moveLevel}'),
            _StatChip(label: 'Full Colonies', value: '$fullColonies'),
            _StatChip(label: 'Hulls This Turn', value: '$totalProduction'),
            _StatChip(
              label: 'Total Hulls',
              value: '${state.totalHullsProducedLifetime}',
            ),
            _StatChip(
              label: 'Deplete EP',
              value: '${state.depletionThresholdPhase}+',
            ),
          ],
        ),
        if (state.empireAdvantage != null) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EA #${state.empireAdvantageCardNumber}: '
                    '${state.empireAdvantage!.name}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.empireAdvantage!.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (state.isImprovedGunnery || state.isWarpGates) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: mechanical effects of this EA are display-only; '
                      'apply them manually in combat/build actions.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const SectionHeader(title: 'Flagship'),
        if (!state.hasFlagship)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flagship destroyed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        onChanged(state.copyWith(hasFlagship: true)),
                    child: const Text('Rebuild'),
                  ),
                ],
              ),
            ),
          ),
        if (state.hasFlagship) ...[
          _infoRow(
            context,
            'Stats',
            'B${state.flagshipHullSize}-${state.flagshipAttack}-'
                'x${1 + state.flagshipDefense} '
                '(A${state.flagshipAttack}/D${state.flagshipDefense})',
          ),
          _infoRow(
            context,
            'Move / Tactics',
            '${state.moveLevel} / '
                '${state.explorationResearched ? 2 : 1}',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged(state.copyWith(hasFlagship: false)),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Mark destroyed'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const SectionHeader(title: 'Movement Tech'),
        _infoRow(context, 'Level', '${state.moveLevel} / 3'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            _moveAutoUpgradeHint(state.moveLevel, turnNumber),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Economy'),
        _numberRow(
          context,
          label: 'CP Pool',
          value: state.cpPool,
          onChanged: (value) => onChanged(state.copyWith(cpPool: value)),
        ),
        _numberRow(
          context,
          label: 'RP Total',
          value: state.rpTotal,
          onChanged: (value) =>
              onChanged(state.copyWith(rpTotal: value.clamp(0, 15))),
        ),
        _numberRow(
          context,
          label: 'Purchased RP',
          value: state.purchasedRpCount,
          onChanged: (value) =>
              onChanged(state.copyWith(purchasedRpCount: value.clamp(0, 5))),
        ),
        _numberRow(
          context,
          label: 'Space Wrecks Found',
          value: state.spaceWrecksEncountered,
          onChanged: (value) => onChanged(
            state.copyWith(spaceWrecksEncountered: value.clamp(0, 99)),
          ),
        ),
        _numberRow(
          context,
          label: 'First Combat Bonuses',
          value: state.firstCombatBonuses,
          onChanged: (value) => onChanged(
            state.copyWith(firstCombatBonuses: value.clamp(0, 99)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Expanded(child: Text('Things Encountered')),
              Text(
                '${state.thingsEncountered.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final type in ReplicatorEncounterType.all)
              FilterChip(
                label: Text(ReplicatorEncounterType.label(type)),
                selected: state.thingsEncountered.contains(type),
                visualDensity: VisualDensity.compact,
                onSelected: (selected) {
                  final list = List<String>.from(state.thingsEncountered);
                  if (selected && !list.contains(type)) {
                    list.add(type);
                  } else if (!selected) {
                    list.remove(type);
                  }
                  onChanged(state.copyWith(thingsEncountered: list));
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              label: state.boughtRpThisPhase
                  ? 'RP Bought This Phase'
                  : 'Buy RP (${state.rpPurchaseCost} CP)',
              enabled:
                  !state.boughtRpThisPhase &&
                  state.cpPool >= state.rpPurchaseCost &&
                  state.purchasedRpCount < 5 &&
                  state.rpTotal < 15,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - state.rpPurchaseCost,
                  rpTotal: (state.rpTotal + 1).clamp(0, 15),
                  purchasedRpCount: state.purchasedRpCount + 1,
                  boughtRpThisPhase: true,
                ),
              ),
            ),
            _ActionChip(
              label: state.boughtMoveThisPhase
                  ? 'Move Bought This Phase'
                  : 'Buy Move (${state.moveTechCost} CP)',
              enabled:
                  !state.boughtMoveThisPhase &&
                  state.cpPool >= state.moveTechCost,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - state.moveTechCost,
                  moveLevel: state.moveLevel + 1,
                  boughtMoveThisPhase: true,
                ),
              ),
            ),
            _ActionChip(
              label: state.homeworldBoostPurchased
                  ? 'HW Boost Purchased'
                  : 'Boost Homeworld (8 CP)',
              enabled: !state.homeworldBoostPurchased && state.cpPool >= 8,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - 8,
                  homeworldBoostPurchased: true,
                ),
              ),
            ),
            _ActionChip(
              label: 'Mineral Hex (+5 CP)',
              enabled: true,
              onPressed: () =>
                  onChanged(state.copyWith(cpPool: state.cpPool + 5)),
            ),
            _ActionChip(
              label: 'Discard AT (+10 CP)',
              enabled: true,
              onPressed: () =>
                  onChanged(state.copyWith(cpPool: state.cpPool + 10)),
            ),
            _ActionChip(
              label: '+Space Wreck (+1 RP)',
              enabled: state.rpTotal < 15,
              onPressed: () => onChanged(
                state.copyWith(
                  rpTotal: (state.rpTotal + 1).clamp(0, 15),
                  spaceWrecksEncountered: state.spaceWrecksEncountered + 1,
                ),
              ),
            ),
            _ActionChip(
              label: '+Hull Produced',
              enabled: true,
              onPressed: () => onChanged(
                state.copyWith(
                  totalHullsProducedLifetime:
                      state.totalHullsProducedLifetime + 1,
                ),
              ),
            ),
            _ActionChip(
              label: '-Hull Produced',
              enabled: state.totalHullsProducedLifetime > 0,
              onPressed: () => onChanged(
                state.copyWith(
                  totalHullsProducedLifetime:
                      (state.totalHullsProducedLifetime - 1)
                          .clamp(0, 9999),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Research (Paid)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              label: 'Research Exploration (15 CP)',
              enabled: !state.explorationResearched && state.cpPool >= 15,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - 15,
                  explorationResearched: true,
                ),
              ),
            ),
            _ActionChip(
              label: 'Research PD (15 CP)',
              enabled: !state.pointDefenseUnlocked && state.cpPool >= 15,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - 15,
                  pointDefenseUnlocked: true,
                ),
              ),
            ),
            _ActionChip(
              label: 'Research Scanners (15 CP)',
              enabled: !state.scannersUnlocked && state.cpPool >= 15,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - 15,
                  scannersUnlocked: true,
                ),
              ),
            ),
            _ActionChip(
              label: 'Research Sweepers (15 CP)',
              enabled: !state.minesweepersUnlocked && state.cpPool >= 15,
              onPressed: () => onChanged(
                state.copyWith(
                  cpPool: state.cpPool - 15,
                  minesweepersUnlocked: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Encounter Auto-Unlock (RAW 40.7, free):',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              label: 'Encountered Fighter → PD',
              enabled: !state.pointDefenseUnlocked,
              onPressed: () =>
                  onChanged(state.copyWith(pointDefenseUnlocked: true)),
            ),
            _ActionChip(
              label: 'Encountered Cloak → Scanners',
              enabled: !state.scannersUnlocked,
              onPressed: () => onChanged(state.copyWith(scannersUnlocked: true)),
            ),
            _ActionChip(
              label: 'Encountered Mine → Sweepers',
              enabled: !state.minesweepersUnlocked,
              onPressed: () =>
                  onChanged(state.copyWith(minesweepersUnlocked: true)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Production Summary'),
        _infoRow(context, 'Homeworld Full', homeworldFull ? 'Yes' : 'No'),
        _infoRow(
          context,
          'Base Hull Production',
          '${fullColonies + (homeworldFull ? 1 : 0)}',
        ),
        _infoRow(context, 'Extra HW Hulls', '$extraHomeworldHulls'),
        _infoRow(context, 'Total Hulls This Turn', '$totalProduction'),
        _infoRow(
          context,
          'Lifetime Hulls Produced',
          '${state.totalHullsProducedLifetime}',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Depletion starts at Economic Phase '
            '${state.depletionThresholdPhase} '
            '(RAW 40.3.3${state.isGreenReplicators ? " + EA #61" : ""}).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
        ),
        if (depletionDue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Economic Phase ${state.depletionThresholdPhase}+ — '
                      'deplete one colony this phase (RAW 40.3.3).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => _promptDepletion(context),
                      child: const Text('Deplete Colony…'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Colonies'),
        ..._buildWorldRows(context),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addColony,
            icon: const Icon(Icons.add),
            label: const Text('Add Colony'),
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Game Log'),
        if (state.notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No entries yet. Tap + to add a note.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          )
        else
          ...state.notes.asMap().entries.map(
                (entry) => _buildNoteEntry(context, entry.key, entry.value),
              ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addNoteEntry(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add entry'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onEndTurn,
            child: Text(
              'End Turn (record $totalProduction produced hulls manually)',
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _moveAutoUpgradeHint(int moveLevel, int turnNumber) {
    if (moveLevel >= 3) {
      return 'Move tech maxed (Level 3).';
    }
    if (moveLevel >= 2) {
      return turnNumber >= 16
          ? 'Auto-upgrade to Level 3 available (EP 16+, RAW 40.2.1).'
          : 'Auto-upgrade to Level 3 at EP 16 (RAW 40.2.1).';
    }
    // moveLevel == 1
    if (turnNumber >= 16) {
      return 'Auto-upgrade to Level 3 available (EP 16+, RAW 40.2.1).';
    }
    if (turnNumber >= 8) {
      return 'Auto-upgrade to Level 2 available (EP 8+, RAW 40.2.1).';
    }
    return 'Auto-upgrade to Level 2 at EP 8, Level 3 at EP 16 (RAW 40.2.1).';
  }

  Widget _buildNoteEntry(BuildContext context, int index, String text) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () {
        final notes = List<String>.from(state.notes)..removeAt(index);
        onChanged(state.copyWith(notes: notes));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: Icon(
                Icons.circle,
                size: 6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _editNoteEntry(context, index, text),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              iconSize: 16,
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: () {
                final notes = List<String>.from(state.notes)..removeAt(index);
                onChanged(state.copyWith(notes: notes));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNoteEntry(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Log Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. "3 hulls sent to Alpha Centauri"',
            isDense: true,
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final notes = [...state.notes, result];
    onChanged(state.copyWith(notes: notes));
  }

  Future<void> _editNoteEntry(
    BuildContext context,
    int index,
    String initial,
  ) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final notes = List<String>.from(state.notes);
    notes[index] = result;
    onChanged(state.copyWith(notes: notes));
  }

  Future<void> _promptDepletion(BuildContext context) async {
    final colonies = [
      for (int i = 0; i < worlds.length; i++)
        if (!worlds[i].isHomeworld) MapEntry(i, worlds[i]),
    ];
    if (colonies.isEmpty) return;
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Deplete which colony?'),
        children: [
          for (final entry in colonies)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, entry.key),
              child: Text(
                '${entry.value.name} (growth ${entry.value.growthMarkerLevel})',
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    final target = worlds[chosen];
    final newLevel = (target.growthMarkerLevel - 1).clamp(0, 3);
    final next = [...worlds];
    next[chosen] = target.copyWith(growthMarkerLevel: newLevel);
    onWorldsChanged(next);
  }

  List<Widget> _buildWorldRows(BuildContext context) {
    final result = <Widget>[];
    for (int index = 0; index < worlds.length; index++) {
      final world = worlds[index];
      result.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        world.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!world.isHomeworld)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeWorld(index),
                      ),
                  ],
                ),
                if (world.isHomeworld)
                  _numberRow(
                    context,
                    label: 'Homeworld Value',
                    value: world.homeworldValue,
                    onChanged: (value) => _updateWorld(
                      index,
                      world.copyWith(homeworldValue: value.clamp(5, 30)),
                    ),
                  )
                else
                  _numberRow(
                    context,
                    label: 'Growth',
                    value: world.growthMarkerLevel,
                    onChanged: (value) => _updateWorld(
                      index,
                      world.copyWith(growthMarkerLevel: value.clamp(0, 3)),
                    ),
                  ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Blocked'),
                  value: world.isBlocked,
                  onChanged: (value) =>
                      _updateWorld(index, world.copyWith(isBlocked: value)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return result;
  }

  Widget _numberRow(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          NumberInput(value: value, min: 0, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  void _addColony() {
    final next = [
      ...worlds,
      WorldState(
        id: WorldState.createId(),
        name:
            'Colony ${worlds.where((world) => !world.isHomeworld).length + 1}',
        growthMarkerLevel: 0,
      ),
    ];
    onWorldsChanged(next);
  }

  void _removeWorld(int index) {
    final next = [...worlds]..removeAt(index);
    onWorldsChanged(next);
  }

  void _updateWorld(int index, WorldState world) {
    final next = [...worlds];
    next[index] = world;
    onWorldsChanged(next);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: enabled ? onPressed : null,
    );
  }
}
