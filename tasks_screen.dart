import 'package:flutter/material.dart';

// This screen is now deprecated as tasks are managed within CourseDetailScreen.
// It is kept as a placeholder to avoid compilation errors if referenced elsewhere.

class TasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF6A11CB),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Tasks are now part of Courses',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Please go to "Courses Record" and select a course to view or add tasks.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6A11CB)),
              child: Text('Go Back', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}