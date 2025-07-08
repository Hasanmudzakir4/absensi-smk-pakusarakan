import 'package:absensi_smk_pakusarakan/controllers/teacher_controller.dart';
import 'package:absensi_smk_pakusarakan/views/admin/admin_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:universal_html/html.dart' as html;

class ManageTeacher extends StatefulWidget {
  const ManageTeacher({super.key});

  @override
  State<ManageTeacher> createState() => _ManageTeacherState();
}

class _ManageTeacherState extends State<ManageTeacher> {
  final TeacherController _teacherController = TeacherController();

  List<Map<String, dynamic>> teacher = [];
  List<Map<String, dynamic>> filteredTeacher = [];
  bool isSidebarVisible = true;
  bool isLoading = true;
  String searchQuery = '';

  // Pagination variables
  int currentPage = 0;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  int get totalPages => (filteredTeacher.length / rowsPerPage).ceil();

  List<Map<String, dynamic>> get paginatedTeacher {
    final startIndex = currentPage * rowsPerPage;
    final endIndex = startIndex + rowsPerPage;
    if (startIndex >= filteredTeacher.length) {
      return [];
    }
    return filteredTeacher.sublist(
      startIndex,
      endIndex > filteredTeacher.length ? filteredTeacher.length : endIndex,
    );
  }

  Future<void> _loadTeacher() async {
    final result = await _teacherController.getAllTeachers();
    if (!mounted) return;

    setState(() {
      teacher = result;
      isLoading = false;
    });

    _applyFilters(); // Aman karena sudah di luar setState
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(teacher);

    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      temp =
          temp.where((s) {
            return [
              s['name'],
              s['idNumber'],
              s['dateOfBirth'],
              s['phone'],
              s['email'],
            ].any(
              (field) =>
                  (field ?? '').toString().toLowerCase().contains(lowerQuery),
            );
          }).toList();
    }

    setState(() {
      filteredTeacher = temp;
      currentPage = 0;
    });
  }

  Future<void> exportToExcel(List<Map<String, dynamic>> data) async {
    final workbook = xlsio.Workbook();

    final worksheet = workbook.worksheets[0];
    worksheet.name = 'Data Guru';

    final headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.bold = true;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

    final dataStyle = workbook.styles.add('DataStyle');
    dataStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

    final headers = [
      'No.',
      'Nama',
      'NIP',
      'Tempat, Tanggal Lahir',
      'No. Telepon',
      'Email',
    ];

    // Header
    for (int col = 0; col < headers.length; col++) {
      final cell = worksheet.getRangeByIndex(1, col + 1);
      cell.setText(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Data
    for (int i = 0; i < data.length; i++) {
      final teacher = data[i];
      final row = i + 2;
      final rowValues = [
        '${i + 1}',
        teacher['name'] ?? '',
        teacher['idNumber'] ?? '',
        teacher['dateOfBirth'] ?? '',
        teacher['phone'] ?? '',
        teacher['email'] ?? '',
      ];

      for (int col = 0; col < rowValues.length; col++) {
        final cell = worksheet.getRangeByIndex(row, col + 1);
        cell.setText(rowValues[col]);
        cell.cellStyle = dataStyle;
      }
    }

    for (int col = 1; col <= headers.length; col++) {
      worksheet.autoFitColumn(col);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'data_guru.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  String _capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
        )
        .join(' ');
  }

  void _showEditTeacherDialog(Map<String, dynamic> teacher) {
    final nameController = TextEditingController(text: teacher['name'] ?? '');
    final nipController = TextEditingController(
      text: teacher['idNumber'] ?? '',
    );
    final phoneController = TextEditingController(text: teacher['phone'] ?? '');

    // Pisahkan tempat & tanggal lahir
    final String rawBirth = teacher['dateOfBirth'] ?? '';
    final List<String> split = rawBirth.split(',');

    final birthPlaceController = TextEditingController(
      text: split.isNotEmpty ? split[0].trim() : '',
    );

    DateTime? selectedDate;
    if (split.length > 1) {
      try {
        final parts = split[1].trim().split('/');
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (_) {}
    }

    final birthDateController = TextEditingController(
      text:
          selectedDate != null
              ? "${selectedDate.day.toString().padLeft(2, '0')}/"
                  "${selectedDate.month.toString().padLeft(2, '0')}/"
                  "${selectedDate.year}"
              : '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Data Guru"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  TextField(
                    controller: nipController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Induk Pegawai',
                    ),
                  ),

                  TextField(
                    controller: birthPlaceController,
                    decoration: const InputDecoration(
                      labelText: 'Tempat Lahir',
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime(2005),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        birthDateController.text =
                            "${picked.day.toString().padLeft(2, '0')}/"
                            "${picked.month.toString().padLeft(2, '0')}/"
                            "${picked.year}";
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: birthDateController,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Lahir',
                          hintText: 'Pilih tanggal',
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'No Telepon'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final uid = teacher['uid'];
                  if (uid == null || selectedDate == null) return;

                  final formattedDate = birthDateController.text.trim();
                  final fullBirth =
                      "${birthPlaceController.text.trim()}, $formattedDate";

                  final updatedData = {
                    'name': nameController.text.trim(),
                    'idNumber': nipController.text.trim(),
                    'dateOfBirth': fullBirth,
                    'phone': phoneController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update(updatedData);

                    if (!context.mounted) return;

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Data Guru berhasil diperbarui"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadTeacher(); // Refresh data tabel
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("❌ Gagal mengupdate guru: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTeacher(
    BuildContext context,
    String? uid,
    String name,
  ) async {
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ UID siswa tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 🔐 Ambil token dari user login saat ini
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Kamu belum login ke Firebase.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final idToken = await user.getIdToken();

      // 🔗 Endpoint HTTPS Cloud Function
      final url = Uri.parse(
        'https://deleteuseraccount-5px5kjkloq-uc.a.run.app/',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $name berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTeacher(); // refresh
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${data['message'] ?? 'Gagal menghapus $name'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final err = jsonDecode(response.body);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${err['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Terjadi kesalahan: $e');
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                                  isSidebarVisible
                                      ? Icons.menu_open
                                      : Icons.menu,
                                ),
                                onPressed: () {
                                  setState(
                                    () => isSidebarVisible = !isSidebarVisible,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Kelola Guru",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Cari guru...',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => searchQuery = value);
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text("Export to Excel"),
                          onPressed:
                              () => exportToExcel(
                                filteredTeacher,
                              ), // Ganti sesuai variabel guru
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child:
                              isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : filteredTeacher.isEmpty
                                  ? const Center(
                                    child: Text("Guru tidak ditemukan."),
                                  )
                                  : Column(
                                    children: [
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _verticalScrollController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller:
                                                _verticalScrollController,
                                            child: Scrollbar(
                                              controller:
                                                  _horizontalScrollController,
                                              thumbVisibility: true,
                                              notificationPredicate:
                                                  (notif) =>
                                                      notif.metrics.axis ==
                                                      Axis.horizontal,
                                              child: SingleChildScrollView(
                                                controller:
                                                    _horizontalScrollController,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: DataTable(
                                                  headingRowColor:
                                                      WidgetStateProperty.all(
                                                        Colors.grey[200],
                                                      ),
                                                  columns: const [
                                                    DataColumn(
                                                      label: Text("No."),
                                                    ),
                                                    DataColumn(
                                                      label: Text("Nama"),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        "Nomor Induk Pegawai",
                                                      ),
                                                    ),

                                                    DataColumn(
                                                      label: Text(
                                                        "Tempat, Tanggal Lahir",
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        "No. Telepon",
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text("Email"),
                                                    ),
                                                    DataColumn(
                                                      label: Text("Aksi"),
                                                    ),
                                                  ],
                                                  rows: List.generate(paginatedTeacher.length, (
                                                    index,
                                                  ) {
                                                    final teacher =
                                                        paginatedTeacher[index];
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Text(
                                                            '${currentPage * rowsPerPage + index + 1}',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            _capitalizeEachWord(
                                                              teacher['name'] ??
                                                                  '-',
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            teacher['idNumber'] ??
                                                                '-',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            teacher['dateOfBirth'] ??
                                                                '-',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            teacher['phone'] ??
                                                                '-',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            teacher['email'] ??
                                                                '-',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Row(
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.edit,
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                                tooltip: 'Edit',
                                                                onPressed: () {
                                                                  _showEditTeacherDialog(
                                                                    teacher,
                                                                  );
                                                                },
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.delete,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                tooltip:
                                                                    'Hapus',
                                                                onPressed: () async {
                                                                  final confirm = await showDialog<
                                                                    bool
                                                                  >(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          context,
                                                                        ) => AlertDialog(
                                                                          title: const Text(
                                                                            'Konfirmasi',
                                                                          ),
                                                                          content: Text(
                                                                            'Apakah Anda yakin ingin menghapus guru "${teacher['name']}"?',
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed:
                                                                                  () => Navigator.of(
                                                                                    context,
                                                                                  ).pop(
                                                                                    false,
                                                                                  ),
                                                                              child: const Text(
                                                                                'Batal',
                                                                              ),
                                                                            ),
                                                                            ElevatedButton(
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor:
                                                                                    Colors.red,
                                                                              ),
                                                                              onPressed:
                                                                                  () => Navigator.of(
                                                                                    context,
                                                                                  ).pop(
                                                                                    true,
                                                                                  ),
                                                                              child: const Text(
                                                                                'Hapus',
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                  );
                                                                  if (!context
                                                                      .mounted) {
                                                                    return;
                                                                  }
                                                                  if (confirm ==
                                                                      true) {
                                                                    _deleteTeacher(
                                                                      context,
                                                                      teacher['uid'],
                                                                      teacher['name'],
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (currentPage > 0)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_back_ios,
                                                ),
                                                onPressed: () {
                                                  setState(() => currentPage--);
                                                },
                                              ),
                                            ...List.generate(totalPages, (
                                              index,
                                            ) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            currentPage == index
                                                                ? Colors.blue
                                                                : Colors
                                                                    .grey[300],
                                                        foregroundColor:
                                                            currentPage == index
                                                                ? Colors.white
                                                                : Colors.black,
                                                        minimumSize: const Size(
                                                          36,
                                                          36,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                  onPressed: () {
                                                    setState(
                                                      () => currentPage = index,
                                                    );
                                                  },
                                                  child: Text('${index + 1}'),
                                                ),
                                              );
                                            }),
                                            if (currentPage < totalPages - 1)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_forward_ios,
                                                ),
                                                onPressed: () {
                                                  setState(() => currentPage++);
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
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
