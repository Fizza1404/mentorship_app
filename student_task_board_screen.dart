import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class StudentTaskBoardScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;
  const StudentTaskBoardScreen({super.key, required this.mentor});

  @override
  State<StudentTaskBoardScreen> createState() => _StudentTaskBoardScreenState();
}

class _StudentTaskBoardScreenState extends State<StudentTaskBoardScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController(); 

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    double currentOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    
    setState(() => _isLoading = true);
    try {
      final courses = await ApiService.getCourses(mentorId: widget.mentor['uid']);
      List<dynamic> allTasks = [];
      for (var course in courses) {
        final tasks = await ApiService.getTasks(course['id'].toString(), studentId: auth.user?.uid, role: 'student');
        for (var t in tasks) { t['course_title'] = course['title']; }
        allTasks.addAll(tasks);
      }
      
      if (mounted) {
        setState(() { 
          _tasks = allTasks; 
          _isLoading = false; 
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(currentOffset);
          }
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _submitAssignment(String taskId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final auth = Provider.of<MyAuthProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing submission...')));
      try {
        String url = await ApiService.uploadFileToDomain(await File(result.files.single.path!).readAsBytes(), result.files.single.name);
        if (url.isNotEmpty) {
          await ApiService.submitTask({
            'task_id': taskId, 'student_id': auth.user!.uid, 'file_url': url
          });
          await _fetchTasks(); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment Submitted! Status: PENDING'), backgroundColor: Colors.orange));
        }
      } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed!'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Academic Task Board', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
        : _tasks.isEmpty 
          ? const Center(child: Text('No tasks assigned yet.'))
          : RefreshIndicator(
              onRefresh: _fetchTasks,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _tasks.length,
                itemBuilder: (context, index) => _taskCard(_tasks[index]),
              ),
            ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    String status = (task['submission_status'] ?? 'none').toString().toLowerCase();
    bool isCompleted = status == 'completed';
    
    String displayStatus = 'NOT SUBMITTED';
    Color statusColor = Colors.grey;

    if (status == 'completed') {
      displayStatus = 'COMPLETED';
      statusColor = Colors.green;
    } else if (status == 'resubmit' || status == 'again') {
      displayStatus = 'RESUBMIT';
      statusColor = Colors.red;
    } else if (status == 'pending' || status == 'under_review') {
      displayStatus = 'PENDING';
      statusColor = Colors.orange;
    }

    String? subFile = task['student_file_url'] ?? task['submission_file_url'];
    bool hasStudentFile = subFile != null && subFile != '' && subFile != 'null';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(task['course_title'] ?? 'Module', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB)))),
            _statusChip(displayStatus, statusColor),
          ]),
          const SizedBox(height: 12),
          Text(task['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(task['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 35),
          if (task['file_url'] != null && task['file_url'] != '')
            _fileLink('View Mentor Material 📘', task['file_url'], Colors.blue),
          if (hasStudentFile)
            Padding(padding: const EdgeInsets.only(top: 8), child: _fileLink('My Submission 📝', subFile!, Colors.green)),
          const SizedBox(height: 25),
          if (!isCompleted)
            ElevatedButton.icon(
              onPressed: () => _submitAssignment(task['id'].toString()),
              icon: Icon(hasStudentFile ? Icons.update : Icons.upload_file),
              label: Text(hasStudentFile ? 'UPDATE WORK' : 'SUBMIT WORK'),
              style: ElevatedButton.styleFrom(backgroundColor: (status == 'resubmit' || status == 'again') ? Colors.redAccent : const Color(0xFF6A11CB), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            )
          else
            const Center(child: Text('Assignment Finalized ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _fileLink(String label, String url, Color color) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Icon(Icons.attachment_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
          Icon(Icons.open_in_new_rounded, size: 14, color: color),
        ]),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }
}