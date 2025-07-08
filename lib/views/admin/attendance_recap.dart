import 'package:absensi_smk_pakusarakan/controllers/attendance_controller.dart';
import 'package:absensi_smk_pakusarakan/controllers/history_controller.dart';
import 'package:absensi_smk_pakusarakan/models/attendance_model.dart';
import 'package:absensi_smk_pakusarakan/views/admin/admin_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:universal_html/html.dart' as html;

class AttendanceRecap extends StatefulWidget {
  const AttendanceRecap({super.key});

  @override
  State<AttendanceRecap> createState() => _AttendanceRecapState();
}

class _AttendanceRecapState extends State<AttendanceRecap> {
  final HistoryController _historyController = HistoryController();
  final AttendanceController _attendanceController = AttendanceController();
  late Future<List<AttendanceModel>> _attendanceDataFuture;

  bool isSidebarVisible = true;

  String selectedClass = 'Semua';
  String searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  List<String> classOptions = ['Semua', '10', '11', '12'];
  List<String> teacherSubjects = [];
  String? selectedSubject;

  Map<String, dynamic>? userData;

  String get currentUserRole => userData?['role'] ?? 'guru';

  @override
  void initState() {
    super.initState();
    _attendanceDataFuture = _historyController.fetchLecturerAttendanceData();
    _loadUserData();
  }

  void _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userData = data;
        });

        if (data?['role'] == 'guru') {
          final scheduleSnapshot =
              await FirebaseFirestore.instance
                  .collection('schedules')
                  .where('teacherId', isEqualTo: uid)
                  .get();

          final subjects =
              scheduleSnapshot.docs
                  .map((doc) => doc['subject'] as String)
                  .toSet()
                  .toList();

          setState(() {
            teacherSubjects = subjects;
            selectedSubject = 'Semua';
          });
        } else if (data?['role'] == 'admin') {
          final scheduleSnapshot =
              await FirebaseFirestore.instance.collection('schedules').get();

          final subjects =
              scheduleSnapshot.docs
                  .map((doc) => doc['subject'] as String)
                  .toSet()
                  .toList();

          setState(() {
            teacherSubjects = subjects;
            selectedSubject = 'Semua';
          });
        }

        _loadAttendanceData(data?['role'] ?? 'guru');
      }
    }
  }

  void _loadAttendanceData(String currentUserRole) {
    setState(() {
      _attendanceDataFuture = _attendanceController.getFilteredAttendance(
        currentUserRole: currentUserRole,
        kelas: selectedClass,
        query: searchQuery,
        startDate: _startDate,
        endDate: _endDate,
        subject: selectedSubject,
      );
    });
  }

  Future<void> exportToExcel(List<AttendanceModel> data) async {
    final workbook = xlsio.Workbook();
    final groupedByClass = <String, List<AttendanceModel>>{};
    for (var data in data) {
      groupedByClass.putIfAbsent(data.studentClass, () => []).add(data);
    }

    final sheet = workbook.worksheets[0];

    final headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.bold = true;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    headerStyle.borders.all.color = '#000000';
    headerStyle.borders.bottom.lineStyle = xlsio.LineStyle.thick;

    final dataStyle = workbook.styles.add('DataStyle');
    dataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    dataStyle.borders.all.color = '#000000';

    if (selectedClass != 'Semua') {
      sheet.name = 'Kelas $selectedClass';
      _fillSheet(sheet, data, headerStyle, dataStyle);
    } else {
      final kelasPertama = groupedByClass.keys.first;
      sheet.name = 'Kelas $kelasPertama';
      _fillSheet(sheet, groupedByClass[kelasPertama]!, headerStyle, dataStyle);

      for (var kelas in groupedByClass.keys.skip(1)) {
        final newSheet = workbook.worksheets.addWithName('Kelas $kelas');
        _fillSheet(newSheet, groupedByClass[kelas]!, headerStyle, dataStyle);
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'rekap_absensi.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _fillSheet(
    xlsio.Worksheet sheet,
    List<AttendanceModel> data,
    xlsio.Style headerStyle,
    xlsio.Style dataStyle,
  ) {
    final headers = [
      'No.',
      'Nama',
      'NIS',
      'Kelas',
      'Mata Pelajaran',
      'Tanggal',
      'Waktu',
      'Status',
    ];

    // Header
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.getRangeByIndex(1, col + 1);
      cell.setText(headers[col]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < data.length; i++) {
      final model = data[i];
      final date =
          model.timestamp is Timestamp
              ? (model.timestamp as Timestamp).toDate()
              : null;

      final row = i + 2;

      final rowValues = [
        (i + 1).toString(),
        model.studentName,
        model.studentNumber,
        model.studentClass,
        model.subject,
        date != null ? "${date.day}-${date.month}-${date.year}" : "-",
        date != null
            ? "${date.hour}:${date.minute.toString().padLeft(2, '0')}"
            : "-",
        model.status,
      ];

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.getRangeByIndex(row, col + 1);
        cell.setText(rowValues[col]);
        cell.cellStyle = dataStyle;
      }
    }

    for (int col = 1; col <= headers.length; col++) {
      sheet.autoFitColumn(col);
    }
  }

  void _confirmDelete(String attendanceId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text(
            "Apakah Anda yakin ingin menghapus data absensi ini?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                // Tutup dialog konfirmasi
                navigator.pop();

                try {
                  await _attendanceController.deleteAttendance(attendanceId);

                  if (!mounted) return;

                  setState(() {
                    _attendanceDataFuture =
                        currentUserRole == 'admin'
                            ? _historyController.fetchAdminAttendanceData()
                            : _historyController.fetchLecturerAttendanceData();
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Data absensi berhasil dihapus."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus data: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime tempStart = _startDate ?? DateTime.now();
    DateTime tempEnd = _endDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pilih Rentang Tanggal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: Text(DateFormat('dd MMM yyyy').format(tempStart)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStart,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          tempStart = picked;
                          // Pastikan end date tidak sebelum start date
                          if (tempEnd.isBefore(tempStart)) {
                            tempEnd = picked;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: Text(DateFormat('dd MMM yyyy').format(tempEnd)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEnd,
                        firstDate: tempStart,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          tempEnd = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = tempStart;
                      _endDate = tempEnd;
                      _attendanceDataFuture = _attendanceController
                          .getFilteredAttendance(
                            currentUserRole: currentUserRole,
                            kelas: selectedClass,
                            query: searchQuery,
                            startDate: _startDate,
                            endDate: _endDate,
                          );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(AttendanceModel model) async {
    String selectedStatus = model.status;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ubah Status Kehadiran"),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            onChanged: (value) {
              selectedStatus = value!;
            },
            items:
                ['Hadir', 'Izin', 'Sakit', 'Tidak Hadir']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                await _attendanceController.updateAttendanceStatus(
                  attendanceId: model.id,
                  newStatus: selectedStatus,
                );

                if (!mounted) return;

                setState(() {
                  _loadAttendanceData(currentUserRole); // ← PENTING!
                });

                navigator.pop();
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _showAddAttendanceDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final nisController = TextEditingController();

    String? kelas;
    String status = 'Hadir';
    String? subject;
    DateTime selectedDate = DateTime.now();

    final String? teacherId = userData?['uid'];
    final String? teacherName = userData?['name'];

    if (teacherId == null || teacherName == null) {
      return;
    }

    final students = await _attendanceController.fetchStudentsByTeacher(
      teacherId,
    );

    // log('[DEBUG] Jumlah siswa ditemukan: ${students.length}');

    List<String> subjectList = [];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void updateFromName(String name) {
              final student = students.firstWhere(
                (s) =>
                    s['name']?.toString().toLowerCase() == name.toLowerCase(),
                orElse: () => {},
              );

              if (student.isEmpty || !student.containsKey('studentClass')) {
                // log('[DEBUG] Nama "$name" tidak ditemukan.');
                return;
              }

              // log('[DEBUG] Nama dipilih: ${student['name']}');
              nisController.text = student['idNumber'] ?? '';
              kelas = student['studentClass'];

              setStateDialog(() {
                subject = null;
                subjectList = [];
              });

              _updateSubjectListByClass(kelas, teacherId, setStateDialog).then((
                list,
              ) {
                setStateDialog(() {
                  subjectList = list;
                });
              });
            }

            void updateFromNIS(String nis) {
              final student = students.firstWhere(
                (s) => s['idNumber'] == nis,
                orElse: () => {},
              );

              // if (student.isEmpty || !student.containsKey('studentClass')) {
              //   log('[DEBUG] NIS "$nis" tidak ditemukan.');
              //   return;
              // }

              // log('[DEBUG] NIS dipilih: ${student['idNumber']}');
              nameController.text = student['name'] ?? '';
              kelas = student['studentClass'];

              setStateDialog(() {
                subject = null;
                subjectList = [];
              });

              _updateSubjectListByClass(kelas, teacherId, setStateDialog).then((
                list,
              ) {
                setStateDialog(() {
                  subjectList = list;
                });
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Tambah Absensi Manual'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        optionsBuilder: (text) {
                          final input = text.text.trim().toLowerCase();
                          // log('[DEBUG] Input nama: "$input"');

                          if (input.isEmpty) {
                            return const Iterable<String>.empty();
                          }

                          final results =
                              students
                                  .map(
                                    (e) => e['name']?.toString().trim() ?? '',
                                  )
                                  .where((name) => name.isNotEmpty)
                                  .where((name) {
                                    final match = name.toLowerCase().contains(
                                      input,
                                    );
                                    // log('[DEBUG] Cek match: $name → $match');
                                    return match;
                                  })
                                  .toSet();

                          // log('[DEBUG] Hasil suggestions: ${results.toList()}');
                          return results;
                        },
                        onSelected: (val) {
                          nameController.text = val;
                          updateFromName(val);
                        },
                        fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                          if (ctrl.text.isEmpty) {
                            ctrl.text = nameController.text;
                          }
                          return TextFormField(
                            controller: ctrl,
                            focusNode: focus,
                            decoration: const InputDecoration(
                              labelText: 'Nama',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final filtered =
                              options
                                  .map((o) => o.trim())
                                  .where((o) => o.isNotEmpty)
                                  .toList();
                          final dropdownHeight = (filtered.length * 48.0).clamp(
                            0.0,
                            200.0,
                          );

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 400,
                                  maxHeight: dropdownHeight,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final option = filtered[index];
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nisController,
                        decoration: const InputDecoration(
                          labelText: 'NIS',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: updateFromNIS,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        isDense: true,
                        value: status,
                        onChanged: (val) => status = val!,
                        items:
                            ['Hadir', 'Izin', 'Sakit', 'Tidak Hadir']
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(
                                      val,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey(subjectList.join()),
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        isDense: true,
                        value: subject,
                        onChanged: (val) => setStateDialog(() => subject = val),
                        validator:
                            (val) =>
                                val == null ? 'Pilih mata pelajaran' : null,
                        items:
                            subjectList
                                .map(
                                  (mapel) => DropdownMenuItem<String>(
                                    value: mapel,
                                    child: Text(
                                      mapel,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tanggal: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final now = DateTime.now();
                    final finalDate = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      now.hour,
                      now.minute,
                    );

                    final scheduleId = await _attendanceController
                        .getScheduleIdBySubjectAndTeacher(
                          subject: subject!,
                          teacherId: teacherId,
                        );

                    if (!context.mounted) return;
                    if (scheduleId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Jadwal tidak ditemukan"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await _attendanceController.addManualAttendance(
                      studentName: nameController.text,
                      studentNumber: nisController.text,
                      studentClass: kelas!,
                      timestamp: finalDate,
                      status: status,
                      subject: subject!,
                      scheduleId: scheduleId,
                      teacherName: teacherName,
                    );

                    if (!mounted) return;
                    setState(() {
                      _attendanceDataFuture =
                          _historyController.fetchLecturerAttendanceData();
                    });

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
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

  Future<List<String>> _updateSubjectListByClass(
    String? kelas,
    String? teacherId,
    void Function(void Function()) setStateDialog,
  ) async {
    if (kelas == null || teacherId == null) return [];
    return await _attendanceController.getSubjectsByClass(
      className: kelas,
      teacherId: teacherId,
    );
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
                              "Rekap Kehadiran Siswa",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: selectedClass,
                              items:
                                  classOptions.map((val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text("Kelas: $val"),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedClass = val!;
                                });
                              },
                            ),

                            if (teacherSubjects.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: DropdownButton<String>(
                                  value: selectedSubject,
                                  hint: const Text("Pilih Mapel"),
                                  items:
                                      [
                                        'Semua',
                                        ...teacherSubjects.map(
                                          (e) => _attendanceController
                                              .toTitleCase(e),
                                        ),
                                      ].map((subject) {
                                        return DropdownMenuItem<String>(
                                          value: subject,
                                          child: Text("Mapel: $subject"),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSubject = value!;
                                      _attendanceDataFuture =
                                          _attendanceController
                                              .getFilteredAttendance(
                                                currentUserRole:
                                                    currentUserRole,
                                                kelas: selectedClass,
                                                query: searchQuery,
                                                startDate: _startDate,
                                                endDate: _endDate,
                                                subject:
                                                    value == 'Semua'
                                                        ? null
                                                        : _attendanceController
                                                            .toTitleCase(value),
                                              );
                                    });
                                  },
                                ),
                              ),

                            const SizedBox(width: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _selectDateRange(context),
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    _startDate != null && _endDate != null
                                        ? "${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}"
                                        : "Pilih Rentang Tanggal",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_startDate != null && _endDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _startDate = null;
                                        _endDate = null;
                                        _attendanceDataFuture =
                                            _attendanceController
                                                .getFilteredAttendance(
                                                  currentUserRole:
                                                      currentUserRole,
                                                  kelas: selectedClass,
                                                  query: searchQuery,
                                                  startDate: null,
                                                  endDate: null,
                                                );
                                      });
                                    },
                                    tooltip: 'Clear Filter',
                                  ),
                              ],
                            ),

                            const SizedBox(width: 16),
                            SizedBox(
                              width: 300,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Cari siswa...',
                                  prefixIcon: const Icon(Icons.search),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 12.0,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          if (currentUserRole != 'admin')
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Absensi'),
                              onPressed: _showAddAttendanceDialog,
                            ),

                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text("Export to Excel"),
                            onPressed: () async {
                              final data = await _attendanceDataFuture;
                              final filtered = _attendanceController
                                  .filterAndSearch(
                                    list: data,
                                    selectedClass: selectedClass,
                                    searchQuery: searchQuery,
                                  );

                              await exportToExcel(filtered);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Expanded(
                        child: FutureBuilder<List<AttendanceModel>>(
                          future: _attendanceDataFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Terjadi kesalahan: ${snapshot.error}",
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text("Belum ada data absensi."),
                              );
                            }

                            final filteredList = _attendanceController
                                .filterAndSearch(
                                  list: snapshot.data!,
                                  selectedClass: selectedClass,
                                  searchQuery: searchQuery,
                                );

                            filteredList.sort((a, b) {
                              final aDate =
                                  a.timestamp?.toDate() ?? DateTime(2000);
                              final bDate =
                                  b.timestamp?.toDate() ?? DateTime(2000);
                              return bDate.compareTo(aDate); // Sort descending
                            });

                            if (filteredList.isEmpty) {
                              return const Center(
                                child: Text("Data tidak ditemukan."),
                              );
                            }

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                border: TableBorder.all(
                                  width: 1,
                                  color: Colors.grey,
                                ),
                                headingRowColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) => Colors.blue.shade100,
                                    ),
                                columns: [
                                  DataColumn(label: Text('No.')),
                                  DataColumn(label: Text('Nama')),
                                  DataColumn(label: Text('NIS')),
                                  DataColumn(label: Text('Kelas')),
                                  DataColumn(label: Text('Mata Pelajaran')),
                                  DataColumn(label: Text('Tanggal')),
                                  DataColumn(label: Text('Status')),
                                  if (currentUserRole == 'guru')
                                    DataColumn(label: Text('Aksi')),
                                ],
                                rows: List<
                                  DataRow
                                >.generate(filteredList.length, (index) {
                                  final attendance = filteredList[index];
                                  final date =
                                      (attendance.timestamp != null &&
                                              attendance.timestamp is Timestamp)
                                          ? (attendance.timestamp as Timestamp)
                                              .toDate()
                                          : null;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(
                                        Text(
                                          _attendanceController.toTitleCase(
                                            attendance.studentName,
                                          ),
                                        ),
                                      ),

                                      DataCell(Text(attendance.studentNumber)),
                                      DataCell(Text(attendance.studentClass)),
                                      DataCell(
                                        Text(
                                          attendance.qrData['subject'] ?? '-',
                                        ),
                                      ),

                                      DataCell(
                                        Text(
                                          date != null
                                              ? "${date.day}-${date.month}-${date.year}"
                                              : "-",
                                        ),
                                      ),

                                      DataCell(
                                        buildStatusWithIcon(
                                          attendance.qrData['status'] ??
                                              'Tidak Diketahui',
                                        ),
                                      ),
                                      if (currentUserRole == 'guru')
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                tooltip: "Edit",
                                                color: Colors.blue,
                                                onPressed: () {
                                                  _showEditDialog(attendance);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                tooltip: "Hapus",
                                                color: Colors.red,
                                                onPressed: () {
                                                  _confirmDelete(attendance.id);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                }),
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

Widget buildStatusWithIcon(String status) {
  IconData icon;
  Color color;

  switch (status.toLowerCase()) {
    case 'hadir':
      icon = Icons.check_circle;
      color = Colors.green;
      break;
    case 'tidak hadir':
      icon = Icons.cancel;
      color = Colors.red;
      break;
    case 'sakit':
      icon = Icons.healing;
      color = Colors.orange;
      break;
    case 'izin':
      icon = Icons.info;
      color = Colors.blue;
      break;
    default:
      icon = Icons.help;
      color = Colors.grey;
  }

  return Row(
    children: [
      Text(status),
      const SizedBox(width: 6),
      Icon(icon, color: color, size: 20),
    ],
  );
}
