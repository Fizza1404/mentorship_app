<?php
header("Content-Type: application/json");
include 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if($method == 'GET'){$action = $_GET['action'] ?? '';
    
    if($action == 'get_resources'){
        $m_id = $conn->real_escape_string($_GET['mentor_id']);
        $sql = "SELECT * FROM resources WHERE mentor_id = '$m_id' ORDER BY created_at DESC";
        $result = $conn->query($sql);
        $res = [];
        while($row = $result->fetch_assoc()){ $res[] = $row; }
        echo json_encode($res);
    }
}

if($method == 'POST'){
    $d = json_decode(file_get_contents("php://input"), true);
    $action = $d['action'] ?? '';

    if($action == 'add_resource'){
        $m_id = $conn->real_escape_string($d['mentor_id']);
        $title = $conn->real_escape_string($d['title']);
        $cat = $conn->real_escape_string($d['category'] ?? 'General');
        $f_url = $conn->real_escape_string($d['file_url']);
        $type = $conn->real_escape_string($d['file_type'] ?? 'file');

        $sql = "INSERT INTO resources (mentor_id, title, category, file_url, file_type) 
                VALUES ('$m_id', '$title', '$cat', '$f_url', '$type')";
        
        if($conn->query($sql)){
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    }
}
?>