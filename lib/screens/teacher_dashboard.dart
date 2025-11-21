import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import 'mark_attendance_screen.dart';
import 'attendance_reports_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final AttendanceService attendanceService;

  TeacherDashboard({required this.attendanceService});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Future<List<Student>> _studentsFuture;
  DateTime _selectedDate = DateTime.now();

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
        title: Text('Teacher Dashboard'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildQuickActions(),
            SizedBox(height: 20),
            Text(
              'Students',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _buildStudentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            SizedBox(width: 12),
            Text(
              'Selected Date:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 8),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Mark Attendance',
            Icons.check_circle,
            Colors.green,
            () => _navigateToMarkAttendance(),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'View Reports',
            Icons.bar_chart,
            Colors.blue,
            () => _navigateToReports(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMarkAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceScreen(
          attendanceService: widget.attendanceService,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceReportsScreen(
          attendanceService: widget.attendanceService,
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading students'));
        }

        final students = snapshot.data ?? [];

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return _buildStudentCard(student);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            student.name[0],
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          student.name,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Roll: ${student.rollNumber}'),
        trailing: FutureBuilder<Map<String, double>>(
          future: widget.attendanceService.getAttendancePercentage(student.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            final percentage = snapshot.data?['present'] ?? 0.0;
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getPercentageColor(percentage),
              ),
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}