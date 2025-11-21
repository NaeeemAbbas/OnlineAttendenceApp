import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final AttendanceService attendanceService;
  final DateTime selectedDate;

  MarkAttendanceScreen({
    required this.attendanceService,
    required this.selectedDate,
  });

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  late Future<List<Student>> _studentsFuture;
  late Future<List<AttendanceRecord>> _attendanceFuture;
  Map<String, String> _selectedStatus = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _studentsFuture = widget.attendanceService.getStudents();
      _attendanceFuture = widget.attendanceService.getAttendanceByDate(widget.selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveAttendance,
            ),
        ],
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : _buildAttendanceList(),
    );
  }

  Widget _buildAttendanceList() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, studentsSnapshot) {
        if (studentsSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (studentsSnapshot.hasError) {
          return Center(child: Text('Error loading students'));
        }

        final students = studentsSnapshot.data ?? [];

        return FutureBuilder<List<AttendanceRecord>>(
          future: _attendanceFuture,
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final existingAttendance = attendanceSnapshot.data ?? [];
            _initializeAttendanceStatus(existingAttendance);

            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildStudentAttendanceCard(student);
              },
            );
          },
        );
      },
    );
  }

void _initializeAttendanceStatus(List<AttendanceRecord> existingAttendance) {
  if (_selectedStatus.isNotEmpty) return;  // ❗ prevent overwriting user selection

  for (final record in existingAttendance) {
    _selectedStatus[record.studentId] = record.status;
  }
}

  Widget _buildStudentAttendanceCard(Student student) {
    final currentStatus = _selectedStatus[student.id] ?? AttendanceStatus.absent;
    
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
                  Text(
                    'Roll: ${student.rollNumber}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            _buildStatusSelector(student.id, currentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector(String studentId, String currentStatus) {
    return Row(
      children: [
        _buildStatusButton(
          studentId,
          AttendanceStatus.present,
          'P',
          Colors.green,
          currentStatus == AttendanceStatus.present,
        ),
        SizedBox(width: 8),
        _buildStatusButton(
          studentId,
          AttendanceStatus.late,
          'L',
          Colors.orange,
          currentStatus == AttendanceStatus.late,
        ),
        SizedBox(width: 8),
        _buildStatusButton(
          studentId,
          AttendanceStatus.absent,
          'A',
          Colors.red,
          currentStatus == AttendanceStatus.absent,
        ),
      ],
    );
  }

  Widget _buildStatusButton(String studentId, String status, String label,
      Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus[studentId] = status;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : Colors.grey[200],
          border: Border.all(
            color: isSelected ? color : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final existingRecords = await widget.attendanceService.getAttendanceByDate(widget.selectedDate);
      
      for (final record in existingRecords) {
        await widget.attendanceService.deleteAttendanceRecord(record.id);
      }

      for (final entry in _selectedStatus.entries) {
        final record = AttendanceRecord(
          id: '${entry.key}_${DateFormat('yyyyMMdd').format(widget.selectedDate)}',
          studentId: entry.key,
          status: entry.value,
          date: widget.selectedDate,
        );
        
        await widget.attendanceService.markAttendance(record);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}