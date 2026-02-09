import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'private_chat_screen.dart';

class PrivateChatListScreen extends StatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  State<PrivateChatListScreen> createState() => _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends State<PrivateChatListScreen> {
  List<dynamic> _myStudents = [];
  bool _isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    _fetchMentees();
  }

  Future<void> _fetchMentees() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    if (auth.userRole?.toLowerCase() == 'mentor') {
      try {
        final data = await ApiService.getMyStudents(auth.user!.uid);
        if (mounted) setState(() { _myStudents = data; _isLoadingStudents = false; });
      } catch (e) { if (mounted) setState(() => _isLoadingStudents = false); }
    } else {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);
    final isMentor = auth.userRole?.toLowerCase() == 'mentor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Direct Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: isMentor ? _buildMentorChatList(auth.user!.uid) : _buildStudentChatList(auth.user!.uid),
    );
  }

  // MENTOR VIEW: Show all his students
  Widget _buildMentorChatList(String mentorId) {
    if (_isLoadingStudents) return const Center(child: CircularProgressIndicator());
    if (_myStudents.isEmpty) return const Center(child: Text('No students enrolled yet.'));

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _myStudents.length,
      itemBuilder: (context, index) {
        final student = _myStudents[index];
        return _buildChatTile(
          name: student['name'] ?? 'Student',
          otherId: student['uid'],
          subtitle: 'Active mentee',
        );
      },
    );
  }

  // STUDENT VIEW: Show his accepted mentors or existing chats
  Widget _buildStudentChatList(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('private_chats').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.where((doc) => doc.id.contains(studentId)).toList();

        if (docs.isEmpty) return const Center(child: Text('No active chats. Start one from mentor portal!'));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chatId = docs[index].id;
            final otherId = chatId.split('_').firstWhere((id) => id != studentId);
            return _buildChatTile(name: 'My Mentor', otherId: otherId, subtitle: 'Tap to chat');
          },
        );
      },
    );
  }

  Widget _buildChatTile({required String name, required String otherId, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF6A11CB), size: 20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PrivateChatScreen(
            otherUserId: otherId,
            otherUserName: name,
          )));
        },
      ),
    );
  }
}