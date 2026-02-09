import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../tasks/add_task_screen.dart';

class StudentPersonalTaskScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentPersonalTaskScreen({super.key, required this.student});

  @override
  State<StudentPersonalTaskScreen> createState() => _StudentPersonalTaskScreenState();
}

class _StudentPersonalTaskScreenState extends State<StudentPersonalTaskScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final sId = (widget.student['uid'] ?? widget.student['student_id'] ?? '').toString();
    
    if (mounted) setState(() => _isLoading = true);
    try {
      final allCourses = await ApiService.getCourses(mentorId: auth.user?.uid);
      List<dynamic> tempTasks = [];
      for (var course in allCourses) {
        final courseTasks = await ApiService.getTasks(course['id'].toString(), studentId: sId, role: 'mentor');
        tempTasks.addAll(courseTasks);
      }
      if (mounted) setState(() { _tasks = tempTasks; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentId = (widget.student['uid'] ?? widget.student['student_id'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text('${widget.student['name']}\'s Tasks', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
        : _tasks.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _tasks.length,
              itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // FIXED: Passing targetStudentId so task is ONLY for this student
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddTaskScreen(initialCourseId: '0', targetStudentId: studentId)
          )); 
          if (result == true) _fetchTasks();
        },
        backgroundColor: const Color(0xFF6A11CB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ASSIGN TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey), SizedBox(height: 10), Text('No tasks assigned yet.')]));
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    String status = (task['submission_status'] ?? 'pending').toString();
    bool isCompleted = status == 'completed';
    String? subFile = task['submission_file_url'] ?? task['student_file_url'];
    bool hasSubmission = (subFile != null && subFile != '' && subFile != 'null');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Text(task['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(task['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 15),
                
                // MENTOR'S FILE (Always viewable)
                if (task['file_url'] != null && task['file_url'] != '' && task['file_url'] != 'null')
                  _fileLink('My Reference File 📘', task['file_url'], Colors.blueGrey),

                const SizedBox(height: 8),

                // STUDENT'S FILE (Viewable if exists)
                if (hasSubmission)
                  _fileLink('Student\'s Submission 📝', subFile!, Colors.green),

                const SizedBox(height: 15),
                Row(
                  children: [
                    _statusBadge(status, isCompleted ? Colors.green : Colors.orange),
                    const Spacer(),
                    Text('Marks: ${task['obtained_marks'] ?? 0} / ${task['total_marks'] ?? 100}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          if (hasSubmission)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () => _showEvalDialog(task), 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 45)), 
                child: const Text('EVALUATE SUBMISSION', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
              ),
            )
        ],
      ),
    );
  }

  Widget _fileLink(String label, String url, Color color) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [Icon(Icons.attachment_rounded, size: 16, color: color), const SizedBox(width: 10), Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  void _showEvalDialog(Map<String, dynamic> task) {
    final m = TextEditingController(text: task['obtained_marks']?.toString() ?? '');
    final f = TextEditingController(text: task['feedback']?.toString() ?? '');
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Task Evaluation'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: m, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Marks')),
        TextField(controller: f, decoration: const InputDecoration(labelText: 'Feedback')),
      ]),
      actions: [
        TextButton(onPressed: () async {
          await ApiService.evaluateTask(task['submission_id'].toString(), '0', 'resubmit', f.text);
          Navigator.pop(context); _fetchTasks();
        }, child: const Text('RESUBMIT', style: TextStyle(color: Colors.red))),
        ElevatedButton(onPressed: () async {
          await ApiService.evaluateTask(task['submission_id'].toString(), m.text, 'completed', f.text);
          Navigator.pop(context); _fetchTasks();
        }, child: const Text('MARK COMPLETE')),
      ],
    ));
  }

  Widget _statusBadge(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));
  }
}