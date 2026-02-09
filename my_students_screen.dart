import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'student_task_progress_screen.dart';
import 'student_profile_view_screen.dart';

class MyStudentsScreen extends StatefulWidget {
  const MyStudentsScreen({super.key});

  @override
  State<MyStudentsScreen> createState() => _MyStudentsScreenState();
}

class _MyStudentsScreenState extends State<MyStudentsScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final mentorId = Provider.of<MyAuthProvider>(context, listen: false).user?.uid ?? '';
    if (mentorId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMyStudents(mentorId);
      if (mounted) {
        setState(() {
          _students = data;
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
        title: const Text('My Active Mentees', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchStudents),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
        : RefreshIndicator(
            onRefresh: _fetchStudents,
            child: _students.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _students.length,
                  itemBuilder: (context, index) => _studentCard(_students[index]),
                ),
          ),
    );
  }

  Widget _studentCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
              child: Text(student['name']?[0].toUpperCase() ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB), fontSize: 20)),
            ),
            title: Text(student['name'] ?? 'Mentee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(student['education'] ?? 'Academic details not provided', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                Text('Interest: ${student['interest'] ?? "General Learning"}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentProfileViewScreen(student: student))),
          ),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentTaskProgressScreen(student: student))),
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('TRACK WORK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF6A11CB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentProfileViewScreen(student: student))),
                  icon: const Icon(Icons.person_outline_rounded, size: 16),
                  label: const Text('PROFILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No accepted mentees found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Accepted students will appear here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}