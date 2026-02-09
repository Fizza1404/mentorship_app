import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courseCodeController = TextEditingController();

  int _years = 0;
  int _months = 0;
  int _days = 0;
  bool _isLoading = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Computer Science', 
    'Information Technology', 
    'Software Engineering', 
    'Artificial Intelligence',
    'Data Science',
    'Cyber Security',
    'Business & Marketing', 
    'Digital Arts', 
    'Other'
  ];

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      if (_years == 0 && _months == 0 && _days == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please specify course duration')));
        return;
      }
      
      setState(() => _isLoading = true);
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

      String durationText = "";
      if (_years > 0) durationText += "$_years Y ";
      if (_months > 0) durationText += "$_months M ";
      if (_days > 0) durationText += "$_days D";

      try {
        final response = await ApiService.addCourse({
          'title': _titleController.text.trim(),
          'description': 'Mentorship Academic Program', 
          'course_code': _courseCodeController.text.trim().toUpperCase(),
          'category': _selectedCategory ?? 'Other',
          'mentor_id': authProvider.user?.uid ?? '',
          'mentor_name': authProvider.userName ?? 'Mentor',
          'duration_hours': durationText.trim(),
        });

        if (response['status'] == 'success') {
          if (mounted) Navigator.pop(context, true);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course Created Successfully!'), backgroundColor: Colors.green));
        } else {
          throw Exception('Failed');
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creating course'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('New Academic Program', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), 
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildStepHeader('PROGRAM SETUP', 'Define your mentorship course details below.'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Program Title'),
                      _buildTextField(_titleController, 'e.g. Full Stack Web Development', Icons.book_outlined),
                      
                      const SizedBox(height: 25),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Code'),
                                _buildTextField(_courseCodeController, 'WEB-101', Icons.tag),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Category'),
                                _buildCategoryDropdown(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      _fieldLabel('Program Duration'),
                      _buildDurationPicker(),
                      
                      const SizedBox(height: 45),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A11CB)))
                          : ElevatedButton(
                              onPressed: _addCourse,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A11CB), 
                                minimumSize: const Size(double.infinity, 55), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 2,
                              ),
                              child: const Text('CREATE PROGRAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(sub, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4), 
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1))
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6A11CB), size: 20),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedCategory,
      decoration: InputDecoration(
        isDense: true,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
      hint: const Text('Select...', style: TextStyle(fontSize: 13, color: Colors.grey)),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildDurationPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _durationCounter('YEARS', _years, (v) => setState(() => _years = v)),
          _durationCounter('MONTHS', _months, (v) => setState(() => _months = v)),
          _durationCounter('DAYS', _days, (v) => setState(() => _days = v)),
        ],
      ),
    );
  }

  Widget _durationCounter(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          children: [
            _btn(Icons.remove, () => value > 0 ? onChanged(value - 1) : null),
            Container(
              constraints: const BoxConstraints(minWidth: 30),
              alignment: Alignment.center,
              child: Text('$value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))
            ),
            _btn(Icons.add, () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: const Color(0xFF6A11CB).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: const Color(0xFF6A11CB)),
      ),
    );
  }
}