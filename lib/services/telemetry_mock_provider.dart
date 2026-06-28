import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'telemetry_controller.dart';

/// Debug amaçlı mock telemetri üreticisi.
///
/// Gerçek AGV firmware'i henüz telemetri göndermediğinde, dashboard
/// göstergelerinin nasıl davrandığını test etmek için kullanılır.
/// Settings ekranındaki "Mock Telemetri" toggle ile aç/kapanır.
class TelemetryMockProvider {
  TelemetryMockProvider._();
  static final TelemetryMockProvider instance = TelemetryMockProvider._();

  final ValueNotifier<bool> enabled = ValueNotifier(false);

  Timer? _timer;
  double _battery = 87.0;
  double _speed = 0.0;
  String _mode = 'M';
  int _tick = 0;
  final _random = Random();

  /// Saniyede ~5 satır (firmware tipik aralığı).
  static const Duration _interval = Duration(milliseconds: 200);

  void setEnabled(bool value) {
    if (enabled.value == value) return;
    enabled.value = value;
    if (value) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _emit());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _stop();
  }

  void _emit() {
    _tick++;

    // Batarya yavaşça azalır (her 50 tick = 10 sn).
    if (_tick % 50 == 0 && _battery > 5) {
      _battery -= 0.5;
    }

    // Hız hedefini periyodik değiştir, mevcut hızı hedefe yaklaştır (smoothing).

    _speed = 1.23;

    // Mod 10 saniyede bir değişebilir.
    if (_tick % 50 == 0 && _random.nextDouble() < 0.3) {
      _mode = _mode == 'M' ? 'A' : 'M';
    }

    final tempC = 30 + _random.nextDouble() * 4;

    final line =
        'BAT:${_battery.toStringAsFixed(1)},'
        'SPD:${_speed.toStringAsFixed(2)},'
        'MODE:$_mode,'
        'T:${tempC.toStringAsFixed(1)}';

    TelemetryController.instance.injectLine(line);
  }
}
