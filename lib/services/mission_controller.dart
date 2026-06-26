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

  /// [AutonomyController.isAuto] değiştiğinde `physicalMode` ve
  /// `remoteControl` alanlarını otomatik senkronize eder.
  void init() {
    AutonomyController.instance.isAuto.addListener(_onAutoChanged);
  }

  void dispose() {
    AutonomyController.instance.isAuto.removeListener(_onAutoChanged);
  }

  void _onAutoChanged() {
    final isAuto = AutonomyController.instance.isAuto.value;
    state.value = state.value.copyWith(
      physicalMode: isAuto ? PhysicalMode.automatic : PhysicalMode.manual,
      remoteControl: isAuto ? RemoteControl.locked : RemoteControl.active,
      lastSystemMessage:
          isAuto ? 'Otomatik moda geçildi' : 'Manuel moda geçildi',
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
