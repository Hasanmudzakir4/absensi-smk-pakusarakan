import 'package:absensi_smk_pakusarakan/models/attendance_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil riwayat absensi untuk siswa yang sedang login
  Future<List<AttendanceModel>> getAttendanceHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot =
          await _firestore
              .collection('attendance')
              .where('studentNumber', isEqualTo: user.uid)
              .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Error fetching attendance data: $e");
      return [];
    }
  }

  /// Mengambil data absensi berdasarkan scheduleId
  Future<List<AttendanceModel>> getAttendanceByScheduleId(
    String scheduleId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('attendance')
              .where('scheduleId', isEqualTo: scheduleId)
              .get();

      return snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Error fetching attendance by scheduleId: $e");
      return [];
    }
  }

  /// Mengambil daftar mata pelajaran berdasarkan className dan teacherId
  Future<List<String>> getSubjectsByClass({
    required String className,
    required String teacherId,
  }) async {
    final snapshot =
        await _firestore
            .collection('schedules')
            .where('teacherId', isEqualTo: teacherId)
            .where('className', isEqualTo: className)
            .get();

    final subjects =
        snapshot.docs.map((e) => e['subject'].toString()).toSet().toList()
          ..sort();

    return subjects;
  }

  Future<List<Map<String, dynamic>>> fetchStudentsByTeacher(
    String teacherId,
  ) async {
    try {
      // log('[DEBUG] UID guru login: $teacherId');
      final schedules =
          await _firestore
              .collection('schedules')
              .where('teacherId', isEqualTo: teacherId)
              .get();

      // log('[DEBUG] Jumlah schedule ditemukan: ${schedules.docs.length}');
      // log('[DEBUG] Data schedule: ${schedules.docs.map((d) => d.data())}');

      final classList =
          schedules.docs
              .map((doc) => doc.data())
              .where((data) => data.containsKey('className'))
              .map((data) => data['className'])
              .toSet()
              .toList();

      // log('[DEBUG] Daftar className dari schedule: $classList');

      if (classList.isEmpty) return [];

      final studentsSnapshot =
          await _firestore
              .collection('users')
              .where('studentClass', whereIn: classList)
              .where('role', isEqualTo: 'siswa')
              .get();

      // log('[DEBUG] Jumlah siswa ditemukan: ${studentsSnapshot.docs.length}');
      // log(
      //   '[DEBUG] Data siswa ditemukan: ${studentsSnapshot.docs.map((d) => d.data())}',
      // );

      return studentsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching students by teacher: $e");
      return [];
    }
  }

  /// Melakukan filter dan pencarian pada data absensi berdasarkan kelas yang dipilih dan kata kunci pencarian.
  List<AttendanceModel> filterAndSearch({
    required List<AttendanceModel> list,
    required String selectedClass,
    required String searchQuery,
  }) {
    final filtered =
        list.where((item) {
          final matchClass =
              selectedClass == 'Semua' || item.studentClass == selectedClass;

          final query = searchQuery.toLowerCase();

          final dateString =
              item.timestamp is Timestamp
                  ? DateFormat(
                    'dd MMMM yyyy',
                    'id_ID',
                  ).format((item.timestamp as Timestamp).toDate()).toLowerCase()
                  : '';

          final matchSearch =
              item.studentName.toLowerCase().contains(query) ||
              item.studentNumber.toLowerCase().contains(query) ||
              item.studentClass.toLowerCase().contains(query) ||
              (item.qrData['subject']?.toLowerCase().contains(query) ??
                  false) ||
              dateString.contains(query);

          return matchClass && matchSearch;
        }).toList();

    filtered.sort((a, b) {
      final aDate = a.timestamp?.toDate() ?? DateTime(2000);
      final bDate = b.timestamp?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate); // Terbaru ke Terlama
    });

    return filtered;
  }

  /// Mengubah string menjadi format Title Case.
  String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Future<void> deleteAttendance(String id) async {
    await FirebaseFirestore.instance.collection('attendance').doc(id).delete();
  }

  Future<void> updateAttendanceStatus({
    required String attendanceId,
    required String newStatus,
  }) async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(attendanceId)
        .update({'qrData.status': newStatus});
  }

  Future<String?> getScheduleIdBySubjectAndTeacher({
    required String subject,
    required String teacherId,
  }) async {
    final query =
        await _firestore
            .collection('schedules')
            .where('subject', isEqualTo: subject)
            .where('teacherId', isEqualTo: teacherId)
            .limit(1)
            .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<void> addManualAttendance({
    required String studentName,
    required String studentNumber,
    required String studentClass,
    required DateTime timestamp,
    required String status,
    required String subject,
    required String scheduleId,
    required String teacherName,
  }) async {
    final docRef = _firestore.collection('attendance').doc();

    await docRef.set({
      'id': docRef.id,
      'studentName': studentName,
      'studentNumber': studentNumber,
      'studentClass': studentClass,
      'timestamp': timestamp,
      'status': status,
      'scheduleId': scheduleId,
      'qrData': {
        'date': DateFormat('dd-MM-yyyy').format(timestamp),
        'day': DateFormat('EEEE', 'id_ID').format(timestamp),
        'status': status,
        'subject': toTitleCase(subject),
        'teacher': teacherName,
        'time': DateFormat('HH:mm').format(timestamp),
      },
    });
  }

  Future<List<AttendanceModel>> getFilteredAttendance({
    required String currentUserRole,
    String? kelas,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    String? subject,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    Query queryRef = FirebaseFirestore.instance.collection('attendance');

    // Jika guru, filter berdasarkan scheduleId miliknya
    if (currentUserRole != 'admin') {
      final scheduleSnapshot =
          await FirebaseFirestore.instance
              .collection('schedules')
              .where('teacherId', isEqualTo: user.uid)
              .get();

      final scheduleIds = scheduleSnapshot.docs.map((doc) => doc.id).toList();
      if (scheduleIds.isEmpty) return [];

      queryRef = queryRef.where('scheduleId', whereIn: scheduleIds);
    }

    // Filter kelas
    if (kelas != null && kelas.isNotEmpty && kelas != 'Semua') {
      queryRef = queryRef.where('studentClass', isEqualTo: kelas);
    }

    // Filter mapel
    if (subject != null && subject.isNotEmpty && subject != 'Semua') {
      queryRef = queryRef.where('qrData.subject', isEqualTo: subject);
    }

    final snapshot = await queryRef.get();

    final allData =
        snapshot.docs.map((doc) => AttendanceModel.fromDocument(doc)).toList();

    // Filter manual by tanggal dan search
    final filtered =
        allData.where((item) {
          final timestamp = item.timestamp;
          if (timestamp is! Timestamp) return false;

          final date = timestamp.toDate();

          final adjustedEndDate = endDate
              ?.add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1));

          final inDateRange =
              (startDate == null || !date.isBefore(startDate)) &&
              (adjustedEndDate == null || !date.isAfter(adjustedEndDate));

          final q = query?.toLowerCase() ?? '';
          final matchesSearch =
              q.isEmpty ||
              item.studentName.toLowerCase().contains(q) ||
              item.studentNumber.toLowerCase().contains(q) ||
              item.studentClass.toLowerCase().contains(q) ||
              (item.qrData['subject']?.toLowerCase().contains(q) ?? false);

          return inDateRange && matchesSearch;
        }).toList();

    return filtered;
  }

  Future<Map<String, String>?> getLastAttendanceToday(String uid) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('attendance')
            .where(
              'studentId',
              isEqualTo: uid,
            ) // pastikan pakai 'studentId' bukan 'userId'
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    // log("Docs found: ${snapshot.docs.length}");

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      // log("Absensi ditemukan: ${data.toString()}");

      final qr = data['qrData'];
      final subject = qr['subject'];
      final time = qr['time'];
      return {'subject': subject, 'time': time};
    }

    return null;
  }

  Future<bool> hasScheduleToday(String studentClass) async {
    final now = DateTime.now();
    final today = _getDayName(now.weekday); // Senin, Selasa, dst.

    final snapshot =
        await FirebaseFirestore.instance
            .collection('schedules')
            .where('className', isEqualTo: studentClass)
            .where('day', isEqualTo: today)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }
}
