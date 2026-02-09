<?php
// PHP Warnings hide karne ke liye
error_reporting(0); 
ini_set('display_errors', 0);

header('Content-Type: application/json');include 'config.php';

$json = file_get_contents('php://input');
$data = json_decode($json, true);

if($_SERVER['REQUEST_METHOD'] == 'POST'){
    $email = $conn->real_escape_string($data['email']);
    $password = $data['password'];
    $uid = isset($data['uid']) ? $conn->real_escape_string($data['uid']) : null;

    $result = $conn->query("SELECT * FROM users WHERE email='$email'");
    if($result && $result->num_rows > 0){
        $user = $result->fetch_assoc();
        if(password_verify($password, $user['password'])){
            
            // UID Sync Logic
            if($uid != null && ($user['uid'] == null || $user['uid'] == '')){
                $conn->query("UPDATE users SET uid='$uid' WHERE email='$email'");
                $user['uid'] = $uid;
            }

            unset($user['password']);
            echo json_encode(["status" => "success", "user" => $user]);
        } else {
            echo json_encode(["status" => "error", "message" => "Wrong password"]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "User not found"]);
    }
}
$conn->close();
?>