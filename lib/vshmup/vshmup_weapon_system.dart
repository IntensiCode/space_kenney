import 'package:signals_core/signals_core.dart';

enum VShmupWeaponKind {
  cluster_bomb(maxAvail: 30, coolDown: 0.5),
  energy_gun(maxAvail: 10000, maxHeat: 1000),
  homing_missile(maxAvail: 30, coolDown: 0.5),
  laser_blaster(maxAvail: 10000, maxHeat: 500),
  mini_gun(maxAvail: 1000, coolDown: 0.1),
  mining_laser(maxAvail: 0),
  multi_missile(maxAvail: 80, coolDown: 0.5),
  ;

  const VShmupWeaponKind({required this.maxAvail, this.maxHeat, this.coolDown});

  final double maxAvail;
  final double? maxHeat;
  final double? coolDown;
}

class VShmupWeaponState {
  double available = 0;
  double heat = 0;
  double coolDown = 0;
}

class VShmupWeaponSystem {
  VShmupWeaponSystem() {
    activeWeapon = VShmupWeaponKind.energy_gun;
    restock(VShmupWeaponKind.energy_gun, 8000);
    restock(VShmupWeaponKind.mining_laser);
  }

  List<(VShmupWeaponKind, VShmupWeaponState?)> display() =>
      VShmupWeaponKind.values.map((it) => (it, available[it])).toList();

  void restock(VShmupWeaponKind kind, [double? amount]) {
    available[kind] ??= VShmupWeaponState();
    if (amount != null) available[kind]!.available += amount;
  }

  final available = <VShmupWeaponKind, VShmupWeaponState>{};

  final _activeWeapon = signal(VShmupWeaponKind.energy_gun);

  VShmupWeaponKind get activeWeapon => _activeWeapon.value;

  set activeWeapon(VShmupWeaponKind it) => _activeWeapon.value = it;
}
