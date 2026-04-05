import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/scenarios.dart';
import '../data/ship_definitions.dart';
import '../data/special_abilities.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../models/turn_summary.dart';
import '../widgets/empire_advantage_picker.dart';

class SettingsPage extends StatelessWidget {
  final GameConfig config;
  final String gameName;
  final int turnNumber;
  final List<SavedGame> savedGames;
  final String? activeGameId;
  final ValueChanged<GameConfig> onConfigChanged;
  final ValueChanged<String> onGameNameChanged;
  final VoidCallback onNewGame;
  final ValueChanged<String> onLoadGame;
  final Function(String, String) onRenameGame;
  final ValueChanged<String> onDeleteGame;
  final VoidCallback onDuplicateGame;
  final VoidCallback onResetGame;
  final VoidCallback onSetupStartingFleet;
  final List<TurnSummary> turnSummaries;
  final GameState gameState;
  final ValueChanged<GameState>? onImportGame;
  final Map<ShipType, int> shipSpecialAbilities;
  final ValueChanged<Map<ShipType, int>>? onSpecialAbilitiesChanged;

  const SettingsPage({
    super.key,
    required this.config,
    required this.gameName,
    required this.turnNumber,
    required this.savedGames,
    required this.activeGameId,
    this.turnSummaries = const [],
    required this.gameState,
    required this.onConfigChanged,
    required this.onGameNameChanged,
    required this.onNewGame,
    required this.onLoadGame,
    required this.onRenameGame,
    required this.onDeleteGame,
    required this.onDuplicateGame,
    required this.onResetGame,
    required this.onSetupStartingFleet,
    this.onImportGame,
    this.shipSpecialAbilities = const {},
    this.onSpecialAbilitiesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // ── Game Setup ──
        _SectionTitle(title: 'GAME SETUP'),
        const SizedBox(height: 8),
        _GameNameTile(gameName: gameName, onChanged: onGameNameChanged),
        ListTile(
          title: const Text('Turn', style: TextStyle(fontSize: 16)),
          trailing: Text(
            '$turnNumber',
            style: TextStyle(
              fontSize: 16,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!config.playerControlsReplicators)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSetupStartingFleet,
                icon: const Icon(Icons.rocket_launch, size: 20),
                label: const Text(
                  'Setup Starting Fleet',
                  style: TextStyle(fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ),
        const Divider(height: 24),

        // ── Turn Log ──
        if (turnSummaries.isNotEmpty) ...[
          _SectionTitle(title: 'TURN LOG'),
          const SizedBox(height: 8),
          for (final summary in turnSummaries)
            _TurnSummaryTile(summary: summary),
          const Divider(height: 24),
        ],

        // ── Expansions Owned ──
        _SectionTitle(title: 'EXPANSIONS OWNED'),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Close Encounters', style: TextStyle(fontSize: 16)),
          value: config.ownership.closeEncounters,
          onChanged: (v) => onConfigChanged(
            config.copyWith(
              ownership: config.ownership.copyWith(closeEncounters: v),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Replicators', style: TextStyle(fontSize: 16)),
          value: config.ownership.replicators,
          onChanged: (v) => onConfigChanged(
            config.copyWith(
              ownership: config.ownership.copyWith(replicators: v),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('All Good Things', style: TextStyle(fontSize: 16)),
          value: config.ownership.allGoodThings,
          onChanged: (v) => onConfigChanged(
            config.copyWith(
              ownership: config.ownership.copyWith(allGoodThings: v),
            ),
          ),
        ),
        const Divider(height: 24),

        // ── Optional Rules ──
        _SectionTitle(title: 'OPTIONAL RULES'),
        const SizedBox(height: 8),
        _RuleToggle(
          title: 'Enable Facilities',
          value: config.enableFacilities,
          enabled: config.ownership.allGoodThings,
          disabledReason: 'Requires All Good Things expansion',
          onChanged: (v) => _setFacilities(v),
        ),
        _RuleToggle(
          title: 'Enable Logistics',
          value: config.enableLogistics,
          enabled: config.enableFacilities,
          disabledReason: 'Requires Facilities enabled',
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableLogistics: v)),
        ),
        _RuleToggle(
          title: 'Enable Temporal',
          value: config.enableTemporal,
          enabled: config.enableFacilities,
          disabledReason: 'Requires Facilities enabled',
          onChanged: (v) => onConfigChanged(config.copyWith(enableTemporal: v)),
        ),
        _RuleToggle(
          title: 'Enable Advanced Construction',
          value: config.enableAdvancedConstruction,
          enabled: true,
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableAdvancedConstruction: v)),
        ),
        _RuleToggle(
          title: 'Replicator Opponent',
          value: config.enableReplicators && !config.playerControlsReplicators,
          enabled: config.ownership.replicators,
          disabledReason: 'Requires Replicators expansion',
          onChanged: (v) => onConfigChanged(
            config.copyWith(
              enableReplicators: v,
              playerControlsReplicators: v
                  ? false
                  : config.playerControlsReplicators,
            ),
          ),
        ),
        _RuleToggle(
          title: 'Player-Controlled Replicators',
          value: config.playerControlsReplicators,
          enabled: config.ownership.replicators,
          disabledReason: 'Requires Replicators expansion',
          onChanged: (v) => onConfigChanged(
            config.copyWith(
              playerControlsReplicators: v,
              enableReplicators: v ? true : config.enableReplicators,
            ),
          ),
        ),
        _RuleToggle(
          title: 'Enable Ship Experience',
          value: config.enableShipExperience,
          enabled: true,
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableShipExperience: v)),
        ),
        _RuleToggle(
          title: 'Unpredictable Research',
          value: config.enableUnpredictableResearch,
          enabled: true,
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableUnpredictableResearch: v)),
        ),
        _RuleToggle(
          title: 'Alternate Empire',
          value: config.enableAlternateEmpire,
          enabled: config.ownership.closeEncounters,
          disabledReason: 'Requires Close Encounters expansion',
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableAlternateEmpire: v)),
        ),
        const Divider(height: 24),

        // ── Scenario ──
        _SectionTitle(title: 'SCENARIO'),
        const SizedBox(height: 8),
        _ScenarioTile(config: config, onConfigChanged: onConfigChanged),
        if ((scenarioById(config.scenarioId)?.replicatorSetup != null ||
                config.enableReplicators) &&
            !config.playerControlsReplicators)
          _ReplicatorDifficultyTile(
            config: config,
            onConfigChanged: onConfigChanged,
          ),
        const Divider(height: 24),

        // ── Empire Advantage ──
        _SectionTitle(title: 'EMPIRE ADVANTAGE'),
        const SizedBox(height: 8),
        _EmpireAdvantageTile(config: config, onConfigChanged: onConfigChanged),

        // ── Ship Special Abilities (Alternate Empire only) ──
        if (config.enableAlternateEmpire) ...[
          const SizedBox(height: 16),
          _SectionTitle(title: 'SHIP SPECIAL ABILITIES'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Rule 24.2: Roll d12 for each ship type before the game starts.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final shipType in kAbilityEligibleShipTypes)
            _SpecialAbilityRow(
              shipType: shipType,
              currentAbility: shipSpecialAbilities[shipType],
              onChanged: (value) {
                final updated = Map<ShipType, int>.from(shipSpecialAbilities);
                if (value == null) {
                  updated.remove(shipType);
                } else {
                  updated[shipType] = value;
                }
                onSpecialAbilitiesChanged?.call(updated);
              },
            ),
        ],

        const Divider(height: 24),

        // ── Game Library ──
        _SectionTitle(title: 'GAME LIBRARY'),
        const SizedBox(height: 8),
        for (final game in savedGames)
          _SavedGameTile(
            game: game,
            isActive: game.id == activeGameId,
            onTap: () => onLoadGame(game.id),
            onRename: () => _showRenameDialog(context, game),
            onDelete: () => _showDeleteConfirm(context, game),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onNewGame,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Game', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onDuplicateGame,
              icon: const Icon(Icons.copy, size: 20),
              label: const Text('Duplicate', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _exportGame(context),
              icon: const Icon(Icons.upload, size: 20),
              label: const Text('Export', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _importGame(context),
              icon: const Icon(Icons.download, size: 20),
              label: const Text('Import', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // ── Danger Zone ──
        _SectionTitle(title: 'DANGER ZONE', color: theme.colorScheme.error),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showResetConfirm(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'Reset Current Game',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const Divider(height: 32),

        // ── About ──
        _SectionTitle(title: 'ABOUT'),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          title: const Text(
            'SE4X Companion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Version 1.0.0\n\u00A9 2026 Fabian Trunz',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          isThreeLine: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'SE4X Companion is an unofficial, fan-made companion for the '
              'board game Space Empires 4X by Jim Krohn, published by GMT '
              'Games, LLC. Not affiliated with or endorsed by GMT Games. '
              'Trademarks belong to their respective owners. A physical copy '
              'of the game is required.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credits',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\u2022 Game design: Jim Krohn (GMT Games, LLC)\n'
                '\u2022 App author: Fabian Trunz (@Fabulu)\n'
                '\u2022 AI assistance: Claude Code (Anthropic)',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          leading: const Icon(Icons.description_outlined, size: 20),
          title: const Text(
            'Open source licenses',
            style: TextStyle(fontSize: 14),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'SE4X Companion',
            applicationVersion: '1.0.0',
            applicationLegalese: '\u00A9 2026 Fabian Trunz',
          ),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.code, size: 20),
          title: const Text('GitHub', style: TextStyle(fontSize: 14)),
          subtitle: const SelectableText(
            'https://github.com/Fabulu/SE4xCompanion',
            style: TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy URL',
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'https://github.com/Fabulu/SE4xCompanion',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GitHub URL copied')),
              );
            },
          ),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.privacy_tip_outlined, size: 20),
          title: const Text(
            'Privacy policy',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const SelectableText(
            'https://github.com/Fabulu/SE4xCompanion/blob/master/PRIVACY_POLICY.md',
            style: TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy URL',
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text:
                      'https://github.com/Fabulu/SE4xCompanion/blob/master/PRIVACY_POLICY.md',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy URL copied')),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Import / Export ──

  void _exportGame(BuildContext context) {
    final json = jsonEncode(gameState.toJson());
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Game copied to clipboard')));
  }

  Future<void> _importGame(BuildContext context) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data == null || data.text == null || data.text!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
        }
        return;
      }
      final parsed = jsonDecode(data.text!) as Map<String, dynamic>;
      final imported = GameState.fromJson(parsed);
      onImportGame?.call(imported);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game imported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString()}')),
        );
      }
    }
  }

  // ── Config helpers ──

  void _setFacilities(bool enabled) {
    var newConfig = config.copyWith(enableFacilities: enabled);
    if (!enabled) {
      // Disable dependent rules when facilities is turned off
      newConfig = newConfig.copyWith(
        enableLogistics: false,
        enableTemporal: false,
      );
    }
    onConfigChanged(newConfig);
  }

  // ── Dialogs ──

  void _showRenameDialog(BuildContext context, SavedGame game) {
    final controller = TextEditingController(text: game.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Game'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Game name'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              onRenameGame(game.id, v.trim());
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
                onRenameGame(game.id, v);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, SavedGame game) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game?'),
        content: Text(
          'Permanently delete "${game.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onDeleteGame(game.id);
    });
  }

  void _showResetConfirm(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Game?'),
        content: const Text(
          'This will reset all production, tech, ships, and aliens back to '
          'turn 1. Your config settings will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onResetGame();
    });
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionTitle({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color:
              color ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _GameNameTile extends StatefulWidget {
  final String gameName;
  final ValueChanged<String> onChanged;

  const _GameNameTile({required this.gameName, required this.onChanged});

  @override
  State<_GameNameTile> createState() => _GameNameTileState();
}

class _GameNameTileState extends State<_GameNameTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.gameName);
  }

  @override
  void didUpdateWidget(_GameNameTile old) {
    super.didUpdateWidget(old);
    if (old.gameName != widget.gameName &&
        _controller.text != widget.gameName) {
      _controller.text = widget.gameName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Game Name', style: TextStyle(fontSize: 16)),
      trailing: SizedBox(
        width: 180,
        child: TextField(
          controller: _controller,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.end,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              widget.onChanged(v.trim());
            }
          },
        ),
      ),
    );
  }
}

class _RuleToggle extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final String? disabledReason;
  final ValueChanged<bool> onChanged;

  const _RuleToggle({
    required this.title,
    required this.value,
    required this.enabled,
    this.disabledReason,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: (!enabled && disabledReason != null)
          ? Text(
              disabledReason!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
              ),
            )
          : null,
      value: value && enabled,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _SavedGameTile extends StatelessWidget {
  final SavedGame game;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _SavedGameTile({
    required this.game,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updatedStr = _formatDate(game.updatedAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: isActive ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(6),
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn ${game.state.turnNumber}  |  $updatedStr',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRename,
                icon: const Icon(Icons.edit, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                splashRadius: 20,
                tooltip: 'Rename',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                splashRadius: 20,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _TurnSummaryTile extends StatelessWidget {
  final TurnSummary summary;

  const _TurnSummaryTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimStyle = TextStyle(
      fontSize: 14,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    final details = <Widget>[];

    if (summary.techsGained.isNotEmpty) {
      details.add(
        Text('Techs: ${summary.techsGained.join(", ")}', style: dimStyle),
      );
    }
    if (summary.shipsBuilt.isNotEmpty) {
      details.add(
        Text('Ships: ${summary.shipsBuilt.join(", ")}', style: dimStyle),
      );
    }
    if (summary.coloniesGrown > 0) {
      details.add(
        Text('Colonies grown: ${summary.coloniesGrown}', style: dimStyle),
      );
    }
    details.add(
      Text('Maintenance: ${summary.maintenancePaid}', style: dimStyle),
    );
    details.add(Text('CP carry-over: ${summary.cpCarryOver}', style: dimStyle));
    if (summary.cpLostToCap > 0) {
      details.add(
        Text(
          'CP lost to cap: ${summary.cpLostToCap}',
          style: dimStyle.copyWith(color: theme.colorScheme.tertiary),
        ),
      );
    }
    if (summary.rpCarryOver > 0 || summary.rpLostToCap > 0) {
      details.add(
        Text('RP carry-over: ${summary.rpCarryOver}', style: dimStyle),
      );
      if (summary.rpLostToCap > 0) {
        details.add(
          Text(
            'RP lost to cap: ${summary.rpLostToCap}',
            style: dimStyle.copyWith(color: theme.colorScheme.tertiary),
          ),
        );
      }
    }

    return ExpansionTile(
      title: Text(
        'Turn ${summary.turnNumber}',
        style: const TextStyle(fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details,
          ),
        ),
      ],
    );
  }
}

class _EmpireAdvantageTile extends StatelessWidget {
  final GameConfig config;
  final ValueChanged<GameConfig> onConfigChanged;

  const _EmpireAdvantageTile({
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ea = config.empireAdvantage;
    final label = ea != null ? '#${ea.cardNumber} ${ea.name}' : 'None';

    return ListTile(
      title: const Text('Selected', style: TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    final playerReplicators = config.playerControlsReplicators;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Empire Advantage',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: EmpireAdvantagePicker(
                    showReplicatorAdvantages:
                        config.ownership.replicators && playerReplicators,
                    selectedCardNumber: config.selectedEmpireAdvantage,
                    descriptionTruncation: 80,
                    style: EmpireAdvantagePickerStyle.avatar,
                    scrollController: scrollController,
                    onChanged: (value) {
                      if (value == null) {
                        onConfigChanged(
                          config.copyWith(clearEmpireAdvantage: true),
                        );
                      } else {
                        onConfigChanged(
                          config.copyWith(selectedEmpireAdvantage: value),
                        );
                      }
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SpecialAbilityRow extends StatelessWidget {
  final ShipType shipType;
  final int? currentAbility;
  final ValueChanged<int?> onChanged;

  const _SpecialAbilityRow({
    required this.shipType,
    required this.currentAbility,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = kShipDefinitions[shipType];
    final shipName = def?.abbreviation ?? shipType.name;
    final ability = currentAbility != null
        ? getSpecialAbility(currentAbility!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              shipName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showAbilityPicker(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (ability != null) ...[
                      Text(
                        '${currentAbility!}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ability.affectsProduction
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ability.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      Text(
                        'Not assigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.unfold_more,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (currentAbility != null)
            IconButton(
              icon: Icon(
                Icons.clear,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32),
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }

  void _showAbilityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Special Ability for ${kShipDefinitions[shipType]?.name ?? shipType.name}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: kSpecialAbilities.length,
                itemBuilder: (ctx, index) {
                  final ab = kSpecialAbilities[index];
                  final isSelected = currentAbility == ab.rollValue;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        '${ab.rollValue}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    title: Text(ab.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      ab.description,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    dense: true,
                    onTap: () {
                      onChanged(ab.rollValue);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final GameConfig config;
  final ValueChanged<GameConfig> onConfigChanged;

  const _ScenarioTile({required this.config, required this.onConfigChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenario = scenarioById(config.scenarioId);
    final label = scenario != null
        ? '${scenario.name} (${scenario.section})'
        : 'None / Custom';

    return ListTile(
      title: const Text('Scenario', style: TextStyle(fontSize: 16)),
      subtitle: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Scenario', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        onConfigChanged(
                          config.copyWith(
                            clearScenario: true,
                            shipCostMultiplier: 1.0,
                            techCostMultiplier: 1.0,
                            colonyIncomeMultiplier: 1.0,
                            colonyGrowthBonus: 0,
                            scenarioBlockedTechs: const [],
                            scenarioBlockedShips: const [],
                          ),
                        );
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: kScenarios.length,
                  itemBuilder: (ctx, index) {
                    final s = kScenarios[index];
                    final isSelected = config.scenarioId == s.id;
                    final effects = <String>[];
                    if (s.shipCostMultiplier != 1.0) {
                      effects.add('${s.shipCostMultiplier}x ship/tech costs');
                    }
                    if (s.colonyIncomeMultiplier != 1.0) {
                      effects.add('${s.colonyIncomeMultiplier}x colony income');
                    }
                    if (s.colonyGrowthBonus > 0) {
                      effects.add('+${s.colonyGrowthBonus} colony growth');
                    }
                    if (s.startingTechOverrides.isNotEmpty) {
                      effects.add('free starting techs');
                    }
                    if (s.blockedTechs.isNotEmpty) {
                      effects.add('blocked techs');
                    }
                    if (s.victoryPoints != null) {
                      effects.add('${s.victoryPoints!.label} track');
                    }
                    if (s.replicatorSetup != null) {
                      effects.add('replicator setup');
                    }
                    final effectStr = effects.isEmpty
                        ? 'Standard rules'
                        : effects.join(', ');

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${s.playerCount}P',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      title: Text(s.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.description,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (effects.isNotEmpty)
                            Text(
                              effectStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                        ],
                      ),
                      selected: isSelected,
                      dense: true,
                      onTap: () {
                        onConfigChanged(
                          config.copyWith(
                            scenarioId: s.id,
                            shipCostMultiplier: s.shipCostMultiplier,
                            techCostMultiplier: s.techCostMultiplier,
                            colonyIncomeMultiplier: s.colonyIncomeMultiplier,
                            colonyGrowthBonus: s.colonyGrowthBonus,
                            scenarioBlockedTechs: s.blockedTechs,
                            scenarioBlockedShips: s.blockedShipTypes,
                          ),
                        );
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReplicatorDifficultyTile extends StatelessWidget {
  final GameConfig config;
  final ValueChanged<GameConfig> onConfigChanged;

  const _ReplicatorDifficultyTile({
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = config.replicatorDifficulty ?? 'Normal';
    return ListTile(
      title: const Text(
        'Replicator Difficulty',
        style: TextStyle(fontSize: 16),
      ),
      subtitle: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final difficulty in const [
              'Easy',
              'Normal',
              'Hard',
              'Impossible',
            ])
              ListTile(
                title: Text(difficulty),
                selected:
                    (config.replicatorDifficulty ?? 'Normal') == difficulty,
                onTap: () {
                  onConfigChanged(
                    config.copyWith(replicatorDifficulty: difficulty),
                  );
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
