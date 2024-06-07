import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:space_kenney/vshmup/vshmup_asteroids.dart';
import 'package:space_kenney/vshmup/vshmup_game_keys.dart';
import 'package:space_kenney/vshmup/vshmup_moons.dart';

import '../core/common.dart';
import '../story/direct_script_component.dart';
import '../vshmup/vshmup_player.dart';
import '../vshmup/vshmup_stars.dart';

class Chapter1_Level1 extends DirectScriptComponent with HasCollisionDetection, KeyboardHandler, TapCallbacks {
  @override
  onLoad() async {
    collisions = collisionDetection;

    backgroundMusic('galactic_dreamers.mp3');
    stars();
    moons();
    at(1, () => subtitles(_kay1, 10, image: kay, audio: 'c1_l1_kay_1.ogg'));
    at(10.5, () => subtitles(_kenney1, 3, image: kenney, audio: 'c1_l1_kenney_1.mp3'));
    at(3, () => hint(_miningLaser, 10));
    at(3, () => add(VShmupPlayer()));
    at(2, () => asteroids());
  }

  final _kay1 = 'The asteroid belt ahead is full of minerals and space junk. '
      'I\'ll be on stand-by. If you can manage, let\'s collect what we find '
      'to replenish our supplies.';

  final _kenney1 = 'Understood. Switching to mining laser for now.';

  final _miningLaser = 'The mining laser auto targets within its field of view. '
      'It is attached at the center below your ship. Watch the heat. '
      'Keys: ${VShmupGameKeys.primaryFireKeys}';
}
