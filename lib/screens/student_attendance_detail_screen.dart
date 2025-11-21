import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class StudentAttendanceDetailScreen extends StatefulWidget {
  final AttendanceService attendanceService;
  final Student student;

  StudentAttendanceDetailScreen({
    required this.attendanceService,
    required this.student,
  });

  @override
  _StudentAttendanceDetailScreenState createState() => _StudentAttendanceDetailScreenState();
}

class _StudentAttendanceDetailScreenState extends State<StudentAttendanceDetailScreen> {
  late Future<List<AttendanceRecord>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() {
    setState(() {
      _attendanceFuture = widget.attendanceService.getStudentAttendance(widget.student.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} - Attendance'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentInfo(),
            SizedBox(height: 20),
            _buildAttendanceStats(),
            SizedBox(height: 20),
            Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _buildAttendanceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 30,
              child: Text(
                widget.student.name[0],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Roll Number: ${widget.student.rollNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return FutureBuilder<Map<String, double>>(
      future: widget.attendanceService.getAttendancePercentage(widget.student.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final percentages = snapshot.data ?? {};
        final presentPercentage = percentages['present'] ?? 0.0;
        final absentPercentage = percentages['absent'] ?? 0.0;
        final latePercentage = percentages['late'] ?? 0.0;
        final totalClasses = percentages['total']?.toInt() ?? 0;

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Classes', totalClasses.toString(), Colors.blue),
                    _buildStatItem('Present %', '${presentPercentage.toStringAsFixed(1)}%', Colors.green),
                    _buildStatItem('Absent %', '${absentPercentage.toStringAsFixed(1)}%', Colors.red),
                    _buildStatItem('Late %', '${latePercentage.toStringAsFixed(1)}%', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return FutureBuilder<List<AttendanceRecord>>(
      future: _attendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading attendance data'));
        }

        final attendanceRecords = snapshot.data ?? [];

        if (attendanceRecords.isEmpty) {
          return Center(
            child: Text(
              'No attendance records found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = attendanceRecords[index];
            return _buildAttendanceRecordCard(record);
          },
        );
      },
    );
  }

  Widget _buildAttendanceRecordCard(AttendanceRecord record) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(record.status),
          ),
          child: Center(
            child: Text(
              _getStatusLabel(record.status),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          DateFormat('EEEE, MMM dd, yyyy').format(record.date),
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getStatusDescription(record.status),
          style: TextStyle(
            color: _getStatusColor(record.status),
          ),
        ),
        trailing: Icon(
          _getStatusIcon(record.status),
          color: _getStatusColor(record.status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.late:
        return 'L';
      default:
        return '?';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }
}