<?php
header("Content-Type: application/json");
include 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if($method == 'GET'){
    $action = $_GET['action'] ?? 'get_courses';
    
    // 1. Get All Courses or Mentor Courses
    if($action == 'get_courses'){
        $m_id = isset($_GET['mentor_id']) ? $conn->real_escape_string($_GET['mentor_id']) : '';
        $query = ($m_id != '') ? "SELECT * FROM courses WHERE mentor_id = '$m_id'" : "SELECT * FROM courses";
        $result = $conn->query($query . " ORDER BY id DESC");
        $res = [];
        while($row = $result->fetch_assoc()){ $res[] = $row; }
        echo json_encode($res);
    }
    
    // 2. Get Modules for a specific Course
    if($action == 'get_modules'){
        $c_id = $conn->real_escape_string($_GET['course_id']);
        $sql = "SELECT * FROM course_modules WHERE course_id = '$c_id' ORDER BY order_index ASC";
        $result = $conn->query($sql);
        $res = [];
        while($row = $result->fetch_assoc()){ $res[] = $row; }
        echo json_encode($res);
    }
}

if($method == 'POST'){
    $d = json_decode(file_get_contents("php://input"), true);
    $action = $d['action'] ?? 'add_course';

    // 1. Add New Course
    if($action == 'add_course'){
        $title = $conn->real_escape_string($d['title']);
        $desc = $conn->real_escape_string($d['description']);
        $m_id = $conn->real_escape_string($d['mentor_id']);
        $m_name = $conn->real_escape_string($d['mentor_name']);
        $dur = $conn->real_escape_string($d['duration_hours']);
        $code = $conn->real_escape_string($d['course_code'] ?? 'N/A');
        $cat = $conn->real_escape_string($d['category'] ?? 'General');

        $sql = "INSERT INTO courses (title, description, mentor_id, mentor_name, duration_hours, course_code, category) 
                VALUES ('$title', '$desc', '$m_id', '$m_name', '$dur', '$code', '$cat')";
        
        if($conn->query($sql)){ echo json_encode(["status" => "success"]); }
        else { echo json_encode(["status" => "error", "message" => $conn->error]); }
    }

    // 2. Add New Module to Course
    if($action == 'add_module'){
        $c_id = $conn->real_escape_string($d['course_id']);
        $title = $conn->real_escape_string($d['title']);
        $desc = $conn->real_escape_string($d['description'] ?? '');
        $video = $conn->real_escape_string($d['video_url'] ?? '');
        $file = $conn->real_escape_string($d['file_url'] ?? '');
        
        $sql = "INSERT INTO course_modules (course_id, title, description, video_url, file_url) 
                VALUES ('$c_id', '$title', '$desc', '$video', '$file')";
        if($conn->query($sql)){ echo json_encode(["status" => "success"]); }
        else { echo json_encode(["status" => "error"]); }
    }
}
?>