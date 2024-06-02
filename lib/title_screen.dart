import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:space_kenney/story/coco_loco_script_component.dart';

import 'core/common.dart';
import 'core/events.dart';

class TitleScreen extends CocoLocoScriptComponent with KeyboardHandler, TapCallbacks {
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
    enact('''
      (music music_title.mp3)
      (fadeIn (image title_background.png))
      (at 0.1 (fadeIn (image title.png 160 5 @topCenter)))
      (at 0.1 (fadeIn (image kenny.png 320 256 @bottomRight)))
      (at 0.1 (fadeIn (image flame.png 4 245 @bottomLeft)))
      (at 0.1 (fadeIn (menuButton "@Settings" 16 200 @topLeft)))
      (at 0.1 (fadeIn (menuButton "@Continue" 16 180 @topLeft)))
      (at 0.1 (fadeIn (menuButton "@New_Game" 16 160 @topLeft)))
      (at 0.1 (pressFireToStart))
    ''');
  }

  Vector2 p(double x, double y) => Vector2(x, y);
}
