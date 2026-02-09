import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final String? initialCourseId; 
  final String? targetStudentId;

  const AddTaskScreen({super.key, this.initialCourseId, this.targetStudentId});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _marksController = TextEditingController(text: '100');
  
  List<dynamic> _myCourses = [];
  String? _selectedCourseId;
  
  List<dynamic> _enrolledStudents = [];
  List<String> _selectedStudentIds = [];
  
  bool _isLoading = false;
  bool _isFetchingInitial = true;
  
  String? _uploadedFileUrl;
  String? _uploadedFileName;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final mentorId = auth.user?.uid ?? '';
    
    try {
      final courses = await ApiService.getCourses(mentorId: mentorId);
      final students = await ApiService.getMyStudents(mentorId);
      
      if (mounted) {
        setState(() {
          _myCourses = courses;
          _enrolledStudents = students;
          
          // Selection Logic: If opened from Student Personal Screen
          if (widget.targetStudentId != null) {
            _selectedStudentIds = [widget.targetStudentId!.toString()];
          }

          if (widget.initialCourseId != null && widget.initialCourseId != '0') {
            _selectedCourseId = widget.initialCourseId;
          } else if (_myCourses.isNotEmpty) {
            _selectedCourseId = _myCourses.first['id'].toString();
          }
          
          _isFetchingInitial = false;
        });
      }
    } catch (e) { if (mounted) setState(() => _isFetchingInitial = false); }
  }

  Future<void> _pickReferenceFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _isUploadingFile = true);
      try {
        File file = File(result.files.single.path!);
        String url = await ApiService.uploadFileToDomain(await file.readAsBytes(), result.files.single.name);
        if (mounted) {
          setState(() {
            _uploadedFileUrl = url;
            _uploadedFileName = result.files.single.name;
          });
        }
      } catch (e) {} finally {
        if (mounted) setState(() => _isUploadingFile = false);
      }
    }
  }

  void _submitTask() async {
    if (_selectedCourseId == null || _titleController.text.trim().isEmpty || _selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Program, Title and at least one Student!')));
      return;
    }
    
    setState(() => _isLoading = true);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    try {
      final res = await ApiService.addTask({
        'course_id': _selectedCourseId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'total_marks': _marksController.text.trim(),
        'file_url': _uploadedFileUrl ?? '',
        'assigned_student_ids': _selectedStudentIds.join(','), // CSV format for database
      });

      if (mounted && res['status'] == 'success') {
        for (var sId in _selectedStudentIds) {
          NotificationService.sendNotification(
            toTopic: sId, 
            title: "New Assignment 📘", 
            body: "Mentor ${auth.userName} has assigned you a new task: ${_titleController.text.trim()}"
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    bool isIndividual = widget.targetStudentId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(isIndividual ? 'Assign Private Task' : 'Assign Group Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isFetchingInitial 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Target Program'),
                _buildCourseDropdown(),
                const SizedBox(height: 25),

                _label('Assignment Details'),
                Row(children: [
                  Expanded(flex: 4, child: _input(_titleController, 'Task Title', Icons.assignment_outlined)),
                  const SizedBox(width: 15),
                  Expanded(flex: 2, child: _input(_marksController, 'Marks', Icons.grade, isNum: true)),
                ]),
                const SizedBox(height: 15),
                _input(_descController, 'Briefly describe the task...', Icons.notes, maxLines: 4),
                
                const SizedBox(height: 25),
                _label('Reference Material'),
                _isUploadingFile ? const LinearProgressIndicator() : _buildFileTile(),

                const SizedBox(height: 30),
                _label('Assigned To'),
                isIndividual 
                  ? Container(
                      padding: const EdgeInsets.all(15), width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green[100]!)),
                      child: Row(children: [
                        const Icon(Icons.person_pin_rounded, color: Colors.green),
                        const SizedBox(width: 15),
                        Text(_enrolledStudents.firstWhere((s) => s['uid'].toString() == widget.targetStudentId.toString(), orElse: () => {'name': 'Student'})['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ]),
                    )
                  : _buildStudentList(),
                
                const SizedBox(height: 40),
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitTask,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text('PUBLISH TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 5), child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)));

  Widget _buildCourseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, value: _selectedCourseId, hint: const Text('Select Program'),
          items: _myCourses.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title'] ?? 'N/A'))).toList(),
          onChanged: (val) => setState(() => _selectedCourseId = val),
        ),
      ),
    );
  }

  Widget _buildFileTile() {
    return ListTile(
      onTap: _pickReferenceFile,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
      leading: Icon(Icons.cloud_upload, color: _uploadedFileName != null ? Colors.green : Colors.blueGrey),
      title: Text(_uploadedFileName ?? 'Upload Reference (PDF/Img)', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
    );
  }

  Widget _buildStudentList() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Column(children: _enrolledStudents.map((s) => CheckboxListTile(
        title: Text(s['name'] ?? 'Mentee', style: const TextStyle(fontSize: 14)),
        value: _selectedStudentIds.contains(s['uid'].toString()),
        activeColor: const Color(0xFF6A11CB),
        onChanged: (v) => setState(() => v! ? _selectedStudentIds.add(s['uid'].toString()) : _selectedStudentIds.remove(s['uid'].toString())),
      )).toList()),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, bool isNum = false}) {
    return TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: const Color(0xFF6A11CB), size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), filled: true, fillColor: Colors.white),
    );
  }
}