import 'package:absensi_smk_pakusarakan/controllers/profile_controller.dart';
import 'package:absensi_smk_pakusarakan/routes/app_routes.dart';
import 'package:absensi_smk_pakusarakan/views/components/widgets/tab_item_widget.dart';
import 'package:flutter/material.dart';

class TabBarScreen extends StatefulWidget {
  const TabBarScreen({super.key});

  @override
  State<TabBarScreen> createState() => _TabBarScreenState();
}

class _TabBarScreenState extends State<TabBarScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final ProfileController _profileController = ProfileController();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    String? role = await _profileController.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String homeRoute =
        userRole == "guru" ? AppRoutes.homeTeacher : AppRoutes.homeStudent;
    final String historyRoute =
        userRole == "guru"
            ? AppRoutes.historyTeacher
            : AppRoutes.historyStudent;
    final String scanRoute =
        userRole == "guru" ? AppRoutes.barcode : AppRoutes.scan;
    final String scheduleRoute =
        userRole == "guru"
            ? AppRoutes.scheduleTeacher
            : AppRoutes.scheduleStudent;
    final String accountRoute =
        userRole == "guru"
            ? AppRoutes.accountTeacher
            : AppRoutes.accountStudent;

    final IconData scanIcon =
        userRole == "guru" ? Icons.document_scanner : Icons.qr_code_scanner;

    final List<String> pageRoutes = [
      homeRoute,
      historyRoute,
      scanRoute,
      scheduleRoute,
      accountRoute,
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pageRoutes.map(AppRoutes.getPageByRouteName).toList(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SafeArea(
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () => _onTabTapped(2),
                backgroundColor: Colors.blueAccent,
                child: Icon(scanIcon, size: 35),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TabItemWidget(
                  icon: Icons.home,
                  label: 'Home',
                  index: 0,
                  selectedIndex: _selectedIndex,
                  onTap: _onTabTapped,
                ),
                TabItemWidget(
                  icon: Icons.history,
                  label: 'Riwayat',
                  index: 1,
                  selectedIndex: _selectedIndex,
                  onTap: _onTabTapped,
                ),
                const SizedBox(width: 60),
                TabItemWidget(
                  icon: Icons.schedule,
                  label: 'Jadwal',
                  index: 3,
                  selectedIndex: _selectedIndex,
                  onTap: _onTabTapped,
                ),
                TabItemWidget(
                  icon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  selectedIndex: _selectedIndex,
                  onTap: _onTabTapped,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
