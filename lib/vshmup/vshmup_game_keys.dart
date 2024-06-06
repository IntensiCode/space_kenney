import 'package:flame/components.dart';
import 'package:flutter/services.dart';

// TODO include synonyms?

enum VShmupGameKey {
  left,
  right,
  up,
  down,
  primaryFire,
  secondaryFire,
  inventory,
  useOrExecute,
}

mixin VShmupGameKeys on KeyboardHandler {
  // just guessing for now what i may need... doesn't matter.. just to have something for now..

  static final leftKeys = ['Arrow Left', 'A'];
  static final rightKeys = ['Arrow Right', 'D'];
  static final downKeys = ['Arrow Down', 'S'];
  static final upKeys = ['Arrow Up', 'W'];
  static final primaryFireKeys = ['Control', 'Space', 'J'];
  static final secondaryFireKeys = ['Shift', 'K'];
  static final inventoryKeys = ['Tab', 'Home', 'I'];
  static final useOrExecuteKeys = ['End', 'U'];

  static final mapping = {
    VShmupGameKey.left: leftKeys,
    VShmupGameKey.right: rightKeys,
    VShmupGameKey.up: upKeys,
    VShmupGameKey.down: downKeys,
    VShmupGameKey.primaryFire: primaryFireKeys,
    VShmupGameKey.secondaryFire: secondaryFireKeys,
    VShmupGameKey.inventory: inventoryKeys,
    VShmupGameKey.useOrExecute: useOrExecuteKeys,
  };

  // held states

  final held = <VShmupGameKey, bool>{}..addEntries(VShmupGameKey.values.map((it) => MapEntry(it, false)));
  final count = <VShmupGameKey, int>{}..addEntries(VShmupGameKey.values.map((it) => MapEntry(it, 0)));

  bool get left => held[VShmupGameKey.left] == true;

  bool get right => held[VShmupGameKey.right] == true;

  bool get up => held[VShmupGameKey.up] == true;

  bool get down => held[VShmupGameKey.down] == true;

  bool get primaryFire => held[VShmupGameKey.primaryFire] == true;

  bool get secondaryFire => held[VShmupGameKey.secondaryFire] == true;

  bool isHeld(VShmupGameKey key) => held[key] == true;

  bool hasCount(VShmupGameKey key) => count[key]! >= 0;

  // TODO clear before update? or manual? let's see..

  String label(LogicalKeyboardKey key) {
    final s = key.synonyms.singleOrNull;
    if (s != null) return label(s);

    final check = key.keyLabel;
    if (check == ' ') return 'Space';
    return check;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyRepeatEvent) {
      return true; // super.onKeyEvent(event, keysPressed);
    }
    if (event case KeyDownEvent it) {
      final check = label(it.logicalKey);
      for (final entry in mapping.entries) {
        final key = entry.key;
        final keys = entry.value;
        if (keys.contains(check)) {
          if (held[key] == false) count.update(key, (it) => it + 1);
          held[key] = true;
        }
      }
    }
    if (event case KeyUpEvent it) {
      final check = label(it.logicalKey);
      for (final entry in mapping.entries) {
        final key = entry.key;
        final keys = entry.value;
        if (keys.contains(check)) {
          held[key] = false;
        }
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
