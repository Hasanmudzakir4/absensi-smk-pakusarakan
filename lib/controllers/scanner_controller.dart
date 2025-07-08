import 'package:absensi_smk_pakusarakan/models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerController {
  final BuildContext context;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  Barcode? result;
  bool _isDialogShown = false;

  VoidCallback? onUpdate;

  QRScannerController({required this.context});

  Widget buildQRView() => QRView(key: qrKey, onQRViewCreated: _onQRViewCreated);

  /// overlay tombol flash & switch camera
  Widget buildOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FutureBuilder<bool?>(
            future: _controller?.getFlashStatus(),
            builder: (context, snap) {
              final flashOn = snap.data ?? false;
              return IconButton(
                icon: Icon(
                  flashOn ? Icons.flash_on : Icons.flash_off,
                  color: flashOn ? Colors.yellow : Colors.white,
                  size: 30,
                ),
                onPressed: () async {
                  await _controller?.toggleFlash();
                  onUpdate?.call();
                },
              );
            },
          ),
          FutureBuilder<CameraFacing?>(
            future: _controller?.getCameraInfo(),
            builder: (context, snap) {
              return IconButton(
                icon: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () async {
                  await _controller?.flipCamera();
                  onUpdate?.call();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    _controller!.scannedDataStream.listen((scanData) async {
      if (_isDialogShown || result != null) return;

      _isDialogShown = true;
      result = scanData;
      onUpdate?.call();

      final hash = result!.code;
      if (hash == null) {
        _isDialogShown = false;
        result = null;
        return;
      }

      // Ambil dokumen QR dari Firestore berdasarkan hash
      final qrDoc =
          await FirebaseFirestore.instance
              .collection('qr_codes')
              .doc(hash)
              .get();

      if (!qrDoc.exists) {
        await _showError("Barcode tidak valid");
        _isDialogShown = false;
        result = null;
        return;
      }

      final qrData = qrDoc.data()!;

      // CEK expiredAt
      final Timestamp expiredAt = qrData['expiredAt'];
      if (DateTime.now().isAfter(expiredAt.toDate())) {
        await _showError("Barcode sudah kedaluwarsa.");
        _isDialogShown = false;
        result = null;
        return;
      }

      final String scheduleId = qrData['scheduleId'];
      final String date = qrData['date'];
      final String time = DateFormat("HH:mm").format(DateTime.now());
      final String teacher = qrData['teacher'];
      final String subject = qrData['subject'];

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isDialogShown = false;
        result = null;
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (!userDoc.exists) {
        _isDialogShown = false;
        result = null;
        return;
      }

      // Cek duplikat absensi berdasarkan qrData
      final dup =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: user.uid)
              .where('qrData.date', isEqualTo: date)
              .where('qrData.teacher', isEqualTo: teacher)
              .where('qrData.subject', isEqualTo: subject)
              .where('qrData.time', isEqualTo: time)
              .get();

      if (dup.docs.isNotEmpty) {
        await _showError("Anda sudah melakukan absensi untuk sesi ini.");
        _isDialogShown = false;
        result = null;
        return;
      }

      // Simpan absensi
      final docRef = FirebaseFirestore.instance.collection('attendance').doc();
      final attendance = AttendanceModel(
        id: docRef.id,
        studentId: user.uid,
        scheduleId: scheduleId,
        studentName: userDoc['name'] ?? '',
        studentClass: userDoc['studentClass'] ?? '',
        studentNumber: userDoc['idNumber'] ?? '',
        studentSemester: userDoc['studentSemester'] ?? '',
        timestamp: null,
        qrData: {
          "teacher": teacher,
          "subject": subject,
          "day": qrData['day'],
          "date": date,
          "time": time,
          "status": qrData['status'],
        },
      );
      await docRef.set(attendance.toMap());

      await _showSuccess("Absensi berhasil disimpan.");
      _isDialogShown = false;
      result = null;
    });
  }

  Future<void> _showError(String msg) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Gagal"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> _showSuccess(String msg) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Berhasil"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void dispose() => _controller?.dispose();
}
