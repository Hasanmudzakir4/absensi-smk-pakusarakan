import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_drawer.dart';

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController classController = TextEditingController();

  bool isSidebarVisible = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? selectedClass;
  String? currentUserRole;
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    getCurrentUserRole();
  }

  Future<void> getCurrentUserRole() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final userData = await authController.getUserData();
    if (!mounted) return;
    setState(() {
      currentUserRole = userData?['role'];
      if (currentUserRole == 'guru') {
        selectedRole = 'siswa'; // default role untuk guru
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth >= 800;

        return Scaffold(
          drawer: isWideScreen ? null : const AdminDrawer(),
          body: Row(
            children: [
              if (isWideScreen && isSidebarVisible)
                const SizedBox(width: 250, child: AdminDrawer()),
              if (isWideScreen && isSidebarVisible)
                const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              "Tambah Pengguna",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Lengkap',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? 'Wajib diisi'
                                              : null,
                                ),
                                const SizedBox(height: 16),

                                // Role (hanya admin)
                                if (currentUserRole == 'admin') ...[
                                  DropdownButtonFormField<String>(
                                    value: selectedRole,
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        ['siswa', 'guru', 'admin']
                                            .map(
                                              (role) =>
                                                  DropdownMenuItem<String>(
                                                    value: role,
                                                    child: Text(
                                                      role.toLowerCase(),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedRole = value;
                                      });
                                    },
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Role wajib dipilih'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Kelas (hanya jika role == siswa)
                                if (selectedRole == 'siswa' ||
                                    currentUserRole == 'guru')
                                  Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedClass,
                                        decoration: const InputDecoration(
                                          labelText: 'Kelas',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            ['10', '11', '12']
                                                .map(
                                                  (kelas) =>
                                                      DropdownMenuItem<String>(
                                                        value: kelas,
                                                        child: Text(kelas),
                                                      ),
                                                )
                                                .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedClass = value;
                                            classController.text = value ?? '';
                                          });
                                        },
                                        validator:
                                            (value) =>
                                                value == null || value.isEmpty
                                                    ? 'Wajib dipilih'
                                                    : null,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // Email
                                TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.length < 6
                                              ? 'Minimal 6 karakter'
                                              : null,
                                ),
                                const SizedBox(height: 16),

                                // Konfirmasi Password
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi Password',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (value != passwordController.text) {
                                      return 'Password tidak cocok';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Tombol Submit
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.person_add),
                                    label: Text(
                                      "Tambah ${selectedRole?.toLowerCase() ?? 'Siswa'}",
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        final authController =
                                            Provider.of<AuthController>(
                                              context,
                                              listen: false,
                                            );
                                        final userData =
                                            await authController.getUserData();

                                        if (!context.mounted) return;
                                        if (userData == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Gagal mengambil data user login',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final roleToCreate =
                                            selectedRole ?? 'siswa';
                                        bool success = false;

                                        if (roleToCreate == 'siswa') {
                                          success = await authController
                                              .createStudentAccount(
                                                email:
                                                    emailController.text.trim(),
                                                password:
                                                    passwordController.text
                                                        .trim(),
                                                name:
                                                    nameController.text.trim(),
                                                className:
                                                    classController.text.trim(),
                                                context: context,
                                                createdBy: {
                                                  'uid':
                                                      authController
                                                          .currentUser
                                                          ?.uid,
                                                  'name': userData['name'],
                                                  'role': userData['role'],
                                                },
                                              );
                                        } else {
                                          success = await authController
                                              .createOtherAccount(
                                                email:
                                                    emailController.text.trim(),
                                                password:
                                                    passwordController.text
                                                        .trim(),
                                                name:
                                                    nameController.text.trim(),
                                                role: roleToCreate,
                                                context: context,
                                                createdBy: {
                                                  'uid':
                                                      authController
                                                          .currentUser
                                                          ?.uid,
                                                  'name': userData['name'],
                                                  'role': userData['role'],
                                                },
                                              );
                                        }

                                        if (success) {
                                          nameController.clear();
                                          emailController.clear();
                                          passwordController.clear();
                                          confirmPasswordController.clear();
                                          classController.clear();
                                          setState(() {
                                            selectedClass = null;
                                            if (currentUserRole == 'admin') {
                                              selectedRole = null;
                                            }
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
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
