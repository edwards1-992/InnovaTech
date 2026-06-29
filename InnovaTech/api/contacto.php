<?php
/**
 * ================================================================
 *  INNOVATECH — api/contacto.php
 *  Endpoint POST para guardar mensajes del formulario de contacto.
 *
 *  Uso:    POST api/contacto.php
 *  Body:   JSON con { nombre, email, telefono, asunto, mensaje }
 * ================================================================
 *
 * Público: cualquier visitante puede enviar un mensaje, no
 * requiere autenticación.
 *
 * Seguridad:
 *   - htmlspecialchars en texto libre (XSS prevention)
 *   - filter_var + FILTER_SANITIZE_EMAIL en el email
 *   - Prepared statement en la escritura
 */

require_once 'config.php';

// ─── Solo aceptar POST ───────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Solo se acepta POST']);
    exit();
}

// ─── Leer JSON del body ──────────────────────────────────────
$data = json_decode(file_get_contents('php://input'), true);

// ─── Validar campos obligatorios ─────────────────────────────
if (empty($data['nombre']) || empty($data['email']) || empty($data['mensaje'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Nombre, email y mensaje son obligatorios']);
    exit();
}

// ─── Insertar en la BD ──────────────────────────────────────
$pdo  = conectar();
$stmt = $pdo->prepare("
    INSERT INTO contacto_mensajes (nombre, email, telefono, asunto, mensaje)
    VALUES (:nombre, :email, :telefono, :asunto, :mensaje)
");

$stmt->execute([
    ':nombre'   => htmlspecialchars($data['nombre']),
    ':email'    => filter_var($data['email'], FILTER_SANITIZE_EMAIL),
    ':telefono' => $data['telefono'] ?? '',
    ':asunto'   => htmlspecialchars($data['asunto']  ?? ''),
    ':mensaje'  => htmlspecialchars($data['mensaje']),
]);

echo json_encode([
    'ok'      => true,
    'mensaje' => 'Mensaje guardado correctamente'
]);
