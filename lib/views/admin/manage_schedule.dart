import 'package:absensi_smk_pakusarakan/controllers/schedule_controller.dart';
import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:absensi_smk_pakusarakan/views/admin/admin_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageSchedule extends StatefulWidget {
  const ManageSchedule({super.key});

  @override
  State<ManageSchedule> createState() => _ManageScheduleState();
}

class _ManageScheduleState extends State<ManageSchedule> {
  bool isSidebarVisible = true;
  List<ScheduleModel> schedules = [];
  bool isLoading = true;
  String? _userRole;

  User? _user;
  String? _teacherName;

  String? selectedDay;
  String? selectedClass;

  final ScheduleController _controller = ScheduleController();

  final List<String> dayOptions = [
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  final List<String> classOptions = ['Semua', '10', '11', '12'];

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
        _userRole = userDoc['role'];
      });

      await _fetchSchedules();
    } catch (e) {
      if (kDebugMode) {
        print("Lengkapi profil Anda!");
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (_userRole == 'admin') {
        // Jika admin, ambil semua jadwal
        schedules = await _controller.fetchAllSchedules();
      } else if (_userRole == 'guru' && _user != null) {
        // Jika guru, ambil berdasarkan teacherId
        schedules = await _controller.fetchSchedulesByTeacherId(_user!.uid);
      }

      // Urutkan berdasarkan hari dan jam mulai
      schedules.sort((a, b) {
        const dayOrder = {
          'Senin': 1,
          'Selasa': 2,
          'Rabu': 3,
          'Kamis': 4,
          'Jumat': 5,
          'Sabtu': 6,
          'Minggu': 7,
        };

        final dayA = dayOrder[a.day] ?? 8;
        final dayB = dayOrder[b.day] ?? 8;
        if (dayA != dayB) return dayA.compareTo(dayB);

        final startA = a.startTimestamp;
        final startB = b.startTimestamp;
        if (startA != null && startB != null) {
          return startA.compareTo(startB);
        }

        return 0;
      });
    } catch (e) {
      if (kDebugMode) print('Error saat fetch jadwal: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  List<ScheduleModel> get filteredSchedules {
    return schedules.where((schedule) {
      final matchDay =
          selectedDay == null || selectedDay == 'Semua'
              ? true
              : schedule.day == selectedDay;

      final matchClass =
          selectedClass == null || selectedClass == 'Semua'
              ? true
              : schedule.className == selectedClass;

      return matchDay && matchClass;
    }).toList();
  }

  Future<void> _showAddEditDialog({ScheduleModel? schedule}) async {
    final formKey = GlobalKey<FormState>();

    // Map name to uid
    Map<String, String> nameToIdMap = {};
    List<String> teacherNames = [];
    String selectedTeacherName = schedule?.teacherName ?? '';

    String subject = schedule?.subject ?? '';
    String className = schedule?.className ?? '';
    String day = schedule?.day ?? '';
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (schedule != null &&
        schedule.startTimestamp != null &&
        schedule.endTimestamp != null) {
      final start = schedule.startTimestamp!;
      final end = schedule.endTimestamp!;
      startTime = TimeOfDay(hour: start.hour, minute: start.minute);
      endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    }

    // Ambil data guru (jika admin)
    if (_userRole == 'admin') {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'guru')
              .get();

      if (!mounted) return;

      nameToIdMap = {
        for (var doc in snapshot.docs) (doc.data()['name'] as String): doc.id,
      };

      teacherNames = nameToIdMap.keys.toList();

      // Pastikan nilai dropdown valid
      if (selectedTeacherName.isNotEmpty &&
          !teacherNames.contains(selectedTeacherName)) {
        selectedTeacherName = '';
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_userRole == 'admin')
                        DropdownButtonFormField<String>(
                          value:
                              selectedTeacherName.isNotEmpty
                                  ? selectedTeacherName
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Nama Guru',
                          ),
                          items:
                              teacherNames
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                  .toList(),
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Pilih guru'
                                      : null,
                          onChanged:
                              (val) => setStateDialog(
                                () => selectedTeacherName = val ?? '',
                              ),
                          onSaved: (val) => selectedTeacherName = val ?? '',
                        ),
                      TextFormField(
                        initialValue: subject,
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran',
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                        onSaved: (val) => subject = val ?? '',
                      ),
                      DropdownButtonFormField<String>(
                        value: className.isNotEmpty ? className : null,
                        decoration: const InputDecoration(labelText: 'Kelas'),
                        items:
                            ['10', '11', '12']
                                .map(
                                  (kelas) => DropdownMenuItem<String>(
                                    value: kelas,
                                    child: Text('Kelas $kelas'),
                                  ),
                                )
                                .toList(),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Wajib dipilih'
                                    : null,
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => className = val);
                          }
                        },
                        onSaved: (val) => className = val ?? '',
                      ),
                      DropdownButtonFormField<String>(
                        value: day.isNotEmpty ? day : null,
                        decoration: const InputDecoration(labelText: 'Hari'),
                        items:
                            [
                                  'Senin',
                                  'Selasa',
                                  'Rabu',
                                  'Kamis',
                                  'Jumat',
                                  'Sabtu',
                                  'Minggu',
                                ]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setStateDialog(() => day = val ?? ''),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Pilih hari'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      startTime ??
                                      const TimeOfDay(hour: 7, minute: 0),
                                );
                                if (picked != null) {
                                  setStateDialog(() => startTime = picked);
                                }
                              },
                              child: Text(
                                startTime == null
                                    ? 'Pilih Jam Mulai'
                                    : 'Mulai: ${startTime!.format(context)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      endTime ??
                                      const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (picked != null) {
                                  setStateDialog(() => endTime = picked);
                                }
                              },
                              child: Text(
                                endTime == null
                                    ? 'Pilih Jam Selesai'
                                    : 'Selesai: ${endTime!.format(context)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate() ||
                        startTime == null ||
                        endTime == null) {
                      return;
                    }

                    formKey.currentState!.save();

                    final now = DateTime.now();
                    final startDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      startTime!.hour,
                      startTime!.minute,
                    );
                    final endDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      endTime!.hour,
                      endTime!.minute,
                    );

                    final newSchedule = ScheduleModel(
                      id: schedule?.id ?? '',
                      teacherId:
                          _userRole == 'admin'
                              ? nameToIdMap[selectedTeacherName] ?? ''
                              : _user!.uid,
                      teacherName:
                          _userRole == 'admin'
                              ? selectedTeacherName
                              : (_teacherName ?? ''),
                      subject: subject,
                      className: className,
                      day: day,
                      startTimestamp: startDateTime,
                      endTimestamp: endDateTime,
                    );

                    if (schedule == null) {
                      await _controller.addSchedule(newSchedule);
                    } else {
                      await _controller.updateSchedule(
                        schedule.id,
                        newSchedule,
                      );
                    }

                    await _fetchSchedules();
                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {
                        selectedDay = 'Semua';
                        selectedClass = 'Semua';
                      });
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus jadwal ini?',
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text('Hapus'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _controller.deleteSchedule(id);
      await _fetchSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

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
                  padding: const EdgeInsets.all(16.0),
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
                              "Kelola Jadwal",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      if (isWideScreen) const SizedBox(height: 24),

                      // Tombol + Filter
                      Row(
                        children: [
                          // Filter Hari
                          DropdownButton<String>(
                            value: selectedDay ?? 'Semua',
                            hint: const Text('Pilih Hari'),
                            items:
                                dayOptions.map((day) {
                                  return DropdownMenuItem(
                                    value: day,
                                    child: Text(
                                      day == 'Semua' ? 'Semua Hari' : day,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() => selectedDay = value);
                            },
                          ),
                          const SizedBox(width: 16),
                          // Filter Kelas
                          DropdownButton<String>(
                            value: selectedClass ?? 'Semua',
                            hint: const Text('Pilih Kelas'),
                            items:
                                classOptions.map((kelas) {
                                  return DropdownMenuItem(
                                    value: kelas,
                                    child: Text(
                                      kelas == 'Semua'
                                          ? 'Semua Kelas'
                                          : 'Kelas $kelas',
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() => selectedClass = value);
                            },
                          ),
                          const Spacer(),
                          if (_userRole == 'admin')
                            // Tombol Tambah Jadwal
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Jadwal'),
                              onPressed: () => _showAddEditDialog(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Expanded untuk GridView agar layout fleksibel
                      Expanded(
                        child:
                            isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : schedules.isEmpty
                                ? const Center(child: Text("Belum ada jadwal."))
                                : filteredSchedules.isEmpty
                                ? const Center(
                                  child: Text(
                                    "Tidak ada jadwal sesuai filter.",
                                  ),
                                )
                                : GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 300,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        childAspectRatio: 1.4,
                                      ),
                                  itemCount: filteredSchedules.length,
                                  itemBuilder: (context, index) {
                                    final schedule = filteredSchedules[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min, // <= Solusi penting!
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (_userRole == 'admin')
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _showAddEditDialog(
                                                          schedule: schedule,
                                                        );
                                                      },
                                                    ),
                                                  if (_userRole == 'admin')
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _deleteSchedule(
                                                          schedule.id,
                                                        );
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              schedule.subject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                _userRole == 'admin'
                                                    ? 'Guru: ${schedule.teacherName}'
                                                    : '',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Kelas : ${schedule.className}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${schedule.day}, ${timeFormat.format(schedule.startTimestamp!)} - ${timeFormat.format(schedule.endTimestamp!)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
