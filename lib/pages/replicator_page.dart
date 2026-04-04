import 'package:flutter/material.dart';

import '../models/replicator_state.dart';
import '../widgets/number_input.dart';
import '../widgets/section_header.dart';

/// RP milestones: what the Replicator unlocks at each RP threshold.
const List<(int rp, String label)> _kRpMilestones = [
  (1, 'Destroyers'),
  (2, 'Point Defense'),
  (3, 'Cruisers'),
  (4, 'Mines / Mine Sweep'),
  (5, 'Battlecruisers'),
  (6, 'Attack +1'),
  (7, 'Defense +1'),
  (8, 'Cloaking'),
  (9, 'Battleships'),
  (10, 'Scanners'),
  (12, 'Fighters / Carriers'),
  (14, 'Attack +2'),
  (16, 'Dreadnoughts'),
  (18, 'Defense +2'),
  (20, 'Titans'),
];

/// Empire advantage options for the Replicator.
const List<String> _kEmpireAdvantages = [
  'Fast Replicators',
  'Green Replicators',
  'Improved Gunnery',
  'Advanced Research',
  'Replicator Capitol',
];

/// Full-page Replicator opponent tracker.
///
/// Dense, spreadsheet-like layout matching the app's dark theme.
class ReplicatorPage extends StatelessWidget {
  final ReplicatorState state;
  final ValueChanged<ReplicatorState> onChanged;
  final VoidCallback onEndTurn;

  const ReplicatorPage({
    super.key,
    required this.state,
    required this.onChanged,
    required this.onEndTurn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        // ── Turn header ──
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replicator - Turn ${state.turnNumber}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (state.scenarioId != null)
                      Text(
                        [
                          state.mapLabel,
                          state.difficultyLabel,
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              if (state.empireAdvantage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    state.empireAdvantage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Empire advantage picker ──
        if (state.empireAdvantage == null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Advantage:', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              ..._kEmpireAdvantages.map(
                (adv) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ActionChip(
                    label: Text(adv, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        onChanged(state.copyWith(empireAdvantage: adv)),
                  ),
                ),
              ),
              ActionChip(
                label: const Text('None', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    onChanged(state.copyWith(empireAdvantage: '-')),
              ),
            ],
          ),
        ],

        // ── Economy section ──
        const SectionHeader(title: 'Economy'),
        _buildRow(
          context,
          label: 'Colonies',
          child: NumberInput(
            value: state.coloniesCount,
            min: 0,
            onChanged: (v) => onChanged(state.copyWith(coloniesCount: v)),
          ),
        ),
        _buildInfoRow(
          context,
          label: 'Hulls produced this turn',
          value: '${state.hullsProducedPerTurn}',
        ),
        _buildInfoRow(
          context,
          label: 'Colony level',
          value: 'Level ${state.colonyLevel}',
        ),
        _buildInfoRow(
          context,
          label: 'Attack bonus',
          value: '+${state.attackBonus}',
        ),
        _buildInfoRow(
          context,
          label: 'Dreadnought production',
          value: state.canProduceDreadnoughts ? 'Online' : 'Locked',
        ),
        _buildRow(
          context,
          label: 'CP Pool',
          child: NumberInput(
            value: state.cpPool,
            min: 0,
            onChanged: (v) => onChanged(state.copyWith(cpPool: v)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _ActionButton(
              label: 'Buy Hull (8 CP)',
              enabled: state.cpPool >= 8,
              onPressed: () => onChanged(state.copyWith(
                cpPool: state.cpPool - 8,
                hullsAtHomeworld: state.hullsAtHomeworld + 1,
              )),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label:
                  'Buy Move Tech (${state.moveTechCost} CP)',
              enabled: state.cpPool >= state.moveTechCost,
              onPressed: () => onChanged(state.copyWith(
                cpPool: state.cpPool - state.moveTechCost,
                moveLevel: state.moveLevel + 1,
              )),
            ),
          ],
        ),
        _buildInfoRow(
          context,
          label: 'Movement Tech',
          value: 'Level ${state.moveLevel}',
        ),

        // ── RP Tracker ──
        _buildInfoRow(
          context,
          label: 'Starting Systems',
          value:
              'PD ${state.pointDefenseUnlocked ? 'Yes' : 'No'} • Scan ${state.scannersUnlocked ? 'Yes' : 'No'} • SW ${state.minesweepersUnlocked ? 'Yes' : 'No'}',
        ),
        _buildInfoRow(
          context,
          label: 'Flagship',
          value: state.hasFlagship ? 'Present' : 'Not used',
        ),
        const SectionHeader(title: 'Research Points'),
        _buildRow(
          context,
          label: 'Current RP',
          child: NumberInput(
            value: state.rpTotal,
            min: 0,
            onChanged: (v) => onChanged(state.copyWith(rpTotal: v)),
          ),
        ),
        const SizedBox(height: 2),
        _buildMilestoneList(context),

        // ── Hull tracker ──
        const SectionHeader(title: 'Hull Tracker'),
        _buildRow(
          context,
          label: 'Hulls at HW',
          child: NumberInput(
            value: state.hullsAtHomeworld,
            min: 0,
            onChanged: (v) => onChanged(state.copyWith(hullsAtHomeworld: v)),
          ),
        ),
        _buildRow(
          context,
          label: 'Hulls in field',
          child: NumberInput(
            value: state.hullsInField,
            min: 0,
            onChanged: (v) => onChanged(state.copyWith(hullsInField: v)),
          ),
        ),
        _buildInfoRow(
          context,
          label: 'Total hulls',
          value: '${state.totalHulls}',
          bold: true,
        ),

        // ── Fleet log ──
        const SectionHeader(title: 'Fleet Log'),
        ...state.fleetLog.asMap().entries.map(
              (entry) => _buildLogEntry(context, entry.key, entry.value),
            ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addLogEntry(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add entry', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),

        // ── End turn ──
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: () => _confirmEndTurn(context),
            child: Text(
              'End Turn (add ${state.hullsProducedPerTurn} hull${state.hullsProducedPerTurn == 1 ? '' : 's'} from colonies)',
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Layout helpers ──

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: _kRpMilestones.map((m) {
        final unlocked = state.rpTotal >= m.$1;
        return SizedBox(
          height: 24,
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${m.$1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: unlocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                unlocked ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: unlocked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 6),
              Text(
                m.$2,
                style: TextStyle(
                  fontSize: 13,
                  color: unlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: unlocked ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogEntry(BuildContext context, int index, String text) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 16,
              icon: Icon(Icons.close,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              onPressed: () {
                final log = List<String>.from(state.fleetLog)..removeAt(index);
                onChanged(state.copyWith(fleetLog: log));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addLogEntry(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fleet Log Entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. "3 hulls sent to Alpha Centauri"',
            isDense: true,
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              final log = List<String>.from(state.fleetLog)
                ..add(controller.text.trim());
              onChanged(state.copyWith(fleetLog: log));
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final log = List<String>.from(state.fleetLog)
                  ..add(controller.text.trim());
                onChanged(state.copyWith(fleetLog: log));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmEndTurn(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Replicator Turn?'),
        content: Text(
          'This will add ${state.hullsProducedPerTurn} hull${state.hullsProducedPerTurn == 1 ? '' : 's'} '
          'from colonies to the homeworld and advance to turn ${state.turnNumber + 1}. '
          '${((state.economicPhasesCompleted + 1) % 3 == 0) ? 'Colony and attack progression will also advance.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onEndTurn();
            },
            child: const Text('End Turn'),
          ),
        ],
      ),
    );
  }
}

// ── Small action button ──

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Text(label),
    );
  }
}
