import 'package:flutter/foundation.dart';

/// Admin modu yöneticisi.
///
/// Admin modu aktifken [ControlLockOverlay] Bluetooth bağlantı
/// kilidini (disconnected / connecting) atlar; joystick serbest kalır.
/// Otonom mod kilidi etkilenmez — o ayrı bir güvenlik katmanıdır.
///
/// Mod uygulama yeniden başlatıldığında otomatik olarak sıfırlanır
/// (kalıcı değil — kasıtlı).
class AdminController {
  AdminController._();
  static final AdminController instance = AdminController._();

  final ValueNotifier<bool> isAdmin = ValueNotifier(false);

  void setAdmin(bool value) {
    isAdmin.value = value;
  }

  void toggle() {
    isAdmin.value = !isAdmin.value;
  }
}
