import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'story/loco_script_component.dart';

class TitleScreen extends Component with KeyboardHandler, TapCallbacks {
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event case KeyDownEvent it) {
      if (it.logicalKey.keyLabel == ' ') showScreen(Screen.intro);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(Screen.intro);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  onLoad() async {
    add(LocoScriptComponent('''
      (0.0 (music 'music_title.mp3'))
      (0.0 (fadeIn (image 'title_background.png')))
      (0.1 (fadeIn (image 'title.png' 160 5 Anchor.topCenter)))
      (0.1 (fadeIn (image 'kenny.png' 320 256 Anchor.bottomRight)))
      (0.1 (fadeIn (image 'flame.png' 4 245 Anchor.bottomLeft)))
      (0.1 (fadeIn (menuButton '@Settings' 16 200 Anchor.topLeft)))
      (0.1 (fadeIn (menuButton '@Continue' 16 180 Anchor.topLeft)))
      (0.1 (fadeIn (menuButton '@New_Game' 16 160 Anchor.topLeft)))
      (0.1 (pressFireToStart))
    '''));
  }
}
