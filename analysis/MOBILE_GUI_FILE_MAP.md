# Mobil Arayüz Dosya Haritası

**Tarih:** 26 Haziran 2026  
**Kapsam:** `lib/` (32 Dart dosyası) + `android/.../MainActivity.kt`  
**Durum:** Salt analiz — kod değişikliği yapılmamıştır.

---

## 1. Ana Ekran

**Ana kapsayıcı dosya:** `lib/gamepage.dart`

`GamePage` bir `Stack` ile aşağıdaki widget katmanlarını birleştiren ana sahnedir.

| Ekran Öğesi | Dosya | Sınıf / Widget | Notlar |
|---|---|---|---|
| **Arka plan** | `lib/background.dart` | `BackgroundColor` | Radyal dark gradient + ince grid; kamera açıkken gizlenir |
| **Bağlantı durumu chip'i** (sol üst) | `lib/widgets/connection_status_bar.dart` | `ConnectionStatusBar` | Pill chip; accent rengi bağlantı durumuna göre değişir |
| **Batarya / Hız / Sıcaklık** (sağ üst) | `lib/widgets/telemetry_chips.dart` | `TelemetryChips` | Bağlantı barından bağımsız; `TelemetryController` dinler |
| **Manuel / Otonom butonu** | `lib/autonom_button.dart` | `AutonomusButton` | Pill buton; onay diyalogu ile otonom moda geçiş |
| **Senaryo & Harita butonları** | `lib/accesories.dart` | `FeatureButtons` → `_ActionChip` | `onTap: () {}` — placeholder, henüz ekran yok |
| **Ana sürüş joystick'i** (sağ alt) | `lib/joystick.dart` | `Joystick` | 8 yönlü; `ValueNotifier<Offset>` ile sadece knob rebuild |
| **Lift (yukarı/aşağı) joystick'i** (sol-orta alt) | `lib/lift_joystick.dart` | `LiftJoystick` | Dikey eksenle kilitli; `LiftCommandThrottler` |
| **E-Stop butonu** (sağ kenar üst) | `lib/widgets/estop_button.dart` | `EStopButton` | Kırmızı gradient; `HapticFeedback.heavyImpact()` |
| **Bluetooth butonu** (sol toolbar) | `lib/bluetooth_button.dart` | `BluetoothButton` | Cihaz listesi bottom sheet; uzun basış = kes |
| **Buzzer butonu** (sol toolbar alt) | `lib/accesories.dart` | `AccessoryButtons` | Toggle; `B_AC` / `B_KAPA` komutu |
| **Ayarlar butonu** (sol toolbar) | `lib/gamepage.dart` → `lib/agv_settings.dart` | `_ToolbarButton` → `AgvSettingsPage` | Yönlendirme `Navigator.push` ile |
| **Kamera butonu** (sol toolbar) | `lib/gamepage.dart` | `_ToolbarButton` | `isCameraOn` state'ini toggle eder |
| **Kamera görüntüsü** (tam arka plan) | `lib/camera_view.dart` | `CameraView` | MJPEG stream; hardcoded URL `http://192.168.1.100:81/stream` |
| **Joystick kilit overlay'i** | `lib/widgets/control_lock_overlay.dart` | `ControlLockOverlay` | Her iki joystick'i sarar; bağlantı/otonom/admin durumuna göre kilitler |

---

## 2. Bluetooth Bağlantı Yapısı

| Katman | Dosya | Sınıf | Sorumluluk |
|---|---|---|---|
| **UI — Cihaz seçimi** | `lib/bluetooth_button.dart` | `BluetoothButton` | İzin isteği, eşleştirilmiş cihaz listesi, bağlanma/kesme |
| **Dart servis — kanal sarmalayıcı** | `lib/services/agv_native_bridge.dart` | `AgvNativeBridge` | Tek `MethodChannel('agv/native')` + `EventChannel('agv/connection')` + `EventChannel('agv/telemetry')` erişim noktası |
| **Dart servis — bağlantı state'i** | `lib/services/connection_controller.dart` | `ConnectionController` | `ValueNotifier<AgvConnectionState>`; disconnected / connecting / connected / error; exponential-backoff auto-reconnect |
| **Native backend (Kotlin)** | `android/app/src/main/kotlin/com/example/marcotest/MainActivity.kt` | `MainActivity` | SPP `BluetoothSocket`, `OutputStream` gönderimi, `InputStream` reader thread, `EventChannel` event push |

### `AgvConnectionState` değerleri (`connection_controller.dart`)

```
disconnected  →  bağlantı yok / kesildi
connecting    →  bağlanma denemesi sürüyor
connected     →  aktif bağlantı
error         →  bağlantı hatası
```

### Native'den Flutter'a gelen olaylar (`EventChannel('agv/connection')`)

| Event | Tetikleyici |
|---|---|
| `connected` | `btSocket.connect()` başarılı |
| `disconnected` | Kullanıcı kesti veya reader thread IOException |
| `error` | `connectToDevice` exception'ı |

---

## 3. Manuel Kontrol Yapısı

| Öğe | Dosya | Sınıf | Notlar |
|---|---|---|---|
| **Sürüş joystick'i widget'ı** | `lib/joystick.dart` | `Joystick` | `GestureDetector.onPanUpdate` → `JoystickCommandThrottler` |
| **Lift joystick'i widget'ı** | `lib/lift_joystick.dart` | `LiftJoystick` | Yalnızca dikey hareket; `LiftCommandThrottler` |
| **Komut throttle + deadzone** | `lib/services/joystick_command_throttler.dart` | `JoystickCommandThrottler` | 8 yönlü, 40 ms throttle, deadzone, haptic |
| **Lift throttle** | `lib/services/joystick_command_throttler.dart` | `LiftCommandThrottler` | ↑/DUR/↓, 50 ms throttle, haptic |
| **Manuel / Otonom geçiş** | `lib/autonom_button.dart` | `AutonomusButton` | `AutonomyController.instance.setAuto()` + `AgvNativeBridge.setMode()` |
| **Joystick kilit mantığı** | `lib/widgets/control_lock_overlay.dart` | `ControlLockOverlay` | Bağlantı yoksa veya otonom moddaysa `IgnorePointer` + overlay |
| **Joystick boyut ayarı** | `lib/joystick_settings.dart` | `JoystickSettingsView` | `SettingsManager.joystickScaleNotifier` |
| **Native komut eşleme** | `android/.../MainActivity.kt` | `Direction` enum | Flutter idx → AGV komut (`0→sağ:2`, `2→ileri:1` vb.) |

### Komut akışı (özet)

```
Parmak hareketi (onPanUpdate)
  → JoystickCommandThrottler.onOffset()
    → AgvNativeBridge.sendJoystick(dir)
      → MethodChannel('agv/native').invokeMethod('joystick', {dir})
        → Kotlin: Direction.fromFlutterIdx(dir).agvCommand
          → BluetoothSocket.outputStream.write("1\n")  ← Arduino'ya gider
```

---

## 4. Senaryo / Görev Ekranı

| Öğe | Dosya | Sınıf | Durum |
|---|---|---|---|
| **Senaryo butonu (UI)** | `lib/accesories.dart` | `FeatureButtons` → `_ActionChip` (label: `'SENARYO'`) | Var; `onTap: () {}` — placeholder |
| **Senaryo ekranı** | — | — | **Yok** — henüz oluşturulmamış |
| **Görev takip state'i** | — | — | **Yok** — veri modeli tanımlı değil |
| **Görev durumu göstergesi** | — | — | **Yok** |

> **Not:** Senaryo butonu sadece görsel bir chip'tir, tıklandığında hiçbir şey olmaz.

---

## 5. Harita Ekranı

| Öğe | Dosya | Sınıf | Durum |
|---|---|---|---|
| **Harita butonu (UI)** | `lib/accesories.dart` | `FeatureButtons` → `_ActionChip` (label: `'HARİTA'`) | Var; `onTap: () {}` — placeholder |
| **Harita ekranı** | — | — | **Yok** — henüz oluşturulmamış |
| **Harita görüntüleme** | — | — | **Yok** |

> **Not:** Harita butonu da sadece görsel chip, işlevsel değil.

---

## 6. Ortak State / Servis Dosyaları

### 6a. Robot & Bluetooth Bağlantısı

| State | Dosya | Sınıf | Tür |
|---|---|---|---|
| Bağlantı durumu | `lib/services/connection_controller.dart` | `ConnectionController` | `ValueNotifier<AgvConnectionState>` (singleton) |
| Native kanal | `lib/services/agv_native_bridge.dart` | `AgvNativeBridge` | `MethodChannel` + `EventChannel` singleton wrapper |
| Son cihaz adresi | `lib/services/connection_controller.dart` | `ConnectionController.lastDeviceAddress` | `String?` |
| Auto-reconnect flag | `lib/services/connection_controller.dart` | `ConnectionController.autoReconnectEnabled` | `bool` (varsayılan: `false`) |

### 6b. Manuel Mod Bilgisi

| State | Dosya | Sınıf | Tür |
|---|---|---|---|
| Manuel / Otonom modu | `lib/services/autonomy_controller.dart` | `AutonomyController` | `ValueNotifier<bool>` (singleton); `false` = manuel |

### 6c. Telemetri (Batarya / Hız / Sıcaklık)

| State | Dosya | Sınıf | Tür |
|---|---|---|---|
| Canlı telemetri verisi | `lib/services/telemetry_controller.dart` | `TelemetryController` | `ValueNotifier<AgvTelemetry>` (singleton, ~15 Hz throttle) |
| Telemetri veri modeli | `lib/models/agv_telemetry.dart` | `AgvTelemetry` | Immutable model; `batteryPct`, `speedMps`, `temperatureC`, `mode`, `sensors` |
| Telemetri parser | `lib/models/agv_telemetry.dart` | `AgvTelemetryParser` | CSV `key:value` / JSON formatlarını parse eder |
| Mock telemetri | `lib/services/telemetry_mock_provider.dart` | `TelemetryMockProvider` | Timer tabanlı simülatör; Ayarlar → Geliştirici toggle |

### 6d. Admin Modu

| State | Dosya | Sınıf | Tür |
|---|---|---|---|
| Admin modu aktiflik | `lib/services/admin_controller.dart` | `AdminController` | `ValueNotifier<bool>` (singleton); uygulama yeniden açılınca sıfırlanır |

> Admin modu aktifken `ControlLockOverlay` BT kilidini (disconnected/connecting) atlar; otonom kilidi etkilenmez.

### 6e. UI Ayarları & Log

| State | Dosya | Sınıf | Tür |
|---|---|---|---|
| Joystick boyut ölçeği | `lib/agv_settings.dart` | `SettingsManager.joystickScaleNotifier` | `ValueNotifier<double>` |
| Sistem log listesi | `lib/log_manager.dart` | `LogManager.logsNotifier` | `ValueNotifier<List<String>>` |
| Log etkinlik bayrağı | `lib/log_manager.dart` | `LogManager.enabled` | `bool` (statik) |

### 6f. QR / PLC / Fabrika Otomasyon / Görev Durumu

| Alan | Durum |
|---|---|
| QR kod okuma | **Yok** — ne dosya ne model tanımlı |
| PLC / fabrika otomasyon durumu | **Yok** |
| Görev durumu | **Yok** |
| Engel / sensör uyarıları | Veri modeli hazır (`AgvTelemetry.sensors: Map<String,bool>`), ancak firmware bu alanları henüz göndermemektedir |

---

## 7. Tema ve Yeniden Kullanılabilir Widget'lar

| Dosya | İçerik |
|---|---|
| `lib/theme/agv_colors.dart` | Tüm renk token'ları (`AgvColors`) |
| `lib/theme/agv_typography.dart` | `technical` (Rajdhani) / `mono` (JetBrainsMono) / `body` (Inter) stiller |
| `lib/theme/agv_decorations.dart` | `glassPanel`, `solidPanel`, `pill`, `statusChip`, `glow` dekorasyonları |
| `lib/widgets/agv_panel.dart` | `AgvPanel` (bölüm kapsayıcı) + `AgvTile` (liste satırı) |
| `lib/main.dart` | `ThemeData` + uygulama başlangıcı; `ConnectionController.init()` + `TelemetryController.init()` |

---

## 8. Ayarlar Ekranları

| Ekran | Dosya | Sınıf | Erişim |
|---|---|---|---|
| Ana ayarlar | `lib/agv_settings.dart` | `AgvSettingsPage` | Sol toolbar → ayarlar butonu |
| Joystick yapılandırması | `lib/joystick_settings.dart` | `JoystickSettingsView` | Ayarlar ekranından `Navigator.push` |
| Sistem logları | `lib/log_manager.dart` | `LogViewerPage` | Ayarlar ekranından `Navigator.push` |

---

## 9. Genel Dosya Ağacı (özet)

```
lib/
├── main.dart                          # Uygulama giriş; theme; init
├── gamepage.dart                      # ANA EKRAN — tüm widget katmanları
├── background.dart                    # Arka plan gradient + grid
├── autonom_button.dart                # Manuel/Otonom geçiş butonu
├── bluetooth_button.dart              # BT cihaz seçimi + bağlan/kes
├── accesories.dart                    # Buzzer butonu + Senaryo/Harita chip'leri
├── joystick.dart                      # Ana sürüş joystick'i
├── lift_joystick.dart                 # Lift (yukarı/aşağı) joystick'i
├── joystick_settings.dart             # Joystick boyut ayarı ekranı
├── agv_settings.dart                  # Ayarlar ekranı + SettingsManager
├── camera_view.dart                   # MJPEG kamera görüntüsü
├── log_manager.dart                   # Log state + LogViewerPage
│
├── models/
│   └── agv_telemetry.dart             # AgvTelemetry modeli + parser
│
├── services/
│   ├── agv_native_bridge.dart         # MethodChannel + EventChannel erişimi
│   ├── connection_controller.dart     # BT bağlantı state (singleton)
│   ├── autonomy_controller.dart       # Otonom/manuel mod state (singleton)
│   ├── admin_controller.dart          # Admin modu state (singleton)
│   ├── joystick_command_throttler.dart# Sürüş + lift throttle/deadzone
│   ├── telemetry_controller.dart      # Telemetri pipeline (singleton)
│   └── telemetry_mock_provider.dart   # Simüle telemetri (debug)
│
├── theme/
│   ├── agv_colors.dart                # Renk token'ları
│   ├── agv_typography.dart            # Font stilleri
│   └── agv_decorations.dart          # Kutu dekorasyonları
│
└── widgets/
    ├── agv_panel.dart                 # AgvPanel + AgvTile
    ├── connection_status_bar.dart     # Bağlantı durumu chip'i
    ├── telemetry_chips.dart           # Batarya/hız/sıcaklık chip'leri
    ├── estop_button.dart              # E-Stop butonu
    └── control_lock_overlay.dart      # Joystick kilit overlay'i

android/app/src/main/kotlin/com/example/marcotest/
└── MainActivity.kt                    # BT native: socket, okuma thread, EventChannel push
```

---

*Bu dosya sadece analiz amaçlıdır. Son kod değişikliği tarihi: 26 Haziran 2026.*
