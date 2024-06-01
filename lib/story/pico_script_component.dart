import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:kart/kart.dart';
import 'package:space_kenney/util/bitmap_button.dart';

import '../components/press_fire_to_start.dart';
import '../core/common.dart';
import '../core/soundboard.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/loading.dart';
import 'story_dialog_component.dart';
import 'subtitles_component.dart';

class PicoScriptComponent extends Component {
  static final outer = RegExp(r'\((\d*\.?\d*)(.*)\)');
  static final inner = RegExp(r'\((\w+)(.*)\)');

  final script = <(double, void Function())>[];

  PicoScriptComponent(String script) {
    final lines = script.split('\n').map((it) => it.trim());
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.startsWith('//')) continue;

      final top = outer.matchAsPrefix(line);
      if (top == null) throw ArgumentError(line);
      final atSeconds = double.parse(top.group(1)!);
      final func = top.group(2)!.trim();
      this.script.add((atSeconds, () => eval(func)));
    }
  }

  dynamic eval(String script) {
    if (script.trim().isEmpty) {
      return [];
    } else if (script.startsWith('(')) {
      logInfo('eval inner func "$script"');
      final call = inner.matchAsPrefix(script);
      if (call == null) throw ArgumentError(script);
      final name = call.group(1)!;
      var args = eval(call.group(2)!.trim());
      if (args is! List) args = [args];
      return _toFunction((name, args))();
    } else if (script.contains(' ')) {
      logInfo('eval args list "$script"');
      final words = script.split(' ');
      final vals = words.map((it) => eval(it));
      return vals.toList();
    } else if (script.startsWith('Anchor.')) {
      final name = script.split('.')[1];
      return Anchor.valueOf(name);
    } else if (script.startsWith('\'')) {
      return script.substring(1, script.length - 1);
    } else {
      return double.parse(script);
    }
  }

  void Function() _toFunction((String, List) it) {
    final func = it.$1;
    final List args = it.$2;
    return switch (func) {
      'clear' => () => _clear(args),
      'dialog' => () => _dialog(args[0], args[1]),
      'fadeIn' => () => _fadeIn(args),
      'fadeOut' => () => _fadeOut(args),
      'image' => () => _image(args),
      'menuButton' => () => _menuButton(args),
      'music' => () => _music(args[0]),
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

  final _handles = <String, dynamic>{};

  Future<SpriteComponent> _image(List args) async {
    final String filename = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    final pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    final it = await loadSprite(filename, position: pos, anchor: anchor);
    _handles[filename] = it;
    add(it);
    return it;
  }

  void _fadeIn(List args) async {
    final it = (await args.single) as Component;
    it.fadeIn();
  }

  void _fadeOut(List args) {
    for (final it in args) {
      final target = _handles[it] as Component?;
      target?.fadeOut();
      target?.add(RemoveEffect(delay: 1));
    }
  }

  Future<BitmapButton> _menuButton(List args) async {
    final String text = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    final pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    final button = await images.load('button_plain.png');
    final it = BitmapButton(
      bgNinePatch: button,
      text: text,
      font: menuFont,
      fontScale: 0.25,
      position: pos,
      anchor: anchor,
      onTap: (_) => {},
    );
    _handles[text] = it;
    add(it);
    return it;
  }

  final stopAudio = <void Function()>[];

  void _music(String filename) async {
    final player;
    if (dev) {
      player = await FlameAudio.playLongAudio(
        'music_title.mp3',
        volume: soundboard.masterVolume,
      );
    } else {
      player = await FlameAudio.loop(
        'music_title.mp3',
        volume: soundboard.masterVolume,
      );
    }
    stop() => player.stop();
    player.onPlayerComplete.listen((_) => stopAudio.remove(stop));
    stopAudio.add(stop);
  }

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

  @override
  void onLoad() async {
    if (active != null) await active?.cancel();

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
