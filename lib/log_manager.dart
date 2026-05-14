import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LogManager {
  static final ValueNotifier<List<String>> logsNotifier = ValueNotifier([]);
  static bool enabled = true;

  static void addLog(String message) {
    if (!enabled) return;
    final now = DateTime.now();
    String time = "${now.hour}:${now.minute}:${now.second}";

    List<String> currentLogs = List.from(logsNotifier.value);
    currentLogs.insert(0, "[$time] $message");

    if (currentLogs.length > 100) {
      currentLogs.removeLast();
    }

    logsNotifier.value = currentLogs;
  }

  static void clear() {
    logsNotifier.value = [];
  }
}

// --- ARAYÜZ KISMI (Log Ekranı Buranın İçinde Kalacak) ---
class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Sistem Logları",
          style: TextStyle(fontSize: 18.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => LogManager.clear(),
            tooltip: "Logları Temizle",
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
          child: Column(
            children: [
              // Log Listesi Kutusu
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: LogManager.logsNotifier,
                    builder: (context, logs, child) {
                      if (logs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.white24,
                                size: 40.r,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "Henüz log kaydı yok.",
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(10.r),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 5.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.arrow_right,
                                  color: Colors.greenAccent,
                                  size: 16.r,
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: Text(
                                    logs[index],
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'Courier', // Terminal havası
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "Son 100 işlem gösteriliyor.",
                style: TextStyle(color: Colors.grey[700], fontSize: 10.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
