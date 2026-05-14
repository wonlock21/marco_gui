# MarcoTest AGV Kontrol Uygulaması — Sistem Check-up Raporu

**Tarih:** 14 Mayıs 2026  
**Kapsam:** `lib/` (12 Dart dosyası), `android/.../MainActivity.kt`, `pubspec.yaml`, `AndroidManifest.xml`  
**Durum:** Salt okunur analiz — henüz kod değişikliği yapılmadı.

---

## 1. Proje Özeti

| Alan | Değer |
|------|-------|
| Platform | Flutter (SDK ^3.9.2), Android odaklı |
| Bağımlılıklar | `flutter_mjpeg`, `flutter_screenutil`, `permission_handler` |
| Mimari | Monolitik widget ağacı, `MethodChannel('agv/native')` ile tek yönlü BT iletişimi |
| Ekran | Landscape kilitli, `ScreenUtilInit(designSize: 844×390)` |
| State yönetimi | Dağınık: yerel `setState` + 2 adet `ValueNotifier` (`SettingsManager`, `LogManager`) |

Uygulama, operatörün Bluetooth üzerinden AGV'ye komut gönderdiği, opsiyonel MJPEG kamera akışı izlediği ve joystick/lift/aksesuar kontrolleri sağladığı bir **manuel sürüş paneli** olarak çalışıyor. Otonom mod, harita ve senaryo UI'da yer alıyor ancak büyük ölçüde **iskelet / placeholder** durumunda.

---

## 2. Kritik Bulgular (Öncelik Sırasıyla)

### 🔴 P0 — Bağlantı Kopması Flutter'a Bildirilmiyor

`MainActivity.kt` içinde `sendBluetoothCommand` bir `IOException` yakaladığında `closeConnection()` çağırıyor ancak **Flutter tarafına hiçbir sinyal göndermiyor**. `BluetoothButton.isConnected` true kalıyor; joystick'ler aktif görünüyor; komutlar sessizce düşüyor.

```152:169:android/app/src/main/kotlin/com/example/marcotest/MainActivity.kt
    private fun sendBluetoothCommand(commandStr: String) {
        if (outStream == null || btSocket == null) {
            android.util.Log.w("Bluetooth", "Bluetooth bağlı değil, komut gönderilemedi: $commandStr")
            return
        }
        // ...
        } catch (e: IOException) {
            android.util.Log.e("Bluetooth", "Gönderme hatası: ${e.message}")
            closeConnection()
        }
    }
```

`GamePage` içindeki `onConnectionChanged` callback'i **boş**:

```64:64:lib/gamepage.dart
              child: BluetoothButton(onConnectionChanged: (status) {}),
```

### 🔴 P0 — `accessory` Native Handler Eksik

Flutter'dan `I_AC`, `F_AC`, `B_AC` vb. komutlar `invokeMethod('accessory', ...)` ile gönderiliyor (`agv_settings.dart`, `accesories.dart`) ancak `MainActivity.kt` bu metodu **işlemiyor** — `result.notImplemented()` yoluna düşüyor. Far, fan ve buzzer komutları donanıma ulaşmıyor.

### 🔴 P0 — Joystick `setState` ile Yüksek Frekanslı Rebuild

`Joystick` ve `LiftJoystick` her `onPanUpdate` olayında `setState` çağırıyor. Dokunma olayları saniyede 60–120+ kez tetiklenebilir; throttle yalnızca **native gönderimi** sınırlıyor, **UI rebuild'i sınırlamıyor**.

```132:146:lib/joystick.dart
          onPanUpdate: (details) {
            // ...
            setState(() => offset = next);
            sendToNative(offset);
          },
```

`ValueListenableBuilder` yalnızca joystick ölçeği için kullanılmış; knob pozisyonu hâlâ `setState` ile yönetiliyor.

### 🟠 P1 — Telemetri / Sensör Verisi Yok

AGV'den Flutter'a veri akışı için `EventChannel`, `Stream`, okuma thread'i veya parse katmanı **bulunmuyor**. Endüstriyel AGV GUI'lerinde beklenen batarya, hız, konum, engel sensörü, mod onayı gibi geri bildirimler mevcut değil. Tek yön: Flutter → Kotlin → BT `OutputStream`.

### 🟠 P1 — Kamera Stream Yaşam Döngüsü

`CameraView` `StatelessWidget`; `isCameraOn` false olduğunda widget ağaçtan çıkarılıyor (`gamepage.dart`). `flutter_mjpeg` paketi genelde dispose eder ancak:

- Hardcoded URL: `http://192.168.1.100:81/stream`
- Yeniden bağlanma / backoff yok
- `StatefulWidget` + explicit `dispose` veya `AutomaticKeepAliveClientMixin` stratejisi tanımlı değil
- Kamera açıkken tüm ekranı kaplayan MJPEG decode işi GPU/CPU üzerinde sürekli yük oluşturuyor

### 🟠 P1 — Bluetooth Bağlantısında Timeout Yok

Kotlin `connectToDevice` thread'i `btSocket?.connect()` için socket timeout ayarlamıyor. Flutter tarafında `invokeMethod('connect')` için de süre sınırı yok — cihaz yanıt vermezse `isLoading` true'da kalma riski var (exception path dışında).

### 🟡 P2 — Ayarlar Kalıcı Değil

`SettingsManager.joystickScaleNotifier` ve bağlantı adresi, kamera IP'si vb. **SharedPreferences / secure storage** ile saklanmıyor. Uygulama yeniden açıldığında sıfırlanıyor.

### 🟡 P2 — LogManager Her Komutta Liste Kopyalıyor

```8:19:lib/log_manager.dart
  static void addLog(String message) {
    List<String> currentLogs = List.from(logsNotifier.value);
    currentLogs.insert(0, "[$time] $message");
    logsNotifier.value = currentLogs;
  }
```

Joystick yön değişimlerinde hem native çağrı hem de log listesi kopyası oluşuyor. Log ekranı açık değilken bile çalışıyor.

---

## 3. Kriter Bazlı Detaylı Analiz

### 3.1 Performans ve State Management

| Bileşen | Mevcut Durum | Risk |
|---------|--------------|------|
| `Joystick` knob hareketi | `setState` / pan event | UI thread jank, frame drop |
| `LiftJoystick` | Aynı pattern | Aynı |
| `SettingsManager` | `ValueNotifier<double>` ✅ | İyi örnek, genelleştirilmeli |
| `LogManager` | `ValueNotifier<List>` ✅ | Liste kopyası + joystick log spam |
| `BluetoothButton` | Yerel `setState` | Global state'e yayılmıyor |
| `AutonomusButton` | Yerel `setState` | Bağlantı/mod senkronu yok |
| `AgvSettingsPage` | Yerel `setState` | GamePage aksesuarlarıyla state kopuk |

**Tespit:** Merkezi bir `AgvConnectionController` / `ChangeNotifier` / `Riverpod` provider yok. Her widget kendi `MethodChannel` static referansını tutuyor (6 dosyada tekrar).

**Önerilen hedef mimari (uygulama aşamasında):**
- `ConnectionState` → `ValueNotifier` veya provider (connected / connecting / disconnected / error)
- `JoystickOffset` → `ValueNotifier<Offset>` + `ListenableBuilder` (sadece knob subtree rebuild)
- Telemetri → `EventChannel` + `StreamBuilder` veya throttled `ValueNotifier` (max 10–20 Hz UI güncellemesi)
- Native çağrılar → tek `AgvNativeBridge` servis sınıfı

### 3.2 Bellek Yönetimi ve Donanım Haberleşmesi

| Kaynak | Sorun |
|--------|-------|
| BT `BluetoothSocket` | Kopunca Flutter bilgilendirilmiyor; auto-reconnect yok |
| BT `OutputStream` | `closeConnection` try-catch ile yutuluyor, log dışında izleme yok |
| MJPEG stream | Widget kaldırılınca implicit dispose; retry/backoff yok |
| `MethodChannel` | Her widget'ta duplicate static const |
| Okuma thread'i | Yok — gelen veri buffer'lanmıyor, parse edilmiyor |
| Activity lifecycle | `onDestroy` / `onPause`'da BT kapatma hook'u yok |

**AndroidManifest notu:** `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `INTERNET`, `ACCESS_FINE_LOCATION` tanımlı. `android:usesCleartextTraffic="true"` MJPEG HTTP için gerekli ancak güvenlik notu düşülmeli.

**Eksik native senaryolar:**
- `accessory` handler
- Gelen veri okuma (`InputStream` + coroutine/thread)
- Bağlantı durumu `EventChannel` push
- Periyodik heartbeat / watchdog ping
- `connect` için `socket.connect()` timeout (ör. 10 sn)

### 3.3 UI/UX Modernizasyonu ve Tutarlılık

**Tasarım sistemi eksikliği:** `ThemeData` yalnızca `brightness: dark` + `primarySwatch: blue`. Endüstriyel dashboard token'ları (renk paleti, border, glassmorphism, tipografi) tanımlı değil.

| Sorun | Konum | Detay |
|-------|-------|-------|
| Parlak gradient arka plan | `background.dart` | Mavi–mor gradient; endüstriyel dark konseptine aykırı |
| FAB dağınıklığı | `gamepage.dart` | 3 ayrı `FloatingActionButton.small`, tutarsız renkler (beyaz/kırmızı/gri) |
| Bottom sheet stil kopukluğu | `bluetooth_button.dart` | `backgroundColor: Colors.white` — karanlık temaya zıt |
| Hardcoded konumlar | `gamepage.dart` | `left: 120.w`, `right: 130.w` — küçük ekranlarda çakışma riski |
| Teknik font yok | genel | Yalnızca log ekranında `Courier`; dashboard'da sistem fontu |
| İsimlendirme | `accesories.dart`, `AutonomusButton` | Yazım hataları, profesyonel görünümü düşürüyor |
| Ölü UI | `FeatureButtons` | `onTap: () {}` — Harita/Senaryo tıklanamaz |
| Duplicate kontrol | Settings + GamePage | Far/fan ayarlarda, buzzer oyunda; state senkron değil |
| SafeArea tutarsızlığı | `gamepage.dart` | Joystick ve aksesuarlarda SafeArea yok |
| Kontrast | Otonom buton | Yeşil/kırmızı yarı saydam arka plan kamera üstünde okunabilirlik sorunu |

**ScreenUtil kullanımı:** Genel olarak `.w/.h/.r/.sp` tutarlı; ancak `joystick.dart` içinde shadow değerleri `.r` olmadan sabit (farklı DPI'da orantısız kalabilir).

### 3.4 Görsel Geri Bildirim (Feedback)

| Olay | Mevcut Davranış | Eksik |
|------|-----------------|-------|
| BT bağlanıyor | FAB'da `CircularProgressIndicator` ✅ | Global overlay yok |
| BT bağlandı | Yeşil FAB + SnackBar ✅ | Diğer kontroller hâlâ "bağlı değilmiş" gibi |
| BT koptu (sessiz) | **Hiçbir UI tepkisi yok** | Kırmızı bar, joystick kilidi, mod sıfırlama |
| BT koparıldı (long press) | Turuncu SnackBar ✅ | Sadece manuel |
| Kamera yükleniyor | MJPEG loading widget ✅ | Ana dashboard'da entegre değil |
| Kamera hata | Kırmızı ikon + IP metni ✅ | Retry butonu yok |
| Komut gönderilemedi | `debugPrint` (native) | Operatör görmez |
| Otonom ↔ Manuel | Renk değişimi ✅ | Onay dialogu, bağlantı kontrolü yok |
| E-Stop | **Yok** | Endüstriyel GUI için kritik eksik |

### 3.5 Widget Tree ve Kod Temizliği

**Spagetti / birleştirilmesi gereken dosyalar:**

| Dosya | Satır | Sorun |
|-------|-------|-------|
| `agv_settings.dart` | 240 | `SettingsManager` + settings UI + switch tiles — 3 ayrı modül olmalı |
| `log_manager.dart` | 138 | Logic + `LogViewerPage` UI aynı dosyada |
| `accesories.dart` | 113 | `AccessoryButtons` + `FeatureButtons` — isim dosya adıyla uyuşmuyor |

**Ölü / yarım kod:**
- `FeatureButtons` boş `onTap`
- `AgvSettingsPage` "Uygulama Hakkında" boş `onTap`
- `GamePage.onConnectionChanged` boş callback
- `BluetoothButton._disconnect` yorumda "lazım olursa" — long press ile var ama entegre değil

**Gereksiz wrap:**
- `gamepage.dart` satır 56: `SafeArea(child: const LiftJoystick())` — const child SafeArea içinde anlamsız const optimizasyonu
- `Joystick` → `ValueListenableBuilder` tüm `GestureDetector`'ı sarıyor; scale değişmediğinde bile pan `setState` tüm subtree'yi yeniden kuruyor

**Tekrarlayan kod:**
- 6 dosyada aynı `static const channel = MethodChannel('agv/native')`
- Joystick ve LiftJoystick'de benzer throttle/deadzone/gesture mantığı
- Settings tile dekorasyonları (`Colors.white10`, `BorderRadius.circular(15.r)`) kopyala-yapıştır

**Test altyapısı:** `test/` klasörü yok (yalnızca default flutter_test dev dependency). Widget ve channel mock testi bulunmuyor.

---

## 4. Endüstri Standardı AGV GUI — Ek Gözlemler

Endüstriyel mobil AGV operatör panellerinde (MiR, Omron, GreyOrange, warehouse AGV referansları) tipik olarak bulunan ve bu projede **eksik** olan öğeler:

| Özellik | Durum | Not |
|---------|-------|-----|
| **Acil Durdurma (E-Stop)** | ❌ | Fiziksel veya yazılımsal; en yüksek öncelikli UI elemanı |
| **Bağlantı durumu şeridi** | ❌ | Sürekli görünür telemetry bar |
| **Komut onayı (ACK)** | ❌ | Gönderilen komutun AGV tarafından alındığı teyidi |
| **Hız / yön göstergesi** | ❌ | Joystick strength hesaplanıyor ama gösterilmiyor |
| **Batarya SOC** | ❌ | BT okuma yok |
| **Engel / lidar uyarıları** | ❌ | Sensör pipeline yok |
| **Dead man's switch** | ❌ | Parmak çekilince DUR var ✅ ama bağlantısızken de aktif |
| **Mod kilidi** | ❌ | Otonom modda joystick disable edilmiyor |
| **Yapılandırılabilir endpoint'ler** | ❌ | IP, MAC, komut protokolü hardcoded |
| **Audit / operatör logu** | Kısmi | Sadece lokal, export yok |
| **Çoklu dil / i18n** | ❌ | Türkçe hardcoded stringler |
| **Erişilebilirlik** | ❌ | Semantics, minimum dokunma hedefi (48dp) kontrolü yok |
| **Haptic feedback** | ❌ | Joystick ve E-stop için önerilir |
| **Keep-screen-on** | ❌ | `Wakelock` yok — operasyon sırasında ekran kapanabilir |
| **Versiyon / build bilgisi** | Kısmi | Settings'te "Versiyon 1.0" statik, `pubspec` 0.1.0 |

**Güçlü yanlar (korunmalı):**
- 8 yönlü joystick + deadzone + throttle mantığı sağlam
- `Direction` enum ile Flutter↔AGV komut eşlemesi Kotlin tarafında merkezi
- Lift joystick dikey kilit (`dx = 0`) doğru uygulanmış
- `permission_handler` ile BT izin akışı düşünülmüş
- Landscape + ScreenUtil responsive altyapısı mevcut
- Log ekranı `ValueListenableBuilder` ile doğru pattern

---

## 5. Dosya Bazlı Risk Matrisi

| Dosya | Performans | Bellek/BT | UI/UX | Temizlik | Öncelik |
|-------|-----------|-----------|-------|----------|---------|
| `joystick.dart` | 🔴 | 🟡 | 🟡 | 🟡 | Yüksek |
| `lift_joystick.dart` | 🔴 | 🟡 | 🟢 | 🟡 | Yüksek |
| `bluetooth_button.dart` | 🟢 | 🔴 | 🟠 | 🟡 | Yüksek |
| `MainActivity.kt` | 🟡 | 🔴 | — | 🟠 | Yüksek |
| `gamepage.dart` | 🟡 | 🟠 | 🟠 | 🟡 | Yüksek |
| `camera_view.dart` | 🟠 | 🟠 | 🟡 | 🟢 | Orta |
| `agv_settings.dart` | 🟢 | 🔴 | 🟡 | 🟠 | Orta |
| `accesories.dart` | 🟢 | 🔴 | 🟡 | 🟠 | Orta |
| `autonom_button.dart` | 🟢 | 🟡 | 🟡 | 🟢 | Orta |
| `background.dart` | 🟢 | 🟢 | 🔴 | 🟢 | Düşük |
| `log_manager.dart` | 🟠 | 🟢 | 🟢 | 🟠 | Düşük |
| `main.dart` | 🟢 | 🟢 | 🟠 | 🟢 | Düşük |

---

## 6. Bağımlılık ve Paket Notları

- **`flutter_mjpeg` ^2.0.4:** Bakımı sınırlı community paketi; production'da `media_kit`, platform-native WebView veya RTSP/HTTP snapshot alternatifleri değerlendirilmeli.
- **State management paketi yok:** Proje büyüdükçe `riverpod` veya `flutter_bloc` eklenmesi önerilir.
- **`shared_preferences` yok:** Operatör ayarları için gerekli.
- **`wakelock_plus` yok:** Saha kullanımı için önerilir.

---

## 7. Özet Skor Kartı

| Kriter | Skor (1–5) | Yorum |
|--------|-----------|-------|
| Performans / State | **2/5** | Kritik joystick setState sorunu |
| Bellek / Haberleşme | **2/5** | Tek yön BT, kopma bildirimi yok, accessory eksik |
| UI/UX Tutarlılık | **2.5/5** | İşlevsel ama amatör; tasarım sistemi yok |
| Görsel Feedback | **2/5** | Bağlantı kopması görünmez |
| Kod Temizliği | **3/5** | Küçük proje ama tekrarlar ve ölü kod var |
| Endüstriyel AGV Standartları | **1.5/5** | E-stop, telemetri, ACK, config eksik |

**Genel değerlendirme:** Uygulama prototip / MVP aşamasında işlevsel bir temel sunuyor. Saha operasyonuna çıkmadan önce bağlantı güvenilirliği, operatör geri bildirimi ve performans katmanının yeniden yapılandırılması **kritik**.
