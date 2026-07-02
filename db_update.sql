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

USE railway;

-- ==============================================================
--  1. Añadir columna 'imagen_url' a la tabla productos
-- ==============================================================
ALTER TABLE productos
  ADD COLUMN imagen_url VARCHAR(255) DEFAULT NULL
  AFTER emoji;

-- ==============================================================
--  2. Añadir columna 'rol' a la tabla clientes
--  Valores posibles: 'cliente' (default) o 'admin'
--  Se inserta después de la columna 'activo'
-- ==============================================================
ALTER TABLE clientes
  ADD COLUMN rol VARCHAR(20) NOT NULL DEFAULT 'cliente'
  AFTER activo;

-- ==============================================================
--  3. Insertar usuario administrador por defecto
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
--  4. Asignar rutas de imágenes locales a productos existentes
--  Las imágenes deben estar en: img/productos/
--  Formato: UPDATE productos SET imagen_url = 'archivo.ext'
--           WHERE sku = 'sku-del-producto';
--
--  Productos con imagen real disponible:
-- ==============================================================
UPDATE productos SET imagen_url = 'GTX 5090.jpg'            WHERE sku = 'gpu-rtx5090';
UPDATE productos SET imagen_url = 'AMD RX 7900 XTX.jpg'     WHERE sku = 'gpu-rx7900';
UPDATE productos SET imagen_url = 'RTX 4070 Super.jpg'      WHERE sku = 'gpu-rtx4070';
UPDATE productos SET imagen_url = 'Asus Strix Z790.jpg'     WHERE sku = 'mb-01';
UPDATE productos SET imagen_url = 'Msi mag B760.png'        WHERE sku = 'mb-02';
UPDATE productos SET imagen_url = 'Gigabyte X670E.jpg'      WHERE sku = 'mb-03';
UPDATE productos SET imagen_url = 'Intel i9-14900K.jpg'     WHERE sku = 'cpu-i9';
UPDATE productos SET imagen_url = 'AMD Ryzen 9 7950X.jpg'   WHERE sku = 'cpu-r9';
UPDATE productos SET imagen_url = 'AMD Ryzen 5 7600X.jpg'   WHERE sku = 'cpu-r5';
UPDATE productos SET imagen_url = 'Corsair Dominator DDR5.jpg' WHERE sku = 'ram-01';
UPDATE productos SET imagen_url = 'G.Skill Trident Z5.jpg'  WHERE sku = 'ram-02';
UPDATE productos SET imagen_url = 'Kingston Fury Beast.jpg'  WHERE sku = 'ram-03';
UPDATE productos SET imagen_url = 'Samsung 990 Pro.jpg'     WHERE sku = 'ssd-01';
UPDATE productos SET imagen_url = 'WD Black SN850X.jpg'     WHERE sku = 'ssd-02';
UPDATE productos SET imagen_url = 'Seagate Barracuda 4TB.jpg' WHERE sku = 'hdd-01';
UPDATE productos SET imagen_url = 'Crucial P5 Plus.jpg'     WHERE sku = 'ssd-03';
UPDATE productos SET imagen_url = 'Logitech G Pro X TKL.jpg' WHERE sku = 'per-kb';
UPDATE productos SET imagen_url = 'Razer DeathAdder V3.jpg' WHERE sku = 'per-ms';
UPDATE productos SET imagen_url = 'HyperX Cloud Alpha.jpg'  WHERE sku = 'per-hd';
UPDATE productos SET imagen_url = 'SteelSeries Rival 650.jpg' WHERE sku = 'per-ms2';
