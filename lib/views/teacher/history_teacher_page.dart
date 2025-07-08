import 'package:absensi_smk_pakusarakan/controllers/history_controller.dart';
import 'package:absensi_smk_pakusarakan/models/attendance_model.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/widget/attendance_detail_card_teacher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class HistoryTeacherPage extends StatefulWidget {
  const HistoryTeacherPage({super.key});

  @override
  State<HistoryTeacherPage> createState() => _HistoryTeacherPageState();
}

class _HistoryTeacherPageState extends State<HistoryTeacherPage> {
  late Future<List<AttendanceModel>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = HistoryController().fetchLecturerAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran Siswa'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<AttendanceModel>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 300,
                    child: Lottie.asset('images/404-notfound.json'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Terjadi Kesalahan.",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 300,
                    child: Lottie.asset('images/empty-data.json'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Belum ada data absen.",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final attendance = data[index];
              final qrData = attendance.qrData;

              return AttendanceDetailCardTeacher(
                date: qrData['date'] ?? "-",
                day: qrData['day'] ?? "-",
                timeIn: qrData['time'] ?? "-",
                subject: qrData['subject'] ?? "-",
                status: qrData['status'] ?? "Tidak Diketahui",
                student: attendance.studentName,
                studentNumber: attendance.studentNumber,
                studentClass: attendance.studentClass,
                scheduleId: attendance.scheduleId,
              );
            },
          );
        },
      ),
    );
  }
}
