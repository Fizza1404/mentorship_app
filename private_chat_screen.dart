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
import '../../services/meeting_service.dart';
import '../../services/notification_service.dart';

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  _PrivateChatScreenState createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;

  String _getChatId(String u1, String u2) {
    List<String> ids = [u1, u2];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage({String type = 'text', String? url, String? fileName}) async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    String msgText = _messageController.text.trim();
    if (type == 'text' && msgText.isEmpty) return;

    if (type == 'text') _messageController.clear();

    String chatId = _getChatId(auth.user!.uid, widget.otherUserId);

    try {
      await _firestore.collection('private_chats').doc(chatId).collection('messages').add({
        'senderId': auth.user!.uid,
        'senderName': auth.userName,
        'message': type == 'text' ? msgText : 'Attachment 📎',
        'type': type,
        'fileUrl': url,
        'fileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats_summary').doc(chatId).set({
        'lastMessage': type == 'text' ? msgText : 'Attachment 📎',
        'lastTime': FieldValue.serverTimestamp(),
        'users': [auth.user!.uid, widget.otherUserId],
        'userName_${widget.otherUserId}': widget.otherUserName,
        'userName_${auth.user!.uid}': auth.userName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("CHAT SEND ERROR: $e");
    }
  }

  Future<void> _pickAndUpload(bool isImage) async {
    String? url;
    String? name;
    setState(() => _isUploading = true);
    try {
      if (isImage) {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
        if (picked != null) {
          url = await ApiService.uploadFileToDomain(await File(picked.path).readAsBytes(), picked.name);
          name = picked.name;
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          url = await ApiService.uploadFileToDomain(await File(result.files.single.path!).readAsBytes(), result.files.single.name);
          name = result.files.single.name;
        }
      }
      if (url != null && url.isNotEmpty) {
        _sendMessage(type: isImage ? 'image' : 'file', url: url, fileName: name);
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

  void _startCall() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    String room = "private_${auth.user!.uid}_${widget.otherUserId}";
    await ApiService.updateLiveStatus(auth.user!.uid, true, room);
    NotificationService.sendNotification(toTopic: widget.otherUserId, title: "Incoming Video Call 📞", body: "${auth.userName} is calling you.");
    MeetingService.startMeeting(roomName: room, userName: auth.userName ?? "User", userEmail: auth.user?.email ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);
    String chatId = _getChatId(auth.user!.uid, widget.otherUserId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        actions: [IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: _startCall), const SizedBox(width: 10)],
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: Colors.orange),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('private_chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Check connection.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == auth.user?.uid;
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
          _inputArea(),
        ],
      ),
    );
  }

  Widget _dateChip(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _messageBubble(Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';
    DateTime? time = (data['timestamp'] as Timestamp?)?.toDate();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]) : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
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
    );
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.blueGrey), onPressed: () => _pickAndUpload(false)),
          IconButton(icon: const Icon(Icons.camera_alt_rounded, color: Colors.blueGrey), onPressed: () => _pickAndUpload(true)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
              child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none)),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFF6A11CB)), onPressed: () => _sendMessage()),
        ],
      ),
    );
  }
}