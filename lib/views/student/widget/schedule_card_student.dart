import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleCardStudent extends StatelessWidget {
  final ScheduleModel schedule;

  const ScheduleCardStudent({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject & Teacher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Guru: ${schedule.teacherName}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            // Day & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hari: ${schedule.day}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                Text(
                  "Jam: ${timeFormat.format(schedule.startTimestamp!)} - ${timeFormat.format(schedule.endTimestamp!)}",
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
