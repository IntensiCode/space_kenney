import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:space_kenney/core/messaging.dart';

import '../core/common.dart';
import '../story/script_functions.dart';
import '../util/extensions.dart';
import '../util/random.dart';

extension ScriptFunctionsExtension on ScriptFunctions {
  VShmupGems gems() => added(VShmupGems());
}

extension ComponentExtensions on Component {
  void spawnGem(VShmupSpawnGem data) => messaging.send('spawn-gem', data);
}

enum VShmupGemKind {
  green(0),
  red(1),
  violet(2),
  ;

  final int row;

  const VShmupGemKind(this.row);
}

class VShmupSpawnGem {
  final double x;
  final double y;
  final double? speed;
  final Set<VShmupGemKind>? kind;

  VShmupSpawnGem(this.x, this.y, [this.speed, this.kind]);
}

class VShmupGems extends ScriptComponent {
  final gems = <VShmupGemKind, SpriteAnimation>{};

  late SpriteAnimation expire;

  @override
  void onLoad() async {
    final sprites = sheet(await image('particles/gems.png'), 12, 4);
    gems[VShmupGemKind.green] = sprites.createAnimation(row: 0, stepTime: 0.1);
    gems[VShmupGemKind.red] = sprites.createAnimation(row: 1, stepTime: 0.1);
    gems[VShmupGemKind.violet] = sprites.createAnimation(row: 2, stepTime: 0.1);
    expire = sprites.createAnimation(row: 3, stepTime: 0.1);
  }

  void spawn(double x, double y, VShmupGemKind kind, [double speed = 50]) {
    final it = added(VShmupGem(kind, speed, gems[kind]!, expire));
    it.position.setValues(x, y);
  }

  @override
  void onMount() {
    super.onMount();
    listen('spawn-gem', (message) {
      final data = message.$2 as VShmupSpawnGem;
      final which = data.kind?.toList() ?? VShmupGemKind.values;
      spawn(data.x, data.y, which.random(random), data.speed ?? 50);
    });
  }
}

class VShmupGem extends PositionComponent {
  final VShmupGemKind kind;
  final double _speed;
  final SpriteAnimation _expire;
  late final SpriteAnimationComponent _gem;

  VShmupGem(this.kind, this._speed, SpriteAnimation gem, this._expire) {
    size.setAll(8);
    add(_gem = SpriteAnimationComponent(
      animation: gem,
      size: size,
      anchor: Anchor.center,
    ));
  }

  double _expireTime = 5;
  double _switchTime = 0.2;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _speed * dt;
    if (position.y > gameHeight + size.y) removeFromParent();
    if (_expireTime > 0) {
      _expireTime -= dt;
      if (_expireTime <= 0) {
        add(SpriteAnimationComponent(
          animation: _expire,
          size: size,
          anchor: Anchor.center,
          removeOnFinish: true,
        ));
      }
    } else if (_switchTime > 0) {
      _switchTime -= dt;
      if (_switchTime <= 0) _gem.removeFromParent();
    } else {
      logInfo('gone');
      removeFromParent();
    }
  }
}
