-- ==============================================================
--  INNOVATECH — db_update.sql
--  Migración: añade columna rol a clientes y crea admin.
--
--  Cómo ejecutar:
--  1. Importa innovatech.sql primero (crea BD + tablas + datos)
--  2. Luego ejecuta ESTE archivo en phpMyAdmin
--  3. Verifica que el admin puede iniciar sesión en login.html
-- ==============================================================

USE railway;

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
        '$2y$10$h1z61BOJp./Z4abne5J53uVA7o/6g/giZUEz2sZ.1pmY859Y0CfEK',
        'admin', 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), rol = VALUES(rol);
