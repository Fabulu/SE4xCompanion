// Spotlight overlay for the in-app tutorial.
//
// Renders a dimmed full-screen scrim with a rounded-rect "hole" cut around
// the current step's target widget, plus a popup card with the step text
// and Next/Back/Skip buttons.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_config.dart';
import 'tutorial_controller.dart';
import 'tutorial_steps.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialController controller;
  final GameConfig config;

  const TutorialOverlay({
    super.key,
    required this.controller,
    required this.config,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    // After the next frame, scroll the target into view if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureTargetVisible();
    });
  }

  void _ensureTargetVisible() {
    final step = widget.controller.currentStep;
    if (step == null) return;
    final ctx = step.targetKey?.currentContext ??
        (step.targetKeys != null && step.targetKeys!.isNotEmpty
            ? step.targetKeys!.first.currentContext
            : null);
    if (ctx == null) return;
    Scrollable.maybeOf(ctx)?.position.ensureVisible(
          ctx.findRenderObject()!,
          alignment: 0.2,
          duration: const Duration(milliseconds: 300),
        );
  }

  void _haptic() {
    if (widget.config.strongHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  Rect? _resolveTargetRect(BuildContext overlayContext) {
    final step = widget.controller.currentStep;
    if (step == null) return null;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;
    if (overlayBox == null) return null;

    Rect? unioned;
    final keys = step.targetKeys ??
        (step.targetKey != null ? [step.targetKey!] : const <GlobalKey>[]);
    for (final key in keys) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
      final rect = topLeft & box.size;
      unioned = unioned == null ? rect : unioned.expandToInclude(rect);
    }
    return unioned;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isActive) {
      return const SizedBox.shrink();
    }
    final step = widget.controller.currentStep;
    if (step == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rawRect = _resolveTargetRect(context);
        // Outset by 6px and clamp inside the screen, then round to whole pixels.
        Rect? holeRect;
        if (rawRect != null) {
          holeRect = rawRect.inflate(6).intersect(Offset.zero & size);
          if (holeRect.isEmpty) holeRect = null;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Scrim with hole punched out.
            IgnorePointer(
              child: CustomPaint(
                painter: _ScrimPainter(
                  hole: holeRect,
                  scrimColor: Colors.black.withValues(alpha: 0.62),
                  cornerRadius: 12,
                ),
                size: size,
              ),
            ),
            // Pointer blocking layer.
            if (step.allowTargetInteraction && holeRect != null)
              ..._buildHoleSurroundBlockers(size, holeRect)
            else
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: step.dismissibleByOutsideTap
                      ? () {
                          _haptic();
                          widget.controller.skip();
                        }
                      : () {},
                  child: const SizedBox.expand(),
                ),
              ),
            // Popup card.
            _buildPopup(context, size, holeRect, step),
          ],
        );
      },
    );
  }

  /// When the spotlight allows interaction, we still want the rest of the
  /// screen to be inert. Stack 4 rectangles around the hole instead of
  /// covering it.
  List<Widget> _buildHoleSurroundBlockers(Size size, Rect hole) {
    Widget block(Rect r) => Positioned(
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: const SizedBox.expand(),
          ),
        );

    final top = Rect.fromLTWH(0, 0, size.width, hole.top.clamp(0, size.height));
    final bottom = Rect.fromLTWH(
        0,
        hole.bottom.clamp(0, size.height),
        size.width,
        (size.height - hole.bottom).clamp(0, size.height));
    final left = Rect.fromLTWH(
        0,
        hole.top.clamp(0, size.height),
        hole.left.clamp(0, size.width),
        hole.height.clamp(0, size.height));
    final right = Rect.fromLTWH(
        hole.right.clamp(0, size.width),
        hole.top.clamp(0, size.height),
        (size.width - hole.right).clamp(0, size.width),
        hole.height.clamp(0, size.height));
    return [
      if (top.height > 0) block(top),
      if (bottom.height > 0) block(bottom),
      if (left.width > 0 && left.height > 0) block(left),
      if (right.width > 0 && right.height > 0) block(right),
    ];
  }

  Widget _buildPopup(
    BuildContext context,
    Size size,
    Rect? hole,
    TutorialStep step,
  ) {
    final theme = Theme.of(context);
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _haptic();
                      widget.controller.skip();
                    },
                    child: const Text('Skip Tutorial'),
                  ),
                  const Spacer(),
                  if (widget.controller.currentIndex > 0)
                    TextButton(
                      onPressed: () {
                        _haptic();
                        widget.controller.back();
                      },
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () {
                      _haptic();
                      widget.controller.next();
                    },
                    child: Text(
                      widget.controller.isLastStep ? 'Got it' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Position: above/below/center based on hole position and anchor hint.
    final placeBelow = _shouldPlaceBelow(size, hole, step.anchor);
    if (hole == null || step.anchor == TutorialAnchor.center) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: card,
        ),
      );
    }
    if (placeBelow) {
      return Positioned(
        top: (hole.bottom + 16).clamp(0.0, size.height - 80),
        left: 16,
        right: 16,
        child: Align(alignment: Alignment.topCenter, child: card),
      );
    } else {
      return Positioned(
        bottom: (size.height - hole.top + 16).clamp(0.0, size.height - 80),
        left: 16,
        right: 16,
        child: Align(alignment: Alignment.bottomCenter, child: card),
      );
    }
  }

  bool _shouldPlaceBelow(Size size, Rect? hole, TutorialAnchor anchor) {
    if (hole == null) return true;
    switch (anchor) {
      case TutorialAnchor.below:
        return true;
      case TutorialAnchor.above:
        return false;
      case TutorialAnchor.center:
        return true;
      case TutorialAnchor.auto:
        return hole.center.dy < size.height / 2;
    }
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect? hole;
  final Color scrimColor;
  final double cornerRadius;

  const _ScrimPainter({
    required this.hole,
    required this.scrimColor,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = scrimColor);
    if (hole != null) {
      final rrect =
          RRect.fromRectAndRadius(hole!, Radius.circular(cornerRadius));
      canvas.drawRRect(
        rrect,
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter old) {
    return old.hole != hole ||
        old.scrimColor != scrimColor ||
        old.cornerRadius != cornerRadius;
  }
}
