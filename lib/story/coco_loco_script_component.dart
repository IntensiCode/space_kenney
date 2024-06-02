import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:kart/kart.dart';

import '../core/common.dart';
import '../core/events.dart';
import '../util/bitmap_button.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import 'script_functions.dart';
import 'subtitles_component.dart';

typedef ProgramLine = Future<dynamic> Function();
typedef Program = Iterable<ProgramLine>;

class CocoLocoScriptComponent extends Component with ScriptFunctions, CocoLocoScript {
  CocoLocoScriptComponent() {
    def('scaleTo', (it) async => _scaleTo(it));
    def('showScreen', (it) async => showScreen(it.single));
  }
}

mixin CocoLocoScript on Component, ScriptFunctions {
  static final _inner = RegExp(r'\((\w+)(.*)\)');
  static final _string = RegExp(r'([a-zA-Z][a-zA-Z0-9_]*)');
  static final _call = RegExp(r'(\([^()]+\))');

  final bindings = <String, dynamic>{
    'false': false,
    'true': true,
    'bottomCenter': Anchor.bottomCenter,
    'bottomLeft': Anchor.bottomLeft,
    'bottomRight': Anchor.bottomRight,
    'center': Anchor.center,
    'centerLeft': Anchor.centerLeft,
    'centerRight': Anchor.centerRight,
    'topCenter': Anchor.topCenter,
    'topLeft': Anchor.topLeft,
    'topRight': Anchor.topRight,
    'fancyFont': fancyFont,
    'menuFont': menuFont,
    'textFont': textFont,
  };

  final functions = <String, Future<dynamic> Function(List)>{};

  StreamSubscription? _active;

  void def(String name, Future<dynamic> Function(List) func) => functions[name] = func;

  void let(String name, dynamic value) => bindings[name] = value;

  Future<StreamSubscription> enact(String script) async {
    final program = _makeProgram(script);
    logInfo('program: $program');
    return runProgram(program);
  }

  Program _makeProgram(String script) {
    script = script.split('\n').map((it) => it.trim()).whereNot((it) => it.isEmpty || it.startsWith('//')).join(' ');

    logInfo('enact $script');
    while (true) {
      final call = _call.firstMatch(script);
      if (call == null) break;
      final before = script.substring(0, call.start).trim();
      final after = script.substring(call.end).trim();
      final lazy = eval(call.group(0)!);
      final ref = autoBind(lazy);
      script = '$before @$ref $after';
    }

    final steps = eval(script) as List;
    return steps.map((it) => it as ProgramLine);
  }

  String autoBind(dynamic value) {
    final name = 'v${bindings.length}';
    bindings[name] = value;
    return name;
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
    final dyn = functions[func];
    if (dyn != null) return () async => await dyn(args);

    return switch (func) {
      'add' => () async => _add(args),
      'anim' => () async => _anim(args),
      'at' => () async => _at(args),
      'clear' => () async => clearByType(args),
      'dialog' => () async => dialog(args[0], args[1]),
      'delay' => () async => delay(args.single),
      'fadeIn' => () async => _fadeIn(args),
      'fadeOut' => () async => _fadeOut(args),
      'fadeOutAll' => () async => fadeOutAll(),
      'font' => () async => _font(args),
      'image' => () async => _image(args),
      'loadAnim' => () async => _loadAnim(args),
      'loop' => () async => _loop(args),
      'menuButton' => () async => _menuButton(args),
      'music' => () async => music(args[0]),
      'playAudio' => () async => playAudio(args.single),
      'pressFireToStart' => () async => pressFireToStart(),
      'remove' => () async => _remove(args),
      'text' => () async => _text(args),
      'subtitles' => () async => _subtitles(args),
      _ => throw ArgumentError('Unknown script command: $func'),
    };
  }

  _add(List args) async {
    args = args.map((it) => it is Function ? it() : it).toList();
    final it = (await args.first) as Component;
    if (args.length == 2) {
      final name = args.lastOrNull();
      if (name != null) let(name, it);
    }
    add(it);
    return it;
  }

  Future<SpriteAnimationComponent> _anim(List args) async {
    final SpriteAnimation animation = await args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    var pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    pos ??= args.whereType<Vector2>().firstOrNull();
    final it = SpriteAnimationComponent(
      animation: animation,
      position: pos,
      anchor: anchor,
    );
    add(it);
    return it;
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
    final duration = args.whereType<num>().firstOrNull()?.toDouble() ?? 1;
    for (final it in args) {
      if (it is String) {
        (bindings[it] as Component).fadeIn(seconds: duration);
      } else if (it is Component) {
        it.fadeIn(seconds: duration);
      } else if (it is Function) {
        ((await it()) as Component).fadeIn(seconds: duration);
      }
    }
  }

  _fadeOut(List args) async {
    for (final it in args) {
      if (it is Future) {
        ((await it) as Component).fadeOut();
      } else if (it is String) {
        final bound = bindings[it];
        if (bound is Component) bound.fadeOut();
        final known = knownComponents[it];
        if (known is Component) known.fadeOut();
      }
    }
  }

  _font(List args) {
    final scale = args.getOrNull(1) as num?;
    fontSelect(args[0], scale: scale?.toDouble());
  }

  Future<SpriteComponent> _image(List args) async {
    final String filename = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    var pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    pos ??= args.whereType<Vector2>().firstOrNull();
    return image(filename: filename, position: pos, anchor: anchor);
  }

  Future<SpriteAnimation> _loadAnim(List args) async {
    final String filename = args[0];
    final frames = args[1] as num;
    final stepTime = args[2] as num;
    final width = args[3] as num;
    final height = args[4] as num;
    final frameSize = Vector2(width.toDouble(), height.toDouble());
    final loop = args.getOrNull(5) ?? true;
    return game.loadSpriteAnimation(
      filename,
      SpriteAnimationData.sequenced(
        amount: frames.toInt(),
        stepTime: stepTime.toDouble(),
        textureSize: frameSize,
        loop: loop,
      ),
    );
  }

  _loop(List args) async {
    while (isMounted) {
      logInfo('loop');
      for (final it in args) {
        if (!isMounted) break;
        await it();
      }
    }
  }

  Future<BitmapButton> _menuButton(List args) async {
    final String text = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    final pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    return menuButton(text: text, pos: pos, anchor: anchor);
  }

  void _remove(List args) {
    for (final it in args) {
      if (it case Component c) c.removeFromParent();
      if (it is String) knownComponents[it]?.removeFromParent();
    }
  }

  void _scaleTo(List args) {
    final it = args[0] as Component;
    final scale = args[1] as num;
    final duration = args[2] as num;
    final curve = args.getOrNull(3);
    scaleTo(it, scale.toDouble(), duration.toDouble(), curve);
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

  BitmapText _text(List args) {
    final string = args[0];
    final xy = args.whereType<num>().toList();
    final anchor = args.whereType<Anchor>().singleOrNull;
    var pos = xy.isEmpty ? null : Vector2(xy[0].toDouble(), xy[1].toDouble());
    pos ??= args.whereType<Vector2>().firstOrNull();
    final scale = xy.getOrNull(2)?.toDouble();
    final it = text(text: string, position: pos, anchor: anchor ?? Anchor.center, scale: scale);
    add(it);
    return it;
  }
}
