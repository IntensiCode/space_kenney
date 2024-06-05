import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:space_kenney/story/direct_script_component.dart';

import '../core/common.dart';
import '../core/events.dart';
import '../story/story_dialog_component.dart';

class Chapter1_Intro extends DirectScriptComponent with KeyboardHandler, TapCallbacks {
  static const next = Screen.chapter1_level1;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event case KeyUpEvent it) {
      if (it.logicalKey.keyLabel == ' ') showScreen(next);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(next);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  onLoad() async {
    fadeIn(await spriteXY('chapter1.png', 160, 128));

    at(1, () => playDialogAudio('chapter_1_1_kenney.mp3'));
    at(0, () => subtitles(_kennyText1, 3.5, image: kenney));
    at(4.5, () => dialog(central, _centralText, audio: 'chapter_1_2_central.mp3'));
    at(8.5, () => dialog(kenney, _kennyText2, audio: 'chapter_1_3_kenney.ogg'));
    at(5, () => clearByType([StoryDialogComponent]));
    at(1, () => subtitles(_kennyText3, 11, image: kenney, audio: 'chapter_1_4_kenney.mp3'));
    at(12, () => pressFireToStart());
  }

  final _kennyText1 = 'I was minding my own business, when a message from '
      'Central arrived...';

  final _centralText = 'Hi Kenney, this is Sheila from Central. We received '
      'a distress call from Argon 4. I have you on stand-by for this sector. '
      'Can you take this one?';

  final _kennyText2 = 'Sure thing. Already on my way. '
      'I should arrive within the hour.';

  final _kennyText3 = 'Best way to Argon 4 is straight through the Lakarian '
      'Belt. I can hyper-jump on the other side straight into Argon 4 reach. '
      'Well, let\'s get through the belt first...';
}
