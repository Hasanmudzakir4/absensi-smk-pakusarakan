import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/schedule_model.dart';

class ScheduleController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mengambil semua jadwal
  Future<List<ScheduleModel>> fetchAllSchedules() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('schedules').get();
      return querySnapshot.docs.map((doc) {
        return ScheduleModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all schedules: $e');
      }
      return [];
    }
  }

  Future<List<ScheduleModel>> fetchSchedulesByTeacherId(
    String teacherId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('schedules')
            .where('teacherId', isEqualTo: teacherId)
            .get();

    return snapshot.docs.map((doc) {
      return ScheduleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  /// Menambahkan jadwal ke Firestore
  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      DocumentReference docRef = _firestore.collection('schedules').doc();
      Map<String, dynamic> data = schedule.toMap();
      // Set id dokumen
      data['id'] = docRef.id;
      // Set createdAt dengan server timestamp
      data['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);
      log("Jadwal berhasil ditambahkan dengan ID: ${docRef.id}");
    } catch (e) {
      log("Error adding schedule: $e");
    }
  }

  /// Mengambil jadwal khusus untuk siswa berdasarkan kelas & semester
  Future<List<ScheduleModel>> fetchSchedulesForStudent(String className) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('schedules')
              .where('className', isEqualTo: className)
              .get();

      return querySnapshot.docs.map((doc) {
        return ScheduleModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        log('Error fetching schedules for student: $e');
      }
      return [];
    }
  }

  // update jadwal mengajar
  Future<void> updateSchedule(String docId, ScheduleModel schedule) async {
    try {
      Map<String, dynamic> data = schedule.toMap();
      data.remove('createdAt');

      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('schedules').doc(docId).update(data);
      log("Jadwal berhasil diperbarui");
    } catch (e) {
      log("Error updating schedule: $e");
    }
  }

  /// Menghapus jadwal berdasarkan ID dokumen Firestore
  Future<void> deleteSchedule(String docId) async {
    try {
      await _firestore.collection('schedules').doc(docId).delete();
      log("Jadwal berhasil dihapus");
    } catch (e) {
      log("Error deleting schedule: $e");
    }
  }

  /// Mengambil jadwal berdasarkan nama guru (optional)
  Future<List<ScheduleModel>> fetchSchedulesByTeacher(
    String teacherName,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('schedules')
              .where('teacherName', isEqualTo: teacherName.trim())
              .get();

      return querySnapshot.docs.map((doc) {
        return ScheduleModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      log("Error fetching schedules by teacher: $e");
      return [];
    }
  }
}
