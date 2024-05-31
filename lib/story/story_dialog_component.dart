import 'package:flame/components.dart';

import '../core/common.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/fonts.dart';
import '../util/nine_patch_image.dart';

class StoryDialogComponent extends PositionComponent {
  String portrait;
  String text;

  StoryDialogComponent(this.portrait, this.text) {
    size = Vector2(256, 72);
  }

  @override
  void onLoad() async {
    final bg = await images.load('button_plain.png');
    add(NinePathComponent(image: bg, size: size));

    final image = await images.load(portrait);
    final it = SpriteComponent(sprite: Sprite(image));
    it.position = Vector2(4, 4);
    add(it);

    final lines = textFont.reflow(text, 256 - 80, scale: 0.5);
    double pos = 0;
    for (final line in lines) {
      add(BitmapText(
        text: line,
        position: Vector2(70, pos += 8),
        font: textFont,
        scale: 0.5,
      ));
    }
  }
}
