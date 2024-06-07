import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:space_kenney/core/messaging.dart';

import '../core/common.dart';
import '../story/script_functions.dart';
import '../util/extensions.dart';
import '../util/random.dart';

extension ScriptFunctionsExtension on ScriptFunctions {
  VShmupExtras extras() => added(VShmupExtras());
}

extension ComponentExtensions on Component {
  void spawnExtra(VShmupSpawnExtra data) => messaging.send('spawn-extra', data);
}

enum VShmupExtraKind {
  triple_laser(1, 0),
  energy_wave(1, 1),
  blaster(1, 2),
  shuriken(1, 3),
  yin_yang(1, 4),
  ion_bomb(1, 5),
  cluster_bomb(1, 6),
  nuke(1, 7),
  integrity_plus(2, 0),
  resource_plus(2, 1),
  energy_plus(2, 2),
  x_red(2, 3),
  x_green(2, 4),
  x_blue(2, 5),
  particle1(2, 6),
  particle2(2, 7),
  ;

  final int row;
  final int column;

  const VShmupExtraKind(this.row, this.column);
}

class VShmupSpawnExtra {
  final double x;
  final double y;
  final double? speed;
  final Set<VShmupExtraKind>? kind;

  VShmupSpawnExtra(this.x, this.y, [this.speed, this.kind]);
}

class VShmupExtras extends ScriptComponent {
  static final stepTimes = [1.0, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];

  late SpriteSheet sprites;
  late SpriteAnimation overlay;

  @override
  void onLoad() async {
    sprites = sheet(await image('particles/extras.png'), 8, 4);
    overlay = sprites.createAnimationWithVariableStepTimes(row: 0, stepTimes: stepTimes);
  }

  void spawn(double x, double y, VShmupExtraKind kind, [double speed = 50]) {
    final sprite = sprites.getSprite(kind.row, kind.column);
    final it = added(VShmupExtra(kind, speed, sprite, overlay));
    it.position.setValues(x, y);
  }

  @override
  void onMount() {
    super.onMount();
    listen('spawn-extra', (message) {
      final data = message.$2 as VShmupSpawnExtra;
      final which = data.kind?.toList() ?? VShmupExtraKind.values;
      spawn(data.x, data.y, which.random(random), data.speed ?? 50);
    });
  }
}

class VShmupExtra extends PositionComponent {
  final VShmupExtraKind kind;
  final double speed;

  VShmupExtra(this.kind, this.speed, Sprite sprite, SpriteAnimation overlay) {
    add(SpriteComponent(sprite: sprite, anchor: Anchor.center));
    add(SpriteAnimationComponent(animation: overlay, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameHeight + size.y) removeFromParent();
  }
}
