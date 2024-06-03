import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'chapter1/chapter1_intro.dart';
import 'chapter1/chapter1_level1.dart';
import 'core/common.dart';
import 'core/events.dart';
import 'splash_screen.dart';
import 'title_screen.dart';

class GameWorld extends World {
  int chapter = 1;

  @override
  void onLoad() => onScreen(_showScreen);

  void _showScreen(Screen it) {
    logInfo(it);
    switch (it) {
      case Screen.chapter1_level1:
        showChapter1Level1();
      case Screen.chapter1:
        showChapter1();
      case Screen.splash:
        showSplash();
      case Screen.title:
        showTitle();
    }
  }

  void showSplash() {
    removeAll(children);
    add(SplashScreen());
  }

  void showTitle() {
    removeAll(children);
    add(TitleScreen());
  }

  void previousChapter() {
    if (chapter > 1) chapter--;
    showChapter1();
  }

  void nextChapter() {
    if (chapter < 1) chapter++;
    showChapter1();
  }

  void showChapter1() {
    removeAll(children);
    add(Chapter1_Intro());
  }

  void showChapter1Level1() {
    removeAll(children);
    add(Chapter1_Level1());
  }
}
