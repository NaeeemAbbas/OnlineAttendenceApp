import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/student.dart';
import 'models/attendance_record.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/welcome_screen.dart';
import 'services/attendance_service.dart';

void main() {
  runApp(AttendanceTrackerApp());
}

class AttendanceTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late AttendanceService _attendanceService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    _attendanceService = AttendanceService(prefs);
    await _attendanceService.initializeSampleData();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Tracker'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: Colors.blue,
            ),
            
            SizedBox(height: 20),
            Text(
              'Attendance Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Track and manage student attendance with ease',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            _buildRoleButton(
              context,
              'Teacher',
              Icons.person,
              Colors.blue,
              TeacherDashboard(attendanceService: _attendanceService),
            ),
            SizedBox(height: 16),
            _buildRoleButton(
              context,
              'Student',
              Icons.people,
              Colors.green,
              StudentDashboard(attendanceService: _attendanceService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, IconData icon,
      Color color, Widget destination) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}