import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:space_kenney/core/common.dart';

import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (dev) {
    FlameAudio.audioCache.clearAll();
    imageCache.clear();
  }
  runApp(GameWidget(game: SpaceKenneyGame()));
}
