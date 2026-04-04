// Space Air Hockey easter egg — a silly mini-game hidden in the app.
// Tap the title bar to discover it.

import 'dart:async';
import 'dart:math';
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

  // Field dimensions (set in build from constraints)
  double fieldW = 300;
  double fieldH = 500;

  // Puck state
  double puckX = 150;
  double puckY = 250;
  double puckDx = 0;
  double puckDy = 0;

  // Player paddle (bottom)
  double playerX = 150;
  double playerY = 420;

  // CPU paddle (top)
  double cpuX = 150;
  double cpuY = 80;

  int playerScore = 0;
  int cpuScore = 0;
  bool gameOver = false;
  String? flashText;
  Timer? _gameLoop;
  final _random = Random();

  // Stars for background
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(40, (_) => _Star(_random));
    _startLoop();
  }

  void _startLoop() {
    _gameLoop?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || gameOver) return;
      _tick();
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  void _resetPuck({bool towardPlayer = false}) {
    puckX = fieldW / 2;
    puckY = fieldH / 2;
    final angle = towardPlayer
        ? (pi / 4 + _random.nextDouble() * pi / 2)
        : -(pi / 4 + _random.nextDouble() * pi / 2);
    final speed = 3.0 + _random.nextDouble() * 2;
    puckDx = cos(angle) * speed * (_random.nextBool() ? 1 : -1);
    puckDy = sin(angle) * speed;
  }

  void _tick() {
    setState(() {
      // Move puck
      puckX += puckDx;
      puckY += puckDy;

      // Wall bounce (left/right)
      if (puckX - puckRadius < 0) {
        puckX = puckRadius;
        puckDx = puckDx.abs();
      }
      if (puckX + puckRadius > fieldW) {
        puckX = fieldW - puckRadius;
        puckDx = -puckDx.abs();
      }

      // Goal detection (top = player scores, bottom = CPU scores)
      final goalLeft = (fieldW - goalWidth) / 2;
      final goalRight = goalLeft + goalWidth;

      if (puckY - puckRadius < 0) {
        if (puckX > goalLeft && puckX < goalRight) {
          playerScore++;
          flashText = _randomCheer();
          _checkWin();
          _resetPuck(towardPlayer: false);
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
          _resetPuck(towardPlayer: true);
        } else {
          puckY = fieldH - puckRadius;
          puckDy = -puckDy.abs();
        }
      }

      // Paddle collisions
      _checkPaddleCollision(playerX, playerY, true);
      _checkPaddleCollision(cpuX, cpuY, false);

      // CPU AI: track puck with some lag and wobble
      if (puckY < fieldH / 2) {
        // Puck in CPU half — actively track
        final targetX = puckX + (_random.nextDouble() - 0.5) * 30;
        cpuX += (targetX - cpuX) * 0.06;
      } else {
        // Return to center-ish
        cpuX += (fieldW / 2 + (_random.nextDouble() - 0.5) * 40 - cpuX) * 0.03;
      }
      cpuX = cpuX.clamp(paddleRadius, fieldW - paddleRadius);

      // Friction
      puckDx *= 0.998;
      puckDy *= 0.998;

      // Minimum speed
      final speed = sqrt(puckDx * puckDx + puckDy * puckDy);
      if (speed < 1.5 && speed > 0.01) {
        final factor = 1.5 / speed;
        puckDx *= factor;
        puckDy *= factor;
      }

      // Animate stars
      for (final s in _stars) {
        s.y += s.speed;
        if (s.y > fieldH) {
          s.y = 0;
          s.x = _random.nextDouble() * fieldW;
        }
      }
    });
  }

  void _checkPaddleCollision(double px, double py, bool isPlayer) {
    final dx = puckX - px;
    final dy = puckY - py;
    final dist = sqrt(dx * dx + dy * dy);
    final minDist = puckRadius + paddleRadius;

    if (dist < minDist && dist > 0) {
      // Bounce angle based on hit position
      final angle = atan2(dy, dx);
      final speed = sqrt(puckDx * puckDx + puckDy * puckDy).clamp(3.0, 10.0);
      final boost = isPlayer ? 1.15 : 1.05;
      puckDx = cos(angle) * speed * boost;
      puckDy = sin(angle) * speed * boost;

      // Push puck out of paddle
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
            Text('$cpuScore',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent.shade100)),
            Text('  SPACE HOCKEY  ',
                style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 2)),
            Text('$playerScore',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent)),
          ],
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          fieldW = constraints.maxWidth;
          fieldH = constraints.maxHeight;

          // Ensure positions are initialized relative to field
          if (playerY > fieldH - 40) playerY = fieldH - 60;
          if (cpuY < 40) cpuY = 60;

          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                playerX = details.localPosition.dx
                    .clamp(paddleRadius, fieldW - paddleRadius);
                playerY = details.localPosition.dy
                    .clamp(fieldH / 2 + paddleRadius, fieldH - paddleRadius);
              });
            },
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
                  _resetPuck();
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
  final double fieldW, fieldH;
  final double puckX, puckY, puckRadius;
  final double playerX, playerY, cpuX, cpuY, paddleRadius;
  final double goalWidth;
  final List<_Star> stars;
  final String? flashText;
  final bool gameOver;

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
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (final s in stars) {
      canvas.drawCircle(Offset(s.x, s.y), s.size, starPaint);
    }

    // Center line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, fieldH / 2), Offset(fieldW, fieldH / 2), linePaint);

    // Center circle
    canvas.drawCircle(
        Offset(fieldW / 2, fieldH / 2),
        40,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Goals
    final goalLeft = (fieldW - goalWidth) / 2;
    final goalPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    // Top goal
    canvas.drawLine(Offset(goalLeft, 0), Offset(goalLeft + goalWidth, 0), goalPaint);
    // Bottom goal
    canvas.drawLine(
        Offset(goalLeft, fieldH), Offset(goalLeft + goalWidth, fieldH), goalPaint);

    // CPU paddle (red glow)
    _drawPaddle(canvas, cpuX, cpuY, Colors.redAccent);

    // Player paddle (cyan glow)
    _drawPaddle(canvas, playerX, playerY, Colors.cyanAccent);

    // Puck (white with glow)
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
    // UFO detail on puck
    canvas.drawCircle(
      Offset(puckX, puckY),
      puckRadius * 0.5,
      Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Flash text
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
      tp.paint(
          canvas, Offset((fieldW - tp.width) / 2, fieldH / 2 - tp.height / 2));
    }
  }

  void _drawPaddle(Canvas canvas, double x, double y, Color color) {
    // Glow
    canvas.drawCircle(
      Offset(x, y),
      paddleRadius + 6,
      Paint()..color = color.withValues(alpha: 0.15),
    );
    // Ring
    canvas.drawCircle(
      Offset(x, y),
      paddleRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Inner fill
    canvas.drawCircle(
      Offset(x, y),
      paddleRadius - 3,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    // Center dot (thruster)
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HockeyPainter oldDelegate) => true;
}
