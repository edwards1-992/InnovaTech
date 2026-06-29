-- ==============================================================
--  INNOVATECH — db_update.sql
--  Migración de base de datos: añade columna rol, usuario admin
--  y rutas de imágenes locales para los productos.
--
--  Cómo ejecutar:
--  1. Importa innovatech.sql primero (crea BD + tablas + datos)
--  2. Luego ejecuta ESTE archivo en phpMyAdmin
--  3. Verifica que el admin puede iniciar sesión en login.html
-- ==============================================================

USE innovatech;

-- ==============================================================
--  1. Añadir columna 'rol' a la tabla clientes
--  Valores posibles: 'cliente' (default) o 'admin'
--  Se inserta después de la columna 'activo'
-- ==============================================================
ALTER TABLE clientes
  ADD COLUMN rol VARCHAR(20) NOT NULL DEFAULT 'cliente'
  AFTER activo;

-- ==============================================================
--  2. Insertar usuario administrador por defecto
--  Email:    admin@innovatech.com
--  Password: innovatech (hash bcrypt verificado)
--  Rol:      admin
--  ON DUPLICATE KEY UPDATE permite re-ejecutar el script sin
--  duplicar el registro.
-- ==============================================================
INSERT INTO clientes (nombre, email, password_hash, rol, activo)
VALUES ('Administrador', 'admin@innovatech.com',
        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        'admin', 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), rol = VALUES(rol);

-- ==============================================================
--  3. Asignar rutas de imágenes locales a productos existentes
--  Las imágenes deben estar en: img/productos/
--  Formato: UPDATE productos SET imagen_url = 'archivo.ext'
--           WHERE sku = 'sku-del-producto';
--
--  Productos con imagen real disponible:
-- ==============================================================
UPDATE productos SET imagen_url = 'GTX 5090.jpg'       WHERE sku = 'gpu-rtx5090';
UPDATE productos SET imagen_url = 'Asus Strix Z790.jpg' WHERE sku = 'mb-01';
UPDATE productos SET imagen_url = 'Msi mag B760.png'    WHERE sku = 'mb-02';
UPDATE productos SET imagen_url = 'Gigabyte X670E.jpg'  WHERE sku = 'mb-03';

--  NOTA: El resto de productos (16) usan SVGs placeholder
--  definidos en img/productos/cat-*.svg como fallback visual.
--  Cuando tengas las imágenes reales, agrega más UPDATEs aquí.
