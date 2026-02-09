import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Mentor Specific Controllers
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  
  String _selectedRole = 'student';

  String? _validateURL(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('http')) return 'Enter valid URL (http/https)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Minimum 6 characters required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)]),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.school_rounded, size: 70, color: Color(0xFF6A11CB)),
                    const SizedBox(height: 10),
                    const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                    const SizedBox(height: 30),
                    
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(_emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 15),
                    _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true, validator: _validatePassword),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(labelText: 'Register As', prefixIcon: const Icon(Icons.category, color: Color(0xFF2575FC)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                      items: ['student', 'mentor'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),

                    // Professional Fields ONLY for Mentor Signup
                    if (_selectedRole == 'mentor') ...[
                      const SizedBox(height: 25),
                      const Text('Mentor Professional Info', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                      const Divider(),
                      _buildTextField(_skillsController, 'Expertise (e.g. Flutter, AI)', Icons.star_outline),
                      const SizedBox(height: 15),
                      _buildTextField(_experienceController, 'Experience Years', Icons.work_outline),
                      const SizedBox(height: 15),
                      _buildTextField(_bioController, 'Professional Bio', Icons.info_outline, maxLines: 3),
                      const SizedBox(height: 15),
                      _buildTextField(_linkedinController, 'LinkedIn URL', Icons.link, validator: _validateURL),
                      const SizedBox(height: 15),
                      _buildTextField(_githubController, 'GitHub URL', Icons.code, validator: _validateURL),
                      const SizedBox(height: 15),
                      _buildTextField(_portfolioController, 'Portfolio (Optional)', Icons.language, validator: _validateURL),
                    ],

                    const SizedBox(height: 35),
                    authProvider.isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF6A11CB))
                        : ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  await authProvider.signup(
                                    name: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                    role: _selectedRole,
                                    phone: _phoneController.text.trim(),
                                    // Professional data sent only if mentor
                                    skills: _selectedRole == 'mentor' ? _skillsController.text : '',
                                    experience: _selectedRole == 'mentor' ? _experienceController.text : '',
                                    bio: _selectedRole == 'mentor' ? _bioController.text : '',
                                    linkedin: _selectedRole == 'mentor' ? _linkedinController.text : '',
                                    github: _selectedRole == 'mentor' ? _githubController.text : '',
                                    portfolio: _selectedRole == 'mentor' ? _portfolioController.text : '',
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Created! Please Login.'), backgroundColor: Colors.green));
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            child: const Text('SIGN UP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                      },
                      child: const Text('Already have an account? Login', style: TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF2575FC)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
    );
  }
}