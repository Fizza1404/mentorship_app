<?php
header("Content-Type: application/json");
include 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

/* =========================
   GET REQUESTS
=========================*/
if ($method === 'GET') {
    $action = $_GET['action'] ?? '';

    /* 1. Mentors Discovery (Explore Mentors) */
    if ($action === 'get_mentors') {
        $sql = "SELECT * FROM users WHERE role = 'mentor'";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 2. Mentor's Mentees List (Accepted Students) - FIXED: Robust fetch from both tables */
    if ($action === 'get_my_students') {
        $m_id = $conn->real_escape_string($_GET['mentor_id'] ?? '');
        // Joined logic: Fetching all profile data (u.*) and all enrollment data (a.*)
        $sql = "SELECT u.*, a.* 
                FROM applications a 
                JOIN users u ON a.student_id = u.uid 
                WHERE TRIM(a.mentor_id) = TRIM('$m_id') 
                AND LOWER(a.status) = 'accepted'";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 3. Pending Requests for Mentor */
    if ($action === 'get_requests') {
        $m_id = $conn->real_escape_string($_GET['mentor_id'] ?? '');
        $sql = "SELECT a.*, u.name AS student_name, u.email AS student_email 
                FROM applications a 
                JOIN users u ON a.student_id = u.uid 
                WHERE TRIM(a.mentor_id) = TRIM('$m_id') AND LOWER(a.status) = 'pending' 
                ORDER BY a.id DESC";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 4. Student's Enrolled Mentors */
    if ($action === 'get_my_mentors') {
        $s_id = $conn->real_escape_string($_GET['student_id'] ?? '');
        $sql = "SELECT u.* FROM applications a 
                JOIN users u ON a.mentor_id = u.uid 
                WHERE TRIM(a.student_id) = TRIM('$s_id') AND LOWER(a.status) = 'accepted'";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 5. Resources Library */
    if ($action === 'get_resources') {
        $m_id = $conn->real_escape_string($_GET['mentor_id'] ?? '');
        $sql = "SELECT * FROM resources WHERE mentor_id = '$m_id' ORDER BY id DESC";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 6. Quiz Results for Mentor (Reports) */
    if ($action === 'get_all_quiz_results') {
        $m_id = $conn->real_escape_string($_GET['mentor_id'] ?? '');
        $sql = "SELECT r.*, q.title as quiz_title, u.name as student_name 
                FROM quiz_results r 
                JOIN quizzes q ON r.quiz_id = q.id 
                JOIN users u ON r.student_id = u.uid
                WHERE q.mentor_id = '$m_id' ORDER BY r.attempted_at DESC";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 7. Reviews */
    if ($action === 'get_reviews') {
        $m_id = $conn->real_escape_string($_GET['mentor_id'] ?? '');
        $sql = "SELECT * FROM reviews WHERE mentor_id = '$m_id' ORDER BY created_at DESC";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 8. User / Application Status Helpers */
    if ($action === 'get_user_details') {
        $uid = $conn->real_escape_string($_GET['uid'] ?? '');
        $sql = "SELECT * FROM users WHERE uid = '$uid'";
        $result = $conn->query($sql);
        echo json_encode($result ? ($result->fetch_assoc() ?? []) : []);
        exit;
    }

    if ($action === 'get_student_applications') {
        $s_id = $conn->real_escape_string($_GET['student_id'] ?? '');
        $sql = "SELECT * FROM applications WHERE student_id = '$s_id'";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* 9. Video Call Status */
    if ($action === 'get_live_status') {
        $uid = $conn->real_escape_string($_GET['uid'] ?? '');
        $sql = "SELECT is_live, live_room, live_assigned_students FROM users WHERE uid = '$uid'";
        $result = $conn->query($sql);
        echo json_encode($result ? ($result->fetch_assoc() ?? []) : []);
        exit;
    }

    /* 10. Quizzes & Questions */
    if ($action === 'get_quizzes') {
        $m_id = $conn->real_escape_string($_GET['mentor_id'] ?? '');
        $sql = "SELECT * FROM quizzes WHERE mentor_id = '$m_id' ORDER BY id DESC";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    if ($action === 'get_questions') {
        $q_id = $conn->real_escape_string($_GET['quiz_id'] ?? '');
        $sql = "SELECT * FROM quiz_questions WHERE quiz_id = '$q_id'";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }

    /* FIXED: Quiz History for Students */
    if ($action === 'get_quiz_history') {
        $s_id = $conn->real_escape_string($_GET['student_id'] ?? '');
        $sql = "SELECT r.*, q.title, q.course_name, q.mentor_id 
                FROM quiz_results r 
                JOIN quizzes q ON r.quiz_id = q.id 
                WHERE r.student_id = '$s_id' 
                ORDER BY r.attempted_at DESC";
        $result = $conn->query($sql);
        $res = [];
        if ($result) { while ($row = $result->fetch_assoc()) $res[] = $row; }
        echo json_encode($res);
        exit;
    }
}

/* =========================
   POST REQUESTS
=========================*/
if ($method === 'POST') {
    $d = json_decode(file_get_contents("php://input"), true);
    if (!$d) { echo json_encode(["status" => "error", "message" => "No data provided"]); exit; }
    $action = $d['action'] ?? '';

    if ($action === 'apply') {
        $s_id = $conn->real_escape_string($d['student_id']);
        $m_id = $conn->real_escape_string($d['mentor_id']);
        $conn->query("DELETE FROM applications WHERE student_id='$s_id' AND mentor_id='$m_id'");
        $sql = "INSERT INTO applications (student_id, mentor_id, education, interest, reason, linkedin, github, portfolio, status) 
                VALUES ('$s_id', '$m_id', '".$conn->real_escape_string($d['education'])."', '".$conn->real_escape_string($d['interest'])."', '".$conn->real_escape_string($d['reason'])."', '".$conn->real_escape_string($d['linkedin'])."', '".$conn->real_escape_string($d['github'])."', '".$conn->real_escape_string($d['portfolio'])."', 'pending')";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error", "message" => $conn->error]);
        exit;
    }

    if ($action === 'update_status') {
        $id = $conn->real_escape_string($d['request_id']);
        $status = $conn->real_escape_string($d['status']);
        $sql = "UPDATE applications SET status = '$status' WHERE id = '$id'";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error"]);
        exit;
    }

    if ($action === 'issue_certificate') {
        $m_id = $conn->real_escape_string($d['mentor_id']);
        $s_id = $conn->real_escape_string($d['student_id']);
        $sql = "UPDATE applications SET is_certified = 1 WHERE mentor_id = '$m_id' AND student_id = '$s_id' AND LOWER(status) = 'accepted'";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error"]);
        exit;
    }

    if ($action === 'create_quiz') {
        $m_id = $conn->real_escape_string($d['mentor_id']);
        $sql = "INSERT INTO quizzes (mentor_id, course_id, course_name, title, description, assigned_student_ids) 
                VALUES ('$m_id', '".$conn->real_escape_string($d['course_id'])."', '".$conn->real_escape_string($d['course_name'])."', '".$conn->real_escape_string($d['title'])."', 'Assessment', '".$conn->real_escape_string($d['assigned_student_ids'])."')";
        if ($conn->query($sql)) {
            $quiz_id = $conn->insert_id;
            foreach ($d['questions'] as $q) {
                $conn->query("INSERT INTO quiz_questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES ('$quiz_id', '".$conn->real_escape_string($q['text'])."', '".$conn->real_escape_string($q['a'])."', '".$conn->real_escape_string($q['b'])."', '".$conn->real_escape_string($q['c'])."', '".$conn->real_escape_string($q['d'])."', '".$conn->real_escape_string($q['correct'])."')");
            }
            echo json_encode(["status" => "success"]);
        } else { echo json_encode(["status" => "error", "message" => $conn->error]); }
        exit;
    }

    /* FIXED: Removed mentor_id from INSERT because column doesn't exist in DB table */
    if ($action === 'save_quiz_result') {
        $s_id = $conn->real_escape_string($d['student_id'] ?? '');
        $q_id = $conn->real_escape_string($d['quiz_id'] ?? '');
        $score = $conn->real_escape_string($d['score'] ?? '0');
        $total = $conn->real_escape_string($d['total'] ?? '0');

        if (empty($s_id) || empty($q_id)) {
            echo json_encode(["status" => "error", "message" => "Missing IDs"]);
            exit;
        }

        // Removed mentor_id from the column list and values list
        $sql = "INSERT INTO quiz_results (student_id, quiz_id, score, total_questions, attempted_at) 
                VALUES ('$s_id', '$q_id', '$score', '$total', NOW())";
        
        if ($conn->query($sql)) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'update_live_status') {
        $uid = $conn->real_escape_string($d['uid']);
        $room = $conn->real_escape_string($d['live_room'] ?? '');
        $assigned = $conn->real_escape_string($d['assigned_student_ids'] ?? ''); 
        $sql = "UPDATE users SET is_live = '".$d['is_live']."', live_room = '$room', live_assigned_students = '$assigned' WHERE uid = '$uid'";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error"]);
        exit;
    }

    if ($action === 'add_resource') {
        $sql = "INSERT INTO resources (mentor_id, title, category, file_url) 
                VALUES ('".$conn->real_escape_string($d['mentor_id'])."', '".$conn->real_escape_string($d['title'])."', '".$conn->real_escape_string($d['category'])."', '".$conn->real_escape_string($d['file_url'])."')";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error"]);
        exit;
    }

    if ($action === 'add_review') {
        $sql = "INSERT INTO reviews (mentor_id, student_id, student_name, rating, review_text) 
                VALUES ('".$conn->real_escape_string($d['mentor_id'])."', '".$conn->real_escape_string($d['student_id'])."', '".$conn->real_escape_string($d['student_name'])."', '".$conn->real_escape_string($d['rating'])."', '".$conn->real_escape_string($d['review_text'])."')";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error"]);
        exit;
    }
    
    if ($action === 'update_profile') {
        $uid = $conn->real_escape_string($d['uid']);
        $sql = "UPDATE users SET bio='".$conn->real_escape_string($d['bio'])."', skills='".$conn->real_escape_string($d['skills'])."', linkedin_url='".$conn->real_escape_string($d['linkedin_url'])."', github_url='".$conn->real_escape_string($d['github_url'])."', portfolio_url='".$conn->real_escape_string($d['portfolio_url'])."' WHERE uid='$uid'";
        echo json_encode($conn->query($sql) ? ["status" => "success"] : ["status" => "error"]);
        exit;
    }
}
?>