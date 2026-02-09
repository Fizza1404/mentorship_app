import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'create_quiz_screen.dart';
import 'quiz_results_screen.dart';

class MentorQuizListScreen extends StatefulWidget {
  const MentorQuizListScreen({super.key});

  @override
  State<MentorQuizListScreen> createState() => _MentorQuizListScreenState();
}

class _MentorQuizListScreenState extends State<MentorQuizListScreen> {
  List<dynamic> _quizzes = [];
  List<dynamic> _myStudents = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final mentorId = Provider.of<MyAuthProvider>(context, listen: false).user?.uid ?? '';
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        ApiService.getQuizzes(mentorId),
        ApiService.getMyStudents(mentorId)
      ]);
      
      if (mounted) {
        setState(() { 
          _quizzes = results[0]; 
          _myStudents = results[1];
          _isLoading = false; 
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  String _getAssignedStudentNames(String? ids) {
    if (ids == null || ids.isEmpty || ids == 'null') return 'All Active Mentees';
    List<String> idList = ids.split(',').map((id) => id.trim()).toList();
    List<String> names = [];
    for (var id in idList) {
      if (id.isEmpty) continue;
      final student = _myStudents.firstWhere((s) => (s['uid'] ?? s['student_id']).toString() == id, orElse: () => null);
      if (student != null) names.add(student['name'] ?? 'Mentee');
    }
    return names.isEmpty ? 'Individual Mentees' : names.join(', ');
  }

  Map<String, List<dynamic>> _getGroupedQuizzes() {
    Map<String, List<dynamic>> grouped = {};
    for (var quiz in _quizzes) {
      String course = quiz['course_name'] ?? 'Curriculum Assessment';
      if (!grouped.containsKey(course)) grouped[course] = [];
      grouped[course]!.add(quiz);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedQuizzes = _getGroupedQuizzes();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Managed Quizzes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MentorQuizResultsScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchInitialData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: groupedQuizzes.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCourseHeader(entry.key),
                          ...entry.value.map((quiz) => _buildQuizManageCard(quiz)),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateQuizScreen()));
          if (res == true) _fetchInitialData();
        },
        backgroundColor: const Color(0xFF6A11CB),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text('CREATE NEW QUIZ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildCourseHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, size: 18, color: Color(0xFF6A11CB)),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildQuizManageCard(Map<String, dynamic> quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(quiz['title'] ?? 'Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ASSIGNED TO:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(_getAssignedStudentNames(quiz['assigned_student_ids']), style: const TextStyle(fontSize: 11, color: Color(0xFF2575FC), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => MentorQuizResultsScreen(quizId: quiz['id'].toString())
                )),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB).withOpacity(0.05), foregroundColor: const Color(0xFF6A11CB), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('VIEW RESULTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              )
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
          Icon(Icons.quiz_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No quizzes found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Click Create New Quiz to start.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}