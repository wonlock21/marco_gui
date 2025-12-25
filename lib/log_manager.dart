import 'package:flutter/material.dart';

class LogManager {
  // --- VERİ KISMI ---
  static final ValueNotifier<List<String>> logsNotifier = ValueNotifier([]);

  static void addLog(String message) {
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

  // --- ARAYÜZ (UI) KISMI ---
  // GamePage'den burayı çağıracağız, kod kirliliği yapmayacak.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sistem Logları",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        // Kendi içindeki clear metodunu çağırır
                        clear();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.greenAccent),
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: logsNotifier,
                  builder: (context, logs, child) {
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          child: Text(
                            logs[index],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
