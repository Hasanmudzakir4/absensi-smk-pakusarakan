import 'package:absensi_smk_pakusarakan/controllers/schedule_controller.dart';
import 'package:absensi_smk_pakusarakan/models/schedule_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ScheduleListWidget extends StatelessWidget {
  final String? teacherName;
  final ScheduleController controller;
  final Function(ScheduleModel) onEdit;
  final Function(ScheduleModel) onDelete;

  const ScheduleListWidget({
    super.key,
    required this.teacherName,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (teacherName == null) {
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

    return FutureBuilder<List<ScheduleModel>>(
      future: controller.fetchSchedulesByTeacher(teacherName!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Terjadi kesalahan"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                  "Tidak ada jadwal.",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final List<String> daysOrder = [
          "Senin",
          "Selasa",
          "Rabu",
          "Kamis",
          "Jumat",
          "Sabtu",
          "Minggu",
        ];

        schedules.sort((a, b) {
          int indexA = daysOrder.indexOf(a.day);
          int indexB = daysOrder.indexOf(b.day);
          if (indexA != indexB) return indexA.compareTo(indexB);
          return a.startTimestamp!.compareTo(b.startTimestamp!);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schedule.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () => onEdit(schedule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => onDelete(schedule),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _infoRow(Icons.calendar_today, "Hari: ${schedule.day}"),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.access_time,
                      "Jam: ${_formatTime(schedule.startTimestamp)} - ${_formatTime(schedule.endTimestamp)}",
                    ),
                    const SizedBox(height: 6),
                    _infoRow(Icons.class_, "Kelas: ${schedule.className}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "-";
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
