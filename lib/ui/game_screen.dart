import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game/entities.dart';
import '../utils/constants.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  late Player player;
  final List<Titan> titans = [];
  final List<Bullet> bullets = [];
  final List<Grenade> grenades = [];
  final List<Explosion> explosions = [];
  final Random rng = Random();
  int score = 0;
  bool gameOver = false, gameStarted = false;
  double groundY = 0, screenW = 0, screenH = 0;
  Timer? _loop;
  DateTime _lastTime = DateTime.now();
  double joyDx = 0, joyDy = 0;
  bool firing = false, aimingUp = false, aimingDown = false;
  double fireAngle = 0;
  Offset joyCenter = Offset.zero, joyKnob = Offset.zero;
  double joyRadius = 70;
  bool joyActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }
  void _startGame() {
    if (!mounted) return;
    screenW = MediaQuery.of(context).size.width;
    screenH = MediaQuery.of(context).size.height;
    groundY = screenH * GameConfig.groundRatio;
    player = Player(x: screenW * 0.2, y: groundY - GameConfig.playerH);
    titans.clear(); bullets.clear(); grenades.clear(); explosions.clear();
    score = 0; gameOver = false; gameStarted = true; firing = false;
    aimingUp = false; aimingDown = false; joyDx = 0; joyDy = 0; fireAngle = 0;
    joyCenter = Offset(110, screenH - 110); joyKnob = joyCenter;
    _spawnWave();
    _lastTime = DateTime.now();
    _loop?.cancel();
    _loop = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    setState(() {});
  }
  void _spawnWave() {
    for (int i = 0; i < 2; i++) {
      final x = screenW * 0.6 + i * 180.0 + rng.nextDouble() * 100;
      titans.add(Titan(
        x: x.clamp(0.0, max(0.0, screenW - GameConfig.titanW)),
        y: groundY - GameConfig.titanH,
      ));
    }
  }
  void _tick() {
    if (!mounted || gameOver) return;
    final now = DateTime.now();
    double dt = now.difference(_lastTime).inMicroseconds / 1000000.0;
    _lastTime = now;
    if (dt > GameConfig.maxDelta) dt = GameConfig.maxDelta;
    setState(() => _update(dt));
  }
  void _update(double dt) {
    if (!gameStarted || gameOver) return;
    player.vx = joyDx.abs() > 0.15 ? joyDx * GameConfig.playerSpeed : 0;
    if (joyDy < -0.5 && player.onGround) player.vy = GameConfig.playerJump;
    player.update(dt, groundY, screenW);
    if (aimingUp) { fireAngle -= 2.5 * dt; }
    else if (aimingDown) { fireAngle += 2.5 * dt; }
    fireAngle = fireAngle.clamp(-pi / 2, pi / 2);
    if (firing && player.fireTimer <= 0) {
      final dir = Offset(cos(fireAngle), sin(fireAngle));
      final pos = player.center + dir * 25;
      bullets.add(Bullet(x: pos.dx, y: pos.dy,
        vx: dir.dx * GameConfig.bulletSpeed, vy: dir.dy * GameConfig.bulletSpeed));
      player.fireTimer = GameConfig.fireCooldown;
    }
    for (final b in bullets) {
      b.update(dt);
      if (b.x < 0 || b.x > screenW || b.y < 0 || b.y > groundY) b.life = 0;
    }
    for (final g in grenades) {
      g.update(dt, groundY);
      if (g.shouldExplode && !g.exploded) {
        g.exploded = true; explosions.add(Explosion(x: g.x, y: g.y));
      }
    }
    for (final e in explosions) { e.update(dt); }
    for (final t in titans) {
      t.update(dt, groundY, player.center, screenW);
      if (t.canAttack() &&
          (t.center - player.center).distance < GameConfig.titanAttackRange) {
        player.takeDamage(GameConfig.titanDamage.round()); t.resetAttack();
      }
    }
    for (final b in bullets) {
      for (final t in titans) {
        if (t.isAlive && b.life > 0 && t.rect.inflate(4).contains(Offset(b.x, b.y))) {
          t.takeDamage(GameConfig.bulletDamage); b.life = 0;
          if (!t.isAlive) score += GameConfig.titanScore;
        }
      }
    }
    for (final e in explosions) {
      if (!e.damageApplied && e.radius > GameConfig.explosionRadius * 0.5) {
        e.damageApplied = true;
        for (final t in titans) {
          if (t.isAlive && (t.center - e.center).distance < GameConfig.explosionRadius * 1.2) {
            t.takeDamage(GameConfig.grenadeDamage);
            if (!t.isAlive) score += GameConfig.titanScore;
          }
        }
      }
    }
    bullets.removeWhere((b) => !b.isAlive);
    grenades.removeWhere((g) => g.exploded);
    explosions.removeWhere((e) => !e.isAlive);
    titans.removeWhere((t) => !t.isAlive);
    if (titans.isEmpty) _spawnWave();
    if (!player.isAlive) { gameOver = true; firing = false; }
  }
  void _fire() {
    if (firing || gameOver || !gameStarted) return;
    setState(() => firing = true);
  }
  void _stopFire() { if (mounted) setState(() => firing = false); }
  void _throwGrenade() {
    if (gameOver || player.grenades <= 0 || player.grenadeTimer > 0) return;
    setState(() {
      player.grenades--; player.grenadeTimer = GameConfig.grenadeCooldown;
      final dir = Offset(cos(fireAngle - 0.5), sin(fireAngle - 0.5));
      grenades.add(Grenade(x: player.center.dx + dir.dx * 20,
        y: player.center.dy + dir.dy * 20,
        vx: dir.dx * GameConfig.grenadeSpeed,
        vy: dir.dy * GameConfig.grenadeSpeed - 150));
    });
  }
  void _onJoyStart(DragStartDetails d) {
    setState(() { joyActive = true; joyCenter = d.localPosition; joyKnob = d.localPosition; });
  }
  void _onJoyUpdate(DragUpdateDetails d) {
    if (!joyActive) return;
    final delta = d.localPosition - joyCenter;
    final dist = delta.distance;
    final clamped = dist > joyRadius ? delta / dist * joyRadius : delta;
    setState(() {
      joyKnob = joyCenter + clamped;
      joyDx = (clamped.dx / joyRadius).clamp(-1.0, 1.0);
      joyDy = (clamped.dy / joyRadius).clamp(-1.0, 1.0);
    });
  }
  void _onJoyEnd(DragEndDetails d) {
    setState(() { joyActive = false; joyKnob = joyCenter; joyDx = 0; joyDy = 0; });
  }
  @override
  void dispose() { _loop?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    screenW = MediaQuery.of(context).size.width;
    screenH = MediaQuery.of(context).size.height;
    return Scaffold(body: Stack(children: [
      _buildBackground(),
      Positioned.fill(child: CustomPaint(painter: _GamePainter(this))),
      _buildJoystick(), _buildActionButtons(), _buildHud(),
      if (gameOver) _buildGameOver(),
    ]));
  }
  Widget _buildBackground() => Positioned.fill(child: Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [GameColors.skyTop, GameColors.skyBottom],
    )),
  ));
  Widget _buildJoystick() => Positioned(
    left: joyCenter.dx - joyRadius - 10, top: joyCenter.dy - joyRadius - 10,
    child: GestureDetector(
      onPanStart: _onJoyStart, onPanUpdate: _onJoyUpdate, onPanEnd: _onJoyEnd,
      child: CustomPaint(size: Size(joyRadius * 2 + 20, joyRadius * 2 + 20),
        painter: _JoystickPainter(
          baseCenter: Offset(joyRadius + 10, joyRadius + 10),
          knobOffset: joyKnob - joyCenter, radius: joyRadius,
        )),
    ),
  );
  Widget _buildActionButtons() {
    const btnSize = 75.0;
    final baseY = screenH - btnSize - 30;
    final baseX = screenW - btnSize - 30;
    return Positioned.fill(child: Stack(children: [
      Positioned(right: 30, bottom: 30, child: _circleButton(
        size: btnSize, color: GameColors.buttonFire, icon: Icons.gps_fixed,
        onTapDown: (_) => _fire(), onTapUp: (_) => _stopFire(),
      )),
      Positioned(right: 30 + btnSize + 15, bottom: 30, child: _circleButton(
        size: btnSize, color: GameColors.buttonGrenade, icon: Icons.brightness_1,
        label: '${player.grenades}', onTapDown: (_) => _throwGrenade(), onTapUp: (_) {},
      )),
      Positioned(right: baseX, bottom: baseY - btnSize - 10, child: _smallButton(
        icon: Icons.keyboard_arrow_up,
        onTapDown: (_) => setState(() => aimingUp = true),
        onTapUp: (_) => setState(() => aimingUp = false),
      )),
      Positioned(right: baseX - btnSize - 10, bottom: baseY - btnSize - 10, child: _smallButton(
        icon: Icons.keyboard_arrow_down,
        onTapDown: (_) => setState(() => aimingDown = true),
        onTapUp: (_) => setState(() => aimingDown = false),
      )),
    ]));
  }
  Widget _circleButton({required double size, required Color color, required IconData icon,
    String? label, required GestureTapDownCallback onTapDown, required GestureTapUpCallback onTapUp}) =>
    GestureDetector(onTapDown: onTapDown, onTapUp: onTapUp,
      onTapCancel: () => onTapUp(TapUpDetails()),
      child: Container(width: size, height: size, decoration: BoxDecoration(
        shape: BoxShape.circle, color: color,
        border: Border.all(color: Colors.white54, width: 2),
      ), child: Stack(alignment: Alignment.center, children: [
        Icon(icon, color: Colors.white, size: size * 0.5),
        if (label != null) Positioned(bottom: 4, right: 8, child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      ])));
  Widget _smallButton({required IconData icon, required GestureTapDownCallback onTapDown,
    required GestureTapUpCallback onTapUp}) => GestureDetector(
    onTapDown: onTapDown, onTapUp: onTapUp, onTapCancel: () => onTapUp(TapUpDetails()),
    child: Container(width: 55, height: 55, decoration: BoxDecoration(
      shape: BoxShape.circle, color: Colors.white24,
      border: Border.all(color: Colors.white54, width: 2),
    ), child: Icon(icon, color: Colors.white, size: 30)));
  Widget _buildHud() {
    final hp = player.isAlive ? player.health : 0;
    final ratio = hp / GameConfig.maxHealth;
    final hpColor = ratio > 0.3 ? GameColors.player : GameColors.titan;
    return Positioned(top: 12, left: 12, right: 12, child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: GameColors.uiPanel, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24)),
        child: Row(children: [
          const Icon(Icons.favorite, color: Colors.red, size: 20), const SizedBox(width: 6),
          SizedBox(width: 100, height: 14, child: Stack(children: [
            Container(color: Colors.white24),
            FractionallySizedBox(widthFactor: ratio.clamp(0.0, 1.0), child: Container(color: hpColor)),
          ])),
          const SizedBox(width: 6), Text('$hp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ])),
      const SizedBox(width: 12),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: GameColors.uiPanel, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24)),
        child: Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 6),
          Text('$score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ])),
    ]));
  }
  Widget _buildGameOver() => Positioned.fill(child: Container(
    color: Colors.black.withOpacity(0.75),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('انتهت اللعبة!', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Text('نقاطك: $score', style: const TextStyle(color: Colors.amber, fontSize: 26)),
      const SizedBox(height: 30),
      ElevatedButton.icon(onPressed: _startGame, icon: const Icon(Icons.replay),
        label: const Text('العب مرة أخرى'),
        style: ElevatedButton.styleFrom(backgroundColor: GameColors.player,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          textStyle: const TextStyle(fontSize: 20))),
    ])),
  ));
}

class _JoystickPainter extends CustomPainter {
  final Offset baseCenter, knobOffset;
  final double radius;
  _JoystickPainter({required this.baseCenter, required this.knobOffset, required this.radius});
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = GameColors.joystickBase;
    final border = Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 3;
    final knob = Paint()..color = GameColors.joystickKnob;
    canvas.drawCircle(baseCenter, radius, base);
    canvas.drawCircle(baseCenter, radius, border);
    canvas.drawCircle(baseCenter + knobOffset, radius * 0.45, knob);
  }
  @override
  bool shouldRepaint(covariant _JoystickPainter old) =>
      old.knobOffset != knobOffset || old.baseCenter != baseCenter;
}
class _GamePainter extends CustomPainter {
  final _GameScreenState s;
  _GamePainter(this.s);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, s.groundY, size.width, size.height - s.groundY),
      Paint()..color = GameColors.ground);
    canvas.drawRect(Rect.fromLTWH(0, s.groundY, size.width, 6),
      Paint()..color = GameColors.groundTop);
    if (s.gameStarted) _drawPlayer(canvas, s.player);
    for (final t in s.titans) { _drawTitan(canvas, t); }
    for (final b in s.bullets) {
      canvas.drawCircle(Offset(b.x, b.y), GameConfig.bulletSize, Paint()..color = GameColors.bullet);
    }
    for (final g in s.grenades) {
      canvas.drawCircle(Offset(g.x, g.y), GameConfig.grenadeSize, Paint()..color = GameColors.grenade);
      canvas.drawCircle(Offset(g.x, g.y - 8), 3, Paint()..color = Colors.orange);
    }
    for (final e in s.explosions) {
      final progress = e.timer / GameConfig.explosionDuration;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(e.center, e.radius, Paint()..color = GameColors.explosionOuter.withOpacity(alpha * 0.7));
      canvas.drawCircle(e.center, e.radius * 0.6, Paint()..color = GameColors.explosionInner.withOpacity(alpha));
    }
  }
  void _drawPlayer(Canvas canvas, Player p) {
    final paint = Paint()..color = GameColors.player;
    if (p.invincibleTimer > 0 && (p.invincibleTimer * 10).toInt() % 2 == 0) paint.color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(p.rect, const Radius.circular(6)), paint);
    canvas.drawCircle(Offset(p.center.dx, p.y + 10), 10, Paint()..color = GameColors.titanSkin);
    final end = p.center + Offset(cos(s.fireAngle), sin(s.fireAngle)) * 30;
    canvas.drawLine(p.center, end, Paint()..color = Colors.black87..strokeWidth = 5);
    canvas.drawCircle(end, 3, Paint()..color = Colors.white);
  }
  void _drawTitan(Canvas canvas, Titan t) {
    final body = Paint()..color = t.hurtFlash > 0 ? Colors.white : GameColors.titan;
    canvas.drawRRect(RRect.fromRectAndRadius(t.rect, const Radius.circular(8)), body);
    canvas.drawCircle(Offset(t.center.dx, t.y + 18), 16, Paint()..color = GameColors.titanSkin);
    canvas.drawCircle(Offset(t.center.dx - 6, t.y + 16), 3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(t.center.dx + 6, t.y + 16), 3, Paint()..color = Colors.black);
    final ratio = t.health / GameConfig.titanHealth;
    canvas.drawRect(Rect.fromLTWH(t.x, t.y - 14, t.w, 6), Paint()..color = Colors.black54);
    canvas.drawRect(Rect.fromLTWH(t.x, t.y - 14, t.w * ratio.clamp(0.0, 1.0), 6),
      Paint()..color = GameColors.titan);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
