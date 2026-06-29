<?php
/**
 * ================================================================
 *  INNOVATECH — api/pedidos.php
 *  Endpoint POST para crear un pedido completo:
 *    - Inserta la cabecera en la tabla `pedidos`
 *    - Inserta cada item en `pedido_items`
 *    - Descuenta el stock en `productos`
 *  Todo dentro de una transacción (todo o nada).
 *
 *  Uso:    POST api/pedidos.php
 *  Body:   JSON con { cliente: {...}, items: [...] }
 * ================================================================
 *
 * Estructura del body esperado:
 *   cliente: {
 *     nombre, email, telefono, direccion, ciudad,
 *     departamento, notas, metodoPago
 *   }
 *   items: [
 *     { id: "sku-xyz", name: "...", price: 123.45, qty: 2 }
 *   ]
 *
 * Seguridad:
 *   - Transacción MySQL: commit/rollback protegen la integridad
 *   - Prepared statements en todas las escrituras
 *   - htmlspecialchars en texto, filter_var en email
 *   - Verificación de stock antes de descontar
 */

require_once 'config.php';

// ─── Solo aceptar POST ───────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Solo se acepta POST']);
    exit();
}

// ─── Leer y parsear el JSON del body ─────────────────────────
$raw  = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['error' => 'No se recibieron datos. Verifica que app.js envía JSON.']);
    exit();
}

$cli   = $data['cliente'] ?? [];
$items = $data['items']   ?? [];

// ─── Validar campos obligatorios ─────────────────────────────
if (empty($cli['nombre']) || empty($cli['email']) || empty($cli['direccion']) || empty($items)) {
    http_response_code(400);
    echo json_encode([
        'error'    => 'Faltan datos obligatorios',
        'recibido' => $cli
    ]);
    exit();
}

$pdo = conectar();

// ─── Calcular totales ────────────────────────────────────────
$subtotal = array_sum(array_map(fn($i) => (float)$i['price'] * (int)$i['qty'], $items));
$envio    = $subtotal >= 500 ? 0.00 : 15.00;  // Envío gratis > $500
$total    = $subtotal + $envio;

// ─── Generar número de orden único ──────────────────────────
// Formato: IT-2025-000001 (año + secuencial de 6 dígitos)
$anio  = date('Y');
$seq   = (int) $pdo->query("SELECT COUNT(*)+1 FROM pedidos WHERE YEAR(creado_en)='$anio'")->fetchColumn();
$orden = "IT-{$anio}-" . str_pad($seq, 6, '0', STR_PAD_LEFT);

// ─── Transacción: todo o nada ────────────────────────────────
$pdo->beginTransaction();

try {

    // ─── 1. Insertar cabecera del pedido ─────────────────────
    $stmt = $pdo->prepare("
        INSERT INTO pedidos
          (numero_orden, nombre_cliente, email_cliente, telefono,
           direccion, ciudad, departamento, notas,
           subtotal, costo_envio, total, metodo_pago)
        VALUES
          (:orden, :nombre, :email, :tel,
           :dir, :ciudad, :dpto, :notas,
           :sub, :envio, :total, :pago)
    ");

    $stmt->execute([
        ':orden'  => $orden,
        ':nombre' => htmlspecialchars($cli['nombre']),
        ':email'  => filter_var($cli['email'], FILTER_SANITIZE_EMAIL),
        ':tel'    => $cli['telefono']     ?? '',
        ':dir'    => $cli['direccion']    ?? '',
        ':ciudad' => $cli['ciudad']       ?? 'Managua',
        ':dpto'   => $cli['departamento'] ?? 'Managua',
        ':notas'  => $cli['notas']        ?? '',
        ':sub'    => $subtotal,
        ':envio'  => $envio,
        ':total'  => $total,
        ':pago'   => $cli['metodoPago']   ?? 'efectivo',
    ]);

    $pedidoId = $pdo->lastInsertId();

    // ─── 2. Insertar cada item + descontar stock ─────────────
    $siItem  = $pdo->prepare("
        INSERT INTO pedido_items (pedido_id, producto_id, nombre, sku, precio_unit, cantidad)
        VALUES (:pid, :prodid, :nom, :sku, :precio, :cant)
    ");
    $siStock = $pdo->prepare("
        UPDATE productos SET stock = stock - :cant WHERE id = :id
    ");

    foreach ($items as $item) {
        // Buscar el producto en BD por su SKU
        $sp = $pdo->prepare("SELECT id, nombre, sku, precio, stock FROM productos WHERE sku = :sku");
        $sp->execute([':sku' => $item['id']]);
        $prod = $sp->fetch();

        if (!$prod) {
            throw new Exception("Producto no encontrado: " . $item['id']);
        }
        if ($prod['stock'] < (int)$item['qty']) {
            throw new Exception("Sin stock suficiente: " . $prod['nombre']);
        }

        $siItem->execute([
            ':pid'    => $pedidoId,
            ':prodid' => $prod['id'],
            ':nom'    => $prod['nombre'],
            ':sku'    => $prod['sku'],
            ':precio' => $prod['precio'],
            ':cant'   => (int)$item['qty'],
        ]);

        $siStock->execute([
            ':cant' => (int)$item['qty'],
            ':id'   => $prod['id'],
        ]);
    }

    // ─── 3. Confirmar la transacción ─────────────────────────
    $pdo->commit();

    echo json_encode([
        'ok'           => true,
        'numero_orden' => $orden,
        'total'        => $total,
        'mensaje'      => 'Pedido guardado correctamente'
    ]);

} catch (Exception $e) {
    // Si algo falla, revertir todos los cambios
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode([
        'error'   => $e->getMessage(),
        'detalle' => 'Se hizo rollback, ningún dato fue guardado'
    ]);
}
