import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'student_personal_task_screen.dart';

class MentorTaskCenterScreen extends StatefulWidget {
  const MentorTaskCenterScreen({super.key});

  @override
  _MentorTaskCenterScreenState createState() => _MentorTaskCenterScreenState();
}

class _MentorTaskCenterScreenState extends State<MentorTaskCenterScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final mentorId = Provider.of<MyAuthProvider>(context, listen: false).user?.uid ?? '';
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final students = await ApiService.getMyStudents(mentorId);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Mentee Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
                : _students.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _students.length,
                          itemBuilder: (context, index) => _buildStudentActionCard(_students[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 15, 30, 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submission Tracking', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('Select a student to review their work and grades.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStudentActionCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
          child: Text(student['name']?[0].toUpperCase() ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
        ),
        title: Text(student['name'] ?? 'Mentee', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(student['education'] ?? 'View Academic Profile', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPersonalTaskScreen(student: student)));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No active mentees found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}