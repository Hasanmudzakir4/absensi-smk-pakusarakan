import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class ProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simpan atau perbarui profil di Firestore
  Future<void> saveProfile(UserModel user) async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final userMap = user.toMap();
      userMap['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(userMap, SetOptions(merge: true));
    }
  }

  // Ambil profil pengguna dari Firestore
  Future<UserModel?> getProfile() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }

  Future<String?> getUserRole() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData["role"];
      }
    }
    return null;
  }
}
