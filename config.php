<?php
header('Content-Type: application/json');
$host = "localhost";
$user = "easyckuq_learncode";
$pass = "learncode@99";
$dbname = "easyckuq_learncode";

$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Connection failed"]));
}
?>