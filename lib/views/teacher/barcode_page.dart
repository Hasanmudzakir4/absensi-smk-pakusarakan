import 'package:absensi_smk_pakusarakan/controllers/barcode_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  BarcodePageState createState() => BarcodePageState();
}

class BarcodePageState extends State<BarcodePage> {
  String? qrData;
  User? _user;
  String? _teacherName;
  bool _isFetching = true;
  late BarcodePageController _controller;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _controller = BarcodePageController(
        teacherId: _user!.uid,
        teacherName: '',
      );
      _fetchTeacherNameAndActiveSchedule();
    } else {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _fetchTeacherNameAndActiveSchedule() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(_user!.uid)
              .get();

      if (!mounted) return;
      setState(() {
        _teacherName = (userDoc['name'] as String).trim();
      });

      _controller = BarcodePageController(
        teacherId: _user!.uid,
        teacherName: _teacherName!,
      );

      await _fetchActiveSchedule();
      if (!mounted) return;
      setState(() {
        _isFetching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _fetchActiveSchedule() async {
    if (_user == null) return;

    final schedule = await _controller.fetchActiveSchedule();
    if (schedule == null) {
      if (!mounted) return;
      setState(() {
        qrData = null;
      });
    } else {
      final now = DateTime.now();
      final existingQrQuery =
          await FirebaseFirestore.instance
              .collection("qr_codes")
              .where("scheduleId", isEqualTo: schedule.id)
              .where("date", isEqualTo: DateFormat("dd-MM-yyyy").format(now))
              .limit(1)
              .get();

      if (existingQrQuery.docs.isNotEmpty) {
        final existingHash = existingQrQuery.docs.first.id;
        if (!mounted) return;
        setState(() {
          qrData = existingHash;
        });
      } else {
        final endTime = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        ); // end of the day
        final hash = await _controller.generateQRCodeForSchedule(
          schedule,
          endTime,
        );
        if (!mounted) return;
        setState(() {
          qrData = hash;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Jadwal'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child:
            _isFetching
                ? const CircularProgressIndicator()
                : (_teacherName == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 250,
                          child: Lottie.asset('images/account-setup.json'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Lengkapi data pribadi Anda.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    )
                    : (qrData != null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Silahkan Absen",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            QrImageView(
                              data: qrData!,
                              size: 250,
                              backgroundColor: Colors.white,
                            ),
                          ],
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 250,
                              child: Lottie.asset('images/empty-data.json'),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Tidak ada absen saat ini.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ))),
      ),
    );
  }
}
