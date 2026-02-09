import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      // Assuming we have a getNotifications API or using a dummy for now
      // Replace with real API: final data = await ApiService.getStudentNotifications(auth.user!.uid);
      await Future.delayed(const Duration(seconds: 1)); // Dummy Delay
      final data = [
        {"title": "Assignment Evaluated", "body": "Your Flutter task has been marked as Completed.", "time": DateTime.now().subtract(const Duration(hours: 2)).toString()},
        {"title": "New Quiz Published", "body": "Mentor assigned a new Midterm Quiz for you.", "time": DateTime.now().subtract(const Duration(days: 1)).toString()},
      ];
      if (mounted) setState(() { _notifications = data; _isLoading = false; });
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Activity Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) => _buildNotifyCard(_notifications[index]),
            ),
    );
  }

  Widget _buildNotifyCard(Map<String, dynamic> note) {
    String time = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(note['time']));
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1), child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF6A11CB), size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 5),
                Text(note['body'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(time, style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text('No new alerts.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}