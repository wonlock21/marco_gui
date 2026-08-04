import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../log_manager.dart';
import 'agv_native_bridge.dart';
import 'ros_connection_controller.dart';

/// 8 yönlü sürüş joystick'i için throttle + deadzone + native gönderim.
class JoystickCommandThrottler {
  JoystickCommandThrottler({
    AgvNativeBridge? bridge,
    this.sendIntervalMs = 40,
    Map<int, String>? labels,
  }) : _bridge = bridge ?? AgvNativeBridge.instance,
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
        LogManager.lastJoyCmdNotifier.value = '0';
        _bridge.sendJoystick(-1).catchError((Object e) {
          debugPrint('Joystick Native Hata: $e');
        });
        RosConnectionController.instance.stopManual();
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
    LogManager.lastJoyCmdNotifier.value = logMsg.split(':').last; // sadece sayı

    _bridge.sendJoystick(direction).catchError((Object e) {
      debugPrint('Joystick Native Hata: $e');
    });
    RosConnectionController.instance.publishManualDirection(direction);
  }

  void reset() {
    _lastDir = 999;
    _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Dikey lift joystick'i için throttle + deadzone + native gönderim.
class LiftCommandThrottler {
  LiftCommandThrottler({AgvNativeBridge? bridge, this.sendIntervalMs = 50})
    : _bridge = bridge ?? AgvNativeBridge.instance;

  final AgvNativeBridge _bridge;
  final int sendIntervalMs;

  // Flutter→Kotlin index'leri enum ile eşleşiyor:
  // 8 = LIFT_UP  → AGV "9"
  // 9 = LIFT_DOWN → AGV "10"
  // 10 = LIFT_STOP → AGV "11"
  static const _liftLabels = {
    8: 'LIFT_YUKARI:9',
    9: 'LIFT_ASAGI:10',
    10: 'LIFT_DUR:11',
  };

  int _lastCommand = 10; // başlangıç: LIFT_STOP
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);

  void onOffset(Offset offset, {required double deadZone}) {
    if (offset.dy.isNaN || offset.dx.isNaN || deadZone.isNaN) {
      debugPrint('Lift: NaN değer algılandı, gönderim atlanıyor');
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastSend).inMilliseconds < sendIntervalMs) {
      return;
    }

    if (offset.distance < deadZone) {
      if (_lastCommand != 10) {
        _lastCommand = 10;
        _lastSend = now;
        HapticFeedback.mediumImpact();
        LogManager.addLog(_liftLabels[10]!);
        LogManager.lastLiftCmdNotifier.value = 'DUR(11)';
        _bridge.sendLift(10).catchError((Object e) {
          debugPrint('Lift DUR komutu hatası: $e');
        });
      }
      return;
    }

    // Yukarı = dy negatif → flutterIdx 8 (LIFT_UP)
    // Aşağı = dy pozitif → flutterIdx 9 (LIFT_DOWN)
    final currentCommand = offset.dy < 0 ? 8 : 9;

    if (currentCommand == _lastCommand) return;

    _lastCommand = currentCommand;
    _lastSend = now;
    HapticFeedback.mediumImpact();
    final label = _liftLabels[currentCommand]!;
    LogManager.addLog(label);
    LogManager.lastLiftCmdNotifier.value = currentCommand == 8
        ? 'YUKARI(9)'
        : 'ASAGI(10)';
    _bridge.sendLift(currentCommand).catchError((Object e) {
      debugPrint('Lift komutu hatası: $e');
    });
  }

  void reset() {
    _lastCommand = 10;
    _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// Yatay lift (sağ/sol) joystick'i için throttle + deadzone + native gönderim.
class LiftSideCommandThrottler {
  LiftSideCommandThrottler({AgvNativeBridge? bridge, this.sendIntervalMs = 50})
    : _bridge = bridge ?? AgvNativeBridge.instance;

  final AgvNativeBridge _bridge;
  final int sendIntervalMs;

  // 11 = LIFT_RIGHT → AGV "17"
  // 12 = LIFT_LEFT  → AGV "18"
  // 13 = LIFT_SIDE_STOP → AGV "19"
  static const _labels = {
    11: 'LIFT_SAG:17',
    12: 'LIFT_SOL:18',
    13: 'LIFT_YAN_DUR:19',
  };

  int _lastCommand = 13;
  DateTime _lastSend = DateTime.fromMillisecondsSinceEpoch(0);

  void onOffset(Offset offset, {required double deadZone}) {
    if (offset.dy.isNaN || offset.dx.isNaN || deadZone.isNaN) {
      debugPrint('LiftSide: NaN değer algılandı, gönderim atlanıyor');
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastSend).inMilliseconds < sendIntervalMs) {
      return;
    }

    if (offset.distance < deadZone) {
      if (_lastCommand != 13) {
        _lastCommand = 13;
        _lastSend = now;
        HapticFeedback.mediumImpact();
        LogManager.addLog(_labels[13]!);
        LogManager.lastLiftCmdNotifier.value = 'YAN_DUR(19)';
        _bridge.sendLift(13).catchError((Object e) {
          debugPrint('Lift yan DUR komutu hatası: $e');
        });
      }
      return;
    }

    // Sağ = dx pozitif → 11 → "17"
    // Sol = dx negatif → 12 → "18"
    final currentCommand = offset.dx > 0 ? 11 : 12;

    if (currentCommand == _lastCommand) return;

    _lastCommand = currentCommand;
    _lastSend = now;
    HapticFeedback.mediumImpact();
    LogManager.addLog(_labels[currentCommand]!);
    LogManager.lastLiftCmdNotifier.value = currentCommand == 11
        ? 'SAG(17)'
        : 'SOL(18)';
    _bridge.sendLift(currentCommand).catchError((Object e) {
      debugPrint('Lift yan komutu hatası: $e');
    });
  }

  void reset() {
    _lastCommand = 13;
    _lastSend = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
