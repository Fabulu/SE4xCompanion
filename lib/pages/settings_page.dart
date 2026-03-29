import 'package:flutter/material.dart';

import '../models/game_config.dart';
import '../models/game_state.dart';

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

  const SettingsPage({
    super.key,
    required this.config,
    required this.gameName,
    required this.turnNumber,
    required this.savedGames,
    required this.activeGameId,
    required this.onConfigChanged,
    required this.onGameNameChanged,
    required this.onNewGame,
    required this.onLoadGame,
    required this.onRenameGame,
    required this.onDeleteGame,
    required this.onDuplicateGame,
    required this.onResetGame,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        // ── Game Setup ──
        _SectionTitle(title: 'GAME SETUP'),
        const SizedBox(height: 4),
        _GameNameTile(
          gameName: gameName,
          onChanged: onGameNameChanged,
        ),
        ListTile(
          title: const Text('Turn', style: TextStyle(fontSize: 13)),
          trailing: Text(
            '$turnNumber',
            style: TextStyle(
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const Divider(height: 24),

        // ── Expansions Owned ──
        _SectionTitle(title: 'EXPANSIONS OWNED'),
        const SizedBox(height: 4),
        SwitchListTile(
          title: const Text('Close Encounters', style: TextStyle(fontSize: 13)),
          value: config.ownership.closeEncounters,
          onChanged: (v) => onConfigChanged(config.copyWith(
            ownership: config.ownership.copyWith(closeEncounters: v),
          )),
        ),
        SwitchListTile(
          title: const Text('Replicators', style: TextStyle(fontSize: 13)),
          value: config.ownership.replicators,
          onChanged: (v) => onConfigChanged(config.copyWith(
            ownership: config.ownership.copyWith(replicators: v),
          )),
        ),
        SwitchListTile(
          title: const Text('All Good Things', style: TextStyle(fontSize: 13)),
          value: config.ownership.allGoodThings,
          onChanged: (v) => onConfigChanged(config.copyWith(
            ownership: config.ownership.copyWith(allGoodThings: v),
          )),
        ),
        const Divider(height: 24),

        // ── Optional Rules ──
        _SectionTitle(title: 'OPTIONAL RULES'),
        const SizedBox(height: 4),
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
          onChanged: (v) => onConfigChanged(config.copyWith(enableLogistics: v)),
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
          title: 'Enable Replicators',
          value: config.enableReplicators,
          enabled: config.ownership.replicators,
          disabledReason: 'Requires Replicators expansion',
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableReplicators: v)),
        ),
        _RuleToggle(
          title: 'Enable Ship Experience',
          value: config.enableShipExperience,
          enabled: true,
          onChanged: (v) =>
              onConfigChanged(config.copyWith(enableShipExperience: v)),
        ),
        const Divider(height: 24),

        // ── Game Library ──
        _SectionTitle(title: 'GAME LIBRARY'),
        const SizedBox(height: 4),
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
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Game', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDuplicateGame,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Duplicate', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
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
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Reset Current Game', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
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
        content: Text('Permanently delete "${game.name}"? This cannot be undone.'),
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
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
    if (old.gameName != widget.gameName && _controller.text != widget.gameName) {
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
      title: const Text('Game Name', style: TextStyle(fontSize: 13)),
      trailing: SizedBox(
        width: 160,
        child: TextField(
          controller: _controller,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.end,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: (!enabled && disabledReason != null)
          ? Text(
              disabledReason!,
              style: TextStyle(
                fontSize: 11,
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
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: isActive ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.play_arrow,
                    size: 14,
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
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn ${game.state.turnNumber}  |  $updatedStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRename,
                icon: const Icon(Icons.edit, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 14,
                tooltip: 'Rename',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 14, color: theme.colorScheme.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 14,
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
