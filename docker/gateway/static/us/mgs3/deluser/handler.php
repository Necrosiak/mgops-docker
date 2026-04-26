<?php
/**
 * NetworkMemories — MGO1 Account Deletion
 * Endpoint: POST /us/mgs3/deluser/deluser.html
 *
 * Response codes:
 *   0  = success
 *   -1 = user not found
 *   -2 = invalid credentials
 *   -3 = server error
 */

header('Content-Type: text/plain');

$db_host = getenv('MYSQL_HOST') ?: 'biomysql';
$db_name = getenv('MYSQL_DATABASE') ?: 'mgops';
$db_user = getenv('MYSQL_USER') ?: '';
$db_pass = getenv('MYSQL_PASSWORD') ?: '';

$username = trim($_POST['username'] ?? $_POST['loginid'] ?? '');
$password = trim($_POST['password'] ?? $_POST['passwd'] ?? '');

if (empty($username) || empty($password)) {
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
    error_log('[deluser] DB connection failed: ' . $e->getMessage());
    echo '-3';
    exit;
}

// Verify credentials before deleting
$stmt = $pdo->prepare("SELECT id, password FROM users WHERE username = ?");
$stmt->execute([$username]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    echo '-1';
    exit;
}

if (!hash_equals($user['password'], $password)) {
    echo '-2';
    exit;
}

try {
    $pdo->prepare("DELETE FROM users WHERE id = ?")->execute([$user['id']]);
    error_log("[deluser] Deleted account: $username");
    echo '0';
} catch (PDOException $e) {
    error_log('[deluser] Delete failed: ' . $e->getMessage());
    echo '-3';
}
