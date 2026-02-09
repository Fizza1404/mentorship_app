import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class StudentTaskProgressScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentTaskProgressScreen({super.key, required this.student});

  @override
  _StudentTaskProgressScreenState createState() => _StudentTaskProgressScreenState();
}

class _StudentTaskProgressScreenState extends State<StudentTaskProgressScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  bool _isCertified = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final mentorId = Provider.of<MyAuthProvider>(context, listen: false).user?.uid ?? '';
    final studentId = (widget.student['uid'] ?? widget.student['student_id'] ?? '').toString();

    try {
      final courses = await ApiService.getCourses(mentorId: mentorId);
      List<dynamic> allStudentTasks = [];
      for (var course in courses) {
        final tasks = await ApiService.getTasks(course['id'].toString(), studentId: studentId, role: 'mentor');
        allStudentTasks.addAll(tasks);
      }

      final apps = await ApiService.getStudentApplications(studentId);
      final myApp = apps.firstWhere(
        (a) => a['mentor_id'].toString() == mentorId.toString(), 
        orElse: () => null
      );

      if (mounted) {
        setState(() {
          _tasks = allStudentTasks;
          _isCertified = myApp != null && (myApp['is_certified'] == 1 || myApp['is_certified'] == "1");
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _approveCertificate() async {
    final mentorId = Provider.of<MyAuthProvider>(context, listen: false).user?.uid ?? '';
    final studentId = (widget.student['uid'] ?? widget.student['student_id'] ?? '').toString();

    final res = await ApiService.issueCertificate(mentorId, studentId);
    if (mounted && res['status'] == 'success') {
      NotificationService.sendNotification(
        toTopic: studentId, 
        title: "Certificate Unlocked! 🏆", 
        body: "Congratulations! Your mentor has issued your completion certificate."
      );
      setState(() => _isCertified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate Issued Successfully!'), backgroundColor: Colors.green)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Performance Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB))) 
        : RefreshIndicator(
            onRefresh: _fetchInitialData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildPerformanceSummary(),
                  const SizedBox(height: 30),
                  _isCertified 
                    ? _certifiedBadge()
                    : ElevatedButton.icon(
                        onPressed: _approveCertificate,
                        icon: const Icon(Icons.workspace_premium, color: Colors.white),
                        label: const Text('ISSUE COMPLETION CERTIFICATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700], 
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                      ),
                  const SizedBox(height: 30),
                  if (_tasks.isEmpty)
                    const Center(child: Text('No tasks assigned yet.', style: TextStyle(color: Colors.grey)))
                  else
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) => _taskTile(_tasks[index]),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _certifiedBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green[50], 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.green.withOpacity(0.3))
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.green, size: 40),
          const SizedBox(height: 10),
          const Text('Student Certified ✅', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
          Text('Completion certificate has been issued.', style: TextStyle(color: Colors.green[700], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    int done = _tasks.where((t) => t['submission_status'] == 'completed').length;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]
      ),
      child: Row(
        children: [
          _statItem(done.toString(), 'Finished'),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _statItem(_tasks.length.toString(), 'Total Tasks'),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _taskTile(Map<String, dynamic> task) {
    String status = (task['submission_status'] ?? 'pending').toString();
    bool isDone = status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(isDone ? Icons.check_circle : Icons.radio_button_off, color: isDone ? Colors.green : Colors.grey),
        title: Text(task['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Status: ${status.toUpperCase()}', style: TextStyle(fontSize: 11, color: isDone ? Colors.green : Colors.blueGrey)),
      ),
    );
  }
}