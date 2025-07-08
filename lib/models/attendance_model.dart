import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String scheduleId;
  final String studentName;
  final String studentClass;
  final String studentNumber;
  final String studentSemester;
  final dynamic timestamp;
  final Map<String, String> qrData;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.scheduleId,
    required this.studentName,
    required this.studentClass,
    required this.studentNumber,
    required this.studentSemester,
    this.timestamp,
    required this.qrData,
  });

  String get status => qrData['status'] ?? 'Hadir';
  String get subject => qrData['subject'] ?? '-';
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'scheduleId': scheduleId,
      'studentName': studentName,
      'studentClass': studentClass,
      'studentNumber': studentNumber,
      'studentSemester': studentSemester,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'qrData': qrData,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentClass: map['studentClass'] ?? '',
      studentNumber: map['studentNumber'] ?? '',
      studentSemester: map['studentSemester'] ?? '',
      timestamp: map['timestamp'],
      qrData: Map<String, String>.from(map['qrData'] ?? {}),
    );
  }

  factory AttendanceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel.fromMap(data, doc.id);
  }
}
