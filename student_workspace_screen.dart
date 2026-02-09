import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentWorkspaceScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const StudentWorkspaceScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'student_${student['uid']}',
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white24,
                        child: Text(
                          (student['name'] ?? 'S')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student['name'] ?? 'Student Name',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      student['education'] ?? 'Course Details',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Application Overview'),
                  _buildProfileCard([
                    _infoRow(Icons.lightbulb_outline, 'Interest Area', student['interest']),
                    _infoRow(Icons.trending_up, 'Experience Level', student['skill_level']),
                    _infoRow(Icons.timer_outlined, 'Availability', student['hours']),
                  ]),
                  
                  const SizedBox(height: 25),
                  _sectionHeader('Student Motivation'),
                  _buildSimpleCard(
                    Text(
                      student['reason'] ?? 'No statement provided by the student.',
                      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  _sectionHeader('Portfolio & Socials'),
                  _buildSimpleCard(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _socialIcon(Icons.link, 'LinkedIn', student['linkedin']),
                        _socialIcon(Icons.code, 'GitHub', student['github']),
                        _socialIcon(Icons.language, 'Portfolio', student['portfolio']),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'UID: ${student['uid']}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSimpleCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: const Color(0xFF6A11CB)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, String label, String? url) {
    bool hasUrl = url != null && url.isNotEmpty && url != 'null';
    return InkWell(
      onTap: hasUrl ? () => _launchURL(url) : null,
      child: Column(
        children: [
          Icon(icon, color: hasUrl ? const Color(0xFF2575FC) : Colors.grey[200], size: 30),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasUrl ? Colors.black87 : Colors.grey[300])),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    String finalUrl = url.trim();
    if (!finalUrl.startsWith('http')) finalUrl = 'https://$finalUrl';
    await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
  }
}