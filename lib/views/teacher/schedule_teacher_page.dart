import 'package:absensi_smk_pakusarakan/controllers/schedule_controller.dart';
import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/widget/schedule_form_widget.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/widget/schedule_list_teacher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleTeacherPage extends StatefulWidget {
  const ScheduleTeacherPage({super.key});

  @override
  ScheduleTeacherPageState createState() => ScheduleTeacherPageState();
}

class ScheduleTeacherPageState extends State<ScheduleTeacherPage> {
  final ScheduleController _controller = ScheduleController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _classController = TextEditingController();

  bool _isLoading = false;
  bool _showForm = false;

  User? _user;
  String? _teacherName;
  ScheduleModel? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchTeacherName();
    }
  }

  Future<void> _fetchTeacherName() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_user!.uid)
              .get();

      setState(() {
        _teacherName = userDoc['name'];
      });
    } catch (e) {
      if (kDebugMode) {
        print("Lengkapi profil Anda!");
      }
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final String formattedTime =
          "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  DateTime _parseTimeOfDay(String time) {
    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(0, 1, 1, hour, minute);
  }

  Future<void> _addOrUpdateSchedule() async {
    if (_dayController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _startTimeController.text.isEmpty ||
        _endTimeController.text.isEmpty ||
        _classController.text.isEmpty ||
        _teacherName == null ||
        _user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua field harus diisi")),
        );
      }
      return;
    }

    // Tampilkan dialog konfirmasi
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              _selectedSchedule == null
                  ? 'Konfirmasi Tambah Jadwal'
                  : 'Konfirmasi Update Jadwal',
            ),
            content: Text(
              _selectedSchedule == null
                  ? 'Apakah Anda yakin ingin menambahkan jadwal ini?'
                  : 'Apakah Anda yakin ingin update jadwal ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ya'),
              ),
            ],
          ),
    );

    if (isConfirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final start = _parseTimeOfDay(_startTimeController.text);
      final end = _parseTimeOfDay(_endTimeController.text);

      // Buat objek ScheduleModel
      ScheduleModel schedule = ScheduleModel(
        id: _selectedSchedule?.id ?? '',
        day: _dayController.text,
        subject: _subjectController.text,
        teacherName: _teacherName!,
        teacherId: _user!.uid,
        className: _classController.text,
        startTimestamp: start,
        endTimestamp: end,
      );

      if (_selectedSchedule == null) {
        await _controller.addSchedule(schedule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Jadwal berhasil ditambahkan")),
          );
        }
      } else {
        await _controller.updateSchedule(schedule.id, schedule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Jadwal berhasil diperbarui")),
          );
        }
      }

      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(ScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Konfirmasi Hapus"),
            content: const Text(
              "Apakah Anda yakin ingin menghapus jadwal ini?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      await _controller.deleteSchedule(schedule.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Jadwal dihapus")));
        setState(() {});
      }
    }
  }

  void _resetForm() {
    _dayController.clear();
    _subjectController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _classController.clear();
    _selectedSchedule = null;
    _showForm = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal Mengajar"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child:
            _showForm
                // ======= Jika showForm true: tampilkan hanya form =======
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedSchedule == null
                          ? 'Tambah Jadwal'
                          : 'Edit Jadwal',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FormScheduleWidget(
                      dayController: _dayController,
                      subjectController: _subjectController,
                      startTimeController: _startTimeController,
                      endTimeController: _endTimeController,
                      classController: _classController,
                      isLoading: _isLoading,
                      isEditing: _selectedSchedule != null,
                      onSubmit: _addOrUpdateSchedule,
                      onCancel: () {
                        setState(() {
                          _showForm = false;
                          _resetForm();
                        });
                      },
                      onPickTime: _pickTime,
                      onDayChanged: (value) {
                        setState(() {
                          _dayController.text = value!;
                        });
                      },
                    ),
                  ],
                )
                : Column(
                  children: [
                    const Text(
                      "Daftar Jadwal",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ScheduleListWidget(
                      teacherName: _teacherName,
                      controller: _controller,
                      onEdit: (schedule) {
                        setState(() {
                          _dayController.text = schedule.day;
                          _subjectController.text = schedule.subject;

                          _startTimeController.text =
                              "${schedule.startTimestamp?.hour.toString().padLeft(2, '0') ?? '00'}:"
                              "${schedule.startTimestamp?.minute.toString().padLeft(2, '0') ?? '00'}";

                          _endTimeController.text =
                              "${schedule.endTimestamp?.hour.toString().padLeft(2, '0') ?? '00'}:"
                              "${schedule.endTimestamp?.minute.toString().padLeft(2, '0') ?? '00'}";

                          _classController.text = schedule.className;
                          _showForm = true;
                          _selectedSchedule = schedule;
                        });
                      },

                      onDelete: _confirmDelete,
                    ),

                    const SizedBox(height: 20),
                    if (_teacherName != null)
                      ElevatedButton(
                        onPressed: () {
                          _resetForm(); // reset semua field terlebih dahulu
                          setState(() {
                            _showForm = true; // baru tampilkan form
                            _selectedSchedule =
                                null; // pastikan edit-mode dimatikan
                          });
                        },
                        child: const Text("Tambah Jadwal"),
                      ),
                  ],
                ),
      ),
    );
  }
}
