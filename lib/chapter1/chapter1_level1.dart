import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:space_kenney/v_shmup/moons_background.dart';

import '../core/common.dart';
import '../story/direct_script_component.dart';
import '../v_shmup/vertical_stars_background.dart';

class Chapter1_Level1 extends DirectScriptComponent with KeyboardHandler, TapCallbacks {
  @override
  onLoad() async {
    stars();
    moons();
    at(1, () => playAudio('dialog/c1_l1_kay_1.ogg'));
    at(0, () => subtitles(_kay1, 10, image: kay));
    at(11, () => playAudio('dialog/c1_l1_kenney_1.mp3'));
    at(0, () => subtitles(_kenney1, 2, image: kenney));
  }

  final _kay1 = 'The asteroid belt ahead is full of minerals and space junk. '
      'I\'ll be on stand-by. If you can manage, let\'s collect what we find '
      'to replenish our supplies.';

  final _kenney1 = 'Thanks Kay. Let\'s see what we can find. ';
}
