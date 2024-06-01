import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:space_kenney/story/coco_loco_script_component.dart';

import 'core/common.dart';
import 'core/events.dart';

class SplashScreen extends CocoLocoScriptComponent with KeyboardHandler, TapCallbacks {
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
  onLoad() async {
    let('anim', await makeAnim(_loadSplashAnim(), Vector2(160, 128), Anchor.center));
    let('title', Screen.title);
    let('decelerate', Curves.decelerate);

    enact('''
    (font @menuFont 0.5)
    (at 0.5 (fadeIn (text 'An' 160 100)))
    (at 1.0 (fadeIn (text 'IntensiCode' 160 120)))
    (at 1.0 (fadeIn (text 'Presentation' 160 140)))
    (at 2.5 (fadeOutAll))
    (at 1.0 (playAudio swoosh.ogg))
    (at 0.1 (add @anim))
    (at 0.0 (fadeIn (text 'A' 160 70)))
    (at 0.0 (fadeIn (text 'Game' 160 190)))
    (at 2.0 (scaleTo @anim 10 1 @decelerate))
    (at 0.0 (fadeOutAll))
    (at 1.0 (showScreen @title))
    ''');
  }

  Future<SpriteAnimation> _loadSplashAnim() =>
      loadAnim('splash_anim.png', frames: 13, stepTimeSeconds: 0.05, frameWidth: 120, frameHeight: 90, loop: false);

  late final SpriteAnimationComponent psychocellComponent;
}
