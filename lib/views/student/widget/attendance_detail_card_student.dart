import 'package:flutter/material.dart';

class AttendanceDetailCardStudent extends StatelessWidget {
  final String date;
  final String day;
  final String timeIn;
  final String subject;
  final String teacher;
  final String status;
  final String scheduleId;

  const AttendanceDetailCardStudent({
    super.key,
    required this.day,
    required this.date,
    required this.timeIn,
    required this.subject,
    required this.teacher,
    required this.status,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'hadir':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'tidak hadir':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      case 'sakit':
        statusIcon = Icons.healing;
        statusColor = Colors.orange;
        break;
      case 'izin':
        statusIcon = Icons.info;
        statusColor = Colors.blue;
        break;
      default:
        statusIcon = Icons.help;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Guru: $teacher",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Icon(statusIcon, color: statusColor, size: 28),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hari/ Tanggal: $day, $date",
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                Text(
                  "Jam: $timeIn",
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
