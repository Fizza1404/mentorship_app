import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://learncode.easycode4u.com/api';

  static dynamic _handleResponse(http.Response response) {
    try {
      if (response.body.isEmpty) return {'status': 'error', 'message': 'Empty response'};
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Invalid response format'};
    }
  }

  // --- Auth & User ---
  static Future<Map<String, dynamic>> loginUser(String email, String password, {String? uid}) async {
    final body = {'email': email, 'password': password};
    if (uid != null) body['uid'] = uid;
    final response = await http.post(Uri.parse('$baseUrl/login.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/register.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUserDetails(String uid) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_user_details&uid=$uid'));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    data['action'] = 'update_profile';
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  // --- Mentorship & Student Management ---
  static Future<List<dynamic>> getAllMentors({String? studentId}) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_mentors&student_id=$studentId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getMyStudents(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_my_students&mentor_id=$mentorId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getMyMentors(String studentId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_my_mentors&student_id=$studentId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getStudentApplications(String studentId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_student_applications&student_id=$studentId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getMentorRequests(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_requests&mentor_id=$mentorId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> applyToMentor(Map<String, dynamic> data) async {
    data['action'] = 'apply';
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMentorshipStatus(String studentId) async {
    final apps = await getStudentApplications(studentId);
    if (apps.isEmpty) return {'status': 'none'};
    for (var app in apps) {
      if (app['status'] == 'accepted') return app;
    }
    return apps.isNotEmpty ? apps.first : {'status': 'none'};
  }

  static Future<Map<String, dynamic>> updateRequestStatus(String requestId, String status) async {
    final body = {'action': 'update_status', 'request_id': requestId, 'status': status};
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(body));
    return _handleResponse(response);
  }

  // --- Courses & Modules ---
  static Future<List<dynamic>> getCourses({String? mentorId}) async {
    String url = '$baseUrl/courses.php?action=get_courses';
    if (mentorId != null) url += '&mentor_id=$mentorId';
    final response = await http.get(Uri.parse(url));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> addCourse(Map<String, dynamic> data) async {
    data['action'] = 'add_course';
    final response = await http.post(Uri.parse('$baseUrl/courses.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getCourseModules(String courseId) async {
    final response = await http.get(Uri.parse('$baseUrl/courses.php?action=get_modules&course_id=$courseId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> addModule(Map<String, dynamic> data) async {
    data['action'] = 'add_module';
    final response = await http.post(Uri.parse('$baseUrl/courses.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  // --- Tasks & Submissions ---
  static Future<Map<String, dynamic>> addTask(Map<String, dynamic> data) async {
    data['action'] = 'add_task';
    final response = await http.post(Uri.parse('$baseUrl/tasks.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitTask(Map<String, dynamic> data) async {
    data['action'] = 'submit_task';
    final response = await http.post(Uri.parse('$baseUrl/tasks.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getTasks(String courseId, {String? studentId, required String role}) async {
    final response = await http.get(Uri.parse('$baseUrl/tasks.php?action=get_tasks&course_id=$courseId&student_id=$studentId&role=$role'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> evaluateTask(String subId, String marks, String status, String feedback) async {
    final response = await http.post(Uri.parse('$baseUrl/tasks.php'), headers: {'Content-Type': 'application/json'}, body: json.encode({
      'action': 'evaluate_task',
      'submission_id': subId,
      'obtained_marks': marks,
      'status': status,
      'feedback': feedback
    }));
    return _handleResponse(response);
  }

  // --- Quiz System ---
  static Future<List<dynamic>> getQuizzes(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_quizzes&mentor_id=$mentorId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getQuizQuestions(String quizId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_questions&quiz_id=$quizId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> data) async {
    data['action'] = 'create_quiz';
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> saveQuizResult(Map<String, dynamic> data) async {
    data['action'] = 'save_quiz_result';
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getQuizHistory(String studentId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_quiz_history&student_id=$studentId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getAllQuizResults(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_all_quiz_results&mentor_id=$mentorId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  // --- External Content (Resources & Reviews) ---
  static Future<List<dynamic>> getResources(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_resources&mentor_id=$mentorId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> addResource(Map<String, dynamic> data) async {
    data['action'] = 'add_resource';
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getMentorReviews(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_reviews&mentor_id=$mentorId'));
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> addReview(Map<String, dynamic> data) async {
    data['action'] = 'add_review';
    final response = await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    return _handleResponse(response);
  }

  // --- Extras & Tools ---
  static Future<Map<String, dynamic>> getLiveStatus(String mentorId) async {
    final response = await http.get(Uri.parse('$baseUrl/m.php?action=get_live_status&uid=$mentorId'));
    return _handleResponse(response);
  }

  static Future<void> updateLiveStatus(String mentorId, bool isLive, String roomName, {String assignedIds = ""}) async {
    await http.post(Uri.parse('$baseUrl/m.php'), headers: {'Content-Type': 'application/json'}, body: json.encode({
      'action': 'update_live_status',
      'uid': mentorId,
      'is_live': isLive ? 1 : 0,
      'live_room': roomName,
      'assigned_student_ids': assignedIds
    }));
  }

  static Future<Map<String, dynamic>> issueCertificate(String mentorId, String studentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/m.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'action': 'issue_certificate', 'mentor_id': mentorId, 'student_id': studentId}),
    );
    return _handleResponse(response);
  }

  static Future<String> uploadFileToDomain(List<int> fileBytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload.php'));
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      return (data is Map && data.containsKey('fileUrl')) ? data['fileUrl'] : '';
    } catch (e) { return ''; }
  }
}