import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class MentorWallScreen extends StatefulWidget {
  final Map<String, dynamic>? mentor; 
  const MentorWallScreen({super.key, this.mentor});

  @override
  _MentorWallScreenState createState() => _MentorWallScreenState();
}

class _MentorWallScreenState extends State<MentorWallScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  final TextEditingController _postController = TextEditingController();
  String? _uploadedFileUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final mentorId = widget.mentor != null ? widget.mentor!['uid'] : auth.user?.uid;
    
    if (mentorId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMentorPosts(mentorId);
      if (mounted) {
        setState(() {
          _posts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _isUploading = true);
      try {
        File file = File(result.files.single.path!);
        String url = await ApiService.uploadFileToDomain(await file.readAsBytes(), result.files.single.name);
        setState(() => _uploadedFileUrl = url);
      } catch (e) {} finally { setState(() => _isUploading = false); }
    }
  }

  void _createPost() async {
    if (_postController.text.trim().isEmpty) return;
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    
    final res = await ApiService.addMentorPost({
      'mentor_id': auth.user?.uid,
      'mentor_name': auth.userName,
      'content': _postController.text.trim(),
      'file_url': _uploadedFileUrl ?? '',
    });

    if (res['status'] == 'success') {
      _postController.clear();
      _uploadedFileUrl = null;
      _fetchPosts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update Shared!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMentor = widget.mentor == null;
    final title = isMentor ? "My Wall" : "${widget.mentor!['name']}'s Feed";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _fetchPosts),
        ],
      ),
      body: Column(
        children: [
          if (isMentor) _buildCreatePostArea(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB))) 
              : _posts.isEmpty 
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchPosts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) => _buildPostCard(_posts[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          TextField(
            controller: _postController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Share a thought, link or resource...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              filled: true, fillColor: const Color(0xFFF0F2F5),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _pickFile, 
                icon: Icon(Icons.attach_file_rounded, color: Colors.indigo[700]), 
                label: Text(_uploadedFileUrl != null ? "Ready ✅" : "Attach File", style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.bold))
              ),
              ElevatedButton(
                onPressed: _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB), 
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('SHARE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_isUploading) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    String dateStr = "Recent";
    try {
      dateStr = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(post['created_at']));
    } catch (e) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1), child: Text(post['mentor_name']?[0] ?? 'M', style: const TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['mentor_name'] ?? 'Mentor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 15),
          Text(post['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
          if (post['file_url'] != null && post['file_url'].toString().isNotEmpty && post['file_url'] != 'null') ...[
            const SizedBox(height: 15),
            InkWell(
              onTap: () => launchUrl(Uri.parse(post['file_url']), mode: LaunchMode.externalApplication),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue[100]!)),
                child: Row(children: [const Icon(Icons.file_present_rounded, size: 20, color: Colors.blue), const SizedBox(width: 10), Expanded(child: Text(post['file_url'].split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)))]),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('No insights shared yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}