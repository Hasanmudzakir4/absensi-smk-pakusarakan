import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'widgets/welcome_page_widget.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 2);
              });
            },
            children: [
              WelcomePageContent(
                image: Image.asset(
                  'assets/images/logo-sekolah.png',
                  fit: BoxFit.cover,
                ),
                title:
                    'Selamat Datang di Aplikasi Absensi\nSMK Pakusarakan Cikampek!',
                description:
                    'Aplikasi ini membantu siswa dan guru untuk mencatat kehadiran secara digital dengan mudah dan efisien.',
              ),
              WelcomePageContent(
                image: Lottie.asset('assets/images/scanner.json'),
                title:
                    'Gunakan fitur scan QR Code untuk mencatat kehadiran dengan cepat dan akurat.',
                description:
                    'Tidak perlu tanda tangan manual! Cukup scan QR Code dan kehadiranmu akan tercatat otomatis.',
              ),
              WelcomePageContent(
                image: Lottie.asset('assets/images/history.json'),
                title: 'Pantau Riwayat Kehadiran!',
                description:
                    'Dengan aplikasi ini, kamu bisa melihat riwayat absensi kapan saja dan di mana saja secara real-time.',
                showButton: true,
                onStart: navigateToHome,
              ),
            ],
          ),

          // Navigasi Halaman Onboarding
          Container(
            alignment: const Alignment(0, 0.85),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    _controller.jumpToPage(2);
                  },
                  child: const Text('Lewati'),
                ),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: const ExpandingDotsEffect(
                    dotWidth: 16.0,
                    dotHeight: 16.0,
                    dotColor: Colors.grey,
                    activeDotColor: Colors.blue,
                  ),
                ),
                onLastPage
                    ? GestureDetector(
                      onTap: navigateToHome,
                      child: const Text('Mulai'),
                    )
                    : GestureDetector(
                      onTap: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      },
                      child: const Text('Lanjut'),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
