import 'package:absensi_smk_pakusarakan/views/student/widget/corner_decoration.dart';
import 'package:absensi_smk_pakusarakan/views/student/widget/scanner_overlay_painter.dart';
import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scanSize = width * 0.8;
        final left = (width - scanSize) / 2;
        final top = (height - scanSize) / 2;

        return Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: ScannerOverlayPainter(),
            ),
            Positioned(
              top: top - 60,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  "Cari kode QR",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: CornerDecoration(corner: Corner.topLeft),
            ),
            Positioned(
              right: left,
              top: top,
              child: CornerDecoration(corner: Corner.topRight),
            ),
            Positioned(
              left: left,
              bottom: top,
              child: CornerDecoration(corner: Corner.bottomLeft),
            ),
            Positioned(
              right: left,
              bottom: top,
              child: CornerDecoration(corner: Corner.bottomRight),
            ),
          ],
        );
      },
    );
  }
}
