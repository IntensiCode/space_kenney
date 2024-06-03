import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

const kay = 'dialog_kay.png';
const kenney = 'dialog_kenney.png';
const central = 'dialog_central.png';

const double tileSize = 16;

const double gameWidth = 320;
const double gameHeight = 256;
const double levelHeight = 15 * tileSize;

final Vector2 gameSize = Vector2(gameWidth, gameHeight);

Paint pixelArtLayerPaint() => Paint()
  ..isAntiAlias = false
  ..filterQuality = FilterQuality.none;

typedef IsTarget = bool Function(PositionComponent);

bool isAttacker(PositionComponent it) => it is Attacker;

enum ProjectileKind {
  acidBall,
}

mixin Attacker {}

void repeat(int count, void Function(int) func) {
  for (var i = 0; i < count; i++) {
    func(i);
  }
}

bool debug = kDebugMode;
bool dev = kDebugMode;

late Game game;
late Images images;

enum Screen {
  chapter1,
  chapter1_level1,
  splash,
  title,
}
