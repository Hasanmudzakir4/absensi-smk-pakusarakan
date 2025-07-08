import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:absensi_smk_pakusarakan/models/user_model.dart';
import 'package:absensi_smk_pakusarakan/views/admin/admin_drawer.dart';
import 'package:absensi_smk_pakusarakan/views/admin/update_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageProfile extends StatefulWidget {
  const ManageProfile({super.key});

  @override
  State<ManageProfile> createState() => _ManageProfileState();
}

class _ManageProfileState extends State<ManageProfile> {
  Map<String, dynamic>? userData;
  bool isSidebarVisible = true;
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

  bool isProfileComplete(Map<String, dynamic>? user) {
    if (user == null) return false;

    return user['name'] != null &&
        user['phone'] != null &&
        user['dateOfBirth'] != null &&
        user['idNumber'] != null &&
        user['role'] != null &&
        (user['role'] == "guru" ? user['subject'] != null : true);
  }

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth >= 800;

        return Scaffold(
          drawer: isWideScreen ? null : AdminDrawer(),
          body: Row(
            children: [
              if (isWideScreen && isSidebarVisible)
                SizedBox(width: 250, child: AdminDrawer()),
              if (isWideScreen && isSidebarVisible)
                const VerticalDivider(width: 1),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      if (isWideScreen)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isSidebarVisible ? Icons.menu_open : Icons.menu,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  isSidebarVisible = !isSidebarVisible;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Profil",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      userData == null
                          ? const Center(child: CircularProgressIndicator())
                          : Expanded(
                            child: SingleChildScrollView(
                              child: Center(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    color: Colors.grey[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: CircleAvatar(
                                              radius: 40,
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: Icon(
                                                Icons.person,
                                                size: 40,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Divider(),

                                          ProfileItem(
                                            icon: Icons.person,
                                            title: "Nama",
                                            value: toTitleCase(
                                              userData?['name'] ??
                                                  'Nama Tidak Diketahui',
                                            ),
                                          ),
                                          ProfileItem(
                                            icon: Icons.email,
                                            title: "Email",
                                            value: userData?['email'] ?? '-',
                                          ),
                                          ProfileItem(
                                            icon: Icons.badge,
                                            title: "Nomor Induk Pegawai",
                                            value: userData?['idNumber'] ?? '-',
                                          ),
                                          ProfileItem(
                                            icon: Icons.cake,
                                            title: "Tempat/ Tanggal Lahir",
                                            value:
                                                userData?['dateOfBirth'] ?? '-',
                                          ),
                                          ProfileItem(
                                            icon: Icons.phone,
                                            title: "No Telepon",
                                            value: userData?['phone'] ?? '-',
                                          ),
                                          ProfileItem(
                                            icon: Icons.verified_user,
                                            title: "Peran",
                                            value: toTitleCase(
                                              userData?['role'] ?? '-',
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Center(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.edit),
                                              label: Text(
                                                isProfileComplete(userData)
                                                    ? "Update Profil"
                                                    : "Lengkapi Profil",
                                              ),
                                              onPressed: () async {
                                                if (userData == null) return;

                                                final user = UserModel.fromMap(
                                                  userData!,
                                                );

                                                final updated =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder:
                                                          (context) =>
                                                              EditProfileDialog(
                                                                user: user,
                                                              ),
                                                    );

                                                if (updated == true) {
                                                  fetchUserData(); // refresh tampilan jika berhasil update
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;

  const ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value ?? "-",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
