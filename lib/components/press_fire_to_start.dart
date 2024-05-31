import 'package:flame/components.dart';

import '../util/bitmap_text.dart';
import '../util/fonts.dart';

class PressFireToStart extends Component with HasVisibility {
  @override
  void onLoad() {
    add(BitmapText(
      text: 'Press Fire To Start',
      position: Vector2(160, 247),
      anchor: Anchor.center,
      font: fancyFont,
    ));
  }

  double _blinkTm = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _blinkTm += dt;
    if (_blinkTm > 2) _blinkTm -= 2;
    isVisible = _blinkTm < 1;
  }
}
