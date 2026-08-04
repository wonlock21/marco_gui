import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/agv_mission_state.dart';
import 'autonomy_controller.dart';

/// AGV görev, QR, fabrika otomasyon ve kontrol modu verilerini
/// tek noktadan yöneten singleton servis.
class MissionController {
  MissionController._();
  static final MissionController instance = MissionController._();

  final ValueNotifier<AgvMissionState> state = ValueNotifier(
    AgvMissionState.initial,
  );
  bool _applyingRosStatus = false;

  /// [AutonomyController.isAuto] değiştiğinde `physicalMode` ve
  /// `remoteControl` alanlarını otomatik senkronize eder.
  void init() {
    AutonomyController.instance.isAuto.addListener(_onAutoChanged);
  }

  void dispose() {
    AutonomyController.instance.isAuto.removeListener(_onAutoChanged);
  }

  void _onAutoChanged() {
    if (_applyingRosStatus) return;
    final isAuto = AutonomyController.instance.isAuto.value;
    state.value = state.value.copyWith(
      physicalMode: isAuto ? PhysicalMode.automatic : PhysicalMode.manual,
      remoteControl: isAuto ? RemoteControl.locked : RemoteControl.active,
      lastSystemMessage: isAuto
          ? 'Otomatik moda geçildi'
          : 'Manuel moda geçildi',
    );
  }

  double _number(dynamic value, [double fallback = 0]) =>
      value is num ? value.toDouble() : fallback;

  /// Gercek marco_msgs/msg/RobotStatus rosbridge JSON alanlarini uygular.
  void applyRobotStatus(Map<String, dynamic> status) {
    final poseStamped = status['pose'];
    final poseWithCovariance = poseStamped is Map ? poseStamped['pose'] : null;
    final pose = poseWithCovariance is Map ? poseWithCovariance['pose'] : null;
    final position = pose is Map ? pose['position'] : null;
    final orientation = pose is Map ? pose['orientation'] : null;
    final qx = orientation is Map ? _number(orientation['x']) : 0.0;
    final qy = orientation is Map ? _number(orientation['y']) : 0.0;
    final qz = orientation is Map ? _number(orientation['z']) : 0.0;
    final qw = orientation is Map ? _number(orientation['w'], 1) : 1.0;
    final missionState = (status['mission_state'] as num?)?.toInt() ?? 0;
    final manual = status['manual_mode_enabled'] == true;
    final estop = status['estop_active'] == true;
    final plc = status['plc_connected'] == true;
    final gate = status['gate_permission_granted'] == true;

    _applyingRosStatus = true;
    AutonomyController.instance.setAuto(!manual);
    _applyingRosStatus = false;
    state.value = state.value.copyWith(
      missionId: status['task_id']?.toString() ?? '',
      taskSource: status['task_source']?.toString() ?? '',
      routeFrom: status['pickup_node']?.toString() ?? '',
      routeTo: status['dropoff_node']?.toString() ?? '',
      missionStatus: switch (missionState) {
        1 => MissionStatus.received,
        2 => MissionStatus.unloaded,
        3 => MissionStatus.loaded,
        4 => MissionStatus.waitingPlc,
        5 => MissionStatus.returning,
        6 => MissionStatus.error,
        7 => MissionStatus.estop,
        _ => MissionStatus.idle,
      },
      nextStep: status['next_node']?.toString() ?? '',
      poseX: position is Map ? _number(position['x']) : 0,
      poseY: position is Map ? _number(position['y']) : 0,
      poseYaw: math.atan2(2 * (qw * qz + qx * qy), 1 - 2 * (qy * qy + qz * qz)),
      localizationValid: status['localization_valid'] == true,
      positionCovariance: _number(
        status['position_covariance'],
        double.infinity,
      ),
      currentRouteEdge: status['current_route_edge']?.toString() ?? '',
      crossTrackError: _number(status['cross_track_error'], double.nan),
      obstacleDetected: status['obstacle_detected'] == true,
      lastQrCode: status['last_qr_data']?.toString() ?? '',
      qrValidation: (status['last_qr_data']?.toString().isNotEmpty ?? false)
          ? ValidateStatus.ok
          : ValidateStatus.waiting,
      locationValidation: status['localization_valid'] == true
          ? ValidateStatus.ok
          : ValidateStatus.error,
      plcConnected: plc,
      doorPermission: gate ? DoorPermission.granted : DoorPermission.waiting,
      physicalMode: manual ? PhysicalMode.manual : PhysicalMode.automatic,
      remoteControl: manual ? RemoteControl.active : RemoteControl.locked,
      estopActive: estop,
    );
  }

  // ─── Sistem mesajı ───────────────────────────────────────────────────────

  void postMessage(String message) {
    state.value = state.value.copyWith(lastSystemMessage: message);
  }

  // ─── Görev güncellemeleri ────────────────────────────────────────────────

  void updateMission({
    String? missionId,
    String? routeFrom,
    String? routeTo,
    MissionStatus? status,
    String? nextStep,
    String? message,
  }) {
    state.value = state.value.copyWith(
      missionId: missionId,
      routeFrom: routeFrom,
      routeTo: routeTo,
      missionStatus: status,
      nextStep: nextStep,
      lastSystemMessage: message,
    );
  }

  // ─── QR güncellemeleri ───────────────────────────────────────────────────

  void updateQr({
    String? lastQrCode,
    ValidateStatus? qrValidation,
    ValidateStatus? locationValidation,
    String? message,
  }) {
    state.value = state.value.copyWith(
      lastQrCode: lastQrCode,
      qrValidation: qrValidation,
      locationValidation: locationValidation,
      lastSystemMessage: message,
    );
  }

  // ─── Fabrika otomasyon güncellemeleri ────────────────────────────────────

  void updateFactory({
    bool? plcConnected,
    DoorPermission? doorPermission,
    String? lastMessage,
  }) {
    state.value = state.value.copyWith(
      plcConnected: plcConnected,
      doorPermission: doorPermission,
      plcLastMessage: lastMessage,
      lastSystemMessage: lastMessage,
    );
  }

  // ─── Mod ve kontrol güncellemeleri ───────────────────────────────────────

  void updateControl({
    PhysicalMode? physicalMode,
    RemoteControl? remoteControl,
    String? message,
  }) {
    state.value = state.value.copyWith(
      physicalMode: physicalMode,
      remoteControl: remoteControl,
      lastSystemMessage: message,
    );
  }

  /// E-Stop basıldığında çağrılır.
  void onEmergencyStop() {
    state.value = state.value.copyWith(
      missionStatus: MissionStatus.error,
      remoteControl: RemoteControl.locked,
      lastSystemMessage: 'Güvenli durdurma komutu gönderildi',
    );
  }

  /// Tüm state'i sıfırlar.
  void reset() {
    state.value = AgvMissionState.initial;
  }
}
