import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // / Ambil semua guru dari koleksi `users` dengan role 'guru'
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'guru')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': data['name'],
        'idNumber': data['idNumber'],
        'dateOfBirth': data['dateOfBirth'],
        'email': data['email'],
        'phone': data['phone'],
      };
    }).toList();
  }
}
