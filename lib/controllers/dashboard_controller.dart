import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, int>> getStudentCountsByClass() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    // Ambil role user
    final role = await getCurrentUserRole();
    if (role == null) return {};

    final Map<String, int> classCounts = {
      'total': 0,
      '10': 0,
      '11': 0,
      '12': 0,
    };

    if (role == 'admin') {
      // Ambil semua siswa
      final allStudentsSnap =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'siswa')
              .get();

      for (final doc in allStudentsSnap.docs) {
        final data = doc.data();
        final className = data['studentClass'] ?? '';

        classCounts['total'] = classCounts['total']! + 1;

        if (className.contains('10')) {
          classCounts['10'] = classCounts['10']! + 1;
        } else if (className.contains('11')) {
          classCounts['11'] = classCounts['11']! + 1;
        } else if (className.contains('12')) {
          classCounts['12'] = classCounts['12']! + 1;
        }
      }
    } else {
      // Role guru, ambil berdasarkan jadwal
      final schedulesSnap =
          await _firestore
              .collection('schedules')
              .where('teacherId', isEqualTo: uid)
              .get();

      final Set<String> classNames =
          schedulesSnap.docs
              .map((doc) => doc.data()['className'] as String)
              .toSet();

      for (final className in classNames) {
        final studentsSnap =
            await _firestore
                .collection('users')
                .where('role', isEqualTo: 'siswa')
                .where('studentClass', isEqualTo: className)
                .get();

        final count = studentsSnap.size;
        classCounts['total'] = classCounts['total']! + count;

        if (className.contains('10')) {
          classCounts['10'] = classCounts['10']! + count;
        }
        if (className.contains('11')) {
          classCounts['11'] = classCounts['11']! + count;
        }
        if (className.contains('12')) {
          classCounts['12'] = classCounts['12']! + count;
        }
      }
    }

    return classCounts;
  }

  Future<int> getScheduleCountByCurrentTeacher() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('schedules')
            .where('teacherId', isEqualTo: uid)
            .get();

    return snapshot.docs.length;
  }

  Future<String?> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return doc.data()?['role'] as String?;
  }

  Future<int> getUserCountByRole(String role) async {
    final querySnapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: role)
            .get();
    return querySnapshot.size;
  }
}
