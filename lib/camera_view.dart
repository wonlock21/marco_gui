import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CameraView extends StatelessWidget {
  // IP adresini bu değişkende tutuyoruz
  final String streamUrl;

  const CameraView({super.key, required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Kenarlıklar ve gölgelendirme (Responsive yapıldı)
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.blueAccent, width: 2.w),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      // Mjpeg paketi burada çalışıyor
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Mjpeg(
          isLive: true,
          stream: streamUrl, // Dışarıdan gelen IP buraya giriyor
          // YÜKLENİYORSA:
          loading: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 10.h),
                const Text(
                  "Sinyal Aranıyor...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // HATA VARSA (Bağlanamadıysa):
          error: (context, error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.red, size: 40.r),
                SizedBox(height: 10.h),
                Text(
                  "Bağlantı Yok\nIP: $streamUrl",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
