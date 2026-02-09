import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  // Common Controllers
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _portfolioController;

  // Student Specific
  late TextEditingController _educationController;
  late TextEditingController _interestController;

  // Mentor Specific
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    _linkedinController = TextEditingController();
    _githubController = TextEditingController();
    _portfolioController = TextEditingController();
    _educationController = TextEditingController();
    _interestController = TextEditingController();
    _bioController = TextEditingController();
    _skillsController = TextEditingController();
    _experienceController = TextEditingController();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<MyAuthProvider>(context, listen: false);
      final data = await ApiService.getUserDetails(auth.user?.uid ?? '');
      if (data.isNotEmpty) {
        setState(() {
          _userData = data;
          _linkedinController.text = data['linkedin']?.toString() ?? '';
          _githubController.text = data['github']?.toString() ?? '';
          _portfolioController.text = data['portfolio']?.toString() ?? '';
          
          _educationController.text = data['education']?.toString() ?? '';
          _interestController.text = data['interest']?.toString() ?? '';
          
          _bioController.text = data['bio']?.toString() ?? '';
          _skillsController.text = data['skills']?.toString() ?? '';
          _experienceController.text = data['experience']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<MyAuthProvider>(context, listen: false);
      final role = auth.userRole?.toLowerCase() ?? 'student';

      Map<String, dynamic> updateData = {
        'uid': auth.user?.uid,
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'portfolio': _portfolioController.text.trim(),
      };

      if (role == 'student') {
        updateData['education'] = _educationController.text.trim();
        updateData['interest'] = _interestController.text.trim();
      } else {
        updateData['bio'] = _bioController.text.trim();
        updateData['skills'] = _skillsController.text.trim();
        updateData['experience'] = _experienceController.text.trim();
      }

      final result = await ApiService.updateUserProfile(updateData);

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving profile.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<MyAuthProvider>(context);
    final role = auth.userRole?.toLowerCase() ?? 'student';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              _buildAppBar(auth.userName ?? 'User'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (role == 'student') _buildStudentFields(),
                        if (role == 'mentor') _buildMentorFields(),
                        
                        const SizedBox(height: 30),
                        _buildSectionHeader('Portfolio & Links'),
                        _buildCard([
                          _buildInputLabel('LinkedIn URL'),
                          _buildTextField(_linkedinController, 'https://linkedin.com/in/...', Icons.link),
                          const SizedBox(height: 15),
                          _buildInputLabel('GitHub Profile'),
                          _buildTextField(_githubController, 'https://github.com/...', Icons.code),
                          const SizedBox(height: 15),
                          _buildInputLabel('Other Portfolio'),
                          _buildTextField(_portfolioController, 'https://...', Icons.language),
                        ]),
                        
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 8,
                          ),
                          child: const Text('SAVE PROFILE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
    );
  }

  Widget _buildStudentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Academic Details'),
        _buildCard([
          _buildInputLabel('Current Qualification'),
          _buildTextField(_educationController, 'e.g. BS Software Engineering', Icons.school_outlined),
          const SizedBox(height: 20),
          _buildInputLabel('Learning Goals / Interests'),
          _buildTextField(_interestController, 'e.g. Flutter, AI, Web', Icons.lightbulb_outline, maxLines: 2),
        ]),
      ],
    );
  }

  Widget _buildMentorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Professional Profile'),
        _buildCard([
          _buildInputLabel('About You (Bio)'),
          _buildTextField(_bioController, 'Describe your expertise...', Icons.person_outline, maxLines: 3),
          const SizedBox(height: 20),
          _buildInputLabel('Technical Skills'),
          _buildTextField(_skillsController, 'e.g. Java, Python, Flutter', Icons.psychology_outlined),
          const SizedBox(height: 20),
          _buildInputLabel('Total Experience'),
          _buildTextField(_experienceController, 'e.g. 5 Years in Industry', Icons.history_edu),
        ]),
      ],
    );
  }

  Widget _buildAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF6A11CB),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white24,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(_userData?['email'] ?? 'Member', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.5)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF6A11CB), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.all(15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}