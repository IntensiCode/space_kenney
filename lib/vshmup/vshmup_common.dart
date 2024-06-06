import 'package:flame/components.dart';

mixin VShmupTarget on PositionComponent {
  Component get visual;

  /// returns true when destroyed
  bool applyDamage({double? laser});
}
