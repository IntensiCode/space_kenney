import 'package:audioplayers/audioplayers.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';

import 'common.dart';

enum Sound {
  asteroid_clash,
  explosion,
  game_over,
}

final soundboard = Soundboard();

double get musicVolume => soundboard.musicVolume * soundboard.masterVolume;

double get soundVolume => soundboard.soundVolume * soundboard.masterVolume;

class Soundboard {
  double masterVolume = 0.3;
  double musicVolume = 0.5;
  double soundVolume = 0.8;

  bool muted = false;

  toggleMute() {
    muted = !muted;
    if (muted && bgm?.state == PlayerState.playing) bgm?.pause();
    if (!muted && bgm?.state == PlayerState.paused) bgm?.resume();
  }

  preload() async {
    for (final it in Sound.values) {
      logInfo('cache $it');
      await FlameAudio.audioCache.load('${it.name}.ogg');
    }
  }

  int _activeSounds = 0;

  play(Sound sound, {double? volume}) {
    if (muted) return;

    volume ??= soundboard.soundVolume;

    if (_activeSounds >= _maxActive) {
      logWarn('sound overload');
      return;
    }

    _playPooled(sound, volume);
  }

  _playPooled(Sound sound, double volume) async {
    final reuse = _pooledPlayers.indexWhere((it) {
      if (it.$1 != sound) return false;
      if (it.$2.state == PlayerState.playing) return false;
      return true;
    });

    if (reuse == -1) {
      while (_pooledPlayers.length >= _maxPooled) {
        logInfo('disposing pooled player');
        final (_, player) = _pooledPlayers.removeAt(0);
        player.dispose();
      }

      final it = await FlameAudio.play('${sound.name}.ogg', volume: volume * masterVolume);
      it.setPlayerMode(PlayerMode.lowLatency);
      it.setReleaseMode(ReleaseMode.stop);
      it.onPlayerStateChanged.listen((it) {
        if (it == PlayerState.playing) {
          _activeSounds++;
        } else {
          _activeSounds--;
        }
      });

      _activeSounds++;
      _pooledPlayers.add((sound, it));
      logInfo('pooled: ${_pooledPlayers.length}');
    } else {
      final it = _pooledPlayers.removeAt(reuse);
      _pooledPlayers.add(it);
      final player = it.$2;
      player.setVolume(volume * masterVolume);
      player.resume();
    }
  }

  final _pooledPlayers = <(Sound, AudioPlayer)>[];

  static const _maxActive = 10;
  static const _maxPooled = 50;

  AudioPlayer? bgm;

  Future<AudioPlayer> playBackgroundMusic(String filename) async {
    bgm?.stop();

    final volume = musicVolume * masterVolume;
    if (dev) {
      bgm = await FlameAudio.playLongAudio(filename, volume: volume);

      // only in dev: stop music after 10 seconds, to avoid playing multiple times on hot restart.
      // final afterTenSeconds = player.onPositionChanged.where((it) => it.inSeconds >= 10).take(1);
      // autoDispose('afterTenSeconds', afterTenSeconds.listen((it) => player.stop()));
    } else {
      await FlameAudio.bgm.play(filename, volume: volume);
      bgm = FlameAudio.bgm.audioPlayer;
    }

    if (muted) bgm!.pause();

    return bgm!;
  }
}

// TODO Replace AudioPlayer result type with AudioHandle to change stop into fade out etc

// TODO Really... it all has to be handled in here somehow...
