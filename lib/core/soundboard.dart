import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';

enum Sound {
  explosion,
  game_over,
  swoosh,
}

final soundboard = Soundboard();

class Soundboard {
  double masterVolume = 0.2;

  preload() async {
    for (final it in Sound.values) {
      logInfo('cache $it');
      await FlameAudio.audioCache.load('${it.name}.ogg');
    }
  }

  play(Sound sound, {double? volume}) {
    volume ??= 0.1;
    FlameAudio.play('${sound.name}.ogg', volume: volume * masterVolume);
  }
}
