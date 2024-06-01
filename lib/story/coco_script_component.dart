import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:kart/kart.dart';

import '../util/bitmap_button.dart';
import '../util/extensions.dart';
import 'script_functions.dart';
import 'subtitles_component.dart';

typedef ProgramLine = Future<dynamic> Function();
typedef Program = List<ProgramLine>;

class CocoScriptComponent extends Component with ScriptFunctions, CocoScript {}

mixin CocoScript on Component, ScriptFunctions {
  static final _inner = RegExp(r'\((\w+)(.*)\)');
  static final _string = RegExp(r'([a-zA-Z][a-zA-Z0-9_]*)');

  final bindings = <String, dynamic>{
    'bottomCenter': Anchor.bottomCenter,
    'bottomLeft': Anchor.bottomLeft,
    'bottomRight': Anchor.bottomRight,
    'center': Anchor.center,
    'centerLeft': Anchor.centerLeft,
    'centerRight': Anchor.centerRight,
    'topCenter': Anchor.topCenter,
    'topLeft': Anchor.topLeft,
    'topRight': Anchor.topRight,
  };

  StreamSubscription? _active;

  void let(String name, dynamic value) => bindings[name] = value;

  Future<StreamSubscription> enact(List<List> script) async {
    final lines = script.map((it) => bind(it));
    lines.forEach((it) => bindings.addAll(it.$2));
    final program = makeProgram(lines.map((it) => it.$1));
    return runProgram(program);
  }

  (String, Map<String, dynamic>) bind(List line) {
    if (line.singleOrNull case String it) return (it, {});

    final script = StringBuffer();
    final bindings = <String, dynamic>{};
    for (final it in line) {
      if (script.isNotEmpty) script.write(' ');
      if (it is String) {
        script.write(it);
      } else {
        final name = 'v${bindings.length}';
        bindings[name] = it;
        script.write('@$name');
      }
    }
    return (script.toString(), bindings);
  }

  Program makeProgram(Iterable<String> script) {
    final program = <ProgramLine>[];
    final lines = script.map((it) => it.trim());
    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.startsWith('//')) continue;
      logInfo('program line: $line');
      program.add(eval(line));
    }
    return program;
  }

  Future<StreamSubscription> runProgram(final Program program) async {
    if (_active != null) await _active?.cancel();
    final it = Stream.fromIterable(program).asyncMap((it) async => await it());
    _active = it.listen((_) {});
    return _active!;
  }

  @override
  void onRemove() {
    super.onRemove();
    _active?.cancel();
    _active = null;
  }

  dynamic eval(String script) {
    script = script.trim();
    if (script.trim().isEmpty) {
      return [];
    } else if (script.startsWith('(')) {
      final call = _inner.matchAsPrefix(script);
      if (call == null) throw ArgumentError(script);
      final name = call.group(1)!;
      var args = eval(call.group(2)!.trim());
      if (args is! List) args = [args];
      return _toFunction((name, args));
    } else if (script.contains(' ')) {
      final split = script.indexOf(' ');
      if (split == -1) throw StateError('logic error');
      final head = eval(script.substring(0, split));
      final tail = eval(script.substring(split));
      if (tail case List l) return [head, ...l];
      return [head, tail];
    } else if (script.startsWith('Anchor.')) {
      final name = script.split('.')[1];
      return Anchor.valueOf(name);
    } else if (script.startsWith("'") || script.startsWith('"')) {
      return script.substring(1, script.length - 1);
    } else if (script.startsWith('@')) {
      final value = bindings[script.substring(1)];
      if (value == null) throw ArgumentError('not bound: $script');
      return value;
    } else if (_string.matchAsPrefix(script) != null) {
      return script;
    } else {
      return double.parse(script);
    }
  }

  ProgramLine _toFunction((String, List) it) {
    final func = it.$1;
    final List args = it.$2;
    return switch (func) {
      'at' => () async => _at(args),
      'clear' => () async => clearByType(args),
      'dialog' => () async => dialog(args[0], args[1]),
      'fadeIn' => () async => _fadeIn(args),
      'fadeOut' => () async => fadeOutByFilename(args.mapToType<String>()),
      'image' => () async => _image(args),
      'menuButton' => () async => _menuButton(args),
      'music' => () async => music(args[0]),
      'playAudio' => () async => playAudio(args.single),
      'pressFireToStart' => () async => pressFireToStart(),
      'subtitles' => () async => _subtitles(args),
      _ => throw ArgumentError('Unknown dialog command: $func'),
    };
  }

  _at(List args) async {
    if (args.length != 2) {
      throw ArgumentError('expected "seconds (some call)" instead of: ${args.join(' ')}');
    }
    final millis = (args.first * 1000).toInt();
    final call = args.last;
    return await Future.delayed(Duration(milliseconds: millis)).then((_) async => await call());
  }

  _fadeIn(List<dynamic> args) async {
    final components = <Component>[];
    for (final it in args) {
      components.add((await it()) as Component);
    }
    fadeInComponents(components);
  }

  Future<SpriteComponent> _image(List args) async {
    final String filename = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    var pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    pos ??= args.whereType<Vector2>().firstOrNull();
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

  double? _pickSeconds(List args, String key) =>
      args.mapNotNull((it) => switch (it) { (String k, num s) when k == key => s.toDouble(), _ => null }).singleOrNull;

  T? _pickValue<T extends Object>(List args, String key) => args.mapNotNull<T>((it) {
        return switch (it) { (String k, T v) when k == key => v, _ => null };
      }).singleOrNull;
}
