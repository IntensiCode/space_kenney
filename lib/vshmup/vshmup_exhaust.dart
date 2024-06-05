import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:space_kenney/util/auto_dispose.dart';
import 'package:space_kenney/util/extensions.dart';
import 'package:space_kenney/util/random.dart';

import '../story/script_functions.dart';

class VShmupExhaust extends AutoDisposeComponent with ScriptFunctions {
  static const count = 10; // TODO depend on speed i guess?

  late final List<SpriteAnimation> _animations;
  late final List<_ExhaustParticle> _pool;

  double perceivedSpeed = 1;

  @override
  void onLoad() async {
    final it = sheet(await image('explosions/explosions.png'), 7, 8);
    _animations = List.generate(8, (row) => it.createAnimation(row: row, stepTime: 0.05, loop: false));
    _pool = List.generate(count, (_) => _ExhaustParticle());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_pool.isNotEmpty) {
      add(_pool.removeLast()..reset(_animations));
    }
    for (final it in children) {
      final sac = it as _ExhaustParticle;
      if (sac.animationTicker?.done() != false) _pool.add(sac);
    }
    for (final it in _pool) {
      if (children.contains(it)) it.removeFromParent();
    }
  }
}

class _ExhaustParticle extends SpriteAnimationComponent {
  double dx = 0;
  double dy = 10;

  _ExhaustParticle() {
    anchor = Anchor.center;
    scale.setAll(0.25);
  }

  void reset(List<SpriteAnimation> animations) {
    animation = animations.random(random);
    animationTicker?.reset();
    position.x = random.nextDoubleLimit(5) - random.nextDoubleLimit(5);
    position.y = 18;
    dx = random.nextDoublePM(25);
    dy = 75 + random.nextDoublePM(25);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += dx * dt;
    position.y += dy * dt;
  }
}
