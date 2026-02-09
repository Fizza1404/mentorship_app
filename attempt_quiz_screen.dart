import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class AttemptQuizScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const AttemptQuizScreen({super.key, required this.quiz});

  @override
  _AttemptQuizScreenState createState() => _AttemptQuizScreenState();
}

class _AttemptQuizScreenState extends State<AttemptQuizScreen> {
  List<dynamic> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Map<int, String> _selectedAnswers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final data = await ApiService.getQuizQuestions(widget.quiz['id'].toString());
      if (mounted) setState(() { _questions = data; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  void _finishQuiz() async {
    if (_selectedAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please answer all questions!')));
      return;
    }

    int finalScore = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correct_option']) {
        finalScore++;
      }
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);

    try {
      final res = await ApiService.saveQuizResult({
        'student_id': auth.user!.uid,
        'quiz_id': widget.quiz['id'],
        'mentor_id': widget.quiz['mentor_id'], 
        'score': finalScore,
        'total': _questions.length,
      });

      if (mounted) {
        if (res['status'] == 'success') {
          NotificationService.sendNotification(
            toTopic: widget.quiz['mentor_id'].toString(), 
            title: "Quiz Attempted! ✅", 
            body: "${auth.userName} has completed the quiz: ${widget.quiz['title']}"
          );
          _showScoreDialog(finalScore, _questions.length);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${res['message'] ?? 'Please check server response'}'))
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showScoreDialog(int score, int total) {
    double percent = (score / total) * 100;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Center(child: Text('Result 🎉', style: TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${percent.toInt()}%', style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: percent >= 50 ? Colors.green : Colors.red)),
            const SizedBox(height: 10),
            Text('You scored $score out of $total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            const Text('Your record is synced with your mentor.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(120, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('FINISH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(widget.quiz['title'] ?? 'Assessment'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
        : _questions.isEmpty
          ? const Center(child: Text('No questions available.'))
          : Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length, minHeight: 8, color: Colors.orange, backgroundColor: Colors.grey[200]),
                  ),
                  const SizedBox(height: 25),
                  Text('Question ${_currentIndex + 1} of ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                  const SizedBox(height: 15),
                  Text(_questions[_currentIndex]['question_text'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildOption('A', _questions[_currentIndex]['option_a']),
                        _buildOption('B', _questions[_currentIndex]['option_b']),
                        _buildOption('C', _questions[_currentIndex]['option_c']),
                        _buildOption('D', _questions[_currentIndex]['option_d']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        IconButton(onPressed: () => setState(() => _currentIndex--), icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF6A11CB)))
                      else const SizedBox(width: 48),
                      
                      _isSaving 
                        ? const CircularProgressIndicator(color: Color(0xFF6A11CB))
                        : ElevatedButton(
                            onPressed: _currentIndex < _questions.length - 1 
                              ? () {
                                  if (_selectedAnswers[_currentIndex] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an answer!')));
                                    return;
                                  }
                                  setState(() => _currentIndex++);
                                }
                              : _finishQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentIndex < _questions.length - 1 ? const Color(0xFF6A11CB) : Colors.green,
                              minimumSize: const Size(140, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 3,
                            ),
                            child: Row(
                              children: [
                                Text(_currentIndex < _questions.length - 1 ? 'NEXT' : 'FINISH', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Icon(_currentIndex < _questions.length - 1 ? Icons.arrow_forward_ios_rounded : Icons.check_circle_outline, size: 16, color: Colors.white),
                              ],
                            ),
                          ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildOption(String key, String text) {
    bool isSelected = _selectedAnswers[_currentIndex] == key;
    return InkWell(
      onTap: () => setState(() => _selectedAnswers[_currentIndex] = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A11CB).withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF6A11CB) : Colors.grey[200]!, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF6A11CB).withOpacity(0.1), blurRadius: 8)] : [],
        ),
        child: IgnorePointer(
          child: RadioListTile<String>(
            title: Text(text, style: TextStyle(color: isSelected ? const Color(0xFF6A11CB) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            value: key,
            groupValue: _selectedAnswers[_currentIndex],
            activeColor: const Color(0xFF6A11CB),
            onChanged: (v) {},
          ),
        ),
      ),
    );
  }
}