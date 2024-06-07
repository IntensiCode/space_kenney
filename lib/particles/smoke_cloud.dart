import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:space_kenney/util/extensions.dart';

import '../core/common.dart';
import '../util/random.dart';

SmokeCloud smokeCloudAt(Vector2 position, {required Component parent}) {
  final smoke = SmokeCloud(position: position);
  parent.add(smoke);
  return smoke;
}

void smokeCloudAround(Vector2 position, double size, {int? count, required Component parent}) {
  logInfo('shade around $size');
  count ??= max(1, size ~/ 4);
  repeat(count, (_) {
    final at = randomNormalizedVector();
    at.x *= size;
    at.y *= size;
    parent.add(SmokeCloud(position: position + at));
  });
}

class SmokeCloud extends PositionComponent {
  SmokeCloud({super.position})
      : super(
          size: Vector2.all(24),
          anchor: Anchor.center,
        );

  static FragmentProgram? program;
  static FragmentShader? shader;
  static Paint? paint;

  late double seed;
  late double dx;
  late double dy;

  @override
  onLoad() async {
    logInfo('load smoke');
    program ??= await FragmentProgram.fromAsset('assets/shaders/smoke.frag');
    shader ??= program!.fragmentShader();
    paint ??= Paint()..shader = shader;
    seed = random.nextDoubleLimit(100);
    dx = random.nextDoublePM(5);
    dy = random.nextDoublePM(5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time.x += dx * dt;
    _time.y += dy * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    shader!.setFloat(0, 24);
    shader!.setFloat(1, 24);
    shader!.setFloat(2, seed);
    shader!.setFloat(3, _time.x);
    shader!.setFloat(4, _time.y);
    canvas.drawRect(size.toRect(), paint!);
  }

  final _time = Vector2.all(0);
}
