import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/agv_telemetry.dart';
import 'agv_native_bridge.dart';

/// AGV telemetri akışını dinleyip parse eden ve UI'yı [AgvTelemetry]
/// olarak ~15 Hz throttle ile besleyen singleton servis.
///
/// - Native [AgvNativeBridge.telemetryEvents] stream'ini dinler.
/// - [AgvTelemetryParser] ile her satırı parse eder ve önceki state
///   üzerine merge eder (firmware her satırda tüm alanları göndermese de
///   UI tutarlı kalır).
/// - UI rebuild oranını sınırlamak için en az 66 ms aralıkla yayın yapar.
class TelemetryController {
  TelemetryController._();
  static final TelemetryController instance = TelemetryController._();

  /// UI maksimum güncelleme oranı (~15 Hz).
  static const Duration _uiThrottle = Duration(milliseconds: 66);

  /// Son veri üzerinden bu süre geçince "veri yok" kabul edilir.
  static const Duration _staleThreshold = Duration(seconds: 3);

  final ValueNotifier<AgvTelemetry> telemetry = ValueNotifier(
    AgvTelemetry.empty,
  );

  /// Son telemetri varış zamanı (epoch ms).
  final ValueNotifier<int?> lastUpdateMs = ValueNotifier(null);

  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _staleTimer;

  AgvTelemetry _pending = AgvTelemetry.empty;
  bool _hasPending = false;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _flushTimer;

  /// Test/mock için geçici stream sağlayıcısı. Set edildiğinde
  /// native stream yerine bu kullanılır.
  Stream<Map<String, dynamic>>? mockStream;

  void init() {
    _sub?.cancel();
    final stream = mockStream ?? AgvNativeBridge.telemetryEvents;
    _sub = stream.listen(
      _onLine,
      onError: (Object e) {
        debugPrint('Telemetri stream hatası: $e');
      },
    );

    _staleTimer?.cancel();
    _staleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkStale();
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _staleTimer?.cancel();
    _staleTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void _onLine(Map<String, dynamic> event) {
    final line = event['line'] as String?;
    if (line == null || line.isEmpty) return;

    final parsed = AgvTelemetryParser.parseLine(line);
    if (parsed == null) return;

    final ts = (event['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    final enriched = parsed.copyWith(timestampMs: ts);
    _pending = telemetry.value.merge(enriched);
    _hasPending = true;
    lastUpdateMs.value = ts;

    final now = DateTime.now();
    if (now.difference(_lastEmit) >= _uiThrottle) {
      _flushPending(now);
    } else {
      _flushTimer ??= Timer(_uiThrottle, () {
        _flushTimer = null;
        _flushPending(DateTime.now());
      });
    }
  }

  void _flushPending(DateTime now) {
    if (!_hasPending) return;
    telemetry.value = _pending;
    _hasPending = false;
    _lastEmit = now;
  }

  void _checkStale() {
    final ts = lastUpdateMs.value;
    if (ts == null) return;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > _staleThreshold.inMilliseconds) {
      // Veri eskidi — son değeri koru ama UI bunu lastUpdateMs üzerinden
      // dinleyerek soluklaştırabilir.
    }
  }

  /// Mock provider veya testler için manuel besleme.
  /// Production akışında çağrılmaz — mock telemetri kapatıldığında
  /// otomatik olarak native stream'e geri dönülür.
  void injectLine(String line, {int? timestamp}) {
    _onLine({
      'line': line,
      'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
    });
  }
}
