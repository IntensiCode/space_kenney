import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:space_kenney/web_play_screen.dart';

import 'core/common.dart';
import 'core/soundboard.dart';
import 'game_world.dart';
import 'global_keys.dart';
import 'util/fonts.dart';
import 'util/performance.dart';

class SpaceKenneyGame extends FlameGame<GameWorld>
    with HasKeyboardHandlerComponents, GlobalKeys<GameWorld>, HasPerformanceTracker {
  //
  final _ticker = Ticker(ticks: 120);

  void _showInitialScreen() {
    if (dev) {
      // world.add(WebPlayScreen());
      // world.showSplash();
      // world.showTitle();
      world.showChapter1Level1();
    } else {
      if (kIsWeb) {
        world.add(WebPlayScreen());
      } else {
        world.showSplash();
      }
    }
  }

  SpaceKenneyGame() : super(world: GameWorld()) {
    game = this;
    images = this.images;

    if (kIsWeb) logAnsi = false;
  }

  @override
  onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera = CameraComponent.withFixedResolution(
      width: gameWidth,
      height: gameHeight,
      hudComponents: [_ticks(), _frames()],
    );
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  _ticks() => RenderTps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 0),
        anchor: Anchor.topLeft,
      );

  _frames() => RenderFps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 8),
        anchor: Anchor.topLeft,
        time: () => renderTime,
      );

  @override
  onLoad() async {
    await soundboard.preload();
    await loadFonts(assets);
    _showInitialScreen();
    if (dev) {
      onKey('<C-d>', () => _toggleDebug());
      onKey('<C-m>', () => soundboard.toggleMute());
      onKey('<C-0>', () => world.showTitle());
      onKey('<C-1>', () => world.showChapter1());
      onKey('<C-->', () => _slowDown());
      onKey('<C-=>', () => _speedUp());
      onKey('<C-S-+>', () => _speedUp());
    }
  }

  _toggleDebug() {
    debug = !debug;
    return KeyEventResult.handled;
  }

  _slowDown() {
    if (_timeScale > 0.125) _timeScale /= 2;
  }

  _speedUp() {
    if (_timeScale < 4.0) _timeScale *= 2;
  }

  @override
  update(double dt) => _ticker.generateTicksFor(dt * _timeScale, (it) => super.update(it));

  double _timeScale = 1;
}
