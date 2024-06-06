import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/animation.dart';
import 'package:space_kenney/core/common.dart';
import 'package:space_kenney/util/auto_dispose.dart';
import 'package:space_kenney/util/random.dart';

import '../story/script_functions.dart';
import '../util/debug.dart';
import '../util/extensions.dart';

const _positionDistribution = Curves.easeInOutCubic;

const _frameSize = 48.0;

const _rotateBaseSeconds = 3.0;
const _rotateVariance = 3.0;

const _baseSpeed = 16;
const _speedVariance = 8.0;

extension ScriptFunctionsExtension on ScriptFunctions {
  VShmupShaderMoons shaderMoons() => added(VShmupShaderMoons());
}

class VShmupShaderMoons extends AutoDisposeComponent with ScriptFunctions {
  static const scale = 1.0;
  static const opacity = 0.333;
  static const baseSpeed = 8;
  static const outsideOffset = 32;
  static final black = Paint()..color = const Color(0xFF000000);

  late FragmentShader backgroundShader;
  late FragmentShader craterShader;

  @override
  void onLoad() async {
    final background = await FragmentProgram.fromAsset('assets/shaders/moon.frag');
    backgroundShader = background.fragmentShader();

    final crater = await FragmentProgram.fromAsset('assets/shaders/moon_crater.frag');
    craterShader = crater.fragmentShader();
  }

  double _releaseTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_releaseTime <= 0) {
      final it = added(VShmupShaderCelestial(backgroundShader, craterShader));
      it.priority = 11;
      it.scale.setValues(scale, scale);
      it.position.x = random.nextDoubleLimit(gameWidth);
      it.position.y = -random.nextDoubleLimit(16) - outsideOffset;
      it.angle = random.nextDoubleLimit(pi);
      _releaseTime = 2 + random.nextDoubleLimit(1);
    } else {
      _releaseTime -= dt;
    }
  }
}

class VShmupShaderCelestial extends PositionComponent {
  final FragmentShader background;
  final FragmentShader crater;

  final backgroundPaint = Paint(); // ..color = Colors.black;
  final craterPaint = Paint(); // ..color = Colors.black;

  late int frames;
  late bool xFlipped;
  late Color color1;
  late Color color2;
  late Color color3;
  late Color color4;
  late Color color5;
  late double dx;
  late double dy;
  late double rotationSeconds;
  late double shaderSizeFactor;
  late double shaderSeed;

  VShmupShaderCelestial(this.background, this.crater) {
    backgroundPaint.shader = background;
    craterPaint.shader = crater;

    background.setFloat(0, _frameSize); // w
    background.setFloat(1, _frameSize); // h
    background.setFloat(2, _frameSize); // pixels
    background.setFloat(18, 1); // should_dither

    crater.setFloat(0, _frameSize); // w
    crater.setFloat(1, _frameSize); // h
    crater.setFloat(2, _frameSize); // pixels
    crater.setFloat(18, 1); // should_dither

    anchor = Anchor.center;
    size.setAll(_frameSize);

    add(DebugCircleHitbox(radius: 20, anchor: Anchor.center));

    reset();
  }

  _pickFlipped() => xFlipped = random.nextBool();

  _pickScale() => scale.setAll(0.25 + random.nextDoubleLimit(0.75));

  _pickTint() {
    final tint = Color(random.nextInt(0x20000000));
    color1 = Color.alphaBlend(tint, const Color(0xFFa3a7c2));
    color2 = Color.alphaBlend(tint, const Color(0xFF4c6885));
    color3 = Color.alphaBlend(tint, const Color(0xFF3a3f5e));
    color4 = Color.alphaBlend(tint, const Color(0xC02a2f3e));
    color5 = Color.alphaBlend(tint, const Color(0xC01a1f2e));
  }

  _pickPosition() {
    final it = random.nextDouble();
    final curved = it < 0.5 //
        ? _positionDistribution.transform(it * 2) / 2
        : 1 - _positionDistribution.transform((1 - it) * 2) / 2;

    position.x = (curved * gameWidth) ~/ _frameSize * _frameSize.toDouble();
    position.y = -random.nextDoubleLimit(16) - _frameSize * scale.y;
  }

  _pickSpeed() {
    // dx = random.nextDouble() - random.nextDouble();
    // dx *= _speedVariance;
    dx = 0;
    dy = _baseSpeed + random.nextDoubleLimit(_speedVariance);
  }

  _pickRotation() => rotationSeconds = _rotateBaseSeconds + random.nextDoubleLimit(_rotateVariance);

  _pickShaderParams() {
    shaderSizeFactor = 1.5 + random.nextDoubleLimit(3);
    shaderSeed = 1 + random.nextDoubleLimit(9);
  }

  reset() {
    _pickFlipped();
    _pickScale();
    _pickTint();
    _pickPosition();
    _pickSpeed();
    _pickRotation();
    _pickShaderParams();
  }

  @override
  void update(double dt) {
    super.update(dt);

    shaderTime += dt / rotationSeconds * (xFlipped ? -1 : 1);

    position.x += dt * dx;
    position.y += dt * dy;

    if (position.y < gameHeight + _frameSize * scale.y) return;
    if (position.x > -_frameSize * scale.x) return;
    if (position.x < gameWidth + _frameSize * scale.x) return;

    bool remove = false;
    if (position.y > gameHeight + _frameSize * scale.y) remove = true;
    if (position.x < -_frameSize * scale.x) remove = true;
    if (position.x > gameWidth + _frameSize * scale.x) remove = true;
    if (remove) removeFromParent();
  }

  double shaderTime = 0;

  final rect = const Rect.fromLTWH(0, 0, _frameSize, _frameSize);

  @override
  render(Canvas canvas) {
    super.render(canvas);
    background.setFloat(3, shaderTime);
    background.setVec4(4, color1);
    background.setVec4(8, color2);
    background.setVec4(12, color3);
    background.setFloat(16, 50);
    background.setFloat(17, shaderSeed);
    background.setFloat(18, shaderSeed);
    canvas.translate(-_frameSize / 2, -_frameSize / 2);
    canvas.drawRect(rect, backgroundPaint);

    crater.setFloat(3, shaderTime);
    crater.setVec4(4, color4);
    crater.setVec4(8, color5);
    crater.setFloat(16, shaderSizeFactor);
    crater.setFloat(17, shaderSeed);
    crater.setFloat(18, shaderTime);
    canvas.drawRect(rect, craterPaint);
    canvas.translate(_frameSize / 2, _frameSize / 2);
  }
}
