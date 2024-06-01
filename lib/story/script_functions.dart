import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';

import '../components/press_fire_to_start.dart';
import '../core/common.dart';
import '../core/soundboard.dart';
import '../util/bitmap_button.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/loading.dart';
import 'story_dialog_component.dart';
import 'subtitles_component.dart';

mixin ScriptFunctions on Component {
  double dialogPosition = 8;

  final dialogOffsets = <String, double>{};

  final _handles = <String, dynamic>{};

  void clearByType(List types) {
    dialogPosition = 8;
    final what = types.isEmpty
        ? children
        : children.where((it) => types.contains(it.runtimeType));
    removeAll(what);
  }

  void delay(double seconds) async {
    final millis = (seconds * 1000).toInt();
    await Stream.periodic(Duration(milliseconds: millis)).first;
  }

  StoryDialogComponent dialog(
    String portrait,
    String text, {
    Anchor anchor = Anchor.topLeft,
  }) {
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

  Future<SpriteComponent> image({
    required String filename,
    Vector2? position,
    Anchor? anchor,
  }) async {
    final it = await loadSprite(filename, position: position, anchor: anchor);
    _handles[filename] = it;
    add(it);
    return it;
  }

  void fadeInComponents(List<Component> components) async {
    components.forEach((it) => it.fadeIn());
  }

  void fadeInByType<T extends Component>([bool reset = true]) async {
    children.whereType<T>().forEach((it) => it.fadeIn());
  }

  void fadeOutByFilename(List<String> filenames) {
    for (final it in filenames) {
      final target = _handles[it] as Component?;
      target?.fadeOut();
      target?.add(RemoveEffect(delay: 1));
    }
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
    _handles[text] = it;
    add(it);
    return it;
  }

  final stopAudio = <void Function()>[];

  void music(String filename) async {
    final AudioPlayer player;
    if (dev) {
      player = await FlameAudio.playLongAudio(
        'music_title.mp3',
        volume: soundboard.masterVolume,
      );
    } else {
      player = await FlameAudio.loop(
        'music_title.mp3',
        volume: soundboard.masterVolume,
      );
    }
    stop() => player.stop();
    player.onPlayerComplete.listen((_) => stopAudio.remove(stop));
    stopAudio.add(stop);
  }

  void playAudio(String filename) async {
    final player = await FlameAudio.play(
      filename,
      volume: soundboard.masterVolume,
    );
    stop() => player.stop();
    player.onPlayerComplete.listen((_) => stopAudio.remove(stop));
    stopAudio.add(stop);
  }

  void pressFireToStart() => add(PressFireToStart());

  void addSubtitles({
    required String text,
    double? autoClearSeconds,
    String? image,
  }) {
    add(SubtitlesComponent(text, autoClearSeconds, image));
  }

  @override
  void onRemove() {
    super.onRemove();
    stopAudio.forEach((it) => it());
  }
}
