import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'services/agv_native_bridge.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

/// PID parametrelerini sol ve sağ motor için ayrı ayrı gönderir.
///
/// Gönderim formatı: `{P|I|D}{L|R}{değer}`
/// Örnekler:
///   PR100  → Sağ motor P = 100
///   IL2.5  → Sol motor I = 2.5
///   DL0.01 → Sol motor D = 0.01
class PidSettingsView extends StatefulWidget {
  const PidSettingsView({super.key});

  @override
  State<PidSettingsView> createState() => _PidSettingsViewState();
}

class _PidSettingsViewState extends State<PidSettingsView> {
  final _bridge = AgvNativeBridge.instance;

  // Sol motor controllers
  final _lpCtrl = TextEditingController();
  final _liCtrl = TextEditingController();
  final _ldCtrl = TextEditingController();

  // Sağ motor controllers
  final _rpCtrl = TextEditingController();
  final _riCtrl = TextEditingController();
  final _rdCtrl = TextEditingController();

  // Son gönderilen komut (her satır için ayrı feedback)
  final Map<String, String?> _sentFeedback = {};

  @override
  void dispose() {
    _lpCtrl.dispose();
    _liCtrl.dispose();
    _ldCtrl.dispose();
    _rpCtrl.dispose();
    _riCtrl.dispose();
    _rdCtrl.dispose();
    super.dispose();
  }

  /// `param` = 'P' | 'I' | 'D'
  /// `side`  = 'L' | 'R'
  void _send(String param, String side, TextEditingController ctrl) {
    final raw = ctrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$param değeri boş olamaz.'),
          backgroundColor: AgvColors.danger,
        ),
      );
      return;
    }

    final cmd = '$param$side$raw';
    _bridge.sendAccessory(cmd).catchError((e) {
      debugPrint('PID gönderim hatası: $e');
    });

    setState(() {
      _sentFeedback['$param$side'] = cmd;
    });

    // Feedback 2 saniye sonra temizle
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _sentFeedback.remove('$param$side'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PID AYARLARI')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bilgi kutusu
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AgvColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                    border:
                        Border.all(color: AgvColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AgvColors.info, size: 14.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Format: P/I/D + Taraf (L/R) + Değer  →  PR100 · IL2.5 · DR0.01',
                          style: AgvTypography.mono(
                            size: 9.sp,
                            color: AgvColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // İki motor yan yana
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sol Motor ──────────────────────────────────────────
                    Expanded(
                      child: _MotorPanel(
                        title: 'SOL MOTOR',
                        side: 'L',
                        accent: AgvColors.info,
                        pCtrl: _lpCtrl,
                        iCtrl: _liCtrl,
                        dCtrl: _ldCtrl,
                        feedback: _sentFeedback,
                        onSend: _send,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // ── Sağ Motor ──────────────────────────────────────────
                    Expanded(
                      child: _MotorPanel(
                        title: 'SAĞ MOTOR',
                        side: 'R',
                        accent: AgvColors.accent,
                        pCtrl: _rpCtrl,
                        iCtrl: _riCtrl,
                        dCtrl: _rdCtrl,
                        feedback: _sentFeedback,
                        onSend: _send,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Alt bilgi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: AgvColors.warning, size: 14.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'PID değerleri geçici olarak uygulanır. '
                        'Robot yeniden başlatıldığında varsayılan değerler yüklenir.',
                        style: AgvTypography.caption.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Motor paneli ──────────────────────────────────────────────────────────────

class _MotorPanel extends StatelessWidget {
  final String title;
  final String side;
  final Color accent;
  final TextEditingController pCtrl;
  final TextEditingController iCtrl;
  final TextEditingController dCtrl;
  final Map<String, String?> feedback;
  final void Function(String param, String side, TextEditingController ctrl)
      onSend;

  const _MotorPanel({
    required this.title,
    required this.side,
    required this.accent,
    required this.pCtrl,
    required this.iCtrl,
    required this.dCtrl,
    required this.feedback,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: AgvDecorations.solidPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AgvTypography.technical(
                  size: 10.sp,
                  color: accent,
                  letterSpacing: 1.0,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          _PidRow(
            param: 'P',
            label: 'Oransal (P)',
            ctrl: pCtrl,
            side: side,
            accent: accent,
            feedback: feedback['P$side'],
            onSend: onSend,
          ),
          SizedBox(height: 8.h),
          _PidRow(
            param: 'I',
            label: 'İntegral (I)',
            ctrl: iCtrl,
            side: side,
            accent: accent,
            feedback: feedback['I$side'],
            onSend: onSend,
          ),
          SizedBox(height: 8.h),
          _PidRow(
            param: 'D',
            label: 'Türev (D)',
            ctrl: dCtrl,
            side: side,
            accent: accent,
            feedback: feedback['D$side'],
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

// ── Tekil PID satırı ──────────────────────────────────────────────────────────

class _PidRow extends StatelessWidget {
  final String param;
  final String label;
  final String side;
  final Color accent;
  final TextEditingController ctrl;
  final String? feedback;
  final void Function(String param, String side, TextEditingController ctrl)
      onSend;

  const _PidRow({
    required this.param,
    required this.label,
    required this.ctrl,
    required this.side,
    required this.accent,
    required this.feedback,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiket
        Text(label, style: AgvTypography.tileSubtitle),
        SizedBox(height: 4.h),
        Row(
          children: [
            // Badge
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              alignment: Alignment.center,
              child: Text(
                param,
                style: AgvTypography.technical(
                  size: 11.sp,
                  color: accent,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Giriş alanı
            Expanded(
              child: SizedBox(
                height: 32.h,
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.\-]')),
                  ],
                  textAlign: TextAlign.center,
                  style: AgvTypography.mono(
                    size: 11.sp,
                    color: AgvColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 7.h,
                    ),
                    hintText: '0',
                    hintStyle: AgvTypography.mono(
                      size: 11.sp,
                      color: AgvColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AgvColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide:
                          BorderSide(color: AgvColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide:
                          BorderSide(color: AgvColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.r),
                      borderSide:
                          BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Gönder butonu
            SizedBox(
              height: 32.h,
              child: ElevatedButton(
                onPressed: () => onSend(param, side, ctrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.15),
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Gönder',
                  style: AgvTypography.technical(
                    size: 9.sp,
                    color: accent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Feedback
        if (feedback != null) ...[
          SizedBox(height: 3.h),
          Row(
            children: [
              SizedBox(width: 36.r + 8.w), // badge + gap ile hizala
              Icon(Icons.check_circle_outline,
                  size: 10.r, color: AgvColors.connected),
              SizedBox(width: 3.w),
              Text(
                'Gönderildi: $feedback',
                style: AgvTypography.mono(
                  size: 8.sp,
                  color: AgvColors.connected,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
