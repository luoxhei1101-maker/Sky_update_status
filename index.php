<?php
require 'config.php';

define('DB_FILE', 'db.json');

/** 快速验证 Auth */
function validateAuth() {
    return (getallheaders()['Authorization'] ?? '') === AUTH_TOKEN;
}

/** 快速读取（无锁，file_get_contents 自身原子） */
function readDb() {
    if (!file_exists(DB_FILE)) {
        return ['status' => 'NoTask'];
    }
    $content = @file_get_contents(DB_FILE);
    if (!$content) return ['status' => 'NoTask'];
    $data = json_decode($content, true);
    return is_array($data) ? $data : ['status' => 'NoTask'];
}

/** 原子写入：先写 tmp 再 rename（防止写半截） */
function writeDb($data) {
    $tmp = DB_FILE . '.' . getmypid() . '.tmp';
    file_put_contents($tmp, json_encode($data, JSON_UNESCAPED_SLASHES), LOCK_EX);
    rename($tmp, DB_FILE);
}

if (!validateAuth()) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'];

switch ($uri) {

    /* ─── 查询状态 ─── */
    case '/get_task_status':
        if ($method !== 'POST') {
            http_response_code(405);
            exit;
        }
        $db = readDb();
        echo json_encode(['status' => $db['status'] ?? 'NoTask']);
        exit;

    /* ─── 提交任务 ─── */
    case '/submit_task':
        if ($method !== 'POST') {
            http_response_code(405);
            exit;
        }
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input
            || ($input['update_status'] ?? '') !== 'NewTask'
            || strlen($input['user'] ?? '') !== 36
            || strlen($input['session'] ?? '') !== 32
        ) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid request']);
            exit;
        }
        $db = readDb();
        if (($db['status'] ?? 'NoTask') !== 'NoTask') {
            echo json_encode([
                'result' => 'failed',
                'status' => $db['status'] ?? 'Working'
            ]);
            exit;
        }
        writeDb([
            'status'     => 'NewTask',
            'user'       => $input['user'],
            'session'    => $input['session'],
            'created_at' => date('c')
        ]);
        echo json_encode(['result' => 'ok']);
        exit;

    /* ─── 更新状态 ─── */
    case '/update_status':
        if ($method !== 'POST') {
            http_response_code(405);
            exit;
        }
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input || !in_array($input['update_status'] ?? '', ['NoTask', 'Working'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid request']);
            exit;
        }
        $db = readDb();
        writeDb([
            'status'     => $input['update_status'],
            'user'       => $db['user'] ?? '',
            'session'    => $db['session'] ?? '',
            'updated_at' => date('c')
        ]);
        echo json_encode(['result' => 'ok']);
        exit;

    default:
        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;
}
