import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final String subject;
  final String teacher;

  const ScheduleCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeText = "${_formatTime(startTime)} - ${_formatTime(endTime)}";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.access_time, color: Colors.blue.shade800),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("$timeText | $teacher"),
      ),
    );
  }
}
