import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:space_kenney/util/fonts.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'story/direct_script_component.dart';

class SplashScreen extends DirectScriptComponent with KeyboardHandler, TapCallbacks {
  late final SpriteAnimation psychocell;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyUpEvent) showScreen(Screen.title);
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(Screen.title);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onLoad() async {
    final anim = makeAnimXY(await _loadSplashAnim(), 160, 128);
    fontSelect(menuFont, scale: 0.5);

    at(0.5, () => fadeIn(textXY('An', 160, 100)));
    at(1.0, () => fadeIn(textXY('IntensiCode', 160, 120)));
    at(1.0, () => fadeIn(textXY('Presentation', 160, 140)));
    at(2.5, () => fadeOutAll());
    at(1.0, () => playAudio('swoosh.ogg'));
    at(0.1, () => add(anim));
    at(0.0, () => fadeIn(textXY('A', 160, 70)));
    at(0.0, () => fadeIn(textXY('Game', 160, 190)));
    at(2.0, () => scaleTo(anim, 10, 1, Curves.decelerate));
    at(0.0, () => fadeOutAll());
    at(1.0, () => showScreen(Screen.title));
  }

  Future<SpriteAnimation> _loadSplashAnim() =>
      loadAnim('splash_anim.png', frames: 13, stepTimeSeconds: 0.05, frameWidth: 120, frameHeight: 90, loop: false);

  late final SpriteAnimationComponent psychocellComponent;
}
