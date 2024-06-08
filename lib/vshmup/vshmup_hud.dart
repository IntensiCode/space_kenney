import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:space_kenney/core/soundboard.dart';
import 'package:space_kenney/util/auto_dispose.dart';
import 'package:space_kenney/util/bitmap_text.dart';
import 'package:space_kenney/util/fonts.dart';

import '../story/script_functions.dart';
import 'vshmup_player.dart';

class VShmupHud extends PositionComponent with AutoDispose, ScriptFunctions {
  VShmupHud(this.player);

  static const _textScale = 0.25;

  final VShmupPlayer player;

  late SpriteSheet energy;

  final addPos = Vector2(5, 5);

  @override
  void onLoad() async {
    scale.setAll(0.5);
    priority = 100;
    energy = sheet(await image('vshmup/hud_meter.png'), 1, 9);
    sprite(filename: 'vshmup/hud_background.png');
    _next(VShmupHudMeter(energy, () => player.shield));
    _next(BitmapText(text: 'Shield', font: menuFont, scale: _textScale));
    _next(VShmupHudMeter(energy, () => player.energy));
    _next(BitmapText(text: 'Energy', font: menuFont, scale: _textScale));
    _next(VShmupHudMeter(energy, () => player.resources));
    _next(BitmapText(text: 'Resources', font: menuFont, scale: _textScale));
  }

  void _next(PositionComponent it) {
    it.priority = 101;
    add(it..position = addPos);
    addPos.y += 10;
  }
}

class VShmupHudMeter extends SpriteComponent with HasVisibility {
  VShmupHudMeter(this.sheet, this.value);

  final SpriteSheet sheet;
  final double Function() value;

  @override
  void onLoad() => _update();

  void _update() {
    final row = ((100 - value()) / 100 * sheet.rows).clamp(0, sheet.rows - 1).toInt();
    sprite = sheet.getSprite(row, 0);
  }

  double blinkTime = 0;
  double warnTime = 0;

  @override
  void update(double dt) {
    blinkTime += dt;
    if (blinkTime > 1) blinkTime -= 1;
    isVisible = value() > 22 || blinkTime > 0.25 ? true : false;
    if (!isVisible) {
      warnTime += dt;
      if (warnTime > 1) {
        warnTime -= 1;
        soundboard.play(Sound.warning);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _update();
    super.render(canvas);
  }
}
