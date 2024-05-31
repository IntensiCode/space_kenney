import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:list_operators/list_operators.dart';
import 'package:space_kenney/util/loading.dart';

import '../core/common.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';

class SubtitlesComponent extends PositionComponent with HasPaint {
  static const _fontScale = 0.5;

  String text;
  double? autoClearSeconds;
  String? portrait;

  SubtitlesComponent(this.text, this.autoClearSeconds, this.portrait);

  SpriteComponent? _portrait;

  @override
  void onLoad() async {
    if (autoClearSeconds != null) {
      add(TimerComponent(period: autoClearSeconds!, onTick: _fadeOut));
      add(RemoveEffect(delay: autoClearSeconds! + 1));
    }

    position.x = gameWidth / 2;
    position.y = gameHeight;
    anchor = Anchor.bottomCenter;

    final lineHeight = textFont.lineHeight(_fontScale) * 4 / 3;
    final lines = textFont.reflow(text, 256 - 80, scale: _fontScale);
    final w = lines.map((it) => textFont.lineWidth(it)).max();
    final h = lines.length * lineHeight;
    size.x = w + 16;
    size.y = h + 16 - (lineHeight - textFont.lineHeight(_fontScale) + 1);

    final pos = Vector2.zero();
    for (final line in lines) {
      pos.x = (size.x - textFont.lineWidth(line)) / 2;
      pos.y += lineHeight;
      final text = BitmapText(
        text: line,
        position: pos,
        font: textFont,
        scale: _fontScale,
      );
      text.fadeIn();
      _lines.add(text);
      add(text);
    }

    if (portrait != null) {
      _portrait = await loadSprite(portrait!);
      _portrait?.anchor = Anchor.bottomRight;
      _portrait?.position.x = -2;
      _portrait?.position.y = size.y;
      add(_portrait!);
    }

    _bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(8),
    );

    paint.color = const Color(0x80000000);
  }

  void _fadeOut() {
    _portrait?.fadeOut();
    _lines.forEach((it) => it.fadeOut());
    fadeOut();
  }

  final _lines = <BitmapText>[];

  late final RRect _bgRect;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_bgRect, paint);
  }
}
