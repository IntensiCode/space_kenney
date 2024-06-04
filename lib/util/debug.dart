import 'dart:ui';

import 'package:flame/components.dart';

import '../core/common.dart';

Color? debugHitboxColor = const Color(0x40ff0000);

class DebugCircleHitbox extends CircleComponent with HasVisibility {
  DebugCircleHitbox({
    super.radius,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority,
    super.paint,
    super.paintLayers,
  }) {
    if (debugHitboxColor != null) paint.color = debugHitboxColor!;
  }

  @override
  bool get isVisible => debug;
}
