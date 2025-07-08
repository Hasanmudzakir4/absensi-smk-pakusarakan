import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String? subject;
  final String? time;
  final bool hasSchedule; // tambahkan ini

  const StatusCard({
    super.key,
    this.subject,
    this.time,
    required this.hasSchedule, // wajib diisi
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAbsen =
        subject != null &&
        subject!.isNotEmpty &&
        time != null &&
        time!.isNotEmpty;

    String statusText;
    Color statusColor;
    Color backgroundColor;

    if (!hasSchedule) {
      statusText = "📌 Tidak ada kelas hari ini";
      statusColor = Colors.grey;
      backgroundColor = Colors.grey.shade200;
    } else if (hasAbsen) {
      statusText = "✅ Terakhir Absen: $time - $subject";
      statusColor = Colors.green;
      backgroundColor = Colors.green.shade50;
    } else {
      statusText = "❗ Belum absen hari ini";
      statusColor = Colors.orange;
      backgroundColor = Colors.orange.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Status Kehadiran",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
