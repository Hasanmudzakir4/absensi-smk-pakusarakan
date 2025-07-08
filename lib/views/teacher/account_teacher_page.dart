import 'dart:io';
import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class AccountTeacherPage extends StatefulWidget {
  const AccountTeacherPage({super.key});

  @override
  State<AccountTeacherPage> createState() => _AccountTeacherPageState();
}

class _AccountTeacherPageState extends State<AccountTeacherPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final data = await authController.getUserData();

    if (mounted) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final authController = Provider.of<AuthController>(context, listen: false);
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = path.basename(pickedFile.path);

      try {
        // 🔁 Hapus gambar lama jika ada
        final oldPhotoUrl = userData?['photoUrl'];
        if (oldPhotoUrl != null && oldPhotoUrl.toString().isNotEmpty) {
          final oldRef = FirebaseStorage.instance.refFromURL(oldPhotoUrl);
          await oldRef.delete();
        }

        // ☁️ Upload gambar baru
        final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${userData?['name']}/$fileName',
        );
        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        // 🔄 Simpan URL baru
        await authController.updateProfileImage(downloadUrl);

        if (!mounted) return;
        setState(() {
          userData?['photoUrl'] = downloadUrl;
        });

        // ✅ Tampilkan notifikasi berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil berhasil diperbarui."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint("Upload error: $e");

        // ❌ Tampilkan notifikasi gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal mengunggah foto: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ada gambar yang dipilih."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah Anda yakin ingin logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text("Logout"),
                      ),
                    ],
                  );
                },
              );
              if (!mounted) return;
              if (confirmed == true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).logout(context);
                });
              }
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData == null
              ? const Center(child: Text("Data pengguna tidak ditemukan."))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    userData?['photoUrl'] != null
                                        ? NetworkImage(userData!['photoUrl'])
                                        : const AssetImage('images/profil.png')
                                            as ImageProvider,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          userData?['name'] ?? 'Nama Tidak Diketahui',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListTile(
                        leading: const Icon(Icons.perm_identity),
                        title: const Text("NIP"),
                        subtitle: Text(userData?['idNumber'] ?? '-'),
                      ),

                      ListTile(
                        leading: const Icon(Icons.cake),
                        title: const Text("Tempat, Tanggal Lahir"),
                        subtitle: Text(userData?['dateOfBirth'] ?? '-'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text("Email"),
                        subtitle: Text(userData?['email'] ?? '-'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text("Telepon"),
                        subtitle: Text(userData?['phone'] ?? '-'),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/profileTeacher');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text("Update Profile"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
