// New Game Wizard — combines expansion/scenario/EA/fleet selection into one flow.

import 'package:flutter/material.dart';

import '../data/empire_advantages.dart';
import '../data/scenarios.dart';
import '../data/ship_definitions.dart';
import '../data/tech_costs.dart';
import '../models/game_config.dart';
import 'empire_advantage_picker.dart';

class NewGameResult {
  final String gameName;
  final GameConfig config;
  final Map<ShipType, int>? startingFleet;
  final Map<TechId, int> startingTechOverrides;
  final int alienPlayerCount;
  final bool isReplicatorGame;

  const NewGameResult({
    required this.gameName,
    required this.config,
    this.startingFleet,
    this.startingTechOverrides = const {},
    this.alienPlayerCount = 0,
    this.isReplicatorGame = false,
  });
}

const List<String> kReplicatorDifficulties = [
  'Easy',
  'Normal',
  'Hard',
  'Impossible',
];

Map<ShipType, int> startingFleetForSelection({
  ScenarioPreset? scenario,
  bool isReplicatorGame = false,
  String? replicatorDifficulty,
}) {
  final fleet = Map<ShipType, int>.from(
    scenario?.startingFleet ?? kStandardScenarioFleet,
  );
  if (isReplicatorGame && replicatorDifficulty == 'Easy') {
    fleet[ShipType.colonyShip] = (fleet[ShipType.colonyShip] ?? 0) + 2;
  }
  return fleet;
}

Future<NewGameResult?> showNewGameWizard(BuildContext context) {
  return showDialog<NewGameResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _NewGameWizardDialog(),
  );
}

class _NewGameWizardDialog extends StatefulWidget {
  const _NewGameWizardDialog();

  @override
  State<_NewGameWizardDialog> createState() => _NewGameWizardDialogState();
}

class _NewGameWizardDialogState extends State<_NewGameWizardDialog> {
  final _nameController = TextEditingController(text: 'New Game');
  int _step = 0; // 0: name+expansions+rules, 1: scenario+EA, 2: confirm

  // Expansion toggles
  bool _ce = false;
  bool _replicators = false;
  bool _agt = false;

  // Rule toggles
  bool _facilities = false;
  bool _altEmpire = false;
  bool _advCon = false;
  bool _shipExp = false;
  bool _unpredictableResearch = false;

  // Scenario
  ScenarioPreset? _scenario;

  // Empire Advantage
  int? _selectedEA;

  // Solo/Coop
  int _alienPlayerCount = 0;
  bool _isReplicatorGame = false;
  String _replicatorDifficulty = 'Normal';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  GameConfig _buildConfig() {
    return GameConfig(
      ownership: ExpansionOwnership(
        closeEncounters: _ce,
        replicators: _replicators,
        allGoodThings: _agt,
      ),
      enableFacilities: _facilities && _agt,
      enableAdvancedConstruction: _advCon,
      enableAlternateEmpire: _altEmpire && _ce,
      enableReplicators: _isReplicatorGame && _replicators,
      enableShipExperience: _shipExp,
      enableUnpredictableResearch: _unpredictableResearch,
      selectedEmpireAdvantage: _selectedEA,
      scenarioId: _scenario?.id,
      replicatorDifficulty: _isReplicatorGame ? _replicatorDifficulty : null,
      shipCostMultiplier: _scenario?.shipCostMultiplier ?? 1.0,
      techCostMultiplier: _scenario?.techCostMultiplier ?? 1.0,
      colonyIncomeMultiplier: _scenario?.colonyIncomeMultiplier ?? 1.0,
      colonyGrowthBonus: _scenario?.colonyGrowthBonus ?? 0,
      scenarioBlockedTechs: _scenario?.blockedTechs ?? const [],
      scenarioBlockedShips: _scenario?.blockedShipTypes ?? const [],
    );
  }

  void _finish() {
    final fleet = startingFleetForSelection(
      scenario: _scenario,
      isReplicatorGame: _isReplicatorGame,
      replicatorDifficulty: _replicatorDifficulty,
    );
    Navigator.of(context).pop(NewGameResult(
      gameName: _nameController.text.isEmpty ? 'New Game' : _nameController.text,
      config: _buildConfig(),
      startingFleet: fleet,
      startingTechOverrides: _scenario?.startingTechOverrides ?? const {},
      alienPlayerCount: _alienPlayerCount,
      isReplicatorGame: _isReplicatorGame,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        _step == 0 ? 'New Game' : _step == 1 ? 'Scenario & EA' : 'Ready',
        style: const TextStyle(fontSize: 18),
      ),
      content: SizedBox(
        width: 340,
        height: 480,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _step == 0
                ? _buildStep0(theme)
                : _step == 1
                    ? _buildStep1(theme)
                    : _buildStep2(theme),
          ),
        ),
      ),
      actions: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        if (_step < 2)
          FilledButton(
            onPressed: () => setState(() => _step++),
            child: const Text('Next'),
          ),
        if (_step == 2)
          FilledButton(
            onPressed: _finish,
            child: const Text('Create'),
          ),
      ],
    );
  }

  // ── Step 0: Name, Expansions, Rules, Game Mode ──

  Widget _buildStep0(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Game Name'),
        ),
        const SizedBox(height: 16),
        _sectionLabel(theme, 'Expansions'),
        _toggle('Close Encounters', _ce, (v) {
          setState(() {
            _ce = v;
            if (!v) _altEmpire = false;
          });
        }),
        _toggle('Replicators', _replicators, (v) {
          setState(() {
            _replicators = v;
            if (!v) _isReplicatorGame = false;
          });
        }),
        _toggle('All Good Things', _agt, (v) {
          setState(() {
            _agt = v;
            if (!v) _facilities = false;
          });
        }),
        const SizedBox(height: 12),
        _sectionLabel(theme, 'Rules'),
        _toggle('Facilities (AGT)', _facilities && _agt,
            _agt ? (v) => setState(() => _facilities = v) : null),
        _toggle('Advanced Construction', _advCon,
            (v) => setState(() => _advCon = v)),
        _toggle('Alternate Empire', _altEmpire && _ce,
            _ce ? (v) => setState(() => _altEmpire = v) : null),
        _toggle('Ship Experience', _shipExp,
            (v) => setState(() => _shipExp = v)),
        _toggle('Unpredictable Research', _unpredictableResearch,
            (v) => setState(() => _unpredictableResearch = v)),
        const SizedBox(height: 12),
        _sectionLabel(theme, 'Game Mode'),
        _toggle('Solitaire Aliens', _alienPlayerCount > 0, (v) {
          setState(() {
            _alienPlayerCount = v ? 2 : 0;
            if (v) _isReplicatorGame = false;
          });
        }),
        if (_alienPlayerCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Text('Alien players: $_alienPlayerCount',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: _alienPlayerCount > 1
                      ? () => setState(() => _alienPlayerCount--)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: _alienPlayerCount < 3
                      ? () => setState(() => _alienPlayerCount++)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        _toggle('Replicator Opponent', _isReplicatorGame && _replicators,
            _replicators
                ? (v) {
                    setState(() {
                      _isReplicatorGame = v;
                      if (v) _alienPlayerCount = 0;
                    });
                  }
                : null),
        if (_isReplicatorGame && _replicators)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: DropdownButtonFormField<String>(
              initialValue: _replicatorDifficulty,
              decoration: const InputDecoration(
                labelText: 'Replicator Difficulty',
              ),
              items: [
                for (final difficulty in kReplicatorDifficulties)
                  DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _replicatorDifficulty = value);
              },
            ),
          ),
      ],
    );
  }

  // ── Step 1: Scenario + Empire Advantage ──

  Widget _buildStep1(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scenario picker
        _sectionLabel(theme, 'Scenario (optional)'),
        const SizedBox(height: 4),
        _radioTile(theme, 'None / Custom', _scenario == null,
            () => setState(() => _scenario = null)),
        for (final s in kScenarios)
          _radioTile(
            theme,
            '${s.name} (${s.playerCount}P)',
            _scenario?.id == s.id,
            () => setState(() => _scenario = s),
            subtitle: s.description,
          ),

        const SizedBox(height: 16),

        // Empire Advantage picker
        _sectionLabel(theme, 'Empire Advantage'),
        const SizedBox(height: 4),
        EmpireAdvantagePicker(
          replicatorsOwned: _replicators,
          selectedCardNumber: _selectedEA,
          descriptionTruncation: 60,
          onChanged: (v) => setState(() => _selectedEA = v),
        ),
      ],
    );
  }

  // ── Step 2: Confirmation ──

  Widget _buildStep2(ThemeData theme) {
    final fleet = startingFleetForSelection(
      scenario: _scenario,
      isReplicatorGame: _isReplicatorGame,
      replicatorDifficulty: _replicatorDifficulty,
    );
    final techs = _scenario?.startingTechOverrides ?? {};
    final ea = _selectedEA != null
        ? kEmpireAdvantages
            .where((e) => e.cardNumber == _selectedEA)
            .firstOrNull
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_nameController.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_scenario != null)
          Text('Scenario: ${_scenario!.name}',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary)),
        if (ea != null)
          Text('EA: #${ea.cardNumber} ${ea.name}',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary)),
        if (_alienPlayerCount > 0)
          Text('Solitaire: $_alienPlayerCount alien players',
              style: const TextStyle(fontSize: 13)),
        if (_isReplicatorGame)
          Text('Replicator opponent ($_replicatorDifficulty)',
              style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        _sectionLabel(theme, 'Starting Fleet'),
        for (final entry in fleet.entries)
          Text(
            '  ${kShipDefinitions[entry.key]?.name ?? entry.key.name} x${entry.value}',
            style: const TextStyle(fontSize: 13),
          ),
        if (techs.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionLabel(theme, 'Starting Tech'),
          for (final entry in techs.entries)
            Text('  ${entry.key.name} ${entry.value}',
                style: const TextStyle(fontSize: 13)),
        ],
        if (_scenario != null && _scenario!.shipCostMultiplier != 1.0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ship/tech costs: ${_scenario!.shipCostMultiplier}x',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.tertiary),
            ),
          ),
        if (_scenario != null && _scenario!.colonyIncomeMultiplier != 1.0)
          Text(
            'Colony income: ${_scenario!.colonyIncomeMultiplier}x (non-HW)',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.tertiary),
          ),
        const SizedBox(height: 8),
        // Rules summary
        _sectionLabel(theme, 'Active Rules'),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            if (_ce) _chip(theme, 'CE'),
            if (_replicators) _chip(theme, 'Rep'),
            if (_agt) _chip(theme, 'AGT'),
            if (_facilities) _chip(theme, 'Facilities'),
            if (_advCon) _chip(theme, 'Adv Con'),
            if (_altEmpire) _chip(theme, 'Alt Empire'),
            if (_shipExp) _chip(theme, 'Experience'),
            if (_unpredictableResearch) _chip(theme, 'Unpred. Research'),
          ],
        ),
      ],
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(ThemeData theme, String text) => Text(text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ));

  Widget _toggle(String label, bool value, ValueChanged<bool>? onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Widget _radioTile(ThemeData theme, String title, bool selected,
      VoidCallback onTap,
      {String? subtitle}) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis)
          : null,
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }

  Widget _chip(ThemeData theme, String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
