import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'theme/agv_colors.dart';
import 'theme/agv_decorations.dart';
import 'theme/agv_typography.dart';

class LogManager {
  static final ValueNotifier<List<String>> logsNotifier = ValueNotifier([]);
  static bool enabled = true;

  static void addLog(String message) {
    if (!enabled) return;
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final currentLogs = List<String>.from(logsNotifier.value);
    currentLogs.insert(0, '[$time] $message');

    if (currentLogs.length > 100) {
      currentLogs.removeLast();
    }

    logsNotifier.value = currentLogs;
  }

  static void clear() {
    logsNotifier.value = [];
  }
}

class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SİSTEM LOGLARI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AgvColors.danger),
            onPressed: () => LogManager.clear(),
            tooltip: 'Logları Temizle',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: AgvDecorations.solidPanel(),
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
                                color: AgvColors.textDisabled,
                                size: 36.r,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Henüz log kaydı yok',
                                style: AgvTypography.caption,
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
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.chevron_right,
                                  color: AgvColors.accent,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    logs[index],
                                    style: AgvTypography.mono(
                                      size: 11.sp,
                                      color: AgvColors.textSecondary,
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
              SizedBox(height: 8.h),
              Text(
                'Son 100 işlem gösteriliyor',
                style: AgvTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
