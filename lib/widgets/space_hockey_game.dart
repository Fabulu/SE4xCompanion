// Space Air Hockey easter egg - a silly mini-game hidden in the app.
// Tap the title bar to discover it.

import 'dart:async';
import 'dart:math';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

class SpaceHockeyGame extends StatefulWidget {
  const SpaceHockeyGame({super.key});

  @override
  State<SpaceHockeyGame> createState() => _SpaceHockeyGameState();
}

class _SpaceHockeyGameState extends State<SpaceHockeyGame> {
  static const double puckRadius = 12;
  static const double paddleRadius = 24;
  static const double goalWidth = 100;
  static const Duration _controlDelay = Duration(seconds: 1);

  double fieldW = 300;
  double fieldH = 500;

  double puckX = 150;
  double puckY = 250;
  double puckDx = 0;
  double puckDy = 0;

  double playerX = 150;
  double playerY = 420;

  double cpuX = 150;
  double cpuY = 80;

  double _playerVx = 0;
  double _playerVy = 0;
  double _cpuVx = 0;
  double _cpuVy = 0;

  int playerScore = 0;
  int cpuScore = 0;
  bool gameOver = false;
  String? flashText;
  Timer? _gameLoop;
  final _random = Random();
  bool _layoutInitialized = false;

  int? _playerPointerId;
  int? _opponentPointerId;
  DateTime _playerControlUnlockAt = DateTime.now();

  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(40, (_) => _Star(_random));
    _resetRound(towardPlayerGoal: false);
    _startLoop();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  bool get _isTwoPlayerMode => _opponentPointerId != null;

  bool get _playerControlUnlocked =>
      DateTime.now().isAfter(_playerControlUnlockAt) ||
      DateTime.now().isAtSameMomentAs(_playerControlUnlockAt);

  void _startLoop() {
    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || gameOver) return;
      _tick();
    });
  }

  void _resetRound({required bool towardPlayerGoal}) {
    playerX = fieldW / 2;
    playerY = fieldH - 72;
    cpuX = fieldW / 2;
    cpuY = 72;
    _playerVx = 0;
    _playerVy = 0;
    _cpuVx = 0;
    _cpuVy = 0;
    _playerPointerId = null;
    _opponentPointerId = null;
    _playerControlUnlockAt = DateTime.now().add(_controlDelay);

    puckX = fieldW / 2 + (_random.nextDouble() - 0.5) * 30;
    puckY = towardPlayerGoal ? fieldH * 0.32 : fieldH * 0.68;
    final baseAngle = towardPlayerGoal
        ? (pi / 2 + (_random.nextDouble() - 0.5) * 0.9)
        : (-pi / 2 + (_random.nextDouble() - 0.5) * 0.9);
    final speed = 3.8 + _random.nextDouble() * 1.6;
    puckDx = cos(baseAngle) * speed;
    puckDy = sin(baseAngle) * speed;
  }

  void _tick() {
    setState(() {
      puckX += puckDx;
      puckY += puckDy;

      if (puckX - puckRadius < 0) {
        puckX = puckRadius;
        puckDx = puckDx.abs();
      }
      if (puckX + puckRadius > fieldW) {
        puckX = fieldW - puckRadius;
        puckDx = -puckDx.abs();
      }

      final goalLeft = (fieldW - goalWidth) / 2;
      final goalRight = goalLeft + goalWidth;

      if (puckY - puckRadius < 0) {
        if (puckX > goalLeft && puckX < goalRight) {
          playerScore++;
          flashText = _randomCheer();
          _checkWin();
          if (!gameOver) _resetRound(towardPlayerGoal: false);
        } else {
          puckY = puckRadius;
          puckDy = puckDy.abs();
        }
      }

      if (puckY + puckRadius > fieldH) {
        if (puckX > goalLeft && puckX < goalRight) {
          cpuScore++;
          flashText = _randomTaunt();
          _checkWin();
          if (!gameOver) _resetRound(towardPlayerGoal: true);
        } else {
          puckY = fieldH - puckRadius;
          puckDy = -puckDy.abs();
        }
      }

      _checkPaddleCollision(playerX, playerY, true);
      _checkPaddleCollision(cpuX, cpuY, false);

      if (!_isTwoPlayerMode) {
        _updateCpuPaddle();
      }

      puckDx *= 0.998;
      puckDy *= 0.998;

      final speed = sqrt(puckDx * puckDx + puckDy * puckDy);
      if (speed < 1.5 && speed > 0.01) {
        final factor = 1.5 / speed;
        puckDx *= factor;
        puckDy *= factor;
      }

      for (final s in _stars) {
        s.y += s.speed;
        if (s.y > fieldH) {
          s.y = 0;
          s.x = _random.nextDouble() * fieldW;
        }
      }
    });
  }

  void _updateCpuPaddle() {
    final defensiveY = 78.0;
    final attackY = fieldH * 0.28;
    final puckMovingUp = puckDy < 0;
    final shouldAttack = puckMovingUp || puckY < fieldH * 0.55;
    final targetY = shouldAttack ? attackY : defensiveY;
    final targetX = _predictPuckXAtY(targetY);

    const maxStep = 5.6;
    final dx = (targetX - cpuX).clamp(-maxStep, maxStep);
    final dy = (targetY - cpuY).clamp(-maxStep, maxStep);

    _cpuVx = dx;
    _cpuVy = dy;
    cpuX = (cpuX + dx).clamp(paddleRadius, fieldW - paddleRadius);
    cpuY = (cpuY + dy).clamp(paddleRadius, fieldH / 2 - paddleRadius);
  }

  double _predictPuckXAtY(double targetY) {
    if (puckDy.abs() < 0.01) return puckX;
    var projectedX = puckX;
    final travelTicks = ((targetY - puckY) / puckDy).abs().clamp(0, 160);
    projectedX += puckDx * travelTicks;

    final left = puckRadius;
    final right = fieldW - puckRadius;
    while (projectedX < left || projectedX > right) {
      if (projectedX < left) {
        projectedX = left + (left - projectedX);
      } else if (projectedX > right) {
        projectedX = right - (projectedX - right);
      }
    }
    return projectedX.clamp(paddleRadius, fieldW - paddleRadius);
  }

  void _checkPaddleCollision(double px, double py, bool isPlayer) {
    final dx = puckX - px;
    final dy = puckY - py;
    final dist = sqrt(dx * dx + dy * dy);
    final minDist = puckRadius + paddleRadius;

    if (dist < minDist && dist > 0) {
      final angle = atan2(dy, dx);
      final speed = sqrt(puckDx * puckDx + puckDy * puckDy).clamp(3.0, 10.0);
      final boost = isPlayer ? 1.15 : 1.08;
      final paddleVx = isPlayer ? _playerVx : _cpuVx;
      final paddleVy = isPlayer ? _playerVy : _cpuVy;

      puckDx = cos(angle) * speed * boost + paddleVx * 0.45;
      puckDy = sin(angle) * speed * boost + paddleVy * 0.45;

      puckX = px + cos(angle) * minDist;
      puckY = py + sin(angle) * minDist;
    }
  }

  void _checkWin() {
    if (playerScore >= 5 || cpuScore >= 5) {
      gameOver = true;
      flashText = playerScore >= 5 ? 'YOU WIN!' : 'CPU WINS!';
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) return;
    if (_playerPointerId == null) {
      _playerPointerId = event.pointer;
      if (_playerControlUnlocked) {
        setState(() => _movePlayerTo(event.localPosition));
      }
      return;
    }
    if (_opponentPointerId == null && event.pointer != _playerPointerId) {
      setState(() {
        _opponentPointerId = event.pointer;
        _moveOpponentTo(event.localPosition);
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (gameOver) return;
    setState(() {
      if (event.pointer == _playerPointerId) {
        if (_playerControlUnlocked) {
          _movePlayerTo(event.localPosition);
        }
      } else if (event.pointer == _opponentPointerId) {
        _moveOpponentTo(event.localPosition);
      }
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer == _playerPointerId) {
      setState(() {
        _playerPointerId = null;
        _playerVx = 0;
        _playerVy = 0;
      });
    } else if (event.pointer == _opponentPointerId) {
      setState(() {
        _opponentPointerId = null;
        _cpuVx = 0;
        _cpuVy = 0;
      });
    }
  }

  void _movePlayerTo(Offset position) {
    final nextX = position.dx.clamp(paddleRadius, fieldW - paddleRadius);
    final nextY = position.dy.clamp(fieldH / 2 + paddleRadius, fieldH - paddleRadius);
    _playerVx = nextX - playerX;
    _playerVy = nextY - playerY;
    playerX = nextX;
    playerY = nextY;
  }

  void _moveOpponentTo(Offset position) {
    final nextX = position.dx.clamp(paddleRadius, fieldW - paddleRadius);
    final nextY = position.dy.clamp(paddleRadius, fieldH / 2 - paddleRadius);
    _cpuVx = nextX - cpuX;
    _cpuVy = nextY - cpuY;
    cpuX = nextX;
    cpuY = nextY;
  }

  String _randomCheer() {
    const cheers = [
      'WARP SPEED GOAL!',
      'SHIELDS DOWN!',
      'CRITICAL HIT!',
      'PHOTON TORPEDO!',
      'HULL BREACH!',
    ];
    return cheers[_random.nextInt(cheers.length)];
  }

  String _randomTaunt() {
    const taunts = [
      'EVASIVE MANEUVERS!',
      'THE ALIENS SCORE!',
      'RED ALERT!',
      'HULL INTEGRITY FAILING!',
      'ABANDON SHIP!',
    ];
    return taunts[_random.nextInt(taunts.length)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$cpuScore',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent.shade100,
              ),
            ),
            Text(
              '  SPACE HOCKEY  ',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
            Text(
              '$playerScore',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previousW = fieldW;
          final previousH = fieldH;
          fieldW = constraints.maxWidth;
          fieldH = constraints.maxHeight;

          if (!_layoutInitialized ||
              (previousW != fieldW && previousW == 300) ||
              (previousH != fieldH && previousH == 500)) {
            _layoutInitialized = true;
            _resetRound(towardPlayerGoal: false);
          }

          if (playerY > fieldH - 40) playerY = fieldH - 60;
          if (cpuY < 40) cpuY = 60;

          return Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerEnd,
            onPointerCancel: _handlePointerEnd,
            child: CustomPaint(
              painter: _HockeyPainter(
                fieldW: fieldW,
                fieldH: fieldH,
                puckX: puckX,
                puckY: puckY,
                puckRadius: puckRadius,
                playerX: playerX,
                playerY: playerY,
                cpuX: cpuX,
                cpuY: cpuY,
                paddleRadius: paddleRadius,
                goalWidth: goalWidth,
                stars: _stars,
                flashText: flashText,
                gameOver: gameOver,
                playerControlLocked: !_playerControlUnlocked,
                twoPlayerMode: _isTwoPlayerMode,
              ),
              size: Size(fieldW, fieldH),
            ),
          );
        },
      ),
      floatingActionButton: gameOver
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  playerScore = 0;
                  cpuScore = 0;
                  gameOver = false;
                  flashText = null;
                  _resetRound(towardPlayerGoal: false);
                  _startLoop();
                });
              },
              icon: const Icon(Icons.replay),
              label: const Text('REMATCH'),
              backgroundColor: Colors.deepPurple,
            )
          : null,
    );
  }
}

class _Star {
  double x;
  double y;
  double speed;
  double size;

  _Star(Random r)
      : x = r.nextDouble() * 400,
        y = r.nextDouble() * 600,
        speed = 0.2 + r.nextDouble() * 0.8,
        size = 0.5 + r.nextDouble() * 1.5;
}

class _HockeyPainter extends CustomPainter {
  final double fieldW;
  final double fieldH;
  final double puckX;
  final double puckY;
  final double puckRadius;
  final double playerX;
  final double playerY;
  final double cpuX;
  final double cpuY;
  final double paddleRadius;
  final double goalWidth;
  final List<_Star> stars;
  final String? flashText;
  final bool gameOver;
  final bool playerControlLocked;
  final bool twoPlayerMode;

  _HockeyPainter({
    required this.fieldW,
    required this.fieldH,
    required this.puckX,
    required this.puckY,
    required this.puckRadius,
    required this.playerX,
    required this.playerY,
    required this.cpuX,
    required this.cpuY,
    required this.paddleRadius,
    required this.goalWidth,
    required this.stars,
    this.flashText,
    this.gameOver = false,
    this.playerControlLocked = false,
    this.twoPlayerMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (final s in stars) {
      canvas.drawCircle(Offset(s.x, s.y), s.size, starPaint);
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, fieldH / 2), Offset(fieldW, fieldH / 2), linePaint);

    canvas.drawCircle(
      Offset(fieldW / 2, fieldH / 2),
      40,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final goalLeft = (fieldW - goalWidth) / 2;
    final goalPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(goalLeft, 0), Offset(goalLeft + goalWidth, 0), goalPaint);
    canvas.drawLine(
      Offset(goalLeft, fieldH),
      Offset(goalLeft + goalWidth, fieldH),
      goalPaint,
    );

    _drawPaddle(canvas, cpuX, cpuY, Colors.cyanAccent);
    _drawPaddle(canvas, playerX, playerY, Colors.redAccent);

    canvas.drawCircle(
      Offset(puckX, puckY),
      puckRadius + 4,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    canvas.drawCircle(
      Offset(puckX, puckY),
      puckRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(puckX, puckY),
      puckRadius * 0.5,
      Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (flashText != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: flashText,
          style: TextStyle(
            fontSize: gameOver ? 32 : 22,
            fontWeight: FontWeight.bold,
            color: gameOver ? Colors.amber : Colors.white.withValues(alpha: 0.8),
            letterSpacing: 3,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset((fieldW - tp.width) / 2, fieldH / 2 - tp.height / 2));
    }

    if (playerControlLocked || twoPlayerMode) {
      final status = [
        if (playerControlLocked) 'PLAYER ONLINE IN 1...',
        if (twoPlayerMode) 'TWO PLAYER MODE',
      ].join('   ');
      final tp = TextPainter(
        text: TextSpan(
          text: status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 1.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: fieldW - 24);
      tp.paint(canvas, Offset((fieldW - tp.width) / 2, fieldH - tp.height - 14));
    }
  }

  void _drawPaddle(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(
      Offset(x, y),
      paddleRadius + 6,
      Paint()..color = color.withValues(alpha: 0.15),
    );
    canvas.drawCircle(
      Offset(x, y),
      paddleRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(x, y),
      paddleRadius - 3,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HockeyPainter oldDelegate) => true;
}
