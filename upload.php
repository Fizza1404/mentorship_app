<?php
header('Content-Type: application/json');
$target_dir = "uploads/";
if (!file_exists($target_dir)) { mkdir($target_dir, 0777, true); }

if (isset($_FILES['file'])) {
    $file_name = time() . '_' . basename($_FILES["file"]["name"]);
    $target_file = $target_dir . $file_name;
    if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $file_url = $protocol . "://" . $_SERVER['HTTP_HOST'] . "/api/" . $target_file;
        echo json_encode(["status" => "success", "fileUrl" => $file_url]);
    } else {
        echo json_encode(["status" => "error"]);
    }
}
?>