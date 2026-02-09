import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, size: 70, color: Color(0xFF6A11CB)),
                      const SizedBox(height: 15),
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Sign in to your Account',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 35),
                      
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6A11CB)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(18),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 15),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6A11CB)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(18),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      
                      const SizedBox(height: 30),
                      authProvider.isLoading
                          ? const CircularProgressIndicator(color: Color(0xFF6A11CB))
                          : ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    await authProvider.login(_emailController.text.trim(), _passwordController.text);
                                    if (!mounted) return;
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A11CB),
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                              ),
                              child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            ),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("New here? ", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen())),
                            child: const Text('Create Account', style: TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}