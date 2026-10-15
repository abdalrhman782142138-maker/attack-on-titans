import 'package:flutter/material.dart';
import '../utils/constants.dart';

class Player {
  double x, y, vx = 0, vy = 0;
  double w = GameConfig.playerW, h = GameConfig.playerH;
  int health = GameConfig.maxHealth;
  bool onGround = false;
  double invincibleTimer = 0, fireTimer = 0, grenadeTimer = 0;
  int grenades = GameConfig.maxGrenades;
  Player({required this.x, required this.y});
  Rect get rect => Rect.fromLTWH(x, y, w, h);
  Offset get center => Offset(x + w / 2, y + h / 2);
  void update(double dt, double groundY, double screenW) {
    vy += GameConfig.gravity * dt;
    x += vx * dt; y += vy * dt;
    if (x < 0) x = 0;
    if (x + w > screenW) x = screenW - w;
    if (y + h >= groundY) {
      y = groundY - h; vy = 0; onGround = true;
    } else { onGround = false; }
    if (invincibleTimer > 0) invincibleTimer -= dt;
    if (fireTimer > 0) fireTimer -= dt;
    if (grenadeTimer > 0) grenadeTimer -= dt;
  }
  void takeDamage(int dmg) {
    if (invincibleTimer > 0) return;
    health = (health - dmg).clamp(0, GameConfig.maxHealth);
    invincibleTimer = GameConfig.invincibilityTime;
  }
  bool get isAlive => health > 0;
}
class Titan {
  double x, y, vx = 0, vy = 0;
  double w = GameConfig.titanW, h = GameConfig.titanH;
  int health = GameConfig.titanHealth;
  double attackTimer = 0, hurtFlash = 0;
  Titan({required this.x, required this.y});
  Rect get rect => Rect.fromLTWH(x, y, w, h);
  Offset get center => Offset(x + w / 2, y + h / 2);
  void update(double dt, double groundY, Offset playerCenter, double screenW) {
    if (playerCenter.dx < center.dx - 5) {
      vx = -GameConfig.titanSpeed;
    } else if (playerCenter.dx > center.dx + 5) {
      vx = GameConfig.titanSpeed;
    } else { vx = 0; }
    vy += GameConfig.gravity * dt;
    x = (x + vx * dt).clamp(0.0, (screenW - w).clamp(0.0, screenW));
    y += vy * dt;
    if (y + h >= groundY) { y = groundY - h; vy = 0; }
    if (attackTimer > 0) attackTimer -= dt;
    if (hurtFlash > 0) hurtFlash -= dt;
  }
  void takeDamage(double dmg) { health -= dmg.round(); hurtFlash = 0.15; }
  bool canAttack() => attackTimer <= 0;
  void resetAttack() => attackTimer = GameConfig.titanAttackCooldown;
  bool get isAlive => health > 0;
}
class Bullet {
  double x, y, vx, vy;
  double size = GameConfig.bulletSize, life = 2.0;
  Bullet({required this.x, required this.y, required this.vx, required this.vy});
  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: size, height: size);
  void update(double dt) { x += vx * dt; y += vy * dt; life -= dt; }
  bool get isAlive => life > 0;
}
class Grenade {
  double x, y, vx, vy;
  double size = GameConfig.grenadeSize, fuse = GameConfig.grenadeFuse;
  bool exploded = false;
  Grenade({required this.x, required this.y, required this.vx, required this.vy});
  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: size, height: size);
  void update(double dt, double groundY) {
    vy += GameConfig.gravity * dt; x += vx * dt; y += vy * dt;
    if (y + size / 2 >= groundY) {
      y = groundY - size / 2; vy = -vy * 0.4; vx *= 0.7;
      if (vy.abs() < 30) vy = 0;
    }
    fuse -= dt;
  }
  bool get shouldExplode => fuse <= 0;
}
class Explosion {
  double x, y, radius = 0;
  double maxRadius = GameConfig.explosionRadius, timer = 0;
  bool damageApplied = false;
  Explosion({required this.x, required this.y});
  Offset get center => Offset(x, y);
  void update(double dt) {
    timer += dt;
    final progress = timer / GameConfig.explosionDuration;
    radius = maxRadius * (progress < 1 ? progress : 1);
  }
  bool get isAlive => timer < GameConfig.explosionDuration;
}
