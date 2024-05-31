import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'core/soundboard.dart';
import 'util/bitmap_text.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

class SplashScreen extends Component with KeyboardHandler, TapCallbacks {
  final _blackPaint = Paint()..color = const Color(0xFF000000);

  final _intensiLine0 = Vector2(160, 70);
  final _intensiLine1 = Vector2(160, 100);
  final _intensiLine2 = Vector2(160, 120);
  final _intensiLine3 = Vector2(160, 140);
  final _intensiLine4 = Vector2(160, 190);

  late final SpriteAnimation psychocell;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) showScreen(Screen.title);
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTapDown(TapDownEvent event) => showScreen(Screen.title);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  onLoad() async {
    psychocell = await game.loadSpriteAnimation(
      'splash_anim.png',
      SpriteAnimationData.sequenced(
        amount: 13,
        stepTime: 0.05,
        textureSize: Vector2(120, 90),
        loop: false,
      ),
    );

    add(RectangleComponent(
      position: Vector2.zero(),
      size: gameSize,
      paint: _blackPaint,
    ));

    final script = [
      (0500, () => _fadeIn('An', _intensiLine1)),
      (1500, () => _fadeIn('IntensiCode', _intensiLine2)),
      (2500, () => _fadeIn('Presentation', _intensiLine3)),
      (5000, () => _fadeOutAll()),
      (6000, () => _fadeIn('A', _intensiLine0)),
      (6000, () => _showPsychocell()),
      (6000, () => _fadeIn('Game', _intensiLine4)),
      (9000, () => _zoomPsychocell()),
      (9000, () => _fadeOutAll()),
      (9999, () => showScreen(Screen.title)),
    ];
    runScript(script);
  }

  void _fadeIn(String text, Vector2 position) {
    final line = _line(text, position);
    line.opacity = 0;
    line.add(OpacityEffect.fadeIn(EffectController(duration: 1)));
    add(line);
  }

  BitmapText _line(String text, Vector2 position) => BitmapText(
        text: text,
        position: position,
        font: menuFont,
        anchor: Anchor.center,
      );

  void _fadeOutAll() {
    for (final it in children) {
      it.add(OpacityEffect.fadeOut(EffectController(duration: 1)));
      it.add(RemoveEffect(delay: 1));
    }
  }

  late final SpriteAnimationComponent psychocellComponent;

  void _showPsychocell() {
    soundboard.masterVolume = 0.75;
    soundboard.play(Sound.swoosh);
    psychocellComponent = SpriteAnimationComponent(
      animation: psychocell,
      position: Vector2(160, 128),
      anchor: Anchor.center,
    );
    add(psychocellComponent);
  }

  void _zoomPsychocell() {
    soundboard.play(Sound.swoosh);
    psychocellComponent.add(
      ScaleEffect.to(
        Vector2.all(10),
        EffectController(duration: 1, curve: Curves.decelerate),
      ),
    );
  }
}
