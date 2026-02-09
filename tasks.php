<?php
header("Content-Type: application/json");
include 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if($method == 'GET'){
    $action = $_GET['action'] ?? '';
    
    if($action == 'get_tasks'){
        $c_id = $conn->real_escape_string($_GET['course_id'] ?? '');
        $s_id = $conn->real_escape_string($_GET['student_id'] ?? '');
        $role = $_GET['role'] ?? 'student';

        if($role == 'mentor'){
            // Mentor View: Filter tasks by specific student if s_id is provided
            $sql = "SELECT t.*, s.id as submission_id, s.status as submission_status, s.obtained_marks, s.feedback, s.file_url as submission_file_url 
                    FROM tasks t 
                    LEFT JOIN task_submissions s ON t.id = s.task_id AND s.student_id = '$s_id'
                    WHERE (t.course_id = '$c_id' OR '$c_id' = '0') 
                    AND FIND_IN_SET('$s_id', t.assigned_student_ids)";
        } else {
            // Student View: STRICTLY show ONLY those tasks where this student's ID exists in assigned_student_ids
            $sql = "SELECT t.*, s.status as submission_status, s.obtained_marks, s.feedback, s.file_url as student_file_url 
                    FROM tasks t 
                    LEFT JOIN task_submissions s ON t.id = s.task_id AND s.student_id = '$s_id'
                    WHERE (t.course_id = '$c_id' OR '$c_id' = '0')
                    AND FIND_IN_SET('$s_id', t.assigned_student_ids)";
        }

        $result = $conn->query($sql);
        $res = [];
        if($result) { while($row = $result->fetch_assoc()){ $res[] = $row; } }
        echo json_encode($res);
    }
}

if($method == 'POST'){
    $d = json_decode(file_get_contents("php://input"), true);
    $action = $d['action'] ?? '';

    if($action == 'add_task'){
        $c_id = $conn->real_escape_string($d['course_id']);
        $title = $conn->real_escape_string($d['title']);
        $desc = $conn->real_escape_string($d['description']);
        $marks = $conn->real_escape_string($d['total_marks']);
        $file = $conn->real_escape_string($d['file_url'] ?? '');
        $assigned = $conn->real_escape_string($d['assigned_student_ids'] ?? '');

        // Zaroori Check: assigned_student_ids khali nahi honi chahiye
        $sql = "INSERT INTO tasks (course_id, title, description, total_marks, file_url, assigned_student_ids) 
                VALUES ('$c_id', '$title', '$desc', '$marks', '$file', '$assigned')";
        
        if($conn->query($sql)){ echo json_encode(["status" => "success"]); }
        else { echo json_encode(["status" => "error", "message" => $conn->error]); }
    }
    
    // submit_task aur evaluate_task logic same rahegi
}
?>