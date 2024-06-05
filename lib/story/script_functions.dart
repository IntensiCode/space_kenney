import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/animation.dart';
import 'package:space_kenney/util/auto_dispose.dart';

import '../components/press_fire_to_start.dart';
import '../core/common.dart';
import '../core/soundboard.dart';
import '../util/bitmap_button.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/loading.dart';
import 'story_dialog_component.dart';
import 'subtitles_component.dart';

mixin ScriptFunctions on Component, AutoDispose {
  double dialogPosition = 8;

  final dialogOffsets = <String, double>{};

  final knownComponents = <String, dynamic>{};

  void clearByType(List types) {
    dialogPosition = 8;
    final what = types.isEmpty ? children : children.where((it) => types.contains(it.runtimeType));
    removeAll(what);
  }

  void delay(double seconds) async {
    final millis = (seconds * 1000).toInt();
    await Stream.periodic(Duration(milliseconds: millis)).first;
  }

  StoryDialogComponent dialog(
    String portrait,
    String text, {
    String? audio,
    Anchor anchor = Anchor.topLeft,
  }) {
    if (audio != null) playDialogAudio(audio);

    final offset = dialogOffsets.putIfAbsent(portrait, _nextPortraitOffset);
    final it = StoryDialogComponent(portrait, text);
    it.position.x = offset;
    it.position.y = dialogPosition;
    it.anchor = anchor;
    add(it);
    dialogPosition += 64;
    return it;
  }

  double _nextPortraitOffset() => (dialogOffsets.length + 1) * 8;

  void fadeIn(Component it, {double duration = 1}) => it.fadeIn(seconds: duration);

  BitmapFont? font;
  double? fontScale;

  fontSelect(BitmapFont? font, {double? scale = 1}) {
    this.font = font;
    fontScale = scale;
  }

  Future<Image> image(String filename) => images.load(filename);

  SpriteSheet sheet(Image image, int columns, int rows) =>
      SpriteSheet.fromColumnsAndRows(image: image, columns: columns, rows: rows);

  Future<SpriteComponent> sprite({
    required String filename,
    Vector2? position,
    Anchor? anchor,
  }) async {
    final it = await loadSprite(filename, position: position, anchor: anchor);
    knownComponents[filename] = it;
    add(it);
    return it;
  }

  SpriteComponent spriteIXY(Image image, double x, double y, [Anchor anchor = Anchor.center]) {
    final it = SpriteComponent(sprite: Sprite(image), position: Vector2(x, y), anchor: anchor);
    add(it);
    return it;
  }

  Future<SpriteComponent> spriteXY(String filename, double x, double y, [Anchor anchor = Anchor.center]) async {
    final it = await loadSprite(filename, position: Vector2(x, y), anchor: anchor);
    knownComponents[filename] = it;
    add(it);
    return it;
  }

  void fadeInComponents(List<Component> args) async {
    final duration = args.whereType<num>().firstOrNull?.toDouble();
    args.whereType<Component>().forEach((it) => it.fadeIn(seconds: duration ?? 0.4));
  }

  void fadeInByType<T extends Component>([bool reset = true]) async {
    children.whereType<T>().forEach((it) => it.fadeIn());
  }

  void fadeOutAll() {
    for (final it in children) {
      it.add(OpacityEffect.fadeOut(EffectController(duration: 1)));
      it.add(RemoveEffect(delay: 1));
    }
  }

  void fadeOutByFilename(List<String> filenames) {
    for (final it in filenames) {
      final target = knownComponents[it] as Component?;
      target?.fadeOut();
      target?.add(RemoveEffect(delay: 1));
    }
  }

  Future<SpriteAnimation> loadAnimWH(
    String filename,
    int frameWidth,
    int frameHeight, [
    double stepTime = 0.1,
    bool loop = true,
  ]) async {
    final image = await images.load(filename);
    final columns = image.width ~/ frameWidth;
    if (columns * frameWidth != image.width) {
      throw ArgumentError('image width ${image.width} / frame width $frameWidth');
    }
    final rows = image.height ~/ frameHeight;
    if (rows * frameHeight != image.height) {
      throw ArgumentError('image height ${image.height} / frame height $frameHeight');
    }
    return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: columns * rows,
          amountPerRow: columns,
          stepTime: stepTime,
          textureSize: Vector2(frameWidth.toDouble(), frameHeight.toDouble()),
          loop: loop,
        ));
  }

  Future<SpriteAnimation> loadAnim(
    String filename, {
    required int frames,
    required double stepTimeSeconds,
    required num frameWidth,
    required num frameHeight,
    bool loop = true,
  }) async {
    final frameSize = Vector2(frameWidth.toDouble(), frameHeight.toDouble());
    return game.loadSpriteAnimation(
      filename,
      SpriteAnimationData.sequenced(
        amount: frames.toInt(),
        stepTime: stepTimeSeconds.toDouble(),
        textureSize: frameSize,
        loop: loop,
      ),
    );
  }

  SpriteAnimationComponent makeAnimXY(SpriteAnimation animation, double x, double y, [Anchor anchor = Anchor.center]) =>
      makeAnim(animation, Vector2(x, y), anchor);

  SpriteAnimationComponent makeAnim(SpriteAnimation animation, Vector2 position, [Anchor anchor = Anchor.center]) =>
      SpriteAnimationComponent(
        animation: animation,
        position: position,
        anchor: anchor,
      );

  Future<BitmapButton> menuButtonXY(
    String text,
    double x,
    double y, [
    Anchor? anchor,
    String? bgNinePatch,
    Function(BitmapButton)? onTap,
  ]) {
    return menuButton(text: text, pos: Vector2(x, y), anchor: anchor, bgNinePatch: bgNinePatch, onTap: onTap);
  }

  Future<BitmapButton> menuButton({
    required String text,
    Vector2? pos,
    Anchor? anchor,
    String? bgNinePatch,
    void Function(BitmapButton)? onTap,
  }) async {
    final button = await images.load(bgNinePatch ?? 'button_plain.png');
    final it = BitmapButton(
      bgNinePatch: button,
      text: text,
      font: menuFont,
      fontScale: 0.25,
      position: pos,
      anchor: anchor,
      onTap: onTap ?? (_) => {},
    );
    knownComponents[text] = it;
    add(it);
    return it;
  }

  void backgroundMusic(String filename) async {
    var volume = soundboard.musicVolume * soundboard.masterVolume;

    dispose('afterTenSeconds');
    dispose('backgroundMusic');
    dispose('backgroundMusic_fadeIn');

    final AudioPlayer player;

    if (dev) {
      await FlameAudio.bgm.play(filename, volume: volume);
      player = FlameAudio.bgm.audioPlayer;

      // only in dev: stop music after 10 seconds, to avoid playing multiple times on hot restart.
      final afterTenSeconds = player.onPositionChanged.where((it) => it.inSeconds >= 10).take(1);
      autoDispose('afterTenSeconds', afterTenSeconds.listen((it) => player.stop()));
    } else {
      await FlameAudio.bgm.play(filename, volume: volume);
      player = FlameAudio.bgm.audioPlayer;
    }
    autoDispose('backgroundMusic', () => player.stop());
    autoDispose('backgroundMusic_fadeIn', player.fadeIn(volume, seconds: 3));
  }

  void playDialogAudio(String filename) async {
    final player = await FlameAudio.play(
      filename,
      volume: soundboard.masterVolume,
    );
    autoDispose('playDialogAudio', () => player.stop());
  }

  void pressFireToStart() => add(PressFireToStart());

  void scaleTo(Component it, double scale, double duration, Curve? curve) {
    it.add(
      ScaleEffect.to(
        Vector2.all(scale.toDouble()),
        EffectController(duration: duration.toDouble(), curve: curve ?? Curves.decelerate),
      ),
    );
  }

  void subtitles(String text, double? autoClearSeconds, {String? image, String? audio}) {
    if (audio != null) playDialogAudio(audio);
    add(SubtitlesComponent(text, autoClearSeconds, image));
  }

  BitmapText textXY(String text, double x, double y, [Anchor anchor = Anchor.center, double scale = 1]) =>
      this.text(text: text, position: Vector2(x, y), anchor: anchor, scale: scale);

  BitmapText text({
    required String text,
    Vector2? position,
    Anchor? anchor,
    double? scale,
  }) {
    final it = BitmapText(
      text: text,
      position: position,
      anchor: anchor ?? Anchor.center,
      font: font,
      scale: scale ?? 1,
    );
    add(it);
    return it;
  }
}

extension on AudioPlayer {
  StreamSubscription fadeIn(double targetVolume, {double seconds = 3}) {
    final steps = (seconds * 10).toInt();
    return Stream.periodic(const Duration(milliseconds: 100), (it) => targetVolume * it / steps)
        .take(steps)
        .listen((it) => setVolume(it), onDone: () => setVolume(targetVolume));
  }
}
