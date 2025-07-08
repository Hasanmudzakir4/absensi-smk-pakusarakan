import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String day;
  final String subject;
  final String teacherName;
  final String teacherId;
  final String className;
  final DateTime? startTimestamp;
  final DateTime? endTimestamp;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScheduleModel({
    required this.id,
    required this.day,
    required this.subject,
    required this.teacherName,
    required this.teacherId,
    required this.className,
    this.startTimestamp,
    this.endTimestamp,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'subject': subject,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'className': className,
      'startTimestamp': startTimestamp != null ? Timestamp.fromDate(startTimestamp!) : null,
      'endTimestamp': endTimestamp != null ? Timestamp.fromDate(endTimestamp!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ScheduleModel(
      id: documentId,
      day: map['day'] ?? '',
      subject: map['subject'] ?? '',
      teacherName: map['teacherName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      className: map['className'] ?? '',
      startTimestamp: map['startTimestamp'] != null
          ? (map['startTimestamp'] as Timestamp).toDate()
          : null,
      endTimestamp: map['endTimestamp'] != null
          ? (map['endTimestamp'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
