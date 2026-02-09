import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'courses_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<dynamic> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getCourseModules(widget.course.id);
      if (mounted) {
        setState(() {
          _modules = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddModuleSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final videoController = TextEditingController();
    String? fileUrl;
    bool isUploading = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Module', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Publish a chapter or topic for students', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 25),
              _simpleInput(titleController, 'Module Title'),
              const SizedBox(height: 15),
              _simpleInput(descController, 'Description', maxLines: 2),
              const SizedBox(height: 15),
              _simpleInput(videoController, 'Video URL (Optional)'),
              const SizedBox(height: 20),
              
              if (isUploading) const LinearProgressIndicator()
              else ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? res = await FilePicker.platform.pickFiles();
                  if (res != null) {
                    setModalState(() => isUploading = true);
                    String url = await ApiService.uploadFileToDomain(await File(res.files.single.path!).readAsBytes(), res.files.single.name);
                    setModalState(() { fileUrl = url; isUploading = false; });
                  }
                },
                icon: const Icon(Icons.upload_file), label: Text(fileUrl != null ? "File Attached ✅" : "Attach PDF/Notes"),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  await ApiService.addModule({
                    'course_id': widget.course.id,
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'video_url': videoController.text.trim(),
                    'file_url': fileUrl,
                  });
                  Navigator.pop(context);
                  _fetchModules();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 55)),
                child: const Text('PUBLISH MODULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<MyAuthProvider>(context).userRole?.toLowerCase() ?? 'student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        title: Text(widget.course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
              : _modules.isEmpty 
                ? _emptyView('No curriculum published yet.', Icons.auto_stories_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _modules.length,
                    itemBuilder: (context, index) => _buildModuleCard(_modules[index], index),
                  ),
          ),
        ],
      ),
      floatingActionButton: userRole == 'mentor' ? FloatingActionButton.extended(
        onPressed: _showAddModuleSheet,
        backgroundColor: const Color(0xFF6A11CB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD MODULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COURSE CURRICULUM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(widget.course.description, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> mod, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold))),
        title: Text(mod['title'] ?? 'Module', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mod['description'] != null) Text(mod['description'], style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    if (mod['video_url'] != null && mod['video_url'].toString().isNotEmpty)
                      _actionChip(Icons.play_circle_fill, 'Video', Colors.red, () => launchUrl(Uri.parse(mod['video_url']), mode: LaunchMode.externalApplication)),
                    const SizedBox(width: 10),
                    if (mod['file_url'] != null && mod['file_url'].toString().isNotEmpty)
                      _actionChip(Icons.file_present, 'Handout', Colors.blue, () => launchUrl(Uri.parse(mod['file_url']), mode: LaunchMode.externalApplication)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 5), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _simpleInput(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl, maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
    );
  }

  Widget _emptyView(String msg, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 60, color: Colors.grey[200]), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: Colors.grey))]));
  }
}