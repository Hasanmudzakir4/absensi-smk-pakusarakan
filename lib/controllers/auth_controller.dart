import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> loadUserData() async {
    if (_auth.currentUser == null) return;

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data after reload: $e");
    }
  }

  // Fungsi untuk ambil ulang dan simpan userData (optional manual refresh)
  Future<void> refreshUserData() async {
    if (currentUser == null) return;
    try {
      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refreshing user data: $e");
    }
  }

  // Fngsi ambil data profile
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;

      // Ambil data pengguna dari Firestore berdasarkan UID
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

  // Fungsi Login
  Future<User?> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    setLoading(true);

    try {
      // 🔍 Cek manual apakah email ada di Firestore
      final query =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        if (context.mounted) {
          _showDialog(context, "Login Gagal", "Email tidak terdaftar.");
        }
        setLoading(false);
        return null;
      }

      // 🔐 Login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        final userDoc =
            await _firestore.collection('users').doc(user!.uid).get();

        if (!userDoc.exists) {
          if (context.mounted) {
            _showDialog(
              context,
              "Akun Tidak Ditemukan",
              "Data pengguna tidak ditemukan di database.",
            );
          }
          setLoading(false);
          return null;
        }

        _userData = userDoc.data() as Map<String, dynamic>;
        notifyListeners();

        final role = (_userData?['role'] as String).trim().toLowerCase();

        if (!['siswa', 'admin', 'guru'].contains(role) && !user.emailVerified) {
          if (context.mounted) {
            _showDialog(
              context,
              "Verifikasi Diperlukan",
              "Akun Anda belum diverifikasi. Silakan periksa email Anda.",
            );
          }
          setLoading(false);
          return null;
        }

        if (context.mounted) {
          if (kIsWeb) {
            if (role == 'guru' || role == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            } else {
              _showDialog(
                context,
                "Akses Ditolak",
                "Siswa tidak diperbolehkan login melalui web.",
              );
              await _auth.signOut();
              setLoading(false);
              return null;
            }
          } else {
            Navigator.pushReplacementNamed(context, '/tabbar');
          }
        }

        setLoading(false);
        return user;
      }

      setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _showDialog(context, "Login Gagal", "Password salah.");
        } else {
          _showDialog(context, "Login Gagal", _getAuthErrorMessage(e.code));
        }
      }
      setLoading(false);
      return null;
    }
  }

  // Fungsi Registrasi
  Future<User?> register(
    String email,
    String password,
    String role,
    BuildContext context,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      if (context.mounted) {
        _showDialog(context, "Input Error", "Silahkan isi email dan password.");
      }
      return null;
    }

    setLoading(true);
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.sendEmailVerification();

      setLoading(false);

      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/otp',
          arguments: {'role': role},
        );
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      if (context.mounted) {
        _showDialog(
          context,
          "Registration Error",
          _getAuthErrorMessage(e.code),
        );
      }
      return null;
    }
  }

  // Fungsi Logout
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    _userData = null; // Bersihkan cache profil
    notifyListeners();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login-admin');
    }
  }

  // Tambah user oleh guru
  Future<bool> createStudentAccount({
    required String email,
    required String password,
    required String name,
    required String className,
    required BuildContext context,
    required Map<String, dynamic> createdBy,
  }) async {
    setLoading(true);

    try {
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } on FirebaseException catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': 'siswa',
        'studentClass': className,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await secondaryAuth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun siswa berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showDialog(
          context,
          "Gagal Menambahkan Siswa",
          _getAuthErrorMessage(e.code),
        );
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createOtherAccount({
    required String email,
    required String password,
    required String name,
    required String role,
    required BuildContext context,
    required Map<String, dynamic> createdBy,
  }) async {
    setLoading(true);

    try {
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } on FirebaseException catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });

      await secondaryAuth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun $role berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showDialog(
          context,
          "Gagal Menambahkan Akun",
          _getAuthErrorMessage(e.code),
        );
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Kirim Email Untuk Reset Password
  Future<void> sendPasswordResetEmail(
    String email,
    BuildContext context,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link reset password telah dikirim ke email.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login-admin');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e.code)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Menampilkan Dialog
  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Mapping Error
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "Email sudah terdaftar.";
      case 'invalid-email':
        return "Format email tidak valid.";
      case 'user-not-found':
        return "Email tidak terdaftar.";
      case 'wrong-password':
      case 'invalid-credential': // tambahkan ini
        return "Password salah.";
      case 'user-disabled':
        return "Akun telah dinonaktifkan.";
      default:
        return "Terjadi kesalahan saat login: $code";
    }
  }

  // Update foto profil
  Future<void> updateProfileImage(String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoUrl': url,
      });

      // Update di cache juga
      _userData?['photoUrl'] = url;
      notifyListeners();
    }
  }
}
