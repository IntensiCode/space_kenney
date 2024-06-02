import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'core/common.dart';
import 'core/events.dart';
import 'splash_screen.dart';
import 'title_screen.dart';
import 'tutorial/tutorial_intro.dart';

class GameWorld extends World {
  int chapter = 1;

  @override
  void onLoad() {
    onScreen(_showScreen);
  }

  void _showScreen(Screen it) {
    logInfo(it);
    switch (it) {
      case Screen.game:
        showGame();
      case Screen.tutorial:
        showTutorial();
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
    showTutorial();
  }

  void nextChapter() {
    if (chapter < 1) chapter++;
    showTutorial();
  }

  void showTutorial() {
    removeAll(children);
    add(TutorialIntro());
  }

  void showGame() {
    removeAll(children);
    // add(Intro1());
  }
}
