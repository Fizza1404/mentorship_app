import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/meeting_service.dart';

import 'auth/login_screen.dart';
import 'chat/group_chat_screen.dart';
import 'chat/private_chat_list_screen.dart';
import 'courses/courses_screen.dart';
import 'mentor/my_students_screen.dart';
import 'mentor/mentor_profile_screen.dart';
import 'mentor/mentor_quiz_list_screen.dart'; 
import 'mentor/mentor_task_center_screen.dart'; 
import 'resources/resource_library_screen.dart'; 
import 'student/enrolled_mentor_dashboard.dart';
import 'profile/edit_profile_screen.dart';
import 'mentor/student_profile_view_screen.dart';
import 'mentor/quiz_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allMentors = []; 
  List<dynamic> _myEnrolledMentors = [];
  List<dynamic> _requests = [];
  List<dynamic> _myApplications = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Flutter', 'Python', 'Java', 'AI', 'UI/UX', 'Web', 'Backend', 'Data Science'];

  @override
  void initState() {
    super.initState();
    _loadCacheAndFetch();
    _searchController.addListener(() { setState(() {}); });
  }

  Future<void> _loadCacheAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('mentors_cache')) {
      if (mounted) {
        setState(() {
          _allMentors = json.decode(prefs.getString('mentors_cache')!);
          _isLoading = false;
        });
      }
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final userRole = authProvider.userRole?.toLowerCase() ?? 'student';
    final userId = authProvider.user?.uid ?? '';

    try {
      if (userRole == 'student') {
        NotificationService.subscribeToTopic(userId);
        
        final results = await Future.wait([
          ApiService.getAllMentors(studentId: userId),
          ApiService.getMyMentors(userId),
          ApiService.getStudentApplications(userId),
        ]);

        if (mounted) {
          setState(() {
            _allMentors = results[0];
            _myEnrolledMentors = results[1];
            _myApplications = results[2]; 
            _isLoading = false;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('mentors_cache', json.encode(_allMentors));
        }
      } else {
        final dynamic reqData = await ApiService.getMentorRequests(userId);
        if (mounted) {
          setState(() {
            _requests = reqData is List ? List<dynamic>.from(reqData) : [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMentorshipStatusFor(String mentorUid) {
    for (var app in _myApplications) {
      if (app['mentor_id'].toString().trim() == mentorUid.toString().trim()) {
        return app['status']?.toString().toLowerCase() ?? 'none';
      }
    }
    return 'none';
  }

  Future<void> _handleRequest(Map<String, dynamic> req, String status) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.updateRequestStatus(req['id'].toString(), status);
      if (status == 'accepted') {
        NotificationService.sendNotification(toTopic: req['student_id'].toString(), title: "Enrollment Accepted! ✅", body: "Your mentor has accepted your request. Welcome aboard!");
      } else if (status == 'rejected') {
        NotificationService.sendNotification(toTopic: req['student_id'].toString(), title: "Enrollment Update ⚠️", body: "Your request was declined.");
      }
      await _fetchData(); 
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);
    final userName = authProvider.userName ?? 'User';
    final userRole = authProvider.userRole?.toLowerCase() ?? 'student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6A11CB),
        centerTitle: true,
        title: Text(userRole == 'mentor' ? 'MENTOR HUB' : 'STUDENT PORTAL', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
        actions: [
          IconButton(icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => _fetchData())),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () async {
            await authProvider.logout();
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFF6A11CB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(userName, userRole),
              if (userRole == 'student') _buildSearchAndFilter(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: userRole == 'student' ? _buildStudentView() : _buildMentorView(authProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String role) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Image.asset('images/logo.png', height: 50, errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: Color(0xFF6A11CB))),
          ),
          const SizedBox(height: 20),
          Text(role.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('Welcome, $name', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: TextField(
            controller: _searchController, 
            decoration: const InputDecoration(hintText: 'Search mentors or skills...', prefixIcon: Icon(Icons.search, color: Color(0xFF6A11CB)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15))
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(height: 45, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _categories.length, itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              selected: isSelected, onSelected: (val) { setState(() { _selectedCategory = cat; }); _fetchData(); },
              backgroundColor: Colors.white, selectedColor: const Color(0xFF6A11CB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), showCheckmark: false, elevation: 2,
            ),
          );
        })),
      ]),
    );
  }

  Widget _buildStudentView() {
    final query = _searchController.text.toLowerCase();
    final discoverMentors = _allMentors.where((m) {
      final name = (m['name'] ?? "").toLowerCase();
      final enrolledUids = _myEnrolledMentors.map((e) => e['uid'].toString()).toList();
      return name.contains(query) && !enrolledUids.contains(m['uid'].toString());
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_myEnrolledMentors.isNotEmpty) ...[
        const Text('Active Mentorships', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _myEnrolledMentors.length, itemBuilder: (context, index) => _buildEnrolledCard(_myEnrolledMentors[index]))),
        const SizedBox(height: 30),
      ],
      const Text('Explore Available Mentors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      if (_isLoading && _allMentors.isEmpty) const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
      else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: discoverMentors.length, itemBuilder: (context, index) => _buildMentorCard(discoverMentors[index])),
    ]);
  }

  Widget _buildEnrolledCard(Map<String, dynamic> mentor) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EnrolledMentorDashboard(mentor: mentor))),
      child: Container(
        width: 140, margin: const EdgeInsets.only(right: 15, bottom: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 25, backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1), child: Text(mentor['name']?[0] ?? 'M', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB)))),
          const SizedBox(height: 10),
          Text(mentor['name'] ?? 'Mentor', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    String status = _getMentorshipStatusFor(mentor['uid']);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(radius: 25, child: Text(mentor['name']?[0] ?? 'M')),
        title: Text(mentor['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(mentor['skills'] ?? 'Expert Mentor', maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MentorProfileScreen(mentor: mentor))),
        trailing: (status == 'pending') 
          ? _statusBadge('PENDING', Colors.orange) 
          : (status == 'rejected') 
            ? _statusBadge('REAPPLY', Colors.red, isReapply: true, mentor: mentor) 
            : ElevatedButton(
                onPressed: () => _showApplyForm(mentor),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(80, 35)),
                child: const Text('APPLY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color, {bool isReapply = false, dynamic mentor}) {
    return InkWell(
      onTap: isReapply ? () => _showApplyForm(mentor) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: isReapply ? Border.all(color: color.withOpacity(0.5)) : null), 
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))
      ),
    );
  }

  Widget _buildMentorView(MyAuthProvider auth) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Management Console', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _buildActionCard(icon: Icons.forum_outlined, title: 'CLASS GROUP', color: const Color(0xFF00CDAC), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupChatScreen())))),
        const SizedBox(width: 15),
        Expanded(child: _buildActionCard(icon: Icons.people_outline, title: 'MY MENTEES', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyStudentsScreen())))),
      ]),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: _buildActionCard(icon: Icons.library_books_outlined, title: 'COURSES', color: const Color(0xFF6A11CB), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CoursesScreen())))),
        const SizedBox(width: 15),
        Expanded(child: _buildActionCard(icon: Icons.folder_shared_outlined, title: 'LIBRARY', color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourceLibraryScreen())))),
      ]),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: _buildActionCard(icon: Icons.quiz_outlined, title: 'QUIZ BUILDER', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MentorQuizListScreen())))),
        const SizedBox(width: 15),
        Expanded(child: _buildActionCard(icon: Icons.assignment_turned_in_outlined, title: 'TASK CENTER', color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MentorTaskCenterScreen())))),
      ]),
      const SizedBox(height: 15),
      _buildActionCard(icon: Icons.mail_outline_rounded, title: 'DIRECT MESSAGES', color: Colors.blueGrey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivateChatListScreen()))),
      
      const SizedBox(height: 40),
      const Text('Pending Enrollment Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      if (_isLoading && _requests.isEmpty) const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
      else if (_requests.isEmpty) const Text('No pending requests.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
      else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _requests.length, itemBuilder: (context, index) => _buildRequestCard(_requests[index])),
    ]);
  }

  Widget _buildActionCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(25), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 10), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))])));
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
                child: Text(req['student_name']?[0] ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['student_name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(req['student_email'] ?? 'Mentee', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('NEW REQUEST', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
          _requestDetailRow(Icons.school_outlined, 'Qualification', req['education']),
          const SizedBox(height: 8),
          _requestDetailRow(Icons.interests_outlined, 'Interest', req['interest']),
          const SizedBox(height: 15),
          const Text('WHY I WANT TO JOIN:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 5),
          Text(req['reason'] ?? 'Not provided', style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleRequest(req, 'rejected'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('DECLINE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleRequest(req, 'accepted'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('ACCEPT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentProfileViewScreen(student: req))),
              child: const Text('VIEW FULL PROFILE', style: TextStyle(fontSize: 12, color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _requestDetailRow(IconData icon, String label, String? val) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Expanded(child: Text(val ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.black87), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Future<void> _showApplyForm(Map<String, dynamic> mentor) async {
    await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _ApplyForm(mentor: mentor, onComplete: _fetchData));
  }
}

class _ApplyForm extends StatefulWidget {
  final Map<String, dynamic> mentor;
  final VoidCallback onComplete;
  const _ApplyForm({super.key, required this.mentor, required this.onComplete});
  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  final _reasonCtrl = TextEditingController();
  final _eduCtrl = TextEditingController();
  final _intCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _gitCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 30, right: 30, top: 30),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Apply to ${widget.mentor['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
          const SizedBox(height: 20),
          _inputField(_eduCtrl, 'Your Academic Qualification (e.g. BS SE Final Year)'),
          const SizedBox(height: 15),
          _inputField(_intCtrl, 'Primary Interest (e.g. Flutter, AI, Data Science)'),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _inputField(_linkCtrl, 'LinkedIn URL')),
            const SizedBox(width: 10),
            Expanded(child: _inputField(_gitCtrl, 'GitHub URL')),
          ]),
          const SizedBox(height: 15),
          _inputField(_portCtrl, 'Portfolio Link (Optional)'),
          const SizedBox(height: 15),
          _inputField(_reasonCtrl, 'Why should this mentor select you?', maxLines: 3),
          const SizedBox(height: 30),
          _submitting ? const Center(child: CircularProgressIndicator()) : ElevatedButton(
            onPressed: () async {
              setState(() => _submitting = true);
              await ApiService.applyToMentor({
                'student_id': auth.user!.uid,
                'mentor_id': widget.mentor['uid'],
                'education': _eduCtrl.text.trim(),
                'interest': _intCtrl.text.trim(),
                'reason': _reasonCtrl.text.trim(),
                'linkedin': _linkCtrl.text.trim(),
                'github': _gitCtrl.text.trim(),
                'portfolio': _portCtrl.text.trim(),
              });
              if (mounted) { Navigator.pop(context); widget.onComplete(); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text('SUBMIT APPLICATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
  }
}