import 'package:flutter/foundation.dart';

/// Otonom / manuel mod durumu — sürüş joystick kilidi için paylaşılır.
class AutonomyController {
  AutonomyController._();
  static final AutonomyController instance = AutonomyController._();

  final ValueNotifier<bool> isAuto = ValueNotifier(false);

  void setAuto(bool value) {
    isAuto.value = value;
  }
}
