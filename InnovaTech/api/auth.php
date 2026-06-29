<?php
/**
 * ================================================================
 *  INNOVATECH — api/auth.php
 *  Endpoint REST de autenticación (registro y login).
 *  Uso:    api/auth.php?action=login    (POST)
 *          api/auth.php?action=registro (POST)
 *  Body:   JSON con { email, password } o { nombre, email, password }
 * ================================================================
 *
 * Flujo:
 *   1. Lee el parámetro ?action= de la URL
 *   2. Recibe JSON desde el body (php://input)
 *   3. Valida campos obligatorios y sanitiza entrada
 *   4. Ejecuta la acción correspondiente contra MySQL vía PDO
 *   5. Retorna JSON con { ok, mensaje, usuario } o { error }
 *
 * Seguridad:
 *   - Contraseñas almacenadas con password_hash() + PASSWORD_BCRYPT
 *   - Verificación con password_verify() (timing-safe)
 *   - HTML sanitizado en nombre (htmlspecialchars)
 *   - Prepared statements en todas las consultas SQL
 *   - No se devuelve el hash de la contraseña al frontend
 */

require_once 'config.php';

// ─── Leer parámetros ─────────────────────────────────────────
$action = $_GET['action'] ?? '';
$raw    = file_get_contents('php://input');
$data   = json_decode($raw, true);

// Si no se recibió JSON válido, responder error 400
if (!$data) {
    http_response_code(400);
    echo json_encode(['error' => 'No se recibieron datos válidos']);
    exit();
}

$pdo = conectar();

// =============================================================
//  ACCIÓN: REGISTRO
//  Crea un nuevo cliente con rol 'cliente' por defecto.
//  Valida: nombre, email válido, password >= 6 caracteres,
//  y que el email no esté ya registrado.
// =============================================================
if ($action === 'registro') {
    $nombre   = trim($data['nombre']   ?? '');
    $email    = trim($data['email']    ?? '');
    $telefono = trim($data['telefono'] ?? '');
    $password = $data['password']      ?? '';

    // Validaciones de campos obligatorios
    if (!$nombre || !$email || !$password) {
        http_response_code(400);
        echo json_encode(['error' => 'Nombre, email y contraseña son obligatorios']);
        exit();
    }

    // Validar formato de correo electrónico
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['error' => 'El correo electrónico no es válido']);
        exit();
    }

    // Mínimo de seguridad en la contraseña
    if (strlen($password) < 6) {
        http_response_code(400);
        echo json_encode(['error' => 'La contraseña debe tener al menos 6 caracteres']);
        exit();
    }

    // Verificar que el email no exista ya en la BD
    $check = $pdo->prepare("SELECT id FROM clientes WHERE email = :email");
    $check->execute([':email' => $email]);
    if ($check->fetch()) {
        http_response_code(409);  // Conflict
        echo json_encode(['error' => 'Este correo ya está registrado. Inicia sesión.']);
        exit();
    }

    // Generar hash bcrypt de la contraseña
    $hash = password_hash($password, PASSWORD_BCRYPT);

    // Insertar nuevo cliente con rol 'cliente'
    $stmt = $pdo->prepare("
        INSERT INTO clientes (nombre, email, telefono, password_hash, rol)
        VALUES (:nombre, :email, :telefono, :hash, 'cliente')
    ");

    $stmt->execute([
        ':nombre'   => htmlspecialchars($nombre),
        ':email'    => $email,
        ':telefono' => $telefono,
        ':hash'     => $hash,
    ]);

    $nuevoId = $pdo->lastInsertId();

    // Devolver datos del nuevo usuario (sin contraseña)
    echo json_encode([
        'ok'      => true,
        'mensaje' => 'Cuenta creada correctamente',
        'usuario' => [
            'id'     => $nuevoId,
            'nombre' => $nombre,
            'email'  => $email,
            'rol'    => 'cliente',
        ]
    ]);
    exit();
}

// =============================================================
//  ACCIÓN: LOGIN
//  Autentica al usuario por email + contraseña.
//  Retorna datos del usuario incluyendo el rol para que
//  el frontend pueda mostrar/ocultar el botón Admin.
// =============================================================
if ($action === 'login') {
    $email    = trim($data['email']    ?? '');
    $password = $data['password']      ?? '';

    if (!$email || !$password) {
        http_response_code(400);
        echo json_encode(['error' => 'Ingresa tu correo y contraseña']);
        exit();
    }

    // Buscar usuario por email
    $stmt = $pdo->prepare("
        SELECT id, nombre, email, password_hash, activo, rol
        FROM clientes
        WHERE email = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $usuario = $stmt->fetch();

    // Si no existe el email, respuesta genérica (no revelar qué falló)
    if (!$usuario) {
        http_response_code(401);
        echo json_encode(['error' => 'Correo o contraseña incorrectos']);
        exit();
    }

    // Verificar si la cuenta está activa (flag activo = 1)
    if (!$usuario['activo']) {
        http_response_code(403);
        echo json_encode(['error' => 'Tu cuenta está desactivada. Contacta al soporte.']);
        exit();
    }

    // Verificar la contraseña contra el hash almacenado
    if (!password_verify($password, $usuario['password_hash'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Correo o contraseña incorrectos']);
        exit();
    }

    // Autenticación exitosa: devolver datos del usuario
    echo json_encode([
        'ok'      => true,
        'mensaje' => 'Sesión iniciada correctamente',
        'usuario' => [
            'id'     => $usuario['id'],
            'nombre' => $usuario['nombre'],
            'email'  => $usuario['email'],
            'rol'    => $usuario['rol'],
        ]
    ]);
    exit();
}

// Si ?action no coincide con ninguna acción conocida
http_response_code(400);
echo json_encode(['error' => 'Acción no válida. Usa ?action=login o ?action=registro']);
