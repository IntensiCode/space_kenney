import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/animation.dart';
import 'package:space_kenney/core/common.dart';
import 'package:space_kenney/core/soundboard.dart';
import 'package:space_kenney/particles/smoke.dart';
import 'package:space_kenney/util/auto_dispose.dart';
import 'package:space_kenney/util/debug.dart';
import 'package:space_kenney/util/random.dart';

import '../story/script_functions.dart';
import '../util/extensions.dart';
import 'vshmup_common.dart';

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
  VShmupAsteroids asteroids() => added(VShmupAsteroids());
}

class VShmupAsteroids extends AutoDisposeComponent with ScriptFunctions {
  final _animations = <(SpriteAnimation, double)>[];

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
    if (children.length < maxAsteroids && lastEmission >= minReleaseInterval) {
      add(VShmupAsteroid(_animations, spawnOff));
      lastEmission = 0;
    }
  }

  void spawnOff(VShmupAsteroid it) => add(VShmupAsteroid.cloned(it));
}

class VShmupAsteroid extends PositionComponent with CollisionCallbacks, VShmupTarget {
  //
  final List<(SpriteAnimation, double)> animations;
  final void Function(VShmupAsteroid) spawnOff;

  late SpriteAnimationComponent sprite;
  late CircleHitbox hitbox;

  late int frames;
  late bool xFlipped;
  late double initialScale;
  late double dx;
  late double dy;
  late double rotationSeconds;
  late double damage;

  static double damagePerScaleUnit = 100;

  // todo pool? probably.. test first..
  bool dieOff = false;

  double get maxDamage => damagePerScaleUnit * initialScale;

  int get forceIndex => scale.x ~/ 0.25;

  @override
  Component get visual => sprite;

  @override
  bool applyDamage({double? laser, double? kinetic}) {
    if (laser != null) damage += laser;
    if (kinetic != null) damage += kinetic;

    final before = forceIndex;
    if (before < 2) damage *= 1.1;
    if (before < 1) damage *= 1.1;

    final maxDamage = damagePerScaleUnit * initialScale;
    if (damage > maxDamage) damage = maxDamage;

    final remaining = 1 - damage / (damagePerScaleUnit * initialScale);
    if (remaining < 0.1) {
      smokeAround(position, size * remaining, parent: parent!);
      reset();
      return true;
    }

    scale.setAll(remaining * initialScale);

    final after = forceIndex;
    if (before == after) return false;

    if (after > 1) {
      onHit(scale.x);

      damage = 0;
      initialScale /= 2;
      scale.setAll(initialScale);

      final diff = randomNormalizedVector();
      dx = -dx * 2 + diff.x * 20;
      dy = -diff.y * 0.75;
      if (dx.abs() < 10) {
        const forced = 8.0;
        dx = random.nextBool() //
            ? forced + random.nextDoubleLimit(forced) //
            : -forced - random.nextDoubleLimit(forced);
      }

      spawnOff(this);
    }
    return false;
  }

  factory VShmupAsteroid.cloned(VShmupAsteroid it) {
    final result = VShmupAsteroid(it.animations, it.spawnOff);
    result.initialScale = it.initialScale;
    result.scale.setFrom(it.scale * (0.5 + random.nextDoubleLimit(0.5)));
    result.position.setFrom(it.position);
    result.dx = -it.dx + random.nextDoublePM(2);
    result.dy = it.dy + random.nextDoublePM(2);
    result.dieOff = true;
    return result;
  }

  VShmupAsteroid(this.animations, this.spawnOff) {
    anchor = Anchor.topLeft;
    size.setAll(_frameSize.toDouble());

    sprite = added(SpriteAnimationComponent(anchor: Anchor.center));
    hitbox = added(CircleHitbox(radius: 6, anchor: Anchor.center, isSolid: true));
    add(DebugCircleHitbox(radius: 6, anchor: Anchor.center));

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

  _pickScale() {
    initialScale = 0.5 + random.nextDoubleLimit(0.5);
    scale.setAll(initialScale);
  }

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
    damage = 0;
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

    // special case of parts drifting upwards:
    if (position.y < -_frameSize * 4) remove = true;

    if (remove && dieOff) {
      removeFromParent();
    } else if (remove) {
      reset();
    }
  }

  static final alreadyCollided = <VShmupAsteroid>[];

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is VShmupAsteroid) {
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
      if (forceIndex > 1 && other.forceIndex > 1) {
        if (forceIndex < other.forceIndex) {
          applyDamage(kinetic: (maxDamage - damage) / 2);
        } else if (forceIndex > other.forceIndex) {
          other.applyDamage(kinetic: (other.maxDamage - other.damage) / 2);
        } else {
          applyDamage(kinetic: (maxDamage - damage) / 4);
          other.applyDamage(kinetic: (other.maxDamage - other.damage) / 4);
        }
      }
    }
  }

  void onHit(double relativeVolume) => soundboard.play(Sound.asteroid_clash, volume: scale.x * relativeVolume);
}
