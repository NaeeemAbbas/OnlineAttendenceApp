import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import 'student_attendance_detail_screen.dart';

class StudentDashboard extends StatefulWidget {
  final AttendanceService attendanceService;

  StudentDashboard({required this.attendanceService});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<List<Student>> _studentsFuture;
  Student? _selectedStudent;

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
        title: Text('Student Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Student',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              _buildStudentSelector(),
              SizedBox(height: 20),
              if (_selectedStudent != null) ...[
                _buildAttendanceSummary(),
                SizedBox(height: 20),
                _buildAttendanceChart(),
                SizedBox(height: 20),
                _buildViewDetailsButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
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

        return DropdownButtonFormField<Student>(
          value: _selectedStudent,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Choose a student',
            prefixIcon: Icon(Icons.person),
          ),
          items: students.map((student) {
            return DropdownMenuItem<Student>(
              value: student,
              child: Text('${student.name} (Roll: ${student.rollNumber})'),
            );
          }).toList(),
          onChanged: (Student? newValue) {
            setState(() {
              _selectedStudent = newValue;
            });
          },
        );
      },
    );
  }

  Widget _buildAttendanceSummary() {
    return FutureBuilder<Map<String, double>>(
      future: widget.attendanceService.getAttendancePercentage(_selectedStudent!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final percentages = snapshot.data ?? {};
        final presentPercentage = percentages['present'] ?? 0.0;
        final totalClasses = percentages['total']?.toInt() ?? 0;

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Present',
                      '${presentPercentage.toStringAsFixed(1)}%',
                      Colors.green,
                    ),
                    _buildSummaryItem(
                      'Total Classes',
                      totalClasses.toString(),
                      Colors.blue,
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    return FutureBuilder<Map<String, double>>(
      future: widget.attendanceService.getAttendancePercentage(_selectedStudent!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final percentages = snapshot.data ?? {};
        final present = percentages['present'] ?? 0.0;
        final absent = percentages['absent'] ?? 0.0;
        final late = percentages['late'] ?? 0.0;

        if (present + absent + late == 0) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No attendance data available'),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: present,
                          color: Colors.green,
                          title: 'Present\n${present.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: absent,
                          color: Colors.red,
                          title: 'Absent\n${absent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: late,
                          color: Colors.orange,
                          title: 'Late\n${late.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      pieTouchData: PieTouchData(enabled: false),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildLegend(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Present', Colors.green),
        _buildLegendItem('Absent', Colors.red),
        _buildLegendItem('Late', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildViewDetailsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAttendanceDetailScreen(
                attendanceService: widget.attendanceService,
                student: _selectedStudent!,
              ),
            ),
          );
        },
        child: Text('View Detailed Attendance'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
