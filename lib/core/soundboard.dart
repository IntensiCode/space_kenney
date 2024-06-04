import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';

enum Sound {
  asteroid_clash,
  explosion,
  game_over,
  swoosh,
}

final soundboard = Soundboard();

class Soundboard {
  double masterVolume = 0.3;
  double musicVolume = 0.5;
  double soundVolume = 0.8;

  preload() async {
    for (final it in Sound.values) {
      logInfo('cache $it');
      await FlameAudio.audioCache.load('${it.name}.ogg');
    }
  }

  play(Sound sound, {double? volume}) {
    volume ??= soundVolume;
    FlameAudio.play('${sound.name}.ogg', volume: volume * masterVolume);
  }
}
