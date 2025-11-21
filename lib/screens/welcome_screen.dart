import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendance_service.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      _attendanceService = AttendanceService(prefs);
      await _attendanceService.initializeSampleData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading Attendance Tracker...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 30),
              Text(
                'Attendance Tracker',
                style: TextStyle(
                  fontSize: 32,
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
              SizedBox(height: 50),
              _buildRoleButton(
                context,
                'Teacher',
                Icons.person,
                Colors.blue,
                TeacherDashboard(attendanceService: _attendanceService),
              ),
              SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, IconData icon,
      Color color, Widget destination) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
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
          elevation: 3,
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