import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'attempt_quiz_screen.dart'; 
import 'quiz_history_screen.dart';

class StudentQuizListScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;
  const StudentQuizListScreen({super.key, required this.mentor});

  @override
  _StudentQuizListScreenState createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  List<dynamic> _availableQuizzes = [];
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final studentId = auth.user?.uid ?? '';
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch only this mentor's quizzes
      final allQuizzes = await ApiService.getQuizzes(widget.mentor['uid']);
      // 2. Fetch full history to check for attempts
      final historyData = await ApiService.getQuizHistory(studentId);
      
      if (mounted) {
        setState(() { 
          // Filter history for this mentor only
          _history = historyData.where((h) => h['mentor_id'].toString() == widget.mentor['uid'].toString()).toList();
          
          // Show quizzes assigned to this student AND not yet attempted
          _availableQuizzes = allQuizzes.where((q) {
            bool isAssigned = (q['assigned_student_ids']?.toString() ?? '').contains(studentId);
            bool isAttempted = historyData.any((h) => h['quiz_id'].toString() == q['id'].toString());
            return isAssigned && !isAttempted;
          }).toList();
          
          _isLoading = false; 
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Available Assessments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizHistoryScreen(mentorId: widget.mentor['uid']))),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHistoryBanner(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('ASSESSMENTS FROM ${widget.mentor['name']?.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey, letterSpacing: 1.2)),
                ),
                Expanded(
                  child: _availableQuizzes.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _availableQuizzes.length,
                            itemBuilder: (context, index) => _buildQuizCard(_availableQuizzes[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 15),
          Expanded(child: Text('Completed ${_history.length} quizzes with this mentor.', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizHistoryScreen(mentorId: widget.mentor['uid']))), 
            child: const Text('VIEW RESULTS')
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quiz['course_name']?.toUpperCase() ?? 'GENERAL', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 9)),
          const SizedBox(height: 8),
          Text(quiz['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(quiz['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Divider(height: 30),
          ElevatedButton(
            onPressed: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => AttemptQuizScreen(quiz: quiz)));
              if (res == true) _fetchData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('START TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No new quizzes assigned by this mentor.', style: TextStyle(color: Colors.grey)));
  }
}