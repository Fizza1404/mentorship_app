import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProfileViewScreen extends StatelessWidget {
  final Map<String, dynamic> student; // Dynamic data from applications + users sync

  const StudentProfileViewScreen({super.key, required this.student});

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty || url == 'null') return;
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Mentee Full Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard('Professional Summary', [
                    _infoRow(Icons.person_outline, 'Full Name', student['name']),
                    _infoRow(Icons.school_outlined, 'Academic Qualification', student['education']),
                    _infoRow(Icons.psychology_outlined, 'Technical Skills', student['skills'] ?? 'Not set in profile'),
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildSectionCard('Interests & Motivation', [
                    _detailBlock('Primary Interests', student['interest']),
                    const SizedBox(height: 15),
                    _detailBlock('Enrollment Reason', student['reason']),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionCard('About Mentee (Bio)', [
                    Text(
                      student['bio'] ?? 'No personal bio added yet.',
                      style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
                    ),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionCard('Connectivity & Links', [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _socialBtn(Icons.link, 'LinkedIn', student['linkedin']),
                        _socialBtn(Icons.code, 'GitHub', student['github']),
                        _socialBtn(Icons.language, 'Portfolio', student['portfolio']),
                      ],
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  const Center(
                    child: Text('Data synced with latest profile update.', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white24,
            child: Text(student['name']?[0].toUpperCase() ?? 'S', style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 15),
          Text(student['name'] ?? 'Mentee', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(student['email'] ?? 'Registered Student', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
          const Divider(height: 25),
          ...content,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6A11CB)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(val ?? 'Not Provided', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailBlock(String label, String? text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 5),
        Text(text ?? 'N/A', style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
      ],
    );
  }

  Widget _socialBtn(IconData icon, String label, String? url) {
    bool hasUrl = url != null && url.isNotEmpty && url != 'null';
    return InkWell(
      onTap: () => _launchURL(url),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: hasUrl ? const Color(0xFF6A11CB).withOpacity(0.1) : Colors.grey[50],
            child: Icon(icon, color: hasUrl ? const Color(0xFF6A11CB) : Colors.grey[300], size: 20),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 10, color: hasUrl ? Colors.black87 : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}