import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:space_kenney/web_play_screen.dart';

import 'core/common.dart';
import 'core/soundboard.dart';
import 'game_world.dart';
import 'util/bitmap_font.dart';
import 'util/fonts.dart';
import 'util/performance.dart';

class SpaceKenneyGame extends FlameGame<GameWorld>
    with HasCollisionDetection, HasKeyboardHandlerComponents, HasPerformanceTracker {
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
    soundboard.preload();

    fancyFont = await BitmapFont.loadDst(
      images,
      assets,
      'fonts/fancyfont.png',
      charWidth: 12,
      charHeight: 10,
    );
    menuFont = await BitmapFont.loadDst(
      images,
      assets,
      'fonts/menufont.png',
      charWidth: 24,
      charHeight: 24,
    );
    textFont = await BitmapFont.loadDst(
      images,
      assets,
      'fonts/textfont.png',
      charWidth: 12,
      charHeight: 12,
    );
    _showInitialScreen();
  }

  @override
  update(double dt) => _ticker.generateTicksFor(dt * _timeScale, (it) => super.update(it));

  double _timeScale = 1;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (!dev) {
      return super.onKeyEvent(event, keysPressed);
    }
    if (event is KeyRepeatEvent) {
      return KeyEventResult.skipRemainingHandlers;
    }
    if (event is KeyDownEvent) {
      if (event.character == 'd') {
        debug = !debug;
        return KeyEventResult.handled;
      }
      // if (event.character == 'L') {
      //   world.previousChapter();
      //   return KeyEventResult.handled;
      // }
      // if (event.character == 'l') {
      //   world.nextChapter();
      //   return KeyEventResult.handled;
      // }
      if (event.character == 'r') {
        world.showChapter1();
        return KeyEventResult.handled;
      }
      // if (event.character == 'S') {
      //   if (_timeScale > 0.125) _timeScale /= 2;
      //   return KeyEventResult.handled;
      // }
      // if (event.character == 's') {
      //   if (_timeScale < 4.0) _timeScale *= 2;
      //   return KeyEventResult.handled;
      // }
      if (event.character == 't') {
        world.showTitle();
        return KeyEventResult.handled;
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
