import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:space_kenney/v_shmup/vshmup_asteroids.dart';
import 'package:space_kenney/v_shmup/vshmup_moons.dart';

import '../core/common.dart';
import '../story/direct_script_component.dart';
import '../v_shmup/vshmup_player.dart';
import '../v_shmup/vshmup_stars.dart';

class Chapter1_Level1 extends DirectScriptComponent with HasCollisionDetection, KeyboardHandler, TapCallbacks {
  @override
  onLoad() async {
    backgroundMusic('background/galactic_dreamers_alt.mp3');
    stars();
    moons();
    at(1, () => subtitles(_kay1, 10, image: kay, audio: 'dialog/c1_l1_kay_1.ogg'));
    at(10.5, () => subtitles(_kenney1, 3, image: kenney, audio: 'dialog/c1_l1_kenney_1.mp3'));
    at(10, () => add(VShmupPlayer()));
    at(2, () => asteroids());
  }

  final _kay1 = 'The asteroid belt ahead is full of minerals and space junk. '
      'I\'ll be on stand-by. If you can manage, let\'s collect what we find '
      'to replenish our supplies.';

  final _kenney1 = 'Understood. Switching to mining laser for now.';
}
