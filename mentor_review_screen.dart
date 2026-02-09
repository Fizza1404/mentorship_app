import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class MentorReviewScreen extends StatefulWidget {
  final Map<String, dynamic> mentor;
  const MentorReviewScreen({super.key, required this.mentor});

  @override
  _MentorReviewScreenState createState() => _MentorReviewScreenState();
}

class _MentorReviewScreenState extends State<MentorReviewScreen> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a review.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);

    try {
      final res = await ApiService.addReview({
        'mentor_id': widget.mentor['uid'],
        'student_id': auth.user?.uid,
        'student_name': auth.userName,
        'rating': _selectedRating,
        'review_text': _commentController.text.trim(),
      });

      if (mounted) {
        if (res['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you! Rating saved.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${res['message'] ?? "Try again later."}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Review Mentor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
                      child: Text(widget.mentor['name']?[0] ?? 'M', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                    ),
                    const SizedBox(height: 20),
                    const Text('Rate your learning journey with', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(widget.mentor['name'] ?? 'Mentor', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 40),
                    
                    // TOGGLE SUPPORT: Professional Star Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        int starValue = index + 1;
                        return InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            setState(() {
                              // If already selected, reduce rating (toggle logic)
                              if (_selectedRating == starValue) {
                                _selectedRating = starValue - 1;
                              } else {
                                _selectedRating = starValue;
                              }
                              // Ensure rating doesn't go below 1 for professional feedback
                              if (_selectedRating < 1) _selectedRating = 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Icon(
                              starValue <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: starValue <= _selectedRating ? Colors.amber[700] : Colors.grey[300],
                              size: 45,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text('Rating: $_selectedRating / 5', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),

                    const SizedBox(height: 40),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any feedback or suggestions?',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    _isSubmitting 
                      ? const CircularProgressIndicator(color: Color(0xFF6A11CB))
                      : ElevatedButton(
                          onPressed: _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                          ),
                          child: const Text('SUBMIT FEEDBACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}