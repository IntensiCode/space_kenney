import 'package:flame/components.dart';

import '../util/auto_dispose.dart';

extension ComponentExtension on Component {
  Messaging get messaging {
    Component? probed = this;
    while (probed is! Messaging) {
      probed = probed?.parent;
      if (probed == null) throw StateError('no messaging found');
    }
    return probed;
  }
}

mixin Messaging on Component {
  final listeners = <String, List<Function((String, dynamic))>>{};

  Disposable listen(String key, void Function((String, dynamic)) callback) {
    listeners[key] ??= [];
    listeners[key]!.add(callback);
    return Disposable.wrap(() => listeners[key]?.remove(callback));
  }

  void send(String key, dynamic message) => send_((key, message));

  void send_((String, dynamic) message) => listeners[message.$1]?.forEach((it) => it(message));

  @override
  void onRemove() => listeners.clear();
}
