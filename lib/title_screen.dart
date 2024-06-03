import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'story/direct_script_component.dart';

class TitleScreen extends DirectScriptComponent with KeyboardHandler, TapCallbacks {
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event case KeyUpEvent it) {
      if (it.logicalKey.keyLabel == ' ') showScreen(Screen.tutorial);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(Screen.tutorial);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  onLoad() async {
    music('music_title.mp3');
    fadeIn(await sprite(filename: 'title_background.png'));
    at(0.1, () async => fadeIn(await spriteXY('title.png', 160, 5, Anchor.topCenter)));
    at(0.1, () async => fadeIn(await spriteXY('kenny.png', 320, 256, Anchor.bottomRight)));
    at(0.1, () async => fadeIn(await spriteXY('flame.png', 4, 245, Anchor.bottomLeft)));
    at(0.1, () async => fadeIn(await menuButtonXY('Settings', 16, 200, Anchor.topLeft)));
    at(0.1, () async => fadeIn(await menuButtonXY('Continue', 16, 180, Anchor.topLeft)));
    at(0.1, () async => fadeIn(await menuButtonXY('New Game', 16, 160, Anchor.topLeft)));
    at(0.1, () => pressFireToStart());
  }

  Vector2 p(double x, double y) => Vector2(x, y);
}
