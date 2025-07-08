import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ambil semua siswa (belum & sudah absen) sesuai jadwal dosen
  Future<List<Map<String, dynamic>>> getAllStudentsBySchedule() async {
    final String? currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return [];

    // Ambil role dari user saat ini
    final userDoc = await _firestore.collection('users').doc(currentUid).get();
    final String? role = userDoc.data()?['role'];

    final List<Map<String, dynamic>> students = [];

    if (role == 'admin') {
      // Jika admin, ambil semua data siswa
      final allStudentsSnap =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'siswa')
              .get();

      for (var userDoc in allStudentsSnap.docs) {
        final u = userDoc.data();
        students.add({
          'uid': userDoc.id,
          'studentId': userDoc.id,
          'name': u['name'],
          'idNumber': u['idNumber'],
          'studentClass': u['studentClass'],
          'email': u['email'],
          'phone': u['phone'],
          'dateOfBirth': u['dateOfBirth'],
          'attended': false,
          'attendanceData': null,
        });
      }
    } else if (role == 'guru') {
      // Jika guru, ambil siswa berdasarkan jadwal yang dia pegang
      final schedulesSnap =
          await _firestore
              .collection('schedules')
              .where('teacherId', isEqualTo: currentUid)
              .get();

      for (var sched in schedulesSnap.docs) {
        final dataSched = sched.data();
        final kelas = dataSched['className'];

        final usersSnap =
            await _firestore
                .collection('users')
                .where('role', isEqualTo: 'siswa')
                .where('studentClass', isEqualTo: kelas)
                .get();

        for (var userDoc in usersSnap.docs) {
          final u = userDoc.data();
          final studentId = userDoc.id;

          final attendanceSnap =
              await _firestore
                  .collection('attendance')
                  .where('scheduleId', isEqualTo: sched.id)
                  .where('studentId', isEqualTo: studentId)
                  .limit(1)
                  .get();

          students.add({
            'uid': studentId,
            'studentId': studentId,
            'name': u['name'],
            'idNumber': u['idNumber'],
            'studentClass': u['studentClass'],
            'email': u['email'],
            'phone': u['phone'],
            'dateOfBirth': u['dateOfBirth'],
            'attended': attendanceSnap.docs.isNotEmpty,
            'attendanceData':
                attendanceSnap.docs.isNotEmpty
                    ? attendanceSnap.docs.first.data()
                    : null,
          });
        }
      }
    }

    // Hilangkan duplikat jika ada
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (var s in students) {
      if (seen.add(s['studentId'] as String)) {
        deduped.add(s);
      }
    }

    return deduped;
  }
}
