import 'package:flame/components.dart';

import '../core/common.dart';
import 'projectile.dart';

Future<Projectile> makeProjectilePrototype(
  ProjectileKind kind,
  IsTarget isTarget,
  double speed,
) async {
  final anim = await switch (kind) {
    ProjectileKind.acidBall => _acidBalls(),
  };
  return Projectile(
    kind: kind,
    animation: anim,
    isTarget: isTarget,
    speed: speed,
  );
}

Future<SpriteAnimation> _acidBalls() async =>
    _loadAnim(filename: 'projectiles/acid_balls.png', frames: 16, perRow: 8);

Future<SpriteAnimation> _loadAnim({
  required String filename,
  required int frames,
  int? perRow,
  double? size,
}) async =>
    await game.loadSpriteAnimation(
        filename,
        SpriteAnimationData.sequenced(
          amount: frames,
          amountPerRow: perRow ?? frames,
          stepTime: 0.05,
          textureSize: Vector2.all(size ?? 16),
        ));
