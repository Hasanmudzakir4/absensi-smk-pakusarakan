import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Widget Kartu Jadwal
class ScheduleCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final String subject;
  final String className;

  const ScheduleCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.className,
  });
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: Colors.blue.shade800),
              title: Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("Kelas : $className"),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Jam: ${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
