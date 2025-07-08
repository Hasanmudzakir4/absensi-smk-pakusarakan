import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // / Ambil semua guru dari koleksi `users` dengan role 'guru'
  Future<List<Map<String, dynamic>>> getAllAdmin() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
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

  /// Hapus guru berdasarkan UID
  // Future<void> deleteTeacher(String uid) async {
  //   await _firestore.collection('users').doc(uid).delete();
  // }
}
