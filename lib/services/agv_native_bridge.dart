import 'dart:async';

import 'package:flutter/services.dart';

/// Tek noktadan native MethodChannel ve EventChannel erişimi.
class AgvNativeBridge {
  AgvNativeBridge._();
  static final AgvNativeBridge instance = AgvNativeBridge._();

  static const _methodChannel = MethodChannel('agv/native');
  static const _connectionEventChannel = EventChannel('agv/connection');
  static const _telemetryEventChannel = EventChannel('agv/telemetry');

  static Stream<Map<String, dynamic>> get connectionEvents =>
      _connectionEventChannel.receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

  /// AGV'den gelen ham telemetri satırları.
  /// Her event: `{'line': String, 'timestamp': int}`
  static Stream<Map<String, dynamic>> get telemetryEvents =>
      _telemetryEventChannel.receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

  Future<List<dynamic>> getPairedDevices() async {
    final result = await _methodChannel.invokeMethod<List<dynamic>>(
      'getPairedDevices',
    );
    return result ?? [];
  }

  Future<void> connect(String address) {
    return _methodChannel.invokeMethod<void>('connect', {'address': address});
  }

  Future<void> disconnect() {
    return _methodChannel.invokeMethod<void>('disconnect');
  }

  Future<void> sendJoystick(int dir) {
    return _methodChannel.invokeMethod<void>('joystick', {'dir': dir});
  }

  Future<void> sendLift(int action) {
    return _methodChannel.invokeMethod<void>('lift', {'action': action});
  }

  Future<void> setMode(bool isAuto) {
    return _methodChannel.invokeMethod<void>('setMode', {'isAuto': isAuto});
  }

  Future<void> sendAccessory(String cmd) {
    return _methodChannel.invokeMethod<void>('accessory', {'cmd': cmd});
  }

  /// Acil durdurma — AGV protokolünde DUR komutu (`0`).
  Future<void> sendEmergencyStop() {
    return sendJoystick(-1);
  }
}
