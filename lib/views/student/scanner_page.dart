import 'package:absensi_smk_pakusarakan/controllers/scanner_controller.dart';
import 'package:absensi_smk_pakusarakan/views/student/widget/scanner_overlay.dart';
import 'package:flutter/material.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late QRScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = QRScannerController(context: context)
      ..onUpdate = () {
        if (mounted) setState(() {});
      };
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          controller.buildQRView(),
          const ScannerOverlay(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: controller.buildOverlay(),
          ),
        ],
      ),
    );
  }
}
