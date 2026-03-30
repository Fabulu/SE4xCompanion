import 'package:flutter/material.dart';

import '../services/dice_service.dart';

/// Terrain types affecting combat in SE4X.
enum CombatTerrain {
  openSpace('Open Space'),
  nebula('Nebula'),
  asteroids('Asteroids');

  final String label;
  const CombatTerrain(this.label);
}

/// Dialog for calculating combat hit probabilities in SE4X.
///
/// SE4X combat formula: Roll d10. Hit if roll <= (Ship's base Attack Strength
/// + Attack Tech - Defender's Defense Tech). Modified by Fleet Size Bonus (+1)
/// and terrain (Nebula/Asteroids force base attack to 1).
class CombatCalculatorDialog extends StatefulWidget {
  const CombatCalculatorDialog({super.key});

  @override
  State<CombatCalculatorDialog> createState() => _CombatCalculatorDialogState();
}

class _CombatCalculatorDialogState extends State<CombatCalculatorDialog>
    with SingleTickerProviderStateMixin {
  int _attackStrength = 1;
  int _attackTech = 0;
  int _defenseTech = 0;
  bool _fleetSizeBonus = false;
  CombatTerrain _terrain = CombatTerrain.openSpace;

  final DiceService _dice = DiceService();
  int? _lastRoll;
  bool? _lastHit;
  late AnimationController _rollAnimController;
  late Animation<double> _rollScale;

  @override
  void initState() {
    super.initState();
    _rollAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rollScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _rollAnimController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _rollAnimController.dispose();
    super.dispose();
  }

  /// The effective base attack, accounting for terrain.
  int get _effectiveBaseAttack {
    if (_terrain == CombatTerrain.nebula ||
        _terrain == CombatTerrain.asteroids) {
      return 1; // All ships fire as E-class
    }
    return _attackStrength;
  }

  /// The modified attack value (number you need to roll or less).
  int get _modifiedAttack {
    int value = _effectiveBaseAttack + _attackTech - _defenseTech;
    if (_fleetSizeBonus) value += 1;
    return value;
  }

  /// Hit probability as a percentage (clamped 0-100).
  double get _hitProbability {
    final target = _modifiedAttack.clamp(0, 10);
    return target * 10.0;
  }

  void _roll() {
    final roll = _dice.rollD10();
    setState(() {
      _lastRoll = roll;
      _lastHit = roll <= _modifiedAttack;
    });
    _rollAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modAttack = _modifiedAttack;
    final prob = _hitProbability;

    return AlertDialog(
      title: const Text('Combat Calculator'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attack Strength
              _buildStepperRow(
                label: 'Attack Strength',
                value: _attackStrength,
                min: 1,
                max: 9,
                onChanged: (v) => setState(() => _attackStrength = v),
              ),
              const SizedBox(height: 8),

              // Attack Tech
              _buildStepperRow(
                label: 'Attack Tech',
                value: _attackTech,
                min: 0,
                max: 4,
                onChanged: (v) => setState(() => _attackTech = v),
              ),
              const SizedBox(height: 8),

              // Defense Tech
              _buildStepperRow(
                label: 'Defender Def Tech',
                value: _defenseTech,
                min: 0,
                max: 3,
                onChanged: (v) => setState(() => _defenseTech = v),
              ),
              const SizedBox(height: 8),

              // Fleet Size Bonus
              SwitchListTile(
                title: const Text('Fleet Size Bonus (+1)'),
                value: _fleetSizeBonus,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _fleetSizeBonus = v),
              ),

              // Terrain
              Row(
                children: [
                  const Text('Terrain: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<CombatTerrain>(
                      value: _terrain,
                      isExpanded: true,
                      onChanged: (v) {
                        if (v != null) setState(() => _terrain = v);
                      },
                      items: CombatTerrain.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Divider
              const Divider(),
              const SizedBox(height: 8),

              // Output
              Text(
                'Modified Attack Value: $modAttack',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                modAttack <= 0
                    ? 'Cannot hit'
                    : modAttack >= 10
                        ? 'Auto-hit (100%)'
                        : 'Hit on $modAttack or less on d10',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Hit probability: ${prob.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (_terrain != CombatTerrain.openSpace) ...[
                const SizedBox(height: 4),
                Text(
                  '(${_terrain.label}: all ships fire as E-class, base attack = 1)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Roll button + result
              Center(
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: _roll,
                      icon: const Icon(Icons.casino),
                      label: const Text('Roll d10'),
                    ),
                    if (_lastRoll != null) ...[
                      const SizedBox(height: 12),
                      ScaleTransition(
                        scale: _rollScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _lastHit!
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _lastHit! ? Colors.green : Colors.red,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$_lastRoll',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _lastHit! ? Colors.green : Colors.red,
                                ),
                              ),
                              Text(
                                _lastHit! ? 'HIT!' : 'MISS',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _lastHit! ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStepperRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

/// Show the combat calculator dialog.
Future<void> showCombatCalculatorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const CombatCalculatorDialog(),
  );
}
