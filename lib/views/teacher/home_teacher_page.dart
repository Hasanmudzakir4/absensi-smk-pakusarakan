import 'package:absensi_smk_pakusarakan/controllers/home_controller.dart';
import 'package:absensi_smk_pakusarakan/controllers/profile_controller.dart';
import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:absensi_smk_pakusarakan/models/user_model.dart';
import 'package:absensi_smk_pakusarakan/views/components/widgets/announcement_card.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/widget/schedule_card_home_teacher.dart';
import 'package:flutter/material.dart';

class HomeTeacherPage extends StatefulWidget {
  const HomeTeacherPage({super.key});

  @override
  HomeTeacherPageState createState() => HomeTeacherPageState();
}

class HomeTeacherPageState extends State<HomeTeacherPage> {
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
            return const Center(child: Text("Gagal mengambil data profil"));
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
                          const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage('images/profil.png'),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, ${user.name ?? 'User'}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "NIP ${user.idNumber ?? '?'}",
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
                  future: _homeController.fetchSchedulesForTodayLecturer(
                    user.name ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text("Terjadi kesalahan: ${snapshot.error}"),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Tidak ada jadwal untuk hari ini."),
                      );
                    }

                    List<ScheduleModel> schedules = snapshot.data!;

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
                          className: schedule.className,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
