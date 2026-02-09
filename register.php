<?php
include 'config.php';
$data = json_decode(file_get_contents("php://input"), true);

if($_SERVER['REQUEST_METHOD'] == 'POST'){$uid = $conn->real_escape_string($data['uid']);
    $name = $conn->real_escape_string($data['name']);
    $email = $conn->real_escape_string($data['email']);
    $password = password_hash($data['password'], PASSWORD_DEFAULT);
    $role = $conn->real_escape_string($data['role']);
    $phone = $conn->real_escape_string($data['phone']);
    
    // Mentor specific fields
    $skills = $conn->real_escape_string($data['skills'] ?? '');
    $experience = $conn->real_escape_string($data['experience'] ?? '');
    $bio = $conn->real_escape_string($data['bio'] ?? '');
    $portfolio = $conn->real_escape_string($data['portfolio'] ?? '');
    $linkedin = $conn->real_escape_string($data['linkedin'] ?? '');
    $github = $conn->real_escape_string($data['github'] ?? '');

    $sql = "INSERT INTO users (uid, name, email, password, role, phone, skills, experience, bio, portfolio, linkedin, github) 
            VALUES ('$uid', '$name', '$email', '$password', '$role', '$phone', '$skills', '$experience', '$bio', '$portfolio', '$linkedin', '$github')";
    
    if($conn->query($sql)){
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
}
?>