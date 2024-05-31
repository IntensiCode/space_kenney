import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:space_kenney/story/script_component.dart';
import 'package:space_kenney/util/bitmap_button.dart';
import 'package:space_kenney/util/fonts.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'core/soundboard.dart';

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
    final List<ScriptLine> lines = [
      (0, ('fadeIn', ['title_background.png'])),
      (0.1, ('fadeIn', ['title.png', 160, 5, Anchor.topCenter])),
      (0.1, ('fadeIn', ['kenny.png', 320, 256, Anchor.bottomRight])),
      (0.1, ('fadeIn', ['flame.png', 4, 245, Anchor.bottomLeft])),
      (1, ('pressFireToStart', [])),
    ];

    final script = ScriptComponent();
    script.addScript(lines);
    script.enact();
    add(script);

    final button = await images.load('button_plain.png');
    const scale = 0.25;
    const step = 20;
    double y = 140;
    add(BitmapButton(
      bgNinePatch: button,
      text: '[N]ew Game',
      font: menuFont,
      fontScale: scale,
      position: Vector2(16, y += step),
      anchor: Anchor.topLeft,
      onTap: (_) => {},
    ));
    add(BitmapButton(
      bgNinePatch: button,
      text: 'Continue',
      font: menuFont,
      fontScale: scale,
      position: Vector2(16, y += step),
      anchor: Anchor.topLeft,
      onTap: (_) => {},
    ));
    add(BitmapButton(
      bgNinePatch: button,
      text: '[S]ettings',
      font: menuFont,
      fontScale: scale,
      position: Vector2(16, y += step),
      anchor: Anchor.topLeft,
      onTap: (_) => {},
    ));

    if (dev) {
      final player = await FlameAudio.playLongAudio(
        'music_title.mp3',
        volume: soundboard.masterVolume,
      );
      _stopMusic = () => player.stop();
    } else {
      final player = await FlameAudio.loop(
        'music_title.mp3',
        volume: soundboard.masterVolume,
      );
      _stopMusic = () => player.stop();
    }
  }

  void Function() _stopMusic = () {};

  @override
  void onRemove() {
    super.onRemove();
    _stopMusic();
  }
}
