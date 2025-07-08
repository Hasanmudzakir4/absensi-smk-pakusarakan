import 'package:absensi_smk_pakusarakan/controllers/auth_controller.dart';
import 'package:absensi_smk_pakusarakan/controllers/profile_controller.dart';
import 'package:absensi_smk_pakusarakan/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const EditProfileDialog({super.key, required this.user});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController idNumberController;
  late TextEditingController placeOfBirthController;
  late TextEditingController dobTextController;

  DateTime? selectedDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user.name ?? '');
    phoneController = TextEditingController(text: widget.user.phone ?? '');
    idNumberController = TextEditingController(
      text: widget.user.idNumber ?? '',
    );
    placeOfBirthController = TextEditingController();

    // Pisahkan tempat dan tanggal lahir jika ada
    if (widget.user.dateOfBirth != null &&
        widget.user.dateOfBirth!.contains(',')) {
      final parts = widget.user.dateOfBirth!.split(', ');
      if (parts.length == 2) {
        placeOfBirthController.text = parts[0];
        selectedDate = _parseDate(parts[1]);
      }
    } else if (widget.user.dateOfBirth != null) {
      // fallback jika hanya tanggal
      selectedDate = _parseDate(widget.user.dateOfBirth!);
    }

    dobTextController = TextEditingController(
      text: selectedDate != null ? _formatDate(selectedDate!) : '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    idNumberController.dispose();
    placeOfBirthController.dispose();
    dobTextController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDate(String input) {
    try {
      final parts = input.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dobTextController.text = _formatDate(picked);
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    // Gabungkan tempat dan tanggal lahir menjadi satu string
    final combinedBirthInfo =
        "${placeOfBirthController.text.trim()}, ${_formatDate(selectedDate!)}";

    final updatedUser = UserModel(
      uid: widget.user.uid,
      email: widget.user.email,
      role: widget.user.role,
      photoUrl: widget.user.photoUrl,
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      idNumber: idNumberController.text.trim(),
      dateOfBirth: combinedBirthInfo,
    );

    await ProfileController().saveProfile(updatedUser);

    if (mounted) {
      await Provider.of<AuthController>(
        context,
        listen: false,
      ).refreshUserData();
      if (!mounted) return;
      Navigator.pop(context, true);
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Induk Pegawai',
                  ),
                ),
                TextFormField(
                  controller: placeOfBirthController,
                  decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: dobTextController,
                  decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
                  readOnly: true,
                  onTap: _pickDate,
                  validator:
                      (val) =>
                          selectedDate == null ? 'Wajib pilih tanggal' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: isSaving ? null : saveProfile,
          icon: const Icon(Icons.save),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}
