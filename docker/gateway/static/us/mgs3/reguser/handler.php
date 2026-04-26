<?php
/**
 * NetworkMemories — MGO1 Account Registration
 * Endpoint: POST /us/mgs3/reguser/reguser.html
 *
 * PS2 sends: username, password (pre-hashed with fixed salt)
 * Password algorithm: MD5(username + FIXED_SALT + password_plaintext)
 * Salt: fixed 16-byte sequence (see docs/password-algorithm.md)
 *
 * Response codes (plain text):
 *   0  = success
 *   -1 = username already taken
 *   -2 = invalid input
 *   -3 = server error
 */

header('Content-Type: text/plain');

$db_host = getenv('MYSQL_HOST') ?: 'biomysql';
$db_name = getenv('MYSQL_DATABASE') ?: 'mgops';
$db_user = getenv('MYSQL_USER') ?: '';
$db_pass = getenv('MYSQL_PASSWORD') ?: '';

// --- Input validation ---
$username = trim($_POST['username'] ?? $_POST['loginid'] ?? '');
$password = trim($_POST['password'] ?? $_POST['passwd'] ?? '');

if (empty($username) || empty($password)) {
    echo '-2';
    exit;
}

// Username: 3-16 chars, alphanumeric + underscore only
if (!preg_match('/^[a-zA-Z0-9_]{3,16}$/', $username)) {
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
    error_log('[reguser] DB connection failed: ' . $e->getMessage());
    echo '-3';
    exit;
}

// Check if username already exists
$stmt = $pdo->prepare("SELECT COUNT(*) FROM users WHERE username = ?");
$stmt->execute([$username]);
if ($stmt->fetchColumn() > 0) {
    echo '-1';
    exit;
}

// Store the already-hashed password as received from PS2
// The PS2 sends: MD5(username + FIXED_SALT + password_plaintext)
// See docs/password-algorithm.md for the full algorithm details
$stmt = $pdo->prepare(
    "INSERT INTO users (username, password, created_at) VALUES (?, ?, NOW())"
);

try {
    $stmt->execute([$username, $password]);
    error_log("[reguser] Created account: $username");
    echo '0';
} catch (PDOException $e) {
    error_log('[reguser] Insert failed: ' . $e->getMessage());
    echo '-3';
}
