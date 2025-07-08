import 'package:absensi_smk_pakusarakan/controllers/schedule_controller.dart';
import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:absensi_smk_pakusarakan/views/student/widget/schedule_card_student.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ScheduleStudentPage extends StatefulWidget {
  const ScheduleStudentPage({super.key});

  @override
  State<ScheduleStudentPage> createState() => _ScheduleStudentPageState();
}

class _ScheduleStudentPageState extends State<ScheduleStudentPage> {
  final ScheduleController _scheduleController = ScheduleController();
  late Future<List<ScheduleModel>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _schedulesFuture = _loadStudentSchedules();
  }

  Future<List<ScheduleModel>> _loadStudentSchedules() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!userDoc.exists) return [];

    final className = userDoc['studentClass'] as String? ?? '';

    List<ScheduleModel> schedules = await _scheduleController
        .fetchSchedulesForStudent(className);

    // Sorting by day and time
    schedules.sort((a, b) {
      const dayOrder = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];

      final indexA = dayOrder.indexOf(a.day);
      final indexB = dayOrder.indexOf(b.day);

      if (indexA != indexB) return indexA.compareTo(indexB);

      final startA = a.startTimestamp ?? DateTime(0);
      final startB = b.startTimestamp ?? DateTime(0);

      return startA.compareTo(startB);
    });

    return schedules;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Mata Pelajaran'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<ScheduleModel>>(
        future: _schedulesFuture,
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
                    child: Lottie.asset('images/account-setup.json'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Lengkapi data pribadi Anda.",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          final schedules = snapshot.data;
          if (schedules == null || schedules.isEmpty) {
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
                    "Tidak ada jadwal untuk Anda.",
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
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, i) {
              return ScheduleCardStudent(schedule: schedules[i]);
            },
          );
        },
      ),
    );
  }
}
