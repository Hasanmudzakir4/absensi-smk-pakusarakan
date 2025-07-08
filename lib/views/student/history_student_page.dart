import 'package:absensi_smk_pakusarakan/controllers/history_controller.dart';
import 'package:absensi_smk_pakusarakan/models/attendance_model.dart';
import 'package:absensi_smk_pakusarakan/views/student/widget/attendance_detail_card_student.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class HistoryStudentPage extends StatefulWidget {
  const HistoryStudentPage({super.key});

  @override
  State<HistoryStudentPage> createState() => _HistoryStudentPageState();
}

class _HistoryStudentPageState extends State<HistoryStudentPage> {
  final HistoryController _controller = HistoryController();

  List<AttendanceModel> allAttendance = [];
  List<AttendanceModel> filteredAttendance = [];

  DateTime? selectedDate;
  String selectedSubject = 'Semua';
  List<String> subjectOptions = ['Semua'];

  String studentClass = ''; // ambil dari user login

  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    try {
      final data = await _controller.fetchAttendanceData();

      // Ambil kelas siswa dari salah satu absensi (asumsi semua absensi milik siswa yang login)
      if (data.isNotEmpty) {
        studentClass = data.first.studentClass;
      }

      final subjects = await _controller.fetchSubjectsByClass(studentClass);

      setState(() {
        allAttendance = data;
        filteredAttendance = data;
        subjectOptions = ['Semua', ...subjects];
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print(e);
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  void filterAttendanceList() {
    setState(() {
      filteredAttendance =
          allAttendance.where((attendance) {
            final qr = attendance.qrData;
            final subject = qr['subject'] ?? '';
            final date = qr['date'] ?? '';

            final subjectMatches =
                selectedSubject == 'Semua' || subject == selectedSubject;

            final dateMatches =
                selectedDate == null || date == formatDate(selectedDate!);

            return subjectMatches && dateMatches;
          }).toList();
    });
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Kehadiran"),
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : isError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300,
                      child: Lottie.asset('assets/images/account-setup.json'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Gagal memuat data. Silakan coba lagi.",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        // Filter Mata Pelajaran
                        DropdownButtonFormField<String>(
                          value: selectedSubject,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Mata Pelajaran',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                          items:
                              subjectOptions.map((subject) {
                                return DropdownMenuItem(
                                  value: subject,
                                  child: Text(
                                    subject,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            selectedSubject = value!;
                            filterAttendanceList();
                          },
                        ),

                        const SizedBox(height: 10),

                        // Filter Tanggal
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedDate != null
                                      ? formatDate(selectedDate!)
                                      : "Belum dipilih",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2023),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    selectedDate = picked;
                                    filterAttendanceList();
                                  }
                                },
                                child: const Text(
                                  "Pilih",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              if (selectedDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    selectedDate = null;
                                    filterAttendanceList();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hasil / List Absensi
                  Expanded(
                    child:
                        filteredAttendance.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 300,
                                    child: Lottie.asset(
                                      'assets/images/empty-data.json',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Tidak ada data absensi.",
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredAttendance.length,
                              itemBuilder: (context, index) {
                                final attendance = filteredAttendance[index];
                                final qrData = attendance.qrData;

                                return AttendanceDetailCardStudent(
                                  date: qrData['date'] ?? "-",
                                  day: qrData['day'] ?? "-",
                                  timeIn: qrData['time'] ?? "-",
                                  subject: qrData['subject'] ?? "-",
                                  teacher: qrData['teacher'] ?? "-",
                                  status: qrData['status'] ?? "Tidak Diketahui",
                                  scheduleId: attendance.scheduleId,
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
