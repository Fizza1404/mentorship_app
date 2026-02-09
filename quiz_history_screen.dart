import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class QuizHistoryScreen extends StatefulWidget {
  final String? mentorId; 
  const QuizHistoryScreen({super.key, this.mentorId});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getQuizHistory(auth.user!.uid);
      if (mounted) {
        setState(() {
          if (widget.mentorId != null && widget.mentorId!.isNotEmpty) {
            // ROBUST FILTER: Compare as strings
            _history = data.where((q) => q['mentor_id'].toString() == widget.mentorId.toString()).toList();
          } else {
            _history = data;
          }
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
        title: const Text('Performance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
        : _history.isEmpty 
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _history.length,
                itemBuilder: (context, index) => _buildResultCard(_history[index]),
              ),
            ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> res) {
    int score = int.tryParse(res['score'].toString()) ?? 0;
    int total = int.tryParse(res['total_questions'].toString()) ?? 1;
    double percentage = (score / total) * 100;
    String courseName = res['course_name'] ?? 'Module Assessment';
    
    String formattedDate = "---";
    try {
      if (res['attempted_at'] != null) {
        formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(res['attempted_at']));
      }
    } catch (e) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                child: Text(courseName.toUpperCase(), style: const TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5)),
              ),
              Text(formattedDate, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: percentage >= 50 ? Colors.green[50] : Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: percentage >= 50 ? Colors.green[700] : Colors.red[700]),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res['title'] ?? 'Academic Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Accuracy: $score / $total correct', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge(percentage >= 50 ? "PASSED" : "FAILED", percentage >= 50 ? Colors.green : Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No records found for this mentor.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}