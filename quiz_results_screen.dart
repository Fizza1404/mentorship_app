import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class MentorQuizResultsScreen extends StatefulWidget {
  final String? studentId; 
  final String? quizId;    
  const MentorQuizResultsScreen({super.key, this.studentId, this.quizId});

  @override
  State<MentorQuizResultsScreen> createState() => _MentorQuizResultsScreenState();
}

class _MentorQuizResultsScreenState extends State<MentorQuizResultsScreen> {
  List<dynamic> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getAllQuizResults(auth.user!.uid);
      if (mounted) {
        setState(() {
          // Robust filter logic
          _results = data.where((r) {
            bool matchesStudent = true;
            if (widget.studentId != null && widget.studentId!.isNotEmpty) {
              matchesStudent = r['student_id'].toString() == widget.studentId.toString();
            }

            bool matchesQuiz = true;
            if (widget.quizId != null && widget.quizId!.isNotEmpty) {
              matchesQuiz = r['quiz_id'].toString() == widget.quizId.toString();
            }

            return matchesStudent && matchesQuiz;
          }).toList();
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
        title: const Text('Quiz Submission Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
          : _results.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchResults,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _results.length,
                    itemBuilder: (context, index) => _buildResultTile(_results[index]),
                  ),
                ),
    );
  }

  Widget _buildResultTile(Map<String, dynamic> res) {
    int score = int.tryParse(res['score'].toString()) ?? 0;
    int total = int.tryParse(res['total_questions'].toString()) ?? 1;
    double perc = (score / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: perc >= 50 ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${perc.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: perc >= 50 ? Colors.green[800] : Colors.red[800])),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res['student_name'] ?? 'Mentee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(res['quiz_title'] ?? 'Module Assessment', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score/$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6A11CB))),
              const SizedBox(height: 4),
              Text(
                res['attempted_at'] != null ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(res['attempted_at'])) : '---', 
                style: const TextStyle(fontSize: 9, color: Colors.grey)
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
          Icon(Icons.assignment_late_outlined, size: 70, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No students have attempted this quiz yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}