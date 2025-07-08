import 'package:absensi_smk_pakusarakan/controllers/profile_controller.dart';
import 'package:absensi_smk_pakusarakan/models/user_model.dart';
import 'package:absensi_smk_pakusarakan/views/components/widgets/profile_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileStudentPage extends StatefulWidget {
  const ProfileStudentPage({super.key});

  @override
  ProfileStudentPageState createState() => ProfileStudentPageState();
}

class ProfileStudentPageState extends State<ProfileStudentPage> {
  final ProfileController _profileController = ProfileController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    UserModel? user = await _profileController.getProfile();
    if (user != null) {
      setState(() {
        _nameController.text = user.name ?? '';
        _idNumberController.text = user.idNumber ?? '';
        _classController.text = user.studentClass ?? '';
        _phoneController.text = user.phone ?? '';
        if (user.dateOfBirth != null && user.dateOfBirth!.contains(',')) {
          var parts = user.dateOfBirth!.split(',');
          _birthPlaceController.text = parts[0].trim();
          _birthDateController.text = parts.length > 1 ? parts[1].trim() : '';
        } else {
          _birthPlaceController.text = user.dateOfBirth ?? '';
          _birthDateController.text = '';
        }
      });
    }
  }

  void _saveProfile() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final oldProfile = await _profileController.getProfile();
      String dobCombined = _birthPlaceController.text;
      if (_birthDateController.text.isNotEmpty) {
        dobCombined += ', ${_birthDateController.text}';
      }

      UserModel userModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: _nameController.text,
        idNumber: _idNumberController.text,
        studentClass: _classController.text,
        phone: _phoneController.text,
        dateOfBirth: dobCombined,
        role: oldProfile?.role,
      );

      try {
        await _profileController.saveProfile(userModel);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/tabbar');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
      }
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
              controller: _nameController,
              label: "Nama Lengkap",
              icon: Icons.person,
            ),
            CustomTextField(
              controller: _idNumberController,
              label: "NIM",
              icon: Icons.badge,
            ),
            CustomTextField(
              controller: _classController,
              label: "Kelas",
              icon: Icons.class_,
            ),
            CustomTextField(
              controller: _phoneController,
              label: "Telepon",
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            CustomTextField(
              controller: _birthPlaceController,
              label: "Tempat Lahir",
              icon: Icons.location_city,
            ),
            CustomTextField(
              controller: _birthDateController,
              label: "Tanggal Lahir",
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectBirthDate(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("Simpan Profil"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
