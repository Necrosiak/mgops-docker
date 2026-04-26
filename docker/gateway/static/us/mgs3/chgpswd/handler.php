<?php
/**
 * NetworkMemories — MGO1 Password Change
 * Endpoint: POST /us/mgs3/chgpswd/chgpswd.html
 *
 * Response codes:
 *   0  = success
 *   -1 = user not found
 *   -2 = invalid current credentials
 *   -3 = server error
 */

header('Content-Type: text/plain');

$db_host = getenv('MYSQL_HOST') ?: 'biomysql';
$db_name = getenv('MYSQL_DATABASE') ?: 'mgops';
$db_user = getenv('MYSQL_USER') ?: '';
$db_pass = getenv('MYSQL_PASSWORD') ?: '';

$username    = trim($_POST['username'] ?? $_POST['loginid'] ?? '');
$old_password = trim($_POST['old_password'] ?? $_POST['oldpasswd'] ?? '');
$new_password = trim($_POST['new_password'] ?? $_POST['newpasswd'] ?? '');

if (empty($username) || empty($old_password) || empty($new_password)) {
    echo '-2';
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=latin1",
        $db_user, $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    error_log('[chgpswd] DB connection failed: ' . $e->getMessage());
    echo '-3';
    exit;
}

$stmt = $pdo->prepare("SELECT id, password FROM users WHERE username = ?");
$stmt->execute([$username]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    echo '-1';
    exit;
}

if (!hash_equals($user['password'], $old_password)) {
    echo '-2';
    exit;
}

try {
    $pdo->prepare("UPDATE users SET password = ? WHERE id = ?")
        ->execute([$new_password, $user['id']]);
    error_log("[chgpswd] Password changed for: $username");
    echo '0';
} catch (PDOException $e) {
    error_log('[chgpswd] Update failed: ' . $e->getMessage());
    echo '-3';
}
