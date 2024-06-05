import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kart/kart.dart';
import 'package:space_kenney/util/auto_dispose.dart';

mixin GlobalKeys<T extends World> on HasKeyboardHandlerComponents<T> {
  late final keyboard = HardwareKeyboard.instance;

  final handlers = <(String, void Function())>[];

  Disposable onKey(String pattern, void Function() callback) {
    logInfo('onKey $pattern');
    final handler = (pattern, callback);
    handlers.add(handler);
    return Disposable.wrap(() => handlers.remove(handler));
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyRepeatEvent) {
      return KeyEventResult.skipRemainingHandlers;
    }
    if (event is KeyDownEvent && !event.character.isNullOrBlank()) {
      final modifiers = StringBuffer();
      if (keyboard.isAltPressed) modifiers.write('A-');
      if (keyboard.isControlPressed) modifiers.write('C-');
      if (keyboard.isMetaPressed) modifiers.write('M-');
      if (keyboard.isShiftPressed) modifiers.write('S-');

      var pattern = event.character!;
      if (modifiers.isNotEmpty) pattern = "<$modifiers$pattern>";

      bool handled = false;
      for (final it in handlers) {
        if (it.$1 == pattern) {
          it.$2();
          handled = true;
        }
      }
      if (handled) return KeyEventResult.skipRemainingHandlers;
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
