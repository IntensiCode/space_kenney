import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:kart/kart.dart';

import '../util/bitmap_button.dart';
import '../util/extensions.dart';
import 'script_functions.dart';
import 'subtitles_component.dart';

class LocoScriptComponent extends Component with ScriptFunctions {
  static final outer = RegExp(r'\((\d*\.?\d*)(.*)\)');
  static final inner = RegExp(r'\((\w+)(.*)\)');

  final script = <(double, void Function())>[];

  LocoScriptComponent(String script) {
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
      'clear' => () => clearByType(args),
      'dialog' => () => dialog(args[0], args[1]),
      'fadeIn' => () => _fadeIn(args),
      'fadeOut' => () => fadeOutByFilename(args.mapToType<String>()),
      'image' => () => _image(args),
      'menuButton' => () => _menuButton(args),
      'music' => () => music(args[0]),
      'playAudio' => () => playAudio(args.single),
      'pressFireToStart' => () => pressFireToStart(),
      'subtitles' => () => _subtitles(args),
      _ => throw ArgumentError('Unknown dialog command: $func'),
    };
  }

  void _fadeIn(List<dynamic> args) async {
    final components = <Component>[];
    for (final it in args) {
      components.add((await it) as Component);
    }
    fadeInComponents(components);
  }

  Future<SpriteComponent> _image(List args) async {
    final String filename = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    final pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    return image(filename: filename, position: pos, anchor: anchor);
  }

  Future<BitmapButton> _menuButton(List args) async {
    final String text = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    final pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    return menuButton(text: text, pos: pos, anchor: anchor);
  }

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
    super.onRemove();
    active?.cancel();
    active = null;
  }
}
