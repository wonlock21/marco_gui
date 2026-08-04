/// Görev, QR, fabrika otomasyon ve kontrol modu anlık durum modeli.
class AgvMissionState {
  // ─── Görev ──────────────────────────────────────────────────────────────
  final String? missionId;
  final String? routeFrom;
  final String? routeTo;
  final MissionStatus missionStatus;
  final String? nextStep;
  final String? taskSource;

  // ─── Lokalizasyon / Navigasyon ─────────────────────────────────────────
  final double poseX;
  final double poseY;
  final double poseYaw;
  final bool localizationValid;
  final double positionCovariance;
  final String? currentRouteEdge;
  final double crossTrackError;
  final bool obstacleDetected;
  final bool estopActive;

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
    this.taskSource,
    this.poseX = 0,
    this.poseY = 0,
    this.poseYaw = 0,
    this.localizationValid = false,
    this.positionCovariance = double.infinity,
    this.currentRouteEdge,
    this.crossTrackError = double.nan,
    this.obstacleDetected = false,
    this.estopActive = false,
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
    String? taskSource,
    double? poseX,
    double? poseY,
    double? poseYaw,
    bool? localizationValid,
    double? positionCovariance,
    String? currentRouteEdge,
    double? crossTrackError,
    bool? obstacleDetected,
    bool? estopActive,
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
      taskSource: taskSource ?? this.taskSource,
      poseX: poseX ?? this.poseX,
      poseY: poseY ?? this.poseY,
      poseYaw: poseYaw ?? this.poseYaw,
      localizationValid: localizationValid ?? this.localizationValid,
      positionCovariance: positionCovariance ?? this.positionCovariance,
      currentRouteEdge: currentRouteEdge ?? this.currentRouteEdge,
      crossTrackError: crossTrackError ?? this.crossTrackError,
      obstacleDetected: obstacleDetected ?? this.obstacleDetected,
      estopActive: estopActive ?? this.estopActive,
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
  received, // Görev alındı
  loaded, // Yüklü Hareket
  unloaded, // Yüksüz Hareket
  waitingPlc, // PLC bekleniyor
  returning, // Başlangıca dönüyor
  idle, // Beklemede
  error, // Hata / Güvenli Duruş
  estop, // Acil stop
}

enum ValidateStatus {
  ok, // Doğrulandı
  waiting, // Bekleniyor
  error, // Hata
}

enum DoorPermission {
  granted, // Verildi / Serbest
  waiting, // Bekleniyor
  denied, // Reddedildi
}

enum PhysicalMode {
  manual, // Manuel
  automatic, // Otomatik
}

enum RemoteControl {
  active, // Aktif
  locked, // Kilitli
}
