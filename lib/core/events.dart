import 'package:dart_minilog/dart_minilog.dart';

import 'common.dart';

typedef Event = (String, dynamic);

final _listeners = <void Function(Event)>[];

void showScreen(Screen screen) {
  logInfo('showScreen $screen');
  _listeners.forEach((it) => it(('screen', screen)));
}

void onScreen(void Function(Screen) func) {
  _listeners.add((it) {
    if (it.$1 == 'screen') func(it.$2);
  });
}
