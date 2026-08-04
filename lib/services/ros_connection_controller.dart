import 'dart:async';

import 'package:flutter/widgets.dart';

import 'mission_controller.dart';
import 'ros_bridge_client.dart';

/// Wi-Fi/WebSocket ROS kanali. Bluetooth [ConnectionController]'dan bagimsizdir.
class RosConnectionController with WidgetsBindingObserver {
  RosConnectionController._();
  static final RosConnectionController instance = RosConnectionController._();

  final RosBridgeClient client = RosBridgeClient();
  bool _initialized = false;

  ValueNotifier<RosConnectionState> get state => client.state;
  bool get manualModeEnabled => client.manualModeEnabled;
  String get url => client.url;

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    client.onRobotStatus = MissionController.instance.applyRobotStatus;
    client.onMissionEvent = MissionController.instance.postMessage;
  }

  Future<void> connect(String address) => client.connect(address);

  Future<void> disconnect() => client.disconnect();

  Future<Map<String, dynamic>> startMission() async {
    final response = await client.startMission();
    _postResponse(response);
    return response;
  }

  Future<Map<String, dynamic>> submitManualTask({
    required String taskId,
    required String pickupNode,
    required String dropoffNode,
  }) async {
    final response = await client.submitManualTask(
      taskId: taskId,
      pickupNode: pickupNode,
      dropoffNode: dropoffNode,
    );
    _postResponse(response);
    return response;
  }

  Future<Map<String, dynamic>> cancelMission() async {
    final response = await client.cancelMission();
    _postResponse(response);
    return response;
  }

  Future<Map<String, dynamic>> resetMissionSafety() async {
    final response = await client.resetMissionSafety();
    _postResponse(response);
    return response;
  }

  bool publishManualDirection(int direction, {double scale = 1}) =>
      client.publishManualDirection(direction, scale: scale);

  void stopManual() => client.stopManual();

  void _postResponse(Map<String, dynamic> response) {
    MissionController.instance.postMessage(
      response['message']?.toString() ?? 'ROS servis yaniti alindi',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      stopManual();
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
    await client.dispose();
  }
}
