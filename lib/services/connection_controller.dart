import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'agv_native_bridge.dart';

enum AgvConnectionStatus { disconnected, connecting, connected, error }

class AgvConnectionState {
  final AgvConnectionStatus status;
  final String? message;
  final String? deviceAddress;

  const AgvConnectionState({
    required this.status,
    this.message,
    this.deviceAddress,
  });

  bool get isConnected => status == AgvConnectionStatus.connected;
  bool get isConnecting => status == AgvConnectionStatus.connecting;

  AgvConnectionState copyWith({
    AgvConnectionStatus? status,
    String? message,
    String? deviceAddress,
  }) {
    return AgvConnectionState(
      status: status ?? this.status,
      message: message ?? this.message,
      deviceAddress: deviceAddress ?? this.deviceAddress,
    );
  }

  static const disconnected = AgvConnectionState(
    status: AgvConnectionStatus.disconnected,
  );
}

/// Global Bluetooth bağlantı durumu ve auto-reconnect yönetimi.
class ConnectionController {
  ConnectionController._();
  static final ConnectionController instance = ConnectionController._();

  final ValueNotifier<AgvConnectionState> state = ValueNotifier(
    AgvConnectionState.disconnected,
  );

  bool autoReconnectEnabled = false;
  String? lastDeviceAddress;

  final _bridge = AgvNativeBridge.instance;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manualDisconnect = false;

  void init() {
    _eventSub?.cancel();
    _eventSub = AgvNativeBridge.connectionEvents.listen(
      _onNativeEvent,
      onError: (Object error) {
        _setState(
          AgvConnectionStatus.error,
          message: error.toString(),
        );
      },
    );
  }

  void dispose() {
    _cancelReconnectTimer();
    _eventSub?.cancel();
    _eventSub = null;
  }

  void _onNativeEvent(Map<String, dynamic> event) {
    final type = event['event'] as String?;
    switch (type) {
      case 'connected':
        _reconnectAttempt = 0;
        _cancelReconnectTimer();
        _manualDisconnect = false;
        final address = event['address'] as String?;
        if (address != null) lastDeviceAddress = address;
        _setState(
          AgvConnectionStatus.connected,
          deviceAddress: lastDeviceAddress,
        );
      case 'disconnected':
        final reason = event['reason'] as String?;
        _setState(
          AgvConnectionStatus.disconnected,
          message: reason,
        );
        if (!_manualDisconnect) {
          _scheduleReconnect();
        }
      case 'error':
        final message = event['message'] as String? ?? 'Bağlantı hatası';
        _setState(AgvConnectionStatus.error, message: message);
        if (!_manualDisconnect) {
          _scheduleReconnect();
        }
    }
  }

  void _setState(
    AgvConnectionStatus status, {
    String? message,
    String? deviceAddress,
  }) {
    state.value = AgvConnectionState(
      status: status,
      message: message,
      deviceAddress: deviceAddress ?? state.value.deviceAddress,
    );
  }

  Future<void> connect(String address) async {
    lastDeviceAddress = address;
    _manualDisconnect = false;
    _setState(AgvConnectionStatus.connecting, deviceAddress: address);

    try {
      await _bridge.connect(address);
    } catch (e) {
      _setState(AgvConnectionStatus.error, message: e.toString());
      if (autoReconnectEnabled) _scheduleReconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _cancelReconnectTimer();
    _reconnectAttempt = 0;

    try {
      await _bridge.disconnect();
    } catch (_) {
      // Native kapatma hatası olsa bile UI güncellenir.
    }

    _setState(AgvConnectionStatus.disconnected, message: 'Bağlantı kesildi');
  }

  void _scheduleReconnect() {
    if (!autoReconnectEnabled || lastDeviceAddress == null) return;
    if (_reconnectTimer?.isActive ?? false) return;

    final delaySeconds = min(30, pow(2, _reconnectAttempt).toInt());
    _reconnectAttempt++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (lastDeviceAddress == null || _manualDisconnect) return;
      try {
        await connect(lastDeviceAddress!);
      } catch (_) {
        // Hata native event veya catch ile işlenir.
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}
