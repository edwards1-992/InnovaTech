<?php
/**
 * ================================================================
 *  INNOVATECH — api/admin.php
 *  REST API protegida para el panel de administración.
 *  Todos los endpoints requieren autenticación vía header
 *  X-Admin-Email con el email de un usuario con rol 'admin'.
 *
 *  Endpoints:
 *    GET ?action=pedidos          → Lista todos los pedidos + items
 *    GET ?action=pedido&id=X       → Detalle de un pedido específico
 *    GET ?action=clientes          → Lista todos los clientes registrados
 *    GET ?action=stats             → Estadísticas consolidadas
 * ================================================================
 *
 * Mecanismo de autenticación:
 *   - El frontend (admin.html) envía el header X-Admin-Email
 *     con el email del usuario logueado
 *   - checkAdmin() verifica que ese email exista en la BD,
 *     tenga rol='admin' y activo=1
 *   - Si no, responde 401/403 y corta la ejecución
 */

require_once 'config.php';

$action = $_GET['action'] ?? '';
$pdo    = conectar();

// ─── Función de autenticación de administrador ───────────────
// Verifica el header HTTP_X_ADMIN_EMAIL contra la BD.
// Retorna los datos del admin si es válido; si no, muere con error.
function checkAdmin(PDO $pdo): array {
    $email = $_SERVER['HTTP_X_ADMIN_EMAIL'] ?? '';
    if (!$email) {
        http_response_code(401);
        echo json_encode(['error' => 'No autorizado']);
        exit();
    }
    $stmt = $pdo->prepare("
        SELECT id, nombre, email, rol
        FROM clientes
        WHERE email = :email AND rol = 'admin' AND activo = 1
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();
    if (!$user) {
        http_response_code(403);
        echo json_encode(['error' => 'Acceso denegado — se requiere rol de administrador']);
        exit();
    }
    return $user;
}

// ─── GET: Listar todos los pedidos ───────────────────────────
// Devuelve cada pedido con sus items asociados (cantidad x nombre).
if ($action === 'pedidos') {
    checkAdmin($pdo);

    $stmt = $pdo->query("
        SELECT
            p.id, p.numero_orden, p.nombre_cliente, p.email_cliente,
            p.telefono, p.direccion, p.ciudad, p.departamento,
            p.subtotal, p.costo_envio, p.total, p.metodo_pago,
            p.estado_pago, p.estado, p.notas, p.creado_en
        FROM pedidos p
        ORDER BY p.creado_en DESC
    ");
    $pedidos = $stmt->fetchAll();

    // Por cada pedido, obtener la lista de productos comprados
    foreach ($pedidos as &$ped) {
        $si = $pdo->prepare("
            SELECT pi.nombre, pi.sku, pi.precio_unit, pi.cantidad,
                   (pi.precio_unit * pi.cantidad) AS subtotal
            FROM pedido_items pi
            WHERE pi.pedido_id = :pid
        ");
        $si->execute([':pid' => $ped['id']]);
        $ped['items'] = $si->fetchAll();
    }

    echo json_encode(['ok' => true, 'pedidos' => $pedidos]);
    exit();
}

// ─── GET: Detalle de un pedido específico ───────────────────
if ($action === 'pedido') {
    checkAdmin($pdo);
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID de pedido requerido']);
        exit();
    }

    $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $pedido = $stmt->fetch();
    if (!$pedido) {
        http_response_code(404);
        echo json_encode(['error' => 'Pedido no encontrado']);
        exit();
    }

    $si = $pdo->prepare("
        SELECT pi.*, (pi.precio_unit * pi.cantidad) AS subtotal
        FROM pedido_items pi WHERE pi.pedido_id = :pid
    ");
    $si->execute([':pid' => $pedido['id']]);
    $pedido['items'] = $si->fetchAll();

    echo json_encode(['ok' => true, 'pedido' => $pedido]);
    exit();
}

// ─── GET: Listar todos los clientes registrados ──────────────
if ($action === 'clientes') {
    checkAdmin($pdo);
    $stmt = $pdo->query("
        SELECT id, nombre, email, rol, activo, creado_en
        FROM clientes ORDER BY id DESC
    ");
    $clientes = $stmt->fetchAll();
    echo json_encode(['ok' => true, 'clientes' => $clientes]);
    exit();
}

// ─── GET: Estadísticas del dashboard ─────────────────────────
// Devuelve: total de pedidos, ingresos acumulados, cantidad de
// clientes, productos activos y pedidos del día de hoy.
if ($action === 'stats') {
    checkAdmin($pdo);

    $totalPedidos   = $pdo->query("SELECT COUNT(*) FROM pedidos")->fetchColumn();
    $ingresos       = $pdo->query("SELECT COALESCE(SUM(total), 0) FROM pedidos")->fetchColumn();
    $totalClientes  = $pdo->query("SELECT COUNT(*) FROM clientes")->fetchColumn();
    $totalProductos = $pdo->query("SELECT COUNT(*) FROM productos WHERE activo = 1")->fetchColumn();
    $pedidosHoy     = $pdo->query("SELECT COUNT(*) FROM pedidos WHERE DATE(creado_en) = CURDATE()")->fetchColumn();

    echo json_encode([
        'ok' => true,
        'stats' => [
            'total_pedidos'   => (int)$totalPedidos,
            'ingresos'        => (float)$ingresos,
            'total_clientes'  => (int)$totalClientes,
            'total_productos' => (int)$totalProductos,
            'pedidos_hoy'     => (int)$pedidosHoy,
        ]
    ]);
    exit();
}

// Si ?action no coincide con ningún endpoint conocido
http_response_code(400);
echo json_encode(['error' => 'Acción no válida. Usa ?action=pedidos, ?action=pedido&id=X, o ?action=stats']);
