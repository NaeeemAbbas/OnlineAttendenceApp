import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/student.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  final SharedPreferences _prefs;
  static const String _studentsKey = 'students';
  static const String _attendanceKey = 'attendance_records';

  AttendanceService(this._prefs);

  Future<void> initializeSampleData() async {
    final studentsExist = _prefs.containsKey(_studentsKey);
    if (!studentsExist) {
      await _initializeSampleStudents();
    }
  }

  Future<void> _initializeSampleStudents() async {
    final sampleStudents = [
      Student(id: '1', name: 'John Doe', rollNumber: '001'),
      Student(id: '2', name: 'Jane Smith', rollNumber: '002'),
      Student(id: '3', name: 'Michael Johnson', rollNumber: '003'),
      Student(id: '4', name: 'Emily Brown', rollNumber: '004'),
      Student(id: '5', name: 'David Wilson', rollNumber: '005'),
      Student(id: '6', name: 'Sarah Davis', rollNumber: '006'),
      Student(id: '7', name: 'James Miller', rollNumber: '007'),
      Student(id: '8', name: 'Emma Garcia', rollNumber: '008'),
      Student(id: '9', name: 'Daniel Martinez', rollNumber: '009'),
      Student(id: '10', name: 'Olivia Rodriguez', rollNumber: '010'),
    ];

    await saveStudents(sampleStudents);
  }

  Future<List<Student>> getStudents() async {
    final studentsJson = _prefs.getString(_studentsKey);
    if (studentsJson == null) return [];

    final List<dynamic> studentsList = json.decode(studentsJson);
    return studentsList.map((json) => Student.fromJson(json)).toList();
  }

  Future<void> saveStudents(List<Student> students) async {
    final studentsJson = json.encode(students.map((s) => s.toJson()).toList());
    await _prefs.setString(_studentsKey, studentsJson);
  }

  Future<void> addStudent(Student student) async {
    final students = await getStudents();
    students.add(student);
    await saveStudents(students);
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final attendanceJson = _prefs.getString(_attendanceKey);
    if (attendanceJson == null) return [];

    final List<dynamic> attendanceList = json.decode(attendanceJson);
    return attendanceList.map((json) => AttendanceRecord.fromJson(json)).toList();
  }

  Future<void> saveAttendanceRecords(List<AttendanceRecord> records) async {
    final attendanceJson = json.encode(records.map((r) => r.toJson()).toList());
    await _prefs.setString(_attendanceKey, attendanceJson);
  }

  Future<void> markAttendance(AttendanceRecord record) async {
    final records = await getAttendanceRecords();
    records.add(record);
    await saveAttendanceRecords(records);
  }

  Future<List<AttendanceRecord>> getStudentAttendance(String studentId) async {
    final records = await getAttendanceRecords();
    return records.where((record) => record.studentId == studentId).toList();
  }

  Future<Map<String, double>> getAttendancePercentage(String studentId) async {
    final records = await getStudentAttendance(studentId);
    if (records.isEmpty) {
      return {
        'present': 0.0,
        'absent': 0.0,
        'late': 0.0,
        'total': 0.0,
      };
    }

    final presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
    final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount = records.where((r) => r.status == AttendanceStatus.late).length;
    final total = records.length;

    return {
      'present': (presentCount / total) * 100,
      'absent': (absentCount / total) * 100,
      'late': (lateCount / total) * 100,
      'total': total.toDouble(),
    };
  }

  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) async {
    final records = await getAttendanceRecords();
    return records.where((record) => 
      record.date.year == date.year &&
      record.date.month == date.month &&
      record.date.day == date.day
    ).toList();
  }

  Future<void> updateAttendanceRecord(AttendanceRecord updatedRecord) async {
    final records = await getAttendanceRecords();
    final index = records.indexWhere((r) => r.id == updatedRecord.id);
    if (index != -1) {
      records[index] = updatedRecord;
      await saveAttendanceRecords(records);
    }
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    final records = await getAttendanceRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveAttendanceRecords(records);
  }
}