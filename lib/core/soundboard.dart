import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';

enum Sound {
  asteroid_clash,
  explosion,
  game_over,
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

  int _activeSounds = 0;

  play(Sound sound, {double? volume}) async {
    if (_activeSounds >= 10) {
      logWarn('sound overload');
      return;
    }
    _activeSounds++;
    volume ??= soundVolume;
    final player = await FlameAudio.play('${sound.name}.ogg', volume: volume * masterVolume);
    await player.onPlayerComplete.first;
    _activeSounds--;
  }
}
