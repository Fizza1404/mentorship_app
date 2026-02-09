import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/certificate_service.dart';
import '../../services/meeting_service.dart';
import '../chat/group_chat_screen.dart';
import '../chat/private_chat_screen.dart';
import '../courses/courses_screen.dart';
import '../mentor/mentor_profile_screen.dart';
import '../resources/resource_library_screen.dart';
import 'student_task_board_screen.dart';
import 'student_quiz_list_screen.dart';
import 'performance_analytics_screen.dart';

class EnrolledMentorDashboard extends StatefulWidget {
  final Map<String, dynamic> mentor;
  const EnrolledMentorDashboard({super.key, required this.mentor});

  @override
  _EnrolledMentorDashboardState createState() => _EnrolledMentorDashboardState();
}

class _EnrolledMentorDashboardState extends State<EnrolledMentorDashboard> {
  double _progress = 0.0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  bool _isLoadingProgress = true;
  bool _isMentorLive = false;
  bool _isCertified = false;
  String _liveRoom = "";
  Timer? _liveCheckTimer;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _liveCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkLiveStatus());
  }

  @override
  void dispose() {
    _liveCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    await _fetchProgress();
    await _checkLiveStatus();
    await _checkCertificationStatus();
  }

  Future<void> _checkCertificationStatus() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    try {
      final apps = await ApiService.getStudentApplications(auth.user!.uid);
      final myApp = apps.firstWhere((a) => a['mentor_id'].toString() == widget.mentor['uid'].toString());
      if (mounted) setState(() => _isCertified = (myApp['is_certified'] == 1 || myApp['is_certified'] == "1"));
    } catch (e) {}
  }

  Future<void> _checkLiveStatus() async {
    try {
      final res = await ApiService.getLiveStatus(widget.mentor['uid']);
      if (mounted) {
        setState(() {
          _isMentorLive = (res['is_live'] == 1 || res['is_live'] == "1");
          _liveRoom = res['live_room'] ?? "";
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchProgress() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    if (!mounted) return;
    setState(() => _isLoadingProgress = true);
    
    try {
      final courses = await ApiService.getCourses(mentorId: widget.mentor['uid']);
      int total = 0;
      int completed = 0;

      for (var course in courses) {
        final tasks = await ApiService.getTasks(course['id'].toString(), studentId: auth.user?.uid, role: 'student');
        total += tasks.length;
        completed += tasks.where((t) => t['submission_status'] == 'completed').length;
      }

      if (mounted) {
        setState(() {
          _totalTasks = total;
          _completedTasks = completed;
          _progress = total == 0 ? 0.0 : (completed / total);
          _isLoadingProgress = false;
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoadingProgress = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        title: Text('${widget.mentor['name']}\'s Portal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MentorProfileScreen(mentor: widget.mentor))),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressHeader(),
              const SizedBox(height: 25),
              if (_isMentorLive) _buildLiveCallCard(auth),
              if (_isCertified) _buildCertificateBanner(auth.userName ?? 'Student'),
              
              _sectionLabel('Learning & Performance'),
              const SizedBox(height: 15),
              _actionTile(Icons.analytics_outlined, 'Performance Analytics', 'Track your scores and progress', Colors.deepOrangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => PerformanceAnalyticsScreen(mentorId: widget.mentor['uid'])))),
              const SizedBox(height: 12),
              _actionTile(Icons.quiz_rounded, 'Skill Assessments', 'Attempt assigned quizzes', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentQuizListScreen(mentor: widget.mentor)))),

              const SizedBox(height: 30),
              _sectionLabel('Academic Resources'),
              const SizedBox(height: 15),
              _actionTile(Icons.auto_stories_rounded, 'Curriculum', 'Modules and syllabus', const Color(0xFF6A11CB), () => Navigator.push(context, MaterialPageRoute(builder: (context) => CoursesScreen(mentorId: widget.mentor['uid'])))),
              const SizedBox(height: 12),
              _actionTile(Icons.assignment_turned_in_rounded, 'Task Board', '$_completedTasks Completed', Colors.pink, () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => StudentTaskBoardScreen(mentor: widget.mentor))); _fetchProgress(); }),
              const SizedBox(height: 12),
              _actionTile(Icons.folder_shared_rounded, 'Resource Library', 'PDFs, Videos and Notes', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ResourceLibraryScreen(mentor: widget.mentor)))),
              
              const SizedBox(height: 30),
              _sectionLabel('Direct Support'),
              const SizedBox(height: 15),
              _actionTile(Icons.forum_rounded, 'Class Discussion', 'Group chat with peers', Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatScreen(mentorId: widget.mentor['uid'], mentorName: widget.mentor['name'])))),
              const SizedBox(height: 12),
              _actionTile(Icons.chat_bubble_rounded, 'Mentor Direct', '1-on-1 private help', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivateChatScreen(otherUserId: widget.mentor['uid'], otherUserName: widget.mentor['name'] ?? 'Mentor')))),
              
              const SizedBox(height: 35),
              _buildMentorCard(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: _progress, strokeWidth: 8, backgroundColor: Colors.grey[100], valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)))),
          Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(width: 25),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('OVERALL PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)), SizedBox(height: 5), Text('Your Learning Path', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Widget _buildMentorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1), child: Text(widget.mentor['name']?[0] ?? 'M', style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.mentor['name'] ?? 'Mentor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Academic Guide', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MentorProfileScreen(mentor: widget.mentor))),
            child: const Text('VIEW PROFILE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String desc, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap, tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  Widget _buildLiveCallCard(MyAuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.red, Color(0xFFFF4B2B)]), borderRadius: BorderRadius.circular(25)),
      child: Row(children: [
        const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
        const SizedBox(width: 15),
        const Expanded(child: Text('LIVE SESSION STARTED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ElevatedButton(onPressed: () => MeetingService.startMeeting(roomName: _liveRoom, userName: auth.userName ?? "Student", userEmail: auth.user?.email ?? ""), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red), child: const Text('JOIN'))
      ]),
    );
  }

  Widget _buildCertificateBanner(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.amber)),
      child: Row(children: [
        const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 40),
        const SizedBox(width: 15),
        const Expanded(child: Text('Program Certified! 🏆', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        TextButton(onPressed: () => CertificateService.generateCertificate(studentName: name, mentorName: widget.mentor['name'] ?? 'Mentor', courseTitle: 'Professional Program'), child: const Text('GET IT'))
      ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.5));
}