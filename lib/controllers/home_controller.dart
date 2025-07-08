import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/schedule_model.dart';

class HomeController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mengambil nama hari ini dalam bahasa Indonesia
  String _getToday() {
    return DateFormat(
      'EEEE',
      'id_ID',
    ).format(DateTime.now()).toLowerCase().trim();
  }

  /// Mengambil jadwal hari ini untuk student berdasarkan kelas dan semester
  Future<List<ScheduleModel>> fetchSchedulesForTodayStudent(
    String studentClass,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('schedules')
              .where('className', isEqualTo: studentClass.trim())
              .get();

      final allSchedules =
          querySnapshot.docs.map((doc) {
            return ScheduleModel.fromMap(doc.data(), doc.id);
          }).toList();

      final today = _getToday();

      // Hanya mengambil jadwal yang sesuai dengan hari ini
      final todaySchedules =
          allSchedules.where((schedule) {
            return schedule.day.toLowerCase().trim() == today;
          }).toList();

      // Urutkan jadwal berdasarkan waktu mulai
      todaySchedules.sort((a, b) {
        if (a.startTimestamp != null && b.startTimestamp != null) {
          return a.startTimestamp!.compareTo(b.startTimestamp!);
        }
        return 0;
      });

      return todaySchedules;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching schedules for today: $e");
      }
      return [];
    }
  }

  /// Mengambil jadwal hari ini untuk lecturer
  Future<List<ScheduleModel>> fetchSchedulesForTodayLecturer(
    String teacherName,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('schedules')
              .where('teacherName', isEqualTo: teacherName.trim())
              .get();

      final List<ScheduleModel> lecturerSchedules =
          querySnapshot.docs.map((doc) {
            return ScheduleModel.fromMap(doc.data(), doc.id);
          }).toList();

      // Ambil hari ini dalam format Bahasa Indonesia
      String today = DateFormat('EEEE', 'id_ID').format(DateTime.now());

      // Filter hanya yang sesuai hari ini
      final List<ScheduleModel> todayLecturerSchedules =
          lecturerSchedules.where((schedule) {
            return schedule.day.toLowerCase().trim() ==
                today.toLowerCase().trim();
          }).toList();

      // Urutkan berdasarkan waktu mulai (pakai startTimestamp)
      todayLecturerSchedules.sort((a, b) {
        if (a.startTimestamp != null && b.startTimestamp != null) {
          return a.startTimestamp!.compareTo(b.startTimestamp!);
        }
        return 0;
      });

      return todayLecturerSchedules;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching lecturer schedules for today: $e");
      }
      return [];
    }
  }
}
