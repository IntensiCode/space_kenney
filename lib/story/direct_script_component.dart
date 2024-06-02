import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:space_kenney/story/script_functions.dart';

class DirectScriptComponent extends Component with ScriptFunctions {
  final script = <Future Function()>[];

  StreamSubscription? active;

  void at(double deltaSeconds, Function() execute) {
    script.add(() async {
      final millis = (deltaSeconds * 1000).toInt();
      await Future.delayed(Duration(milliseconds: millis)).then((_) async {
        if (!isMounted) return;
        return await execute();
      });
    });
  }

  StreamSubscription execute() {
    final it = Stream.fromIterable(script).asyncMap((it) async {
      logInfo('execute isMounted=$isMounted $it');
      if (!isMounted) return;
      return await it();
    });
    active = it.listen((it) {});
    return active!;
  }

  @override
  void onRemove() {
    super.onRemove();
    active?.cancel();
    active = null;
  }
}
