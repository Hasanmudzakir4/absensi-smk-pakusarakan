import 'package:absensi_smk_pakusarakan/controllers/dashboard_controller.dart';
import 'package:absensi_smk_pakusarakan/views/admin/admin_drawer.dart';
import 'package:absensi_smk_pakusarakan/views/admin/widget/dashboard_card.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DashboardController _dashboardController = DashboardController();

  bool isSidebarVisible = true;

  Map<String, int> studentCounts = {'total': 0, '10': 0, '11': 0, '12': 0};
  int totalSchedules = 0;
  int totalGuru = 0;
  int totalAdmin = 0;

  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadStudentCounts();
    _loadScheduleCount();
    _loadUserCounts();
    _loadUserRole();
  }

  Future<void> _loadScheduleCount() async {
    final count = await _dashboardController.getScheduleCountByCurrentTeacher();
    if (!mounted) return;
    setState(() {
      totalSchedules = count;
    });
  }

  Future<void> _loadStudentCounts() async {
    final counts = await _dashboardController.getStudentCountsByClass();
    if (!mounted) return;
    setState(() {
      studentCounts = counts;
    });
  }

  Future<void> _loadUserRole() async {
    final role =
        await _dashboardController.getCurrentUserRole(); // misal dari Firestore
    if (!mounted) return;
    setState(() {
      userRole = role; // 'admin' atau 'guru'
    });
  }

  Future<void> _loadUserCounts() async {
    final guruCount = await _dashboardController.getUserCountByRole('guru');
    final adminCount = await _dashboardController.getUserCountByRole('admin');

    if (!mounted) return;
    setState(() {
      totalGuru = guruCount;
      totalAdmin = adminCount;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      if (isWideScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                              "Dashboard Admin",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      if (isWideScreen) const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                crossAxisCount: isWideScreen ? 3 : 1,
                                childAspectRatio: 3,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                children: [
                                  DashboardCard(
                                    title: "Total Siswa",
                                    value: "${studentCounts['total']}",
                                    color: Colors.indigo,
                                  ),
                                  DashboardCard(
                                    title: "Siswa Kelas 10",
                                    value: "${studentCounts['10']}",
                                    color: Colors.green,
                                  ),
                                  DashboardCard(
                                    title: "Siswa Kelas 11",
                                    value: "${studentCounts['11']}",
                                    color: Colors.orange,
                                  ),
                                  DashboardCard(
                                    title: "Siswa Kelas 12",
                                    value: "${studentCounts['12']}",
                                    color: Colors.deepPurple,
                                  ),

                                  if (userRole == 'guru')
                                    DashboardCard(
                                      title: "Total Jadwal",
                                      value: "$totalSchedules",
                                      color: Colors.teal,
                                    ),

                                  // Hanya untuk admin
                                  if (userRole == 'admin')
                                    DashboardCard(
                                      title: "Jumlah Guru",
                                      value: "$totalGuru",
                                      color: Colors.pinkAccent,
                                    ),
                                  if (userRole == 'admin')
                                    DashboardCard(
                                      title: "Jumlah Admin",
                                      value: "$totalAdmin",
                                      color: Colors.redAccent,
                                    ),
                                ],
                              ),
                            ],
                          ),
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
