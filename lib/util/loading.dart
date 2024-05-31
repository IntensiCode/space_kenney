import 'package:flame/components.dart';

import '../core/common.dart';

Future<SpriteComponent> loadSprite(
  String filename, {
  Vector2? position,
  Vector2? size,
  Anchor? anchor,
}) async {
  final image = await game.loadSprite(filename);
  return SpriteComponent(
    sprite: image,
    position: position,
    size: size,
    anchor: anchor,
  );
}
