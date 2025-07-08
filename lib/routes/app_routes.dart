import 'package:absensi_smk_pakusarakan/views/admin/add_user.dart';
import 'package:absensi_smk_pakusarakan/views/admin/admin_dashboard.dart';
import 'package:absensi_smk_pakusarakan/views/admin/attendance_recap.dart';
import 'package:absensi_smk_pakusarakan/views/admin/manage_admin.dart';
import 'package:absensi_smk_pakusarakan/views/admin/manage_profile.dart';
import 'package:absensi_smk_pakusarakan/views/admin/manage_schedule.dart';
import 'package:absensi_smk_pakusarakan/views/admin/manage_students.dart';
import 'package:absensi_smk_pakusarakan/views/admin/manage_teacher.dart';
import 'package:absensi_smk_pakusarakan/views/auth/admin/admin_login_page.dart';
import 'package:absensi_smk_pakusarakan/views/auth/forgot_password_page.dart';
import 'package:absensi_smk_pakusarakan/views/auth/login_page.dart';
import 'package:absensi_smk_pakusarakan/views/components/not_found_page.dart';
import 'package:absensi_smk_pakusarakan/views/components/splash_page.dart';
import 'package:absensi_smk_pakusarakan/views/components/tabbar.dart';
import 'package:absensi_smk_pakusarakan/views/components/welcome_page.dart';
import 'package:absensi_smk_pakusarakan/views/student/account_student_page.dart';
import 'package:absensi_smk_pakusarakan/views/student/history_student_page.dart';
import 'package:absensi_smk_pakusarakan/views/student/home_student_page.dart';
import 'package:absensi_smk_pakusarakan/views/student/profile_student_page.dart';
import 'package:absensi_smk_pakusarakan/views/student/scanner_page.dart';
import 'package:absensi_smk_pakusarakan/views/student/schedule_student_page.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/account_teacher_page.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/barcode_page.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/history_teacher_page.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/home_teacher_page.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/profile_teacher_page.dart';
import 'package:absensi_smk_pakusarakan/views/teacher/schedule_teacher_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String loginAdmin = '/login-admin';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String tabbar = '/tabbar';
  static const String homeStudent = '/homeStudent';
  static const String homeTeacher = '/homeTeacher';
  static const String historyStudent = '/historyStudent';
  static const String historyTeacher = '/historyTeacher';
  static const String accountStudent = '/accountStudent';
  static const String scheduleTeacher = '/scheduleTeacher';
  static const String scheduleStudent = '/scheduleStudent';
  static const String accountTeacher = '/accountTeacher';
  static const String profileStudent = '/profileStudent';
  static const String profileTeacher = '/profileTeacher';
  static const String detailAbsen = '/detailAbsen';
  static const String scan = '/scan';
  static const String barcode = '/barcode';

  // Admin
  static const String adminDashboard = '/admin-dashboard';
  static const String manageStudents = '/manage-students';
  static const String manageTeacher = '/manage-teacher';
  static const String manageAdmin = '/manage-admin';
  static const String manageSchedule = '/manage-schedule';
  static const String manageProfile = '/profile-admin';
  static const String attendanceRecap = '/attendance-recap';
  static const String addStudent = '/add-student';

  static Widget getPageByRouteName(String? routeName) {
    switch (routeName) {
      case splash:
        return SplashPage();
      case welcome:
        return WelcomePage();
      case login:
        return LoginPage();
      case loginAdmin:
        return AdminLoginPage();
      case forgotPassword:
        return ForgotPasswordPage();
      case tabbar:
        return TabBarScreen();

      // siswa
      case homeStudent:
        return HomeStudentPage();
      case profileStudent:
        return ProfileStudentPage();
      case historyStudent:
        return HistoryStudentPage();
      case accountStudent:
        return AccountStudentPage();
      case scheduleStudent:
        return ScheduleStudentPage();
      case scan:
        return ScanPage();

      // guru
      case detailAbsen:
        return HistoryStudentPage();
      case homeTeacher:
        return HomeTeacherPage();

      case accountTeacher:
        return AccountTeacherPage();
      case scheduleTeacher:
        return ScheduleTeacherPage();
      case profileTeacher:
        return ProfileTeacherPage();
      case historyTeacher:
        return HistoryTeacherPage();
      case barcode:
        return BarcodePage();

      // admin
      case adminDashboard:
        return AdminDashboardPage();
      case manageStudents:
        return ManageStudents();
      case manageProfile:
        return ManageProfile();
      case manageTeacher:
        return ManageTeacher();
      case manageAdmin:
        return ManageAdmin();
      case manageSchedule:
        return ManageSchedule();
      case attendanceRecap:
        return AttendanceRecap();
      case addStudent:
        return AddUser();

      default:
        return NotFoundPage();
    }
  }

  // ✅ Tambahkan ini agar tidak error di main.dart
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => getPageByRouteName(settings.name),
      settings: settings,
    );
  }
}
