// Dialog for funding unpredictable research grants (rule 33.0).

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/tech_costs.dart';
import '../services/dice_service.dart';

/// Result of a research grant funding session.
class ResearchGrantResult {
  final TechId techId;
  final int targetLevel;
  final int grantsUsed;
  final int cpSpent;
  final int totalRolled;
  final bool breakthroughAchieved;
  final TechId? reassignedFrom;

  const ResearchGrantResult({
    required this.techId,
    required this.targetLevel,
    required this.grantsUsed,
    required this.cpSpent,
    required this.totalRolled,
    required this.breakthroughAchieved,
    this.reassignedFrom,
  });
}

/// Information about a tech that can be targeted for reassignment.
class ReassignTarget {
  final TechId techId;
  final String name;
  final int targetLevel;
  final int currentAccumulated;
  final int targetCost;

  const ReassignTarget({
    required this.techId,
    required this.name,
    required this.targetLevel,
    required this.currentAccumulated,
    required this.targetCost,
  });
}

bool _sessionAppRollMode = true;

Future<ResearchGrantResult?> showResearchGrantDialog({
  required BuildContext context,
  required TechId techId,
  required String techName,
  required int targetLevel,
  required int currentAccumulated,
  required int targetCost,
  required int maxGrantsAffordable,
  List<ReassignTarget> reassignTargets = const [],
  DiceService? diceService,
}) {
  return showDialog<ResearchGrantResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ResearchGrantDialog(
      techId: techId,
      techName: techName,
      targetLevel: targetLevel,
      currentAccumulated: currentAccumulated,
      targetCost: targetCost,
      maxGrantsAffordable: maxGrantsAffordable,
      reassignTargets: reassignTargets,
      diceService: diceService ?? DiceService(),
    ),
  );
}

class _ResearchGrantDialog extends StatefulWidget {
  final TechId techId;
  final String techName;
  final int targetLevel;
  final int currentAccumulated;
  final int targetCost;
  final int maxGrantsAffordable;
  final List<ReassignTarget> reassignTargets;
  final DiceService diceService;

  const _ResearchGrantDialog({
    required this.techId,
    required this.techName,
    required this.targetLevel,
    required this.currentAccumulated,
    required this.targetCost,
    required this.maxGrantsAffordable,
    required this.reassignTargets,
    required this.diceService,
  });

  @override
  State<_ResearchGrantDialog> createState() => _ResearchGrantDialogState();
}

enum _DialogPhase { setup, manualEntry, rolling, rolled }

class _ResearchGrantDialogState extends State<_ResearchGrantDialog>
    with TickerProviderStateMixin {
  int _grantCount = 1;
  bool _appRollMode = _sessionAppRollMode;
  _DialogPhase _phase = _DialogPhase.setup;

  // Roll state
  List<int> _diceRolls = [];
  int _totalRolled = 0;       // actual total (for result)
  int _displayRolled = 0;     // what the progress bar shows (fills up after dice land)
  bool _breakthrough = false;
  bool _reassigning = false;

  // Animation state for dice
  List<_DieAnimState> _dieAnims = [];
  bool _showTotal = false;
  bool _showBreakthrough = false;

  // Breakthrough animation
  AnimationController? _breakthroughController;
  Animation<double>? _breakthroughScale;
  AnimationController? _breakthroughGlowController;

  final _random = Random();

  // Manual entry
  final _manualController = TextEditingController();
  final _manualFocus = FocusNode();

  @override
  void dispose() {
    _breakthroughController?.dispose();
    _breakthroughGlowController?.dispose();
    for (final p in _particles) {
      p.controller.dispose();
    }
    _manualController.dispose();
    _manualFocus.dispose();
    for (final a in _dieAnims) {
      a.controller.dispose();
      a.landController?.dispose();
      a.tumbleTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final newAccumulated = widget.currentAccumulated + _displayRolled;

    return AlertDialog(
      title: Text('Research: ${widget.techName} ${widget.targetLevel}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_phase == _DialogPhase.setup) ...[
              _buildModeToggle(theme),
              const SizedBox(height: 12),
            ],

            // Progress bar
            _buildProgressBar(theme, newAccumulated),
            const SizedBox(height: 4),
            Text(
              '$newAccumulated / ${widget.targetCost}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            if (_phase == _DialogPhase.setup)
              _buildGrantSelector(theme),

            if (_phase == _DialogPhase.manualEntry)
              _buildManualEntryField(theme),

            if (_phase == _DialogPhase.rolling ||
                _phase == _DialogPhase.rolled) ...[
              const SizedBox(height: 8),
              _buildDiceArea(theme),
            ],

            if (_showTotal && _diceRolls.length > 1) ...[
              const SizedBox(height: 12),
              _buildTotalDisplay(theme),
            ],

            if (_showBreakthrough) ...[
              const SizedBox(height: 16),
              _buildBreakthroughBanner(theme),
            ],

            if (_phase == _DialogPhase.rolled &&
                _appRollMode &&
                widget.reassignTargets.isNotEmpty &&
                !_reassigning) ...[
              const SizedBox(height: 8),
              _buildReassignLink(theme),
            ],
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  // ==========================================================================
  // Setup widgets
  // ==========================================================================

  Widget _buildModeToggle(ThemeData theme) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          label: Text('App rolls'),
          icon: Icon(Icons.casino_outlined),
        ),
        ButtonSegment(
          value: false,
          label: Text('Manual entry'),
          icon: Icon(Icons.edit_outlined),
        ),
      ],
      selected: {_appRollMode},
      onSelectionChanged: (sel) {
        setState(() {
          _appRollMode = sel.first;
          _sessionAppRollMode = _appRollMode;
        });
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildGrantSelector(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _grantCount > 1
                  ? () => setState(() => _grantCount--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline, size: 28),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '$_grantCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            IconButton(
              onPressed: _grantCount < widget.maxGrantsAffordable
                  ? () => setState(() => _grantCount++)
                  : null,
              icon: const Icon(Icons.add_circle_outline, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$_grantCount grant${_grantCount == 1 ? '' : 's'} = ${_grantCount * 5} CP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          _appRollMode ? '(1d10 per grant)' : '(roll ${_grantCount}d10 yourself)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // Progress bar
  // ==========================================================================

  Widget _buildProgressBar(ThemeData theme, int newAccumulated) {
    final progress = (newAccumulated / widget.targetCost).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 14,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _breakthrough
                  ? theme.colorScheme.primary
                  : theme.colorScheme.tertiary,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // Dice area - the main show
  // ==========================================================================

  Widget _buildDiceArea(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _dieAnims.length; i++)
              _buildAnimatedDie(i, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDie(int index, ThemeData theme) {
    final anim = _dieAnims[index];

    return AnimatedBuilder(
      animation: anim.controller,
      builder: (context, child) {
        final t = anim.controller.value;
        final isLanded = anim.landed;
        final displayValue = isLanded ? anim.finalValue : anim.tumbleValue;

        // During tumble: rapid spin + scale bounce
        // On land: elastic overshoot settle
        double scale;
        double rotation;
        if (!isLanded) {
          // Tumbling: pulsing scale, spinning
          scale = 0.8 + 0.2 * sin(t * pi * 4);
          rotation = t * pi * 6;
        } else {
          // Landing: elastic overshoot
          scale = anim.landScale?.value ?? 1.0;
          rotation = anim.landRotation?.value ?? 0.0;
        }

        final isHigh = isLanded && displayValue >= 7;
        final bgColor = isLanded
            ? (isHigh
                ? theme.colorScheme.primary
                : theme.colorScheme.primaryContainer)
            : theme.colorScheme.surfaceContainerHighest;
        final textColor = isLanded
            ? (isHigh
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimaryContainer)
            : theme.colorScheme.onSurface.withValues(alpha: 0.5);
        final borderColor = isLanded
            ? (isHigh
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.5))
            : theme.colorScheme.onSurface.withValues(alpha: 0.2);

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: isLanded && isHigh
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$displayValue',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalDisplay(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Text(
        '= $_totalRolled',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ==========================================================================
  // Breakthrough!
  // ==========================================================================

  Widget _buildBreakthroughBanner(ThemeData theme) {
    return AnimatedBuilder(
      animation: _breakthroughController!,
      builder: (context, child) {
        final scale = _breakthroughScale!.value;
        final glow = _breakthroughGlowController!.value;

        return SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Floating space particles
              for (final p in _particles)
                AnimatedBuilder(
                  animation: p.controller,
                  builder: (context, _) {
                    final t = p.controller.value;
                    final dx = p.dx * t * 120;
                    final dy = p.dy * t * -100 - (t * t * 30);
                    final opacity = (1.0 - t).clamp(0.0, 1.0);
                    final particleScale = 1.0 + t * 0.3;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(dx, dy),
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: particleScale,
                              child: Transform.rotate(
                                angle: t * p.spin,
                                child: Text(
                                  p.emoji,
                                  style: TextStyle(fontSize: p.size),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Main banner
              Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3 + 0.4 * glow),
                        blurRadius: 16 + 12 * glow,
                        spreadRadius: 3 * glow,
                      ),
                      BoxShadow(
                        color: theme.colorScheme.tertiary.withValues(alpha: 0.2 * glow),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\uD83D\uDE80 BREAKTHROUGH! \uD83D\uDE80',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.techName} ${widget.targetLevel} acquired!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Space particle emojis for breakthrough celebration
  static const _spaceEmojis = [
    '\uD83D\uDE80', // rocket
    '\uD83D\uDC7D', // alien
    '\u2B50',       // star
    '\uD83C\uDF1F', // glowing star
    '\uD83E\uDE90', // ringed planet
    '\uD83C\uDF0C', // milky way
    '\u2604\uFE0F', // comet
    '\uD83D\uDEF8', // flying saucer
    '\uD83C\uDF1E', // sun
    '\uD83C\uDF19', // crescent moon
  ];

  List<_SpaceParticle> _particles = [];

  void _startBreakthroughAnimation() {
    _breakthroughController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _breakthroughScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breakthroughController!,
        curve: Curves.elasticOut,
      ),
    );

    _breakthroughGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Launch space particles
    _particles = List.generate(12, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1200 + _random.nextInt(800)),
      );
      final particle = _SpaceParticle(
        emoji: _spaceEmojis[_random.nextInt(_spaceEmojis.length)],
        dx: (_random.nextDouble() - 0.5) * 2, // -1 to 1
        dy: (_random.nextDouble() - 0.5) * 2,
        spin: (_random.nextDouble() - 0.5) * 4, // random rotation
        size: 16.0 + _random.nextInt(12).toDouble(),
        controller: controller,
      );
      // Stagger particle launches
      Future.delayed(Duration(milliseconds: _random.nextInt(400)), () {
        if (mounted) controller.forward();
      });
      return particle;
    });

    _breakthroughController!.forward();
  }

  // ==========================================================================
  // Manual entry
  // ==========================================================================

  Widget _buildManualEntryField(ThemeData theme) {
    return Column(
      children: [
        Text(
          '$_grantCount grant${_grantCount == 1 ? '' : 's'} = ${_grantCount * 5} CP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your roll total:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: Center(
            child: TextField(
              controller: _manualController,
              focusNode: _manualFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '0',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // Reassign
  // ==========================================================================

  Widget _buildReassignLink(ThemeData theme) {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: _showReassignSheet,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Reassign rolls to a different tech',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Future<void> _showReassignSheet() async {
    final targets = widget.reassignTargets;
    if (targets.isEmpty) return;

    final chosen = await showDialog<ReassignTarget>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SimpleDialog(
          title: const Text('Reassign rolls to...'),
          children: [
            for (final t in targets)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${t.name} ${t.targetLevel}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Text(
                        '${t.currentAccumulated} / ${t.targetCost}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (chosen == null || !mounted) return;

    final newAccumulated = chosen.currentAccumulated + _totalRolled;
    final bt = newAccumulated >= chosen.targetCost;

    setState(() {
      _reassigning = true;
    });

    Navigator.pop(
      context,
      ResearchGrantResult(
        techId: chosen.techId,
        targetLevel: chosen.targetLevel,
        grantsUsed: _grantCount,
        cpSpent: _grantCount * 5,
        totalRolled: _totalRolled,
        breakthroughAchieved: bt,
        reassignedFrom: widget.techId,
      ),
    );
  }

  // ==========================================================================
  // Actions
  // ==========================================================================

  List<Widget> _buildActions() {
    switch (_phase) {
      case _DialogPhase.setup:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (_appRollMode)
            FilledButton.icon(
              onPressed: _roll,
              icon: const Icon(Icons.casino, size: 20),
              label: const Text('Roll!'),
            )
          else
            FilledButton(
              onPressed: _beginManualEntry,
              child: const Text('Apply'),
            ),
        ];
      case _DialogPhase.manualEntry:
        final enteredValue = int.tryParse(_manualController.text) ?? 0;
        return [
          TextButton(
            onPressed: () {
              setState(() {
                _phase = _DialogPhase.setup;
                _totalRolled = 0;
                _manualController.clear();
              });
            },
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: enteredValue > 0 ? _confirmManualEntry : null,
            child: const Text('Confirm'),
          ),
        ];
      case _DialogPhase.rolling:
        return []; // No actions during roll animation
      case _DialogPhase.rolled:
        return [
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                ResearchGrantResult(
                  techId: widget.techId,
                  targetLevel: widget.targetLevel,
                  grantsUsed: _grantCount,
                  cpSpent: _grantCount * 5,
                  totalRolled: _totalRolled,
                  breakthroughAchieved: _breakthrough,
                ),
              );
            },
            child: Text(_breakthrough ? '\u2728 Claim!' : 'Done'),
          ),
        ];
    }
  }

  // ==========================================================================
  // Roll logic
  // ==========================================================================

  void _beginManualEntry() {
    setState(() {
      _phase = _DialogPhase.manualEntry;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manualFocus.requestFocus();
    });
  }

  void _confirmManualEntry() {
    final entered = int.tryParse(_manualController.text) ?? 0;
    if (entered <= 0) return;

    final newTotal = widget.currentAccumulated + entered;
    setState(() {
      _totalRolled = entered;
      _displayRolled = entered;
      _breakthrough = newTotal >= widget.targetCost;
      _phase = _DialogPhase.rolled;
      _showTotal = true;
    });

    if (_breakthrough) {
      _showBreakthrough = true;
      _startBreakthroughAnimation();
    }
  }

  Future<void> _roll() async {
    // Generate the actual results
    _diceRolls = widget.diceService.rollMultiple(_grantCount);
    _totalRolled = _diceRolls.fold(0, (sum, r) => sum + r);

    // Create animation controllers for each die
    for (final a in _dieAnims) {
      a.controller.dispose();
    }

    _dieAnims = List.generate(_grantCount, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      return _DieAnimState(
        controller: controller,
        finalValue: _diceRolls[i],
        tumbleValue: _random.nextInt(10) + 1,
      );
    });

    setState(() {
      _phase = _DialogPhase.rolling;
      _displayRolled = 0;
    });

    // Staggered launch: each die starts tumbling with a delay
    for (int i = 0; i < _dieAnims.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted) return;

      final anim = _dieAnims[i];

      // Start the tumble: rapidly cycle random numbers
      anim.tumbleTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) {
          if (!mounted) return;
          setState(() {
            anim.tumbleValue = _random.nextInt(10) + 1;
          });
        },
      );

      // Start the animation controller (drives scale/rotation)
      anim.controller.forward();
    }

    // Let them all tumble for a beat
    await Future.delayed(const Duration(milliseconds: 600));

    // Land dice one by one with staggered timing
    for (int i = 0; i < _dieAnims.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (!mounted) return;

      final anim = _dieAnims[i];
      anim.tumbleTimer?.cancel();

      // Create landing animations
      anim.landController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      anim.landScale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
      ]).animate(CurvedAnimation(
        parent: anim.landController!,
        curve: Curves.easeOut,
      ));
      anim.landRotation = Tween<double>(
        begin: ((_random.nextDouble() - 0.5) * 0.3),
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: anim.landController!,
        curve: Curves.elasticOut,
      ));

      setState(() {
        anim.landed = true;
        _displayRolled += anim.finalValue;
      });

      anim.landController!.forward();
    }

    // Pause, then show total
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final newTotal = widget.currentAccumulated + _totalRolled;
    final bt = newTotal >= widget.targetCost;

    setState(() {
      _showTotal = true;
      _phase = _DialogPhase.rolled;
      _breakthrough = bt;
    });

    // If breakthrough, dramatic pause then reveal
    if (bt) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _showBreakthrough = true;
      });
      _startBreakthroughAnimation();
    }
  }
}

// =============================================================================
// Die animation state
// =============================================================================

class _DieAnimState {
  final AnimationController controller;
  final int finalValue;
  int tumbleValue;
  bool landed = false;
  Timer? tumbleTimer;

  AnimationController? landController;
  Animation<double>? landScale;
  Animation<double>? landRotation;

  _DieAnimState({
    required this.controller,
    required this.finalValue,
    required this.tumbleValue,
  });
}

// =============================================================================
// Space particle for breakthrough celebration
// =============================================================================

class _SpaceParticle {
  final String emoji;
  final double dx;     // direction x (-1 to 1)
  final double dy;     // direction y (-1 to 1)
  final double spin;   // rotation speed
  final double size;   // font size
  final AnimationController controller;

  _SpaceParticle({
    required this.emoji,
    required this.dx,
    required this.dy,
    required this.spin,
    required this.size,
    required this.controller,
  });
}
