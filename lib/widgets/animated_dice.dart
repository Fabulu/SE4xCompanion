import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// State for a single animated die.
class DieAnimState {
  final AnimationController controller;
  final int finalValue;
  int tumbleValue;
  bool landed = false;
  Timer? tumbleTimer;
  AnimationController? landController;
  Animation<double>? landScale;
  Animation<double>? landRotation;

  DieAnimState({
    required this.controller,
    required this.finalValue,
    required this.tumbleValue,
  });
}

/// Controller for animated dice rolls.
class AnimatedDiceController with ChangeNotifier {
  List<DieAnimState> dice = [];
  bool showTotal = false;
  int totalRolled = 0;
  bool isRolling = false;
  final Random _random = Random();

  /// Roll dice with the given pre-determined values.
  Future<void> roll(List<int> values, TickerProvider vsync) async {
    // Clean up previous dice
    disposeControllers();

    isRolling = true;
    showTotal = false;
    totalRolled = values.fold(0, (sum, v) => sum + v);

    // Create animation controllers for each die
    dice = List.generate(values.length, (i) {
      final controller = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 800),
      );
      return DieAnimState(
        controller: controller,
        finalValue: values[i],
        tumbleValue: _random.nextInt(10) + 1,
      );
    });
    notifyListeners();

    // Staggered launch: each die starts tumbling with a delay
    for (int i = 0; i < dice.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final anim = dice[i];

      // Start the tumble: rapidly cycle random numbers
      anim.tumbleTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) {
          anim.tumbleValue = _random.nextInt(10) + 1;
          notifyListeners();
        },
      );

      // Start the animation controller (drives scale/rotation)
      anim.controller.forward();
    }

    // Let them all tumble for a beat
    await Future.delayed(const Duration(milliseconds: 600));

    // Land dice one by one with staggered timing
    for (int i = 0; i < dice.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final anim = dice[i];
      anim.tumbleTimer?.cancel();

      // Create landing animations
      anim.landController = AnimationController(
        vsync: vsync,
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

      anim.landed = true;
      notifyListeners();

      anim.landController!.forward();
    }

    // Pause, then show total
    await Future.delayed(const Duration(milliseconds: 500));

    showTotal = true;
    isRolling = false;
    notifyListeners();
  }

  void reset() {
    disposeControllers();
    dice = [];
    showTotal = false;
    totalRolled = 0;
    isRolling = false;
    notifyListeners();
  }

  void disposeControllers() {
    for (final a in dice) {
      a.controller.dispose();
      a.landController?.dispose();
      a.tumbleTimer?.cancel();
    }
  }
}

/// Displays animated dice from an [AnimatedDiceController].
class AnimatedDiceDisplay extends StatelessWidget {
  final AnimatedDiceController controller;

  const AnimatedDiceDisplay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < controller.dice.length; i++)
                      AnimatedDie(anim: controller.dice[i]),
                  ],
                ),
              ),
            ),
            if (controller.showTotal && controller.dice.length > 1) ...[
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
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
                  '= ${controller.totalRolled}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A single animated die widget.
class AnimatedDie extends StatelessWidget {
  final DieAnimState anim;

  const AnimatedDie({super.key, required this.anim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: anim.controller,
      builder: (context, child) {
        final t = anim.controller.value;
        final isLanded = anim.landed;
        final displayValue = isLanded ? anim.finalValue : anim.tumbleValue;

        double scale;
        double rotation;
        if (!isLanded) {
          scale = 0.8 + 0.2 * sin(t * pi * 4);
          rotation = t * pi * 6;
        } else {
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
}
