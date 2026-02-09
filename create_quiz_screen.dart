import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleController = TextEditingController();
  
  String? _selectedCourseId;
  String? _selectedCourseName;
  List<dynamic> _myCourses = [];
  List<dynamic> _myStudents = [];
  List<String> _selectedStudentIds = [];
  
  final List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    try {
      final results = await Future.wait([
        ApiService.getCourses(mentorId: auth.user!.uid),
        ApiService.getMyStudents(auth.user!.uid)
      ]);
      
      if (mounted) {
        setState(() { 
          _myCourses = results[0]; 
          _myStudents = results[1];
          _isLoading = false; 
        });
      }
    } catch (e) { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'text': TextEditingController(),
        'a': TextEditingController(),
        'b': TextEditingController(),
        'c': TextEditingController(),
        'd': TextEditingController(),
        'correct': 'A',
      });
    });
  }

  void _saveQuiz() async {
    if (_selectedCourseId == null || _titleController.text.trim().isEmpty || _questions.isEmpty || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all details, select participants, and add at least 1 MCQ!')));
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);

    List<Map<String, dynamic>> finalQuestions = _questions.map((q) => {
      'text': q['text'].text.trim(),
      'a': q['a'].text.trim(),
      'b': q['b'].text.trim(),
      'c': q['c'].text.trim(),
      'd': q['d'].text.trim(),
      'correct': q['correct'],
    }).toList();

    try {
      final res = await ApiService.createQuiz({
        'mentor_id': auth.user?.uid,
        'course_id': _selectedCourseId,
        'course_name': _selectedCourseName,
        'title': _titleController.text.trim(),
        'description': 'Academic Assessment',
        'assigned_student_ids': _selectedStudentIds.join(','),
        'questions': finalQuestions,
      });

      if (mounted) {
        if (res['status'] == 'success') {
          for (var sId in _selectedStudentIds) {
            NotificationService.sendNotification(
              toTopic: sId, 
              title: "New Quiz Assigned! 📝", 
              body: "Your mentor has assigned: ${_titleController.text.trim()}"
            );
          }
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz Published Successfully!'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res['message'] ?? 'Check inputs'}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Design Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        actions: [
          if (!_isLoading) TextButton(onPressed: _isSaving ? null : _saveQuiz, child: const Text('PUBLISH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('QUIZ INFORMATION'),
                _buildCourseDropdown(),
                const SizedBox(height: 15),
                _buildInputField(_titleController, 'Assignment Title', Icons.edit_note_rounded),
                
                const SizedBox(height: 30),
                _buildSectionLabel('TARGET PARTICIPANTS'),
                _buildParticipantSelector(),

                const SizedBox(height: 30),
                _buildSectionLabel('QUESTIONS LIST'),
                ..._questions.asMap().entries.map((entry) => _buildQuestionForm(entry.key)).toList(),
                
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline_rounded), label: const Text('ADD MCQ'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                ),
                
                const SizedBox(height: 40),
                _isSaving 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveQuiz,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text('SAVE & PUBLISH ASSESSMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionLabel(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 5), child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)));

  Widget _buildCourseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourseId, hint: const Text('Select Academic Module', style: TextStyle(fontSize: 14)), isExpanded: true,
          items: _myCourses.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title'] ?? 'N/A'))).toList(),
          onChanged: (v) {
            setState(() {
              _selectedCourseId = v;
              _selectedCourseName = _myCourses.firstWhere((c) => c['id'].toString() == v)['title'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildParticipantSelector() {
    if (_myStudents.isEmpty) return const Text('No active mentees to assign.', style: TextStyle(fontSize: 12, color: Colors.grey));
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        children: _myStudents.map((s) => CheckboxListTile(
          title: Text(s['name'] ?? 'Mentee', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          value: _selectedStudentIds.contains(s['uid'].toString()),
          activeColor: const Color(0xFF6A11CB),
          onChanged: (val) => setState(() { if (val!) _selectedStudentIds.add(s['uid'].toString()); else _selectedStudentIds.remove(s['uid'].toString()); }),
        )).toList(),
      ),
    );
  }

  Widget _buildQuestionForm(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Q${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _questions.removeAt(i))),
          ]),
          const Divider(),
          TextField(controller: _questions[i]['text'], decoration: const InputDecoration(hintText: 'Ask your question...', border: InputBorder.none)),
          const SizedBox(height: 10),
          _miniInput(_questions[i]['a'], 'Option A'),
          _miniInput(_questions[i]['b'], 'Option B'),
          _miniInput(_questions[i]['c'], 'Option C'),
          _miniInput(_questions[i]['d'], 'Option D'),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _questions[i]['correct'],
            decoration: InputDecoration(labelText: 'Correct Key', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: ['A', 'B', 'C', 'D'].map((o) => DropdownMenuItem(value: o, child: Text('Option $o is Correct'))).toList(),
            onChanged: (v) => setState(() => _questions[i]['correct'] = v!),
          ),
        ],
      ),
    );
  }

  Widget _miniInput(TextEditingController ctrl, String hint) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: ctrl, style: const TextStyle(fontSize: 13), decoration: InputDecoration(labelText: hint, filled: true, fillColor: Colors.grey[50], border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none))));
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(controller: ctrl, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
  }
}