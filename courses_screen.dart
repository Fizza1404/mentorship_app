import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'add_course_screen.dart';
import 'course_detail_screen.dart'; // Import added

class Course {
  final String id;
  final String title;
  final String description;
  final String mentorName;
  final String mentorId;
  final String duration;
  final String courseCode;
  final String category;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.mentorName,
    required this.mentorId,
    required this.duration,
    required this.courseCode,
    required this.category,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Course',
      description: json['description'] ?? 'No description provided.',
      mentorName: json['mentor_name'] ?? 'Assigned Mentor',
      mentorId: json['mentor_id']?.toString() ?? '',
      duration: json['duration_hours']?.toString() ?? 'N/A',
      courseCode: json['course_code'] ?? 'N/A',
      category: json['category'] ?? 'General',
      createdAt: parsedDate,
    );
  }
}

class CoursesScreen extends StatefulWidget {
  final String? mentorId;
  const CoursesScreen({super.key, this.mentorId});

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final userRole = authProvider.userRole?.toLowerCase() ?? 'student';
    final userId = authProvider.user?.uid ?? '';

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String? filterId;
      if (userRole == 'mentor') {
        filterId = userId;
      } else {
        if (widget.mentorId != null) {
          filterId = widget.mentorId;
        } else {
          final status = await ApiService.getMentorshipStatus(userId);
          if (status['status'] == 'accepted') {
            filterId = status['mentor_id'].toString();
          }
        }
      }

      if (filterId == null) {
        if (mounted) setState(() { _courses = []; _isLoading = false; });
        return;
      }

      final data = await ApiService.getCourses(mentorId: filterId);
      if (mounted) {
        setState(() {
          if (data is List) {
            _courses = data.map((x) => Course.fromJson(x)).toList();
          } else {
            _courses = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    final userRole = authProvider.userRole?.toLowerCase() ?? 'student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        title: const Text('Academic Curriculum', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17)),
        actions: [
          if (userRole == 'mentor')
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: _navigateToAddCourse,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCourses,
              color: const Color(0xFF6A11CB),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
                  : _courses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            List<Color> cardColors = [Colors.blueAccent, Colors.deepPurpleAccent, Colors.teal, Colors.indigo];
                            return _buildCourseCard(_courses[index], cardColors[index % cardColors.length]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVAILABLE CONTENT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text('${_courses.length} Active Modules', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _navigateToAddCourse() async {
    bool? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCourseScreen()));
    if (result == true) _fetchCourses();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No modules registered yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course))),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(height: 5, width: double.infinity, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(course.courseCode, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      Text(course.category.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(course.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const Divider(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _iconLabel(Icons.timer_outlined, course.duration),
                      _iconLabel(Icons.person_pin_rounded, course.mentorName),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }
}