import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  /// Mengubah string menjadi format Title Case.
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
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final userMap = authController.userData;
        final String? currentRoute = ModalRoute.of(context)?.settings.name;

        if (userMap == null) {
          authController.loadUserData();
          return const Drawer(child: Center(child: Text("Memuat profil...")));
        }

        final String name = userMap['name'] ?? 'Tidak ada nama';
        final String email = userMap['email'] ?? '-';
        final String? photoUrl = userMap['photoUrl'];
        final String role = (userMap['role'] ?? '').toLowerCase();

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(toTitleCase(name)),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          )
                          : null,
                ),
                decoration: const BoxDecoration(color: Colors.blue),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.space_dashboard,
                title: 'Dashboard',
                routeName: '/admin-dashboard',
                currentRoute: currentRoute,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.school,
                title: 'Kelola Siswa',
                routeName: '/manage-students',
                currentRoute: currentRoute,
              ),
              if (role == 'admin')
                _buildDrawerItem(
                  context,
                  icon: Icons.badge,
                  title: 'Kelola Guru',
                  routeName: '/manage-teacher',
                  currentRoute: currentRoute,
                ),
              if (role == 'admin')
                _buildDrawerItem(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Kelola Admin',
                  routeName: '/manage-admin',
                  currentRoute: currentRoute,
                ),

              _buildDrawerItem(
                context,
                icon: Icons.calendar_month,
                title: role == 'guru' ? 'Jadwal Pelajaran' : 'Kelola Jadwal',
                routeName: '/manage-schedule',
                currentRoute: currentRoute,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.fact_check,
                title: 'Rekap Absensi',
                routeName: '/attendance-recap',
                currentRoute: currentRoute,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.person_add_alt_1,
                title: 'Tambah Pengguna',
                routeName: '/add-student',
                currentRoute: currentRoute,
              ),
              _buildDrawerItem(
                context,
                icon: Icons.account_circle,
                title: 'Profile',
                routeName: '/profile-admin',
                currentRoute: currentRoute,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text("Konfirmasi Logout"),
                        content: const Text("Apakah Anda yakin ingin logout?"),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.of(dialogContext).pop(false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.of(dialogContext).pop(true),
                            child: const Text("Logout"),
                          ),
                        ],
                      );
                    },
                  );

                  if (!context.mounted) return;
                  if (confirmed == true) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
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
        );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
    required String? currentRoute,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: currentRoute == routeName,
      selectedTileColor: Colors.blue.shade100,
      onTap: () {
        if (currentRoute != routeName) {
          Navigator.pushReplacementNamed(context, routeName);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}
