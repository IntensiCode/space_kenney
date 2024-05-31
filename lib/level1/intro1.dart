import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

import '../core/common.dart';
import '../core/events.dart';
import '../story/script_component.dart';
import '../story/story_dialog_component.dart';

class Intro1 extends Component with KeyboardHandler, TapCallbacks {
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event case KeyDownEvent it) {
      if (it.logicalKey.keyLabel == ' ') showScreen(Screen.game);
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(Screen.game);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  final kenney = 'dialog_kenney.png';
  final central = 'dialog_central.png';

  @override
  onLoad() async {
    final List<ScriptLine> lines = [
      (0, ('fadeIn', ['chapter1.png', 160, 128, Anchor.center])),
      (1, ('playAudio', ['chapter_1_1_kenney.mp3'])),
      (0, ('subtitles', [_kennyText1, ('clear', 3.5), ('image', kenney)])),
      (4.5, ('dialog', [central, _centralText])),
      (0, ('playAudio', ['chapter_1_2_central.mp3'])),
      (8.5, ('dialog', [kenney, _kennyText2])),
      (0, ('playAudio', ['chapter_1_3_kenney.ogg'])),
      (5, ('clear', [StoryDialogComponent])),
      (1, ('playAudio', ['chapter_1_4_kenney.mp3'])),
      (0, ('subtitles', [_kennyText3, ('clear', 11), ('image', kenney)])),
      (12, ('pressFireToStart', [])),
    ];
    final script = ScriptComponent();
    script.addScript(lines);
    script.enact();
    add(script);
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
