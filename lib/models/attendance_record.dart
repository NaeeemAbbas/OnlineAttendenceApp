import 'package:intl/intl.dart';

class AttendanceStatus {
  static const String present = 'present';
  static const String absent = 'absent';
  static const String late = 'late';
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String status;
  final DateTime date;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.status,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'status': status,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      studentId: json['studentId'],
      status: json['status'],
      date: DateFormat('yyyy-MM-dd').parse(json['date']),
      notes: json['notes'],
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? status,
    DateTime? date,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}