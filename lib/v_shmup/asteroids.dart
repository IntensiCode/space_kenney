import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/animation.dart';
import 'package:space_kenney/core/common.dart';
import 'package:space_kenney/core/soundboard.dart';
import 'package:space_kenney/util/debug.dart';
import 'package:space_kenney/util/random.dart';

import '../story/script_functions.dart';
import '../util/extensions.dart';

const _positionDistribution = Curves.easeInOutCubic;

const _frameSize = 32;

const _rotateBaseSeconds = 10.0;
const _rotateVariance = 5.0;

const _baseSpeed = 24;
const _speedVariance = 12.0;

final _fileSpec = [
  ('asteroid_32_8_480989078.png', 10),
  ('asteroid_32_8_606090416.png', 10),
  ('asteroid_32_8_1608776684.png', 10),
  ('asteroid_32_8_2528342683.png', 10),
  ('asteroid_32_8_2615803189.png', 10),
  ('asteroid_32_8_3670379078.png', 10),
];

int _nextAnim = random.nextInt(_fileSpec.length);

extension ScriptFunctionsExtension on ScriptFunctions {
  Asteroids asteroids() => added(Asteroids());
}

class Asteroids extends Component with ScriptFunctions {
  final _animations = <(SpriteAnimation, double)>[];

  double _releaseTime = 0;

  int maxAsteroids = 16;

  @override
  void onLoad() async {
    for (final (it, hitrad) in _fileSpec) {
      _animations.add((
        await loadAnimWH('celestials/$it', _frameSize, _frameSize),
        hitrad.toDouble(),
      ));
    }
  }

  double lastEmission = 0;

  @override
  void update(double dt) {
    super.update(dt);
    lastEmission += dt;
    final minReleaseInterval = 1 / sqrt(maxAsteroids);
    if (_releaseTime <= 0 || (children.length < maxAsteroids && lastEmission >= minReleaseInterval)) {
      add(Asteroid(_animations));
      lastEmission = 0;
      _releaseTime = 1 + random.nextDoubleLimit(2);
    } else {
      _releaseTime -= dt;
    }
  }
}

class Asteroid extends PositionComponent with CollisionCallbacks {
  //
  final List<(SpriteAnimation, double)> animations;

  late SpriteAnimationComponent sprite;
  late CircleHitbox hitbox;

  late int frames;
  late bool xFlipped;
  late double dx;
  late double dy;
  late double rotationSeconds;

  Asteroid(this.animations) {
    anchor = Anchor.center;
    size.setAll(_frameSize.toDouble());

    add(DebugCircleHitbox(radius: 6, anchor: Anchor.center));
    sprite = added(SpriteAnimationComponent(anchor: Anchor.center));
    hitbox = added(CircleHitbox(radius: 6, anchor: Anchor.center, isSolid: true));

    reset();

    sprite.animationTicker?.onFrame = (_) => sprite.angle = 0;
  }

  _pickAnimation() {
    _nextAnim += random.nextInt(3) + 1;
    if (_nextAnim >= animations.length) _nextAnim -= animations.length;

    final (anim, hitrad) = animations[_nextAnim];
    sprite.animation = anim;
    frames = anim.frames.length;
    hitbox.radius = hitrad;
  }

  _pickFlipped() {
    xFlipped = random.nextBool();
    if (xFlipped != sprite.isFlippedHorizontally) sprite.flipHorizontallyAroundCenter();
  }

  _pickScale() => scale.setAll(0.25 + random.nextDoubleLimit(0.75));

  _pickTint() => sprite.tint(Color(0x20000000 + random.nextInt(0xffffff)));

  _pickPosition() {
    final it = random.nextDouble();
    final curved = it < 0.5 //
        ? _positionDistribution.transform(it * 2) / 2
        : 1 - _positionDistribution.transform((1 - it) * 2) / 2;

    position.x = (curved * gameWidth) ~/ _frameSize * _frameSize.toDouble();
    position.y = -random.nextDoubleLimit(gameHeight / 2) - _frameSize * scale.y;
  }

  _pickSpeed() {
    dx = random.nextDouble() - random.nextDouble();
    dx *= _speedVariance;
    dy = _baseSpeed + random.nextDoubleLimit(_speedVariance);
  }

  _pickRotation() {
    rotationSeconds = _rotateBaseSeconds + random.nextDoubleLimit(_rotateVariance);
    final anim = sprite.animation;
    if (anim == null) return;
    anim.stepTime = rotationSeconds / frames;
  }

  reset() {
    _pickAnimation();
    _pickFlipped();
    _pickScale();
    _pickTint();
    _pickPosition();
    _pickSpeed();
    _pickRotation();
  }

  @override
  void update(double dt) {
    alreadyCollided.clear();
    super.update(dt);

    final direction = sprite.isFlippedHorizontally ? 1 : -1;
    final it = sprite.animationTicker!.clock;
    sprite.angle = it / (rotationSeconds / frames) * (2 * pi / frames) * direction;

    position.x += dt * dx;
    position.y += dt * dy;

    bool remove = false;
    if (position.y > gameHeight + _frameSize * scale.y) remove = true;
    if (position.x < -_frameSize * scale.x) remove = true;
    if (position.x > gameWidth + _frameSize * scale.x) remove = true;

    if (remove) removeFromParent();
  }

  static final alreadyCollided = <Asteroid>[];

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Asteroid) {
      if (alreadyCollided.contains(this)) return;
      if (alreadyCollided.contains(other)) return;
      alreadyCollided.add(this);
      alreadyCollided.add(other);
      final m1 = scale.x;
      final m2 = other.scale.x;
      final u1 = Vector2(dx, dy);
      final u2 = Vector2(other.dx, other.dy);
      final v1 = (u1 * (m1 - m2) + u2 * m2 * 2) / (m1 + m2);
      final v2 = (u2 * (m2 - m1) + u1 * m1 * 2) / (m1 + m2);
      dx = v1.x;
      dy = v1.y;
      other.dx = v2.x;
      other.dy = v2.y;
      onHit(other.scale.x);
    }
  }

  void onHit(double relativeVolume) => soundboard.play(Sound.asteroid_clash, volume: scale.x * relativeVolume);
}
