/// Görev, QR, fabrika otomasyon ve kontrol modu anlık durum modeli.
class AgvMissionState {
  // ─── Görev ──────────────────────────────────────────────────────────────
  final String? missionId;
  final String? routeFrom;
  final String? routeTo;
  final MissionStatus missionStatus;
  final String? nextStep;

  // ─── QR ─────────────────────────────────────────────────────────────────
  final String? lastQrCode;
  final ValidateStatus qrValidation;
  final ValidateStatus locationValidation;

  // ─── Fabrika Otomasyon ───────────────────────────────────────────────────
  final bool plcConnected;
  final DoorPermission doorPermission;
  final String? plcLastMessage;

  // ─── Mod ve Kontrol ──────────────────────────────────────────────────────
  final PhysicalMode physicalMode;
  final RemoteControl remoteControl;

  // ─── Sistem mesajı ───────────────────────────────────────────────────────
  /// Son sistem olayı mesajı (E-Stop, QR, kapı izni, görev olayları...).
  final String? lastSystemMessage;

  const AgvMissionState({
    this.missionId,
    this.routeFrom,
    this.routeTo,
    this.missionStatus = MissionStatus.idle,
    this.nextStep,
    this.lastQrCode,
    this.qrValidation = ValidateStatus.waiting,
    this.locationValidation = ValidateStatus.waiting,
    this.plcConnected = false,
    this.doorPermission = DoorPermission.waiting,
    this.plcLastMessage,
    this.physicalMode = PhysicalMode.manual,
    this.remoteControl = RemoteControl.locked,
    this.lastSystemMessage,
  });

  static const AgvMissionState initial = AgvMissionState(
    missionId: 'MSN-0042',
    routeFrom: 'A2',
    routeTo: 'B3',
    missionStatus: MissionStatus.idle,
    nextStep: 'Alma Noktasına Git',
    lastQrCode: 'QA2.1',
    qrValidation: ValidateStatus.waiting,
    locationValidation: ValidateStatus.waiting,
    plcConnected: false,
    doorPermission: DoorPermission.waiting,
    plcLastMessage: 'Geçiş izni bekleniyor',
    physicalMode: PhysicalMode.manual,
    remoteControl: RemoteControl.active,
    lastSystemMessage: 'Sistem hazır',
  );

  AgvMissionState copyWith({
    String? missionId,
    String? routeFrom,
    String? routeTo,
    MissionStatus? missionStatus,
    String? nextStep,
    String? lastQrCode,
    ValidateStatus? qrValidation,
    ValidateStatus? locationValidation,
    bool? plcConnected,
    DoorPermission? doorPermission,
    String? plcLastMessage,
    PhysicalMode? physicalMode,
    RemoteControl? remoteControl,
    String? lastSystemMessage,
  }) {
    return AgvMissionState(
      missionId: missionId ?? this.missionId,
      routeFrom: routeFrom ?? this.routeFrom,
      routeTo: routeTo ?? this.routeTo,
      missionStatus: missionStatus ?? this.missionStatus,
      nextStep: nextStep ?? this.nextStep,
      lastQrCode: lastQrCode ?? this.lastQrCode,
      qrValidation: qrValidation ?? this.qrValidation,
      locationValidation: locationValidation ?? this.locationValidation,
      plcConnected: plcConnected ?? this.plcConnected,
      doorPermission: doorPermission ?? this.doorPermission,
      plcLastMessage: plcLastMessage ?? this.plcLastMessage,
      physicalMode: physicalMode ?? this.physicalMode,
      remoteControl: remoteControl ?? this.remoteControl,
      lastSystemMessage: lastSystemMessage ?? this.lastSystemMessage,
    );
  }
}

enum MissionStatus {
  loaded,    // Yüklü Hareket
  unloaded,  // Yüksüz Hareket
  idle,      // Beklemede
  error,     // Hata / Güvenli Duruş
}

enum ValidateStatus {
  ok,       // Doğrulandı
  waiting,  // Bekleniyor
  error,    // Hata
}

enum DoorPermission {
  granted,   // Verildi / Serbest
  waiting,   // Bekleniyor
  denied,    // Reddedildi
}

enum PhysicalMode {
  manual,    // Manuel
  automatic, // Otomatik
}

enum RemoteControl {
  active,  // Aktif
  locked,  // Kilitli
}
