<?php
/**
 * ================================================================
 *  INNOVATECH — api/productos.php
 *  Endpoint GET que devuelve el catálogo completo de productos
 *  en formato JSON para que app.js lo consuma.
 *
 *  Uso:    GET api/productos.php
 *  Prueba: http://localhost/innovatech/api/productos.php
 * ================================================================
 *
 * Consulta SQL:
 *   - JOIN con categorías para obtener el nombre de la categoría
 *   - Filtra solo productos activos (activo = 1)
 *   - Ordena: destacados primero, luego por categoría y nombre
 *
 * Transformaciones:
 *   - Renombra campos al inglés para consistencia en el frontend
 *     (sku → id, nombre → name, precio → price, etc.)
 *   - Convierte tipos: price a float, stock a int, featured a bool
 *   - Calcula inStock como booleano derivado de stock > 0
 */

require_once 'config.php';
$pdo = conectar();

// ─── Consulta principal ──────────────────────────────────────
// Usa alias en inglés para que app.js consuma directamente:
//   id, name, cat, specs, price, oldPrice, stock, emoji, etc.
$sql = "
    SELECT
        p.sku               AS id,
        p.nombre            AS name,
        c.nombre            AS cat,
        p.especificaciones  AS specs,
        p.precio            AS price,
        p.precio_anterior   AS oldPrice,
        p.stock,
        p.emoji,
        p.imagen_url,
        p.badge,
        p.badge_tipo        AS badgeType,
        p.destacado         AS featured,
        IF(p.stock > 0, 1, 0) AS inStock
    FROM productos p
    JOIN categorias c ON c.id = p.categoria_id
    WHERE p.activo = 1
    ORDER BY p.destacado DESC, c.nombre, p.nombre
";

$stmt = $pdo->query($sql);
$rows = $stmt->fetchAll();

// ─── Conversión de tipos ────────────────────────────────────
// PHP PDO devuelve todo como string por defecto, así que
// convertimos explícitamente a los tipos que espera el frontend.
foreach ($rows as &$p) {
    $p['price']    = (float) $p['price'];
    $p['oldPrice'] = $p['oldPrice'] !== null ? (float) $p['oldPrice'] : null;
    $p['stock']    = (int)   $p['stock'];
    $p['featured'] = (bool)  $p['featured'];
    $p['inStock']  = (bool)  $p['inStock'];
}

// Devolver JSON con acentos y formato legible
echo json_encode($rows, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
