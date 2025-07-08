import 'package:absensi_smk_pakusarakan/models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryController {
  Future<List<AttendanceModel>> fetchAttendanceData() async {
    // Ambil user yang sedang login
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Langsung gunakan user.uid (studentId)
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: user.uid)
            .orderBy('qrData.date', descending: true)
            .get();

    // Mapping ke model
    List<AttendanceModel> attendanceList =
        querySnapshot.docs.map((doc) {
          return AttendanceModel.fromMap(doc.data(), doc.id);
        }).toList();

    return attendanceList;
  }

  Future<List<AttendanceModel>> fetchLecturerAttendanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Ambil semua jadwal yang dibuat oleh dosen yang login
    final scheduleSnapshot =
        await FirebaseFirestore.instance
            .collection('schedules')
            .where('teacherId', isEqualTo: user.uid)
            .get();

    if (scheduleSnapshot.docs.isEmpty) return [];

    // Ambil daftar scheduleId
    List<String> scheduleIds =
        scheduleSnapshot.docs.map((doc) => doc.id).toList();

    // Ambil semua data absensi yang memiliki scheduleId sesuai dengan dosen
    final attendanceSnapshot =
        await FirebaseFirestore.instance
            .collection('attendance')
            .where('scheduleId', whereIn: scheduleIds)
            .orderBy('timestamp', descending: true)
            .get();

    return attendanceSnapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<AttendanceModel>> fetchAdminAttendanceData() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('attendance')
            .orderBy('timestamp', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<String>> fetchSubjectsByClass(String className) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('schedules')
            .where('className', isEqualTo: className)
            .get();

    final subjects =
        snapshot.docs
            .map((doc) => doc['subject']?.toString() ?? '-')
            .toSet()
            .toList();

    return subjects;
  }
}
