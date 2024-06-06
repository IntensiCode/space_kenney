import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:list_operators/list_operators.dart';

import '../core/common.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';

class HintComponent extends PositionComponent with HasPaint {
  static const _fontScale = 0.2;

  String text;
  double? autoClearSeconds;

  HintComponent(this.text, this.autoClearSeconds);

  BitmapFont font = menuFont;

  @override
  void onLoad() async {
    if (autoClearSeconds != null) {
      add(TimerComponent(period: autoClearSeconds!, onTick: _fadeOut));
      add(RemoveEffect(delay: autoClearSeconds! + 1));
    }

    position.x = 0;
    position.y = gameHeight - 8;
    anchor = Anchor.bottomLeft;

    final lineHeight = font.lineHeight(_fontScale);
    final lines = font.reflow(text, 100, scale: _fontScale);
    final w = lines.map((it) => font.lineWidth(it)).max();
    final h = lines.length * lineHeight;
    size.x = w + 16;
    size.y = h + 16 - (lineHeight - font.lineHeight(_fontScale) + 3);

    final pos = Vector2.zero();
    for (final line in lines) {
      pos.x = (size.x - font.lineWidth(line)) / 2;
      pos.y += lineHeight;
      final text = BitmapText(
        text: line,
        position: pos,
        font: font,
        scale: _fontScale,
      );
      text.fadeIn();
      _lines.add(text);
      add(text);
    }

    position.x = gameWidth - size.x - 8;

    _bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0.0, size.x, size.y),
      const Radius.circular(8),
    );

    paint.color = const Color(0xA02a2a4a);
  }

  void _fadeOut() {
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
