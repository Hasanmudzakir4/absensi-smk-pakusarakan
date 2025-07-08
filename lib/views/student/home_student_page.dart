import 'package:absensi_smk_pakusarakan/controllers/attendance_controller.dart';
import 'package:absensi_smk_pakusarakan/controllers/home_controller.dart';
import 'package:absensi_smk_pakusarakan/controllers/profile_controller.dart';
import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:absensi_smk_pakusarakan/models/user_model.dart';
import 'package:absensi_smk_pakusarakan/views/components/widgets/announcement_card.dart';
import 'package:absensi_smk_pakusarakan/views/student/widget/schedule_card_home_student.dart';
import 'package:absensi_smk_pakusarakan/views/student/widget/status_card.dart';
import 'package:flutter/material.dart';

class HomeStudentPage extends StatefulWidget {
  const HomeStudentPage({super.key});

  @override
  HomeStudentPageState createState() => HomeStudentPageState();
}

class HomeStudentPageState extends State<HomeStudentPage> {
  final HomeController _homeController = HomeController();
  final ProfileController _profileController = ProfileController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<UserModel?>(
        future: _profileController.getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Gagal mengambil data profil."));
          }

          UserModel user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade900, Colors.blue.shade400],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                user.photoUrl != null &&
                                        user.photoUrl!.isNotEmpty
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                            backgroundColor: Colors.white,
                            child:
                                (user.photoUrl == null ||
                                        user.photoUrl!.isEmpty)
                                    ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.blue,
                                    )
                                    : null,
                          ),

                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hallo, ${user.name ?? 'User'}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "NIS ${user.idNumber ?? '?'} | Kelas ${user.studentClass ?? '?'}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // STATUS KEHADIRAN
                FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    AttendanceController().getLastAttendanceToday(user.uid),
                    AttendanceController().hasScheduleToday(user.studentClass!),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Text("Gagal memuat status kehadiran");
                    }

                    final attendanceData =
                        snapshot.data![0] as Map<String, String>?;
                    final hasSchedule = snapshot.data![1] as bool;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: StatusCard(
                        subject: attendanceData?['subject'],
                        time: attendanceData?['time'],
                        hasSchedule: hasSchedule,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // JADWAL PELAJARAN
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "📅 Jadwal Hari Ini",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                FutureBuilder<List<ScheduleModel>>(
                  future: _homeController.fetchSchedulesForTodayStudent(
                    user.studentClass ?? '',
                  ),
                  builder: (context, scheduleSnapshot) {
                    if (scheduleSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (scheduleSnapshot.hasError) {
                      return Center(
                        child: Text("Error: ${scheduleSnapshot.error}"),
                      );
                    } else if (!scheduleSnapshot.hasData ||
                        scheduleSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Tidak ada kelas hari ini."),
                      );
                    }

                    List<ScheduleModel> schedules = scheduleSnapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        return ScheduleCard(
                          startTime: schedule.startTimestamp!,
                          endTime: schedule.endTimestamp!,
                          subject: schedule.subject,
                          teacher: schedule.teacherName,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // PENGUMUMAN
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "📢 Pengumuman",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementCard(
                    text: "🟢 Ujian Tengah Semester mulai 11 Mei 2025!",
                  ),
                ),
                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementCard(
                    text: "🔴 Hari Raya Waisak 12 Mei 2025!",
                  ),
                ),
                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementCard(
                    text: "🟢 Ujian Akhir Semester mulai 11 Juli 2025!",
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
