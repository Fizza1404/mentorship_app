import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class MyAuthProvider with ChangeNotifier {
  User? _user;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  String? _skills;
  String? _experience;
  String? _bio;
  String? _portfolio;
  String? _linkedin;
  String? _github;
  bool _isLoading = false;

  User? get user => _user;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  MyAuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('name');
    _userEmail = prefs.getString('email');
    _userRole = prefs.getString('role');
    _skills = prefs.getString('skills');
    _experience = prefs.getString('experience');
    _bio = prefs.getString('bio');
    _portfolio = prefs.getString('portfolio');
    _linkedin = prefs.getString('linkedin');
    _github = prefs.getString('github');
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  Future<void> login(String email, String password, {String? uid}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;

      final apiResponse = await ApiService.loginUser(email, password, uid: _user!.uid);
      
      if (apiResponse['status'] == 'error') {
         throw Exception(apiResponse['message'] ?? 'Login failed');
      }

      final userData = apiResponse['user'];
      _userName = userData['name']?.toString() ?? 'User';
      _userRole = userData['role']?.toString() ?? 'student';
      _skills = userData['skills']?.toString();
      _experience = userData['experience']?.toString();
      _userEmail = email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', _user!.uid);
      await prefs.setString('email', email);
      await prefs.setString('name', _userName!);
      await prefs.setString('role', _userRole!);
      if (_skills != null) await prefs.setString('skills', _skills!);
      if (_experience != null) await prefs.setString('experience', _experience!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    String? skills,
    String? experience,
    String? bio,
    String? portfolio,
    String? linkedin,
    String? github,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String firebaseUid = credential.user!.uid;

      final apiResponse = await ApiService.registerUser({
        'uid': firebaseUid,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'skills': skills ?? '',
        'experience': experience ?? '',
        'bio': bio ?? '',
        'portfolio': portfolio ?? '',
        'linkedin': linkedin ?? '',
        'github': github ?? '',
      });

      if (apiResponse['status'] == 'error') {
        await credential.user!.delete();
        throw Exception(apiResponse['message'] ?? 'Signup failed');
      }

      await credential.user!.updateDisplayName(name);
      await FirebaseService.addUser({
        'uid': firebaseUid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'skills': skills ?? '',
        'experience': experience ?? '',
        'bio': bio ?? '',
        'portfolio': portfolio ?? '',
        'linkedin': linkedin ?? '',
        'github': github ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await FirebaseAuth.instance.signOut();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _user = null;
      _userName = null;
      _userEmail = null;
      _userRole = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}