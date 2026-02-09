import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ResourceLibraryScreen extends StatefulWidget {
  final Map<String, dynamic>? mentor;
  const ResourceLibraryScreen({super.key, this.mentor});

  @override
  State<ResourceLibraryScreen> createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  List<dynamic> _resources = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'PDF', 'Video', 'Link', 'Notes'];

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

  Future<void> _fetchResources() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final mentorId = widget.mentor != null ? widget.mentor!['uid'] : auth.user?.uid;
    
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ApiService.getResources(mentorId);
      if (mounted) setState(() { _resources = data; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  void _showAddResourceDialog() {
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    String category = 'PDF';
    String? fileUrl;
    bool isUploading = false;
    bool isLinkMode = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share New Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: InputDecoration(hintText: 'Resource Title (e.g. Flutter Video)', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: category, items: _filters.where((f) => f != 'All').map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                setModalState(() { 
                  category = v!;
                  isLinkMode = (category == 'Link' || category == 'Video');
                });
              },
              decoration: InputDecoration(labelText: 'Category', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),
            
            if (isLinkMode)
              TextField(controller: linkController, decoration: InputDecoration(hintText: 'Paste Video URL or Link here...', prefixIcon: const Icon(Icons.link), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))
            else if (isUploading) 
              const Center(child: CircularProgressIndicator()) 
            else 
              ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    setModalState(() => isUploading = true);
                    String url = await ApiService.uploadFileToDomain(await File(result.files.single.path!).readAsBytes(), result.files.single.name);
                    setModalState(() { fileUrl = url; isUploading = false; });
                  }
                }, 
                icon: const Icon(Icons.cloud_upload_outlined), label: Text(fileUrl != null ? "File Ready ✅" : "Upload File (PDF/Docs)"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: (fileUrl == null && linkController.text.isEmpty) ? null : () async {
                final auth = Provider.of<MyAuthProvider>(context, listen: false);
                await ApiService.addResource({
                  'mentor_id': auth.user?.uid, 
                  'title': titleController.text.trim(), 
                  'category': category, 
                  'file_url': isLinkMode ? linkController.text.trim() : fileUrl
                });
                Navigator.pop(context); _fetchResources();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('PUBLISH NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMentor = widget.mentor == null;
    final title = isMentor ? "Resource Repository" : "${widget.mentor!['name']}'s Resources";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB))) 
              : _resources.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _resources.length,
                    itemBuilder: (context, index) => _buildResourceCard(_resources[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: isMentor ? FloatingActionButton.extended(
        onPressed: _showAddResourceDialog, 
        backgroundColor: const Color(0xFF6A11CB), label: const Text('ADD CONTENT'),
        icon: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
              selected: isSelected, onSelected: (val) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white, selectedColor: const Color(0xFF6A11CB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), showCheckmark: false, elevation: 1,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> res) {
    if (_selectedFilter != 'All' && res['category'] != _selectedFilter) return const SizedBox.shrink();

    IconData icon;
    Color iconColor;
    switch (res['category']) {
      case 'Video': icon = Icons.play_circle_fill_rounded; iconColor = Colors.redAccent; break;
      case 'Link': icon = Icons.link_rounded; iconColor = Colors.blue; break;
      case 'PDF': icon = Icons.picture_as_pdf_rounded; iconColor = Colors.orange; break;
      default: icon = Icons.description_rounded; iconColor = Colors.teal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
        title: Text(res['title'] ?? 'Educational Content', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Format: ${res['category']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: Container(decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.arrow_forward_rounded, size: 18), onPressed: () => launchUrl(Uri.parse(res['file_url']), mode: LaunchMode.externalApplication))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('Resource Library is empty.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}