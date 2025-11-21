import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student.dart';
import '../services/attendance_service.dart';

class AttendanceReportsScreen extends StatefulWidget {
  final AttendanceService attendanceService;

  AttendanceReportsScreen({required this.attendanceService});

  @override
  _AttendanceReportsScreenState createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  late Future<List<Student>> _studentsFuture;
  String _selectedReportType = 'overview';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    setState(() {
      _studentsFuture = widget.attendanceService.getStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Reports'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportTypeSelector(),
            SizedBox(height: 20),
            Expanded(
              child: _buildReportContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _buildReportTypeButton('Overview', 'overview'),
                SizedBox(width: 8),
                _buildReportTypeButton('Class Stats', 'class_stats'),
                SizedBox(width: 8),
                _buildReportTypeButton('Low Attendance', 'low_attendance'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeButton(String label, String type) {
    final isSelected = _selectedReportType == type;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedReportType = type;
          });
        },
        child: Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'overview':
        return _buildOverviewReport();
      case 'class_stats':
        return _buildClassStatsReport();
      case 'low_attendance':
        return _buildLowAttendanceReport();
      default:
        return Container();
    }
  }

  Widget _buildOverviewReport() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            return _buildStudentReportCard(students[index]);
          },
        );
      },
    );
  }

  Widget _buildStudentReportCard(Student student) {
    return FutureBuilder<Map<String, double>>(
      future: widget.attendanceService.getAttendancePercentage(student.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final percentages = snapshot.data ?? {};
        final presentPercentage = percentages['present'] ?? 0.0;
        final totalClasses = percentages['total']?.toInt() ?? 0;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    student.name[0],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text('Roll: ${student.rollNumber}'),
                      SizedBox(height: 8),
                      Text('Total Classes: $totalClasses'),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${presentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(presentPercentage),
                      ),
                    ),
                    Text(
                      'Present',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassStatsReport() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];
        return FutureBuilder<Map<String, dynamic>>(
          future: _calculateClassStats(students),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final stats = statsSnapshot.data ?? {};
            final averageAttendance = stats['averageAttendance'] ?? 0.0;
            final totalStudents = stats['totalStudents'] ?? 0;
            final above90 = stats['above90'] ?? 0;
            final below75 = stats['below75'] ?? 0;

            return ListView(
              children: [
                _buildStatCard('Total Students', totalStudents.toString(), Colors.blue),
                _buildStatCard('Average Attendance', '${averageAttendance.toStringAsFixed(1)}%', Colors.green),
                _buildStatCard('Students Above 90%', above90.toString(), Colors.green[700]!),
                _buildStatCard('Students Below 75%', below75.toString(), Colors.red),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowAttendanceReport() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];
        return FutureBuilder<List<Student>>(
          future: _getLowAttendanceStudents(students),
          builder: (context, lowAttendanceSnapshot) {
            if (lowAttendanceSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final lowAttendanceStudents = lowAttendanceSnapshot.data ?? [];

            if (lowAttendanceStudents.isEmpty) {
              return Center(
                child: Text(
                  'No students with low attendance',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: lowAttendanceStudents.length,
              itemBuilder: (context, index) {
                return _buildStudentReportCard(lowAttendanceStudents[index]);
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calculateClassStats(List<Student> students) async {
    double totalAttendance = 0;
    int above90 = 0;
    int below75 = 0;

    for (final student in students) {
      final percentages = await widget.attendanceService.getAttendancePercentage(student.id);
      final presentPercentage = percentages['present'] ?? 0.0;
      totalAttendance += presentPercentage;

      if (presentPercentage >= 90) {
        above90++;
      } else if (presentPercentage < 75) {
        below75++;
      }
    }

    final averageAttendance = students.isNotEmpty ? totalAttendance / students.length : 0.0;

    return {
      'averageAttendance': averageAttendance,
      'totalStudents': students.length,
      'above90': above90,
      'below75': below75,
    };
  }

  Future<List<Student>> _getLowAttendanceStudents(List<Student> students) async {
    final lowAttendanceStudents = <Student>[];

    for (final student in students) {
      final percentages = await widget.attendanceService.getAttendancePercentage(student.id);
      final presentPercentage = percentages['present'] ?? 0.0;

      if (presentPercentage < 75) {
        lowAttendanceStudents.add(student);
      }
    }

    return lowAttendanceStudents;
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}