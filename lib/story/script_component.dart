import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:kart/kart.dart';

import '../components/press_fire_to_start.dart';
import '../core/soundboard.dart';
import '../util/extensions.dart';
import '../util/loading.dart';
import 'story_dialog_component.dart';
import 'subtitles_component.dart';

typedef ScriptLine = (double, (String, List));

class ScriptComponent extends Component {
  final script = <(double, void Function())>[];

  void addScript(Iterable<ScriptLine> script) {
    final it = script.map((it) => (it.$1, _toFunction(it.$2)));
    this.script.addAll(it);
  }

  void Function() _toFunction((String, List) it) {
    final func = it.$1;
    final List args = it.$2;
    return switch (func) {
      'clear' => () => _clear(args),
      'dialog' => () => _dialog(args[0], args[1]),
      'fadeIn' => () => _fadeIn(args),
      'fadeOut' => () => _fadeOut(args),
      'playAudio' => () => _playAudio(args.single),
      'pressFireToStart' => () => _pressFireToStart(),
      'subtitles' => () => _subtitles(args),
      _ => throw ArgumentError('Unknown dialog command: $func'),
    };
  }

  void _clear(List types) {
    dialogPosition = 8;
    final what = types.isEmpty
        ? children
        : children.where((it) => types.contains(it.runtimeType));
    removeAll(what);
  }

  double dialogPosition = 8;

  final dialogOffsets = <String, double>{};

  void _dialog(
    String portrait,
    String text, {
    Anchor anchor = Anchor.topLeft,
  }) async {
    final offset = dialogOffsets.putIfAbsent(
      portrait,
      () => (dialogOffsets.length + 1) * 8,
    );
    final it = StoryDialogComponent(portrait, text);
    it.position.x = offset;
    it.position.y = dialogPosition;
    it.anchor = anchor;
    add(it);

    dialogPosition += 64;
  }

  final _fadeHandles = <String, SpriteComponent>{};

  void _fadeIn(List args) async {
    final String filename = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    final pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    final it = await loadSprite(filename, position: pos, anchor: anchor);
    it.fadeIn();
    add(it);
    _fadeHandles[filename] = it;
  }

  void _fadeOut(List args) {
    for (final it in args) {
      _fadeHandles[it]?.fadeOut();
      _fadeHandles[it]?.add(RemoveEffect(delay: 1));
    }
  }

  final stopAudio = <void Function()>[];

  void _playAudio(String filename) async {
    final player = await FlameAudio.play(
      filename,
      volume: soundboard.masterVolume,
    );
    stop() => player.stop();
    player.onPlayerComplete.listen((_) => stopAudio.remove(stop));
    stopAudio.add(stop);
  }

  void _pressFireToStart() => add(PressFireToStart());

  void _subtitles(List args) {
    final text = args[0];
    final autoClearSeconds = _pickSeconds(args, 'clear');
    final image = _pickValue<String>(args, 'image');
    add(SubtitlesComponent(text, autoClearSeconds, image));
  }

  double? _pickSeconds(List args, String key) => args
      .mapNotNull((it) => switch (it) {
            (String k, num s) when k == key => s.toDouble(),
            _ => null
          })
      .singleOrNull;

  T? _pickValue<T extends Object>(List args, String key) =>
      args.mapNotNull<T>((it) {
        return switch (it) { (String k, T v) when k == key => v, _ => null };
      }).singleOrNull;

  StreamSubscription? active;

  void enact() {
    final it = Stream.fromIterable(script).asyncMap((it) async {
      final double delaySeconds = it.$1;
      logInfo('script delay: $delaySeconds');
      if (delaySeconds > 0) {
        final millis = (delaySeconds * 1000).toInt();
        await Future.delayed(Duration(milliseconds: millis));
      }
      return it.$2;
    });
    active = it.listen((it) => it());
  }

  @override
  void onRemove() {
    stopAudio.forEach((it) => it());
    active?.cancel();
    active = null;
  }
}
