<?php
/**
 * ================================================================
 *  INNOVATECH — api/config.php
 *  Conexión centralizada a MySQL vía PDO con estilo singleton.
 *  Todos los endpoints incluyen este archivo para obtener $pdo.
 * ================================================================
 *
 * Arquitectura:
 *   - Define constantes de entorno (host, db, usuario, pass)
 *   - Configura cabeceras CORS para que JS (fetch) pueda leer
 *     las respuestas JSON desde cualquier origen
 *   - Exporta la función conectar() que retorna una única
 *     instancia PDO reutilizable (patrón singleton)
 *
 * Requisito: XAMPP con MySQL corriendo en localhost, root sin pass
 */

// ─── Modo depuración: muestra errores PHP en pantalla ─────────
// Al publicar en producción, cambiar a 0 o comentar estas líneas
// ─── Modo producción: desactivar en Railway ──────────────────
if (getenv('RAILWAY_ENVIRONMENT')) {
    ini_set('display_errors', 0);
    error_reporting(0);
} else {
    ini_set('display_errors', 1);
    error_reporting(E_ALL);
}

// ─── Constantes de conexión ──────────────────────────────────
// Railway inyecta automáticamente MYSQL_* al añadir un plugin MySQL
define('DB_HOST',    getenv('MYSQL_HOST')    ?: 'localhost');
define('DB_NAME',    getenv('MYSQL_DATABASE') ?: 'innovatech');
define('DB_USER',    getenv('MYSQL_USER')     ?: 'root');
define('DB_PASS',    getenv('MYSQL_PASSWORD') ?: '');
define('DB_CHARSET', 'utf8mb4');

// ─── Cabeceras HTTP (CORS) para comunicación con JS ──────────
// Content-Type: la respuesta siempre será JSON
// Access-Control-Allow-Origin: * permite peticiones desde cualquier
//   origen (útil en desarrollo con múltiples puertos/dominios)
// Access-Control-Allow-Methods: métodos HTTP permitidos
// Access-Control-Allow-Headers: headers que el frontend puede enviar
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// ─── Preflight CORS (OPTIONS) ───────────────────────────────
// El navegador envía una petición OPTIONS antes de cada POST
// para verificar que el servidor acepta el origen.
// Respondemos 204 (Sin contenido) y cortamos la ejecución.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

// ─── Función singleton de conexión PDO ──────────────────────
// Retorna siempre la misma instancia PDO en una misma petición
// para evitar abrir múltiples conexiones a MySQL.
function conectar(): PDO {
    static $pdo = null;
    if ($pdo !== null) return $pdo;

    try {
        $dsn = "mysql:host=" . DB_HOST
             . ";dbname="    . DB_NAME
             . ";charset="   . DB_CHARSET;

        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'error'   => 'Error de conexión a MySQL',
            'detalle' => $e->getMessage()
        ]);
        exit();  // No podemos continuar sin BD
    }

    return $pdo;
}
