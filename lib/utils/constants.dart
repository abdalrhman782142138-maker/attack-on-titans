import 'package:flutter/material.dart';

class GameColors {
  static const Color skyTop = Color(0xFF16213E);
  static const Color skyBottom = Color(0xFF0F3460);
  static const Color ground = Color(0xFF3D3D3D);
  static const Color groundTop = Color(0xFF4A4A4A);
  static const Color player = Color(0xFF4CAF50);
  static const Color titan = Color(0xFFE53935);
  static const Color titanSkin = Color(0xFFFFCCBC);
  static const Color bullet = Color(0xFFFFEB3B);
  static const Color grenade = Color(0xFF8BC34A);
  static const Color explosionOuter = Color(0xFFFF9800);
  static const Color explosionInner = Color(0xFFFFF176);
  static const Color uiPanel = Color(0xCC000000);
  static const Color buttonFire = Color(0xCCF44336);
  static const Color buttonGrenade = Color(0xCC8BC34A);
  static const Color joystickBase = Color(0x44FFFFFF);
  static const Color joystickKnob = Color(0xCC4CAF50);
}
class GameConfig {
  static const double gravity = 1400.0;
  static const double groundRatio = 0.85;
  static const double playerSpeed = 300.0;
  static const double playerJump = -700.0;
  static const double playerW = 32.0;
  static const double playerH = 56.0;
  static const int maxHealth = 100;
  static const double invincibilityTime = 1.0;
  static const double bulletSpeed = 800.0;
  static const double bulletDamage = 15.0;
  static const double bulletSize = 6.0;
  static const double fireCooldown = 0.12;
  static const double grenadeSpeed = 450.0;
  static const double grenadeDamage = 60.0;
  static const double grenadeSize = 14.0;
  static const double grenadeFuse = 1.5;
  static const int maxGrenades = 5;
  static const double grenadeCooldown = 0.8;
  static const double explosionRadius = 110.0;
  static const double explosionDuration = 0.5;
  static const double titanSpeed = 70.0;
  static const double titanDamage = 25.0;
  static const int titanHealth = 60;
  static const double titanW = 55.0;
  static const double titanH = 110.0;
  static const double titanAttackRange = 65.0;
  static const double titanAttackCooldown = 1.2;
  static const int titanScore = 10;
  static const double maxDelta = 0.05;
}
