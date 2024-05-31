import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'util/bitmap_button.dart';
import 'util/fonts.dart';

class WebPlayScreen extends Component with KeyboardHandler, TapCallbacks {
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) showScreen(Screen.splash);
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(Screen.splash);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  onLoad() async {
    final button = await images.load('button_plain.png');
    const scale = 0.5;
    add(BitmapButton(
      bgNinePatch: button,
      text: 'Start',
      font: menuFont,
      fontScale: scale,
      position: Vector2(gameWidth / 2, gameHeight / 2),
      anchor: Anchor.center,
      onTap: (_) => showScreen(Screen.splash),
    ));
  }
}
