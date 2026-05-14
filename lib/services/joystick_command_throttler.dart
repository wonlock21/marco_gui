import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../log_manager.dart';
import 'agv_native_bridge.dart';

/// 8 yönlü sürüş joystick'i için throttle + deadzone + native gönderim.
class JoystickCommandThrottler {
  JoystickCommandThrottler({
    AgvNativeBridge? bridge,
    this.sendIntervalMs = 40,
    Map<int, String>? labels,
  })  : _bridge = bridge ?? AgvNativeBridge.instance,
        _labels = labels ?? _defaultLabels;

  final AgvNativeBridge _bridge;
  final int sendIntervalMs;
  final Map<int, String> _labels;

  int _lastDir = 999;
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);

  static const _defaultLabels = {
    -1: 'DUR:0',
    0: 'SAĞ:2',
    1: 'SAĞ_İLERİ:12',
    2: 'İLERİ:1',
    3: 'SOL_İLERİ:41',
    4: 'SOL:4',
    5: 'SOL_GERİ:34',
    6: 'GERİ:3',
    7: 'SAĞ_GERİ:23',
  };

  void onOffset(Offset offset, {required double deadZone}) {
    if (offset.distance < deadZone) {
      if (_lastDir != -1) {
        _lastDir = -1;
        HapticFeedback.mediumImpact();
        LogManager.addLog(_labels[-1]!);
        _bridge.sendJoystick(-1).catchError((Object e) {
          debugPrint('Joystick Native Hata: $e');
        });
      }
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastSend).inMilliseconds < sendIntervalMs) {
      return;
    }
    _lastSend = now;

    double angle = atan2(-offset.dy, offset.dx) * 180 / pi;
    if (angle < 0) angle += 360;

    final direction = ((angle + 22.5) / 45).floor() % 8;

    if (direction == _lastDir) return;

    _lastDir = direction;
    HapticFeedback.mediumImpact();
    final logMsg = _labels[direction] ?? 'BİLİNMEYEN:$direction';
    LogManager.addLog(logMsg);

    _bridge.sendJoystick(direction).catchError((Object e) {
      debugPrint('Joystick Native Hata: $e');
    });
  }

  void reset() {
    _lastDir = 999;
    _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Dikey lift joystick'i için throttle + deadzone + native gönderim.
class LiftCommandThrottler {
  LiftCommandThrottler({
    AgvNativeBridge? bridge,
    this.sendIntervalMs = 50,
  }) : _bridge = bridge ?? AgvNativeBridge.instance;

  final AgvNativeBridge _bridge;
  final int sendIntervalMs;

  int _lastCommand = 0;
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);

  void onOffset(Offset offset, {required double deadZone}) {
    if (offset.dy.isNaN ||
        offset.dx.isNaN ||
        deadZone.isNaN) {
      debugPrint('Lift: NaN değer algılandı, gönderim atlanıyor');
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastSend).inMilliseconds < sendIntervalMs) {
      return;
    }

    if (offset.distance < deadZone) {
      if (_lastCommand != 0) {
        _lastCommand = 0;
        _lastSend = now;
        HapticFeedback.mediumImpact();
        _bridge.sendLift(0).catchError((Object e) {
          debugPrint('Lift DUR komutu hatası: $e');
        });
      }
      return;
    }

    final currentCommand = offset.dy < 0 ? 1 : -1;

    if (currentCommand == _lastCommand) return;

    _lastCommand = currentCommand;
    _lastSend = now;
    HapticFeedback.mediumImpact();
    _bridge.sendLift(currentCommand).catchError((Object e) {
      debugPrint('Lift komutu hatası: $e');
    });
  }

  void reset() {
    _lastCommand = 0;
    _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
