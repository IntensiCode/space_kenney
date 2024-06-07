import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:space_kenney/core/common.dart';
import 'package:space_kenney/particles/smoke.dart';

import '../core/soundboard.dart';
import '../util/random.dart';
import 'vshmup_common.dart';
import 'vshmup_game_keys.dart';

class VShmupMiningLaser extends Component {
  final VShmupGameKeys keys;
  final PositionComponent ship;

  VShmupMiningLaser(this.keys, this.ship);

  final paint = Paint();

  VShmupTarget? _targeted;

  double scanAngle = 0;
  double scanDir = 1;

  double smoking = 0;
  static double smokesPerSecond = 4;
  static double damagePerSecond = 40;

  @override
  void update(double dt) {
    super.update(dt);

    scanAngle += dt * pi / 2 * scanDir;
    if (scanAngle.abs() > pi / 8) scanDir = -scanDir;

    final target = keys.primaryFire ? _findTarget() : null;
    if (target != _targeted) {
      _clearTargeted();
      _targeted = target;
      if (target != null) soundboard.play(Sound.mining_laser);
    }

    if (target != null) {
      _emitSmoke(target, dt);
      final damage = dt * damagePerSecond;
      final destroyed = target.applyDamage(laser: damage);
      if (destroyed) _clearTargeted();
    }
  }

  void _clearTargeted() => _targeted = null;

  void _emitSmoke(VShmupTarget target, double dt) {
    final dir = ship.position - target.position;
    final ray = Ray2(origin: target.position, direction: dir.normalized());
    final hit = collisions.raycast(ray);
    if (hit != null && hit.isActive) {
      final ip = hit.intersectionPoint;
      if (ip != null) {
        smoking += dt;
        if (smoking > 1 / smokesPerSecond) {
          smoking -= 1 / smokesPerSecond;
          smokeAt(ip + randomNormalizedVector() * 4, parent: parent!);
        }
      }
    }
  }

  VShmupTarget? _findTarget() {
    final p = parent;
    if (p == null) return null;

    late double minDist;
    VShmupTarget? min;
    p.propagateToChildren<VShmupTarget>((it) {
      if (it.position.y + it.size.y * it.scale.x / 2 < 0) return true;

      final angle = ship.angleTo(it.position).abs();
      if (angle > pi / 8) return true;

      if (min == null) {
        minDist = ship.distanceSquared(it);
        min = it;
      } else {
        final dist = ship.distanceSquared(it);
        if (dist < minDist) {
          minDist = dist;
          min = it;
        }
      }
      return true;
    }, includeSelf: false);

    return min;
  }

  @override
  void render(Canvas canvas) {
    final from = ship.position.toOffset();

    final target = _targeted;
    if (target == null) {
      if (keys.primaryFire) _drawScan(canvas, from);
    } else {
      _drawBeam(canvas, from, target);
    }
  }

  void _drawScan(Canvas canvas, Offset from) {
    paint.color = const Color(0x80ff0000);
    paint.strokeWidth = 0.5;

    var scan = from + Offset.fromDirection(scanAngle - pi / 2, 250);
    canvas.drawLine(from, scan, paint);
    scan = from + Offset.fromDirection(-scanAngle - pi / 2, 250);
    canvas.drawLine(from, scan, paint);
  }

  void _drawBeam(Canvas canvas, Offset from, PositionComponent target) {
    final to = target.position.toOffset();

    paint.color = const Color(0x80ffff00);
    paint.strokeWidth = 2.5;
    canvas.drawLine(from, to, paint);

    paint.color = const Color(0xFFffffff);
    paint.strokeWidth = 1;
    canvas.drawLine(from, to, paint);
  }
}

extension on PositionComponent {
  double distanceSquared(PositionComponent other) => position.distanceToSquared(other.position);
}
