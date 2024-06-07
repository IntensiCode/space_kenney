import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:space_kenney/core/messaging.dart';

import '../core/common.dart';
import '../story/script_functions.dart';
import '../util/extensions.dart';
import '../util/random.dart';

extension ScriptFunctionsExtension on ScriptFunctions {
  VShmupPills pills() => added(VShmupPills());
}

extension ComponentExtensions on Component {
  void spawnPill(VShmupSpawnPill data) => messaging.send('spawn-pill', data);
}

enum VShmupPillKind {
  blue(0),
  green(1),
  red(2),
  light_green(3),
  yellow(4),
  dark_red(5),
  violet(6),
  ;

  final int row;

  const VShmupPillKind(this.row);
}

class VShmupSpawnPill {
  final double x;
  final double y;
  final double? speed;
  final Set<VShmupPillKind>? kind;

  VShmupSpawnPill(this.x, this.y, [this.speed, this.kind]);
}

class VShmupPills extends ScriptComponent {
  final pills = <VShmupPillKind, SpriteAnimation>{};

  @override
  void onLoad() async {
    final sprites = sheet(await image('particles/pills.png'), 18, 7);
    for (final kind in VShmupPillKind.values) {
      pills[kind] = sprites.createAnimation(row: kind.row, stepTime: 0.1);
    }
  }

  void spawn(double x, double y, VShmupPillKind kind, [double speed = 50]) {
    final it = added(VShmupPill(kind, speed, pills[kind]!));
    it.position.setValues(x, y);
  }

  @override
  void onMount() {
    super.onMount();
    listen('spawn-pill', (message) {
      final data = message.$2 as VShmupSpawnPill;
      final which = data.kind?.toList() ?? VShmupPillKind.values;
      spawn(data.x, data.y, which.random(random), data.speed ?? 50);
    });
  }
}

class VShmupPill extends PositionComponent {
  final VShmupPillKind kind;
  final double _speed;
  late final SpriteAnimationComponent _pill;

  VShmupPill(this.kind, this._speed, SpriteAnimation pill) {
    scale.setAll(0.5);
    add(_pill = SpriteAnimationComponent(animation: pill, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _speed * dt;
    if (position.y > gameHeight + size.y) removeFromParent();
  }
}
