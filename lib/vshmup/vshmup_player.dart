import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:space_kenney/util/auto_dispose.dart';
import 'package:space_kenney/vshmup/vshmup_asteroids.dart';

import '../core/common.dart';
import '../story/script_functions.dart';
import '../util/input_acceleration.dart';
import 'vshmup_game_keys.dart';
import 'vshmup_mining_laser.dart';

enum _PlayerState {
  incoming,
  playing,
  //...
}

class VShmupPlayer extends PositionComponent
    with AutoDispose, ScriptFunctions, KeyboardHandler, VShmupGameKeys, CollisionCallbacks {
  //
  static final incomingSpeed = dev ? 100 : 20;

  late final xMovement = InputAcceleration(
    goNegative: () => held[VShmupGameKey.left] == true,
    goPositive: () => held[VShmupGameKey.right] == true,
  );

  late final yMovement = InputAcceleration(
    goNegative: () => held[VShmupGameKey.up] == true,
    goPositive: () => held[VShmupGameKey.down] == true,
    position: 40,
    positionLimit: 80,
  );

  late SpriteAnimationComponent ship;
  late SpriteAnimationComponent booster;

  // TODO weapon system instead! also: hud!
  late Component _primaryWeapon;

  var _state = _PlayerState.incoming;

  @override
  void onLoad() async {
    priority = 100;

    parent!.add(_primaryWeapon = VShmupMiningLaser(this, this));

    final shipFrames = await loadAnimWH('vshmup/player.png', 64, 64);
    add(ship = makeAnimXY(shipFrames, 0, 0)..playing = false);
    ship.playing = false;
    ship.priority = 101;

    final boosterFrames = await loadAnimWH('vshmup/player_small_boosters.png', 16, 10);
    add(booster = makeAnimXY(boosterFrames, 0, 26));
    booster.scale.setAll(1.8);
    booster.priority = 99;

    final hBox = RectangleHitbox(anchor: Anchor.topCenter);
    hBox.y += 2;
    hBox.width = ship.width;
    hBox.height = ship.height / 4;
    add(hBox);

    final vBox = RectangleHitbox(anchor: Anchor.bottomCenter);
    vBox.width = ship.width / 4;
    vBox.height = ship.height / 3;
    add(vBox);

    position.x = 160;
    position.y = 280;
    anchor = Anchor.center;
    scale.setAll(0.5);

    _frame = 3;
  }

  double _incoming = 0;

  @override
  void update(double dt) {
    super.update(dt);
    switch (_state) {
      case _PlayerState.incoming:
        _incoming += dt;

        final t = _incoming.clamp(0, 1).toDouble();
        final dy = Curves.decelerate.transform(t) * 60;
        position.y = 280 - dy;
        if (position.y <= 220) _state = _PlayerState.playing;

      case _PlayerState.playing:
        onPlaying(dt);
        break;
    }
  }

  void onPlaying(double dt) {
    xMovement.update(dt);
    yMovement.update(dt);
    position.x = 160 + xMovement.position;
    position.y = 180 + yMovement.position;

    final target = xMovement.targetFrame + 3;
    if (_frameChangeTimer <= 0 && _frame != target) {
      _frame = target;
      _frameChangeTimer = 0.25;
    } else {
      _frameChangeTimer -= dt;
    }

    yMovement.targetFrame;
    booster.scale.setAll(1.8 - 0.2 * yMovement.targetFrame);
  }

  int get _frame => ship.animationTicker?.currentIndex ?? 3;

  set _frame(int it) => ship.animationTicker?.currentIndex = it;

  double _frameChangeTimer = 0;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is VShmupAsteroid) {
      other.onHit(0.5);
    }
  }
}
