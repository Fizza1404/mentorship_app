import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String? mentorId;
  final String? mentorName;

  const GroupChatScreen({super.key, this.mentorId, this.mentorName});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  String _activeMentorId = '';
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  Future<void> _setupChat() async {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final userRole = authProvider.userRole?.toLowerCase() ?? 'student';
    final userId = authProvider.user?.uid ?? '';

    if (userRole == 'mentor') {
      setState(() { _activeMentorId = userId; _isReady = true; });
    } else {
      if (widget.mentorId != null) {
        setState(() { _activeMentorId = widget.mentorId!; _isReady = true; });
      } else {
        final status = await ApiService.getMentorshipStatus(userId);
        if (status['status'] == 'accepted' || status['status'] == 'Accepted') {
          setState(() { _activeMentorId = status['mentor_id'].toString(); _isReady = true; });
        } else {
          setState(() { _isReady = true; });
        }
      }
    }
  }

  Future<void> _sendMessage(String userId, String userName, {String type = 'text', String? url, String? fileName}) async {
    if (type == 'text' && _messageController.text.trim().isEmpty) return;
    if (_activeMentorId.isEmpty) return;

    final msg = type == 'text' ? _messageController.text.trim() : 'Attachment 📎';
    if (type == 'text') _messageController.clear();

    try {
      await _firestore.collection('group_chats').add({
        'mentorId': _activeMentorId.trim(),
        'userId': userId,
        'userName': userName,
        'message': msg,
        'type': type,
        'fileUrl': url,
        'fileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("CHAT ERROR: $e");
    }
  }

  Future<void> _pickAndUpload(String userId, String userName, bool isImage) async {
    setState(() => _isUploading = true);
    try {
      String? url;
      String? name;
      if (isImage) {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
        if (picked != null) {
          url = await ApiService.uploadFileToDomain(await File(picked.path).readAsBytes(), picked.name);
          name = picked.name;
        }
      } else {
        FilePickerResult? res = await FilePicker.platform.pickFiles();
        if (res != null) {
          url = await ApiService.uploadFileToDomain(await File(res.files.single.path!).readAsBytes(), res.files.single.name);
          name = res.files.single.name;
        }
      }
      if (url != null && url.isNotEmpty) {
        _sendMessage(userId, userName, type: isImage ? 'image' : 'file', url: url, fileName: name);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return "Today";
    if (date.day == now.subtract(const Duration(days: 1)).day) return "Yesterday";
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);
    if (!_isReady) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_activeMentorId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Chat'), flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])))),
        body: const Center(child: Text('Only enrolled students can access this chat.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: Text(widget.mentorName != null ? '${widget.mentorName}\'s Group' : 'Official Class Group'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: Colors.orange),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('group_chats')
                  .where('mentorId', isEqualTo: _activeMentorId.trim())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Please check internet or Firebase Index.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                // Manual Sorting to avoid Index error
                docs.sort((a, b) {
                  Timestamp? t1 = a['timestamp'] as Timestamp?;
                  Timestamp? t2 = b['timestamp'] as Timestamp?;
                  if (t1 == null || t2 == null) return 0;
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['userId'] == auth.user?.uid;
                    DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
                    
                    bool showDate = false;
                    if (date != null) {
                      if (index == docs.length - 1) showDate = true;
                      else {
                        DateTime? nextDate = (docs[index + 1]['timestamp'] as Timestamp?)?.toDate();
                        if (nextDate != null && date.day != nextDate.day) showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate && date != null) _dateChip(_formatDate(date)),
                        _messageBubble(data, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _inputArea(auth.user!.uid, auth.userName ?? 'User'),
        ],
      ),
    );
  }

  Widget _dateChip(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _messageBubble(Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';
    DateTime? time = (data['timestamp'] as Timestamp?)?.toDate();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) Text(data['userName'] ?? 'Peer', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          Container(
            margin: const EdgeInsets.only(bottom: 10, top: 2),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF6A11CB) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 15),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (type == 'text') 
                  Text(data['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14))
                else if (type == 'image') 
                  InkWell(onTap: () => launchUrl(Uri.parse(data['fileUrl'])), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(data['fileUrl'])))
                else 
                  InkWell(onTap: () => launchUrl(Uri.parse(data['fileUrl'])), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.description, size: 16), const SizedBox(width: 8), Flexible(child: Text(data['fileName'] ?? 'File', style: TextStyle(color: isMe ? Colors.white : Colors.blue, decoration: TextDecoration.underline, fontSize: 12)))])) ,
                const SizedBox(height: 4),
                if (time != null) Text(DateFormat('hh:mm a').format(time), style: TextStyle(fontSize: 8, color: isMe ? Colors.white70 : Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputArea(String uid, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.blueGrey), onPressed: () => _pickAndUpload(uid, name, false)),
          IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.blueGrey), onPressed: () => _pickAndUpload(uid, name, true)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
              child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none)),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFF6A11CB)), onPressed: () => _sendMessage(uid, name)),
        ],
      ),
    );
  }
}