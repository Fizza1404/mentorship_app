import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Authentication
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore Operations
  static Future<void> addUser(Map<String, dynamic> userData) async {
    if (userData['uid'] != null) {
      await _firestore
          .collection('users')
          .doc(userData['uid'])
          .set(userData);
    }
  }

  static Stream<QuerySnapshot> getGroupChats() {
    return _firestore
        .collection('group_chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(Map<String, dynamic> message) async {
    await _firestore.collection('group_chats').add(message);
  }

  // Tasks Operations
  static Future<void> addTask(Map<String, dynamic> taskData) async {
    await _firestore.collection('tasks').add(taskData);
  }

  static Stream<QuerySnapshot> getTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Storage Operations
  static Future<String> uploadFile(File file, String fileName) async {
    try {
      final ref = _storage.ref().child('files/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      return '';
    }
  }

  // Get User Data
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }
}