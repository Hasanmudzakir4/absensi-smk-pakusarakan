import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';

class BarcodePageController {
  final String teacherId;
  final String teacherName;

  BarcodePageController({required this.teacherId, required this.teacherName});

  Future<String?> generateQRCodeForSchedule(
    ScheduleModel schedule,
    DateTime endTime,
  ) async {
    final now = DateTime.now();
    final formattedTime = DateFormat("HH:mm").format(now);
    final formattedDate = DateFormat("dd-MM-yyyy").format(now);

    final data = {
      "teacher": teacherName,
      "subject": schedule.subject,
      "day": schedule.day,
      "time": formattedTime,
      "date": formattedDate,
      "status": "Hadir",
      "scheduleId": schedule.id,
      "createdAt": FieldValue.serverTimestamp(),
      "expiredAt": Timestamp.fromDate(endTime),
    };

    // Membuat referensi dokumen di Firestore tanpa parameter ID
    final qrRef = FirebaseFirestore.instance.collection("qr_codes").doc();

    // Menyimpan data ke Firestore dengan ID yang dihasilkan oleh Firestore
    await qrRef.set({
      ...data,
      "id": qrRef.id, // Menggunakan ID yang dihasilkan Firestore
    });

    // Kembalikan ID yang dihasilkan Firestore
    return qrRef.id;
  }

  Future<ScheduleModel?> fetchActiveSchedule() async {
    final now = DateTime.now();
    final today = DateFormat('EEEE', 'id_ID').format(now);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('teacherId', isEqualTo: teacherId)
              .where('day', isEqualTo: today)
              .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final schedule = ScheduleModel.fromMap(data, doc.id);
        final timeRange = data['time']?.split(" - ");
        if (timeRange == null || timeRange.length != 2) continue;

        final start = DateFormat("HH:mm").parse(timeRange[0]);
        final end = DateFormat("HH:mm").parse(timeRange[1]);

        final startTime = DateTime(
          now.year,
          now.month,
          now.day,
          start.hour,
          start.minute,
        );
        final endTime = DateTime(
          now.year,
          now.month,
          now.day,
          end.hour,
          end.minute,
        );

        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          return schedule;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching active schedule: $e");
      }
    }

    return null;
  }
}
