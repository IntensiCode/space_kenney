import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:space_kenney/core/common.dart';
import 'package:space_kenney/util/random.dart';

import '../story/script_functions.dart';
import '../util/extensions.dart';

final _fileSpec = [
  'moon_32_16_2876676768.png',
];

extension ScriptFunctionsExtension on ScriptFunctions {
  MoonsBackground moons() => added(MoonsBackground());
}

class MoonsBackground extends Component with ScriptFunctions {
  static const scale = 1.0;
  static const opacity = 0.333;
  static const baseSpeed = 8;
  static const outsideOffset = 32;
  static final black = Paint()..color = const Color(0xFF000000);

  final _animations = <SpriteAnimation>[];

  @override
  void onLoad() async {
    for (final it in _fileSpec) {
      final animation = await loadAnimWH('planets/$it', 32, 32, 0.1);
      _animations.add(animation);
    }
  }

  double _releaseTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_releaseTime <= 0) {
      final bg = added(CircleComponent(radius: 16, anchor: Anchor.center, paint: black));
      bg.priority = 10;

      final anim = _animations.random(random);
      final it = added(SpriteAnimationComponent(animation: anim, anchor: Anchor.center));
      it.priority = 11;
      it.scale.setValues(scale, scale);
      it.opacity = opacity - random.nextDoubleLimit(0.1);
      it.position.x = random.nextDoubleLimit(gameWidth);
      it.position.y = -random.nextDoubleLimit(16) - outsideOffset;
      it.angle = random.nextDoubleLimit(pi);
      it.tint(Color(random.nextInt(0x20000000)));

      bg.position.setFrom(it.position);

      _releaseTime = 30 + random.nextDoubleLimit(30);
    } else {
      _releaseTime -= dt;
    }

    for (final it in children) {
      final anim = (it as PositionComponent);
      anim.position.y += dt * baseSpeed;
      if (anim.position.y > gameHeight + outsideOffset) {
        it.removeFromParent();
      }
    }
  }
}
