-- ==============================================================
--  INNOVATECH — innovatech.sql (Base de datos completa)
--  Dump SQL con estructura + datos iniciales para XAMPP.
--  Contiene 9 tablas y 20 productos de ejemplo.
--
--  Cómo importar:
--  1. Abre http://localhost/phpmyadmin
--  2. Clic en "Importar" (menú superior)
--  3. Selecciona este archivo y haz clic en "Importar"
--  ¡Listo! La BD se crea con todas las tablas y datos.
--
--  Post-importación: ejecuta db_update.sql para añadir
--  la columna 'rol', el admin y las rutas de imágenes.
-- ==============================================================

-- ==============================================================
--  Eliminar y recrear la BD (start fresh)
--  ⚠ ADVERTENCIA: Esto borra cualquier dato existente en la
--    base de datos 'innovatech'.
-- ==============================================================
DROP DATABASE IF EXISTS railway;
CREATE DATABASE railway
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE railway;

-- ==============================================================
-- TABLA 1: categorias
-- ==============================================================
CREATE TABLE categorias (
  id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(80)      NOT NULL,
  emoji       VARCHAR(20)      NOT NULL DEFAULT '',
  descripcion TEXT,
  activa      TINYINT(1)       NOT NULL DEFAULT 1,
  creado_en   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cat_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 2: productos
-- ==============================================================
CREATE TABLE productos (
  id               INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  sku              VARCHAR(30)      NOT NULL,
  nombre           VARCHAR(150)     NOT NULL,
  categoria_id     INT UNSIGNED     NOT NULL,
  especificaciones VARCHAR(255)     DEFAULT NULL,
  descripcion      TEXT             DEFAULT NULL,
  precio           DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
  precio_anterior  DECIMAL(10,2)    DEFAULT NULL,
  stock            INT UNSIGNED     NOT NULL DEFAULT 0,
  emoji            VARCHAR(20)      DEFAULT NULL,
  badge            VARCHAR(40)      DEFAULT NULL,
  badge_tipo       VARCHAR(10)      DEFAULT NULL,
  destacado        TINYINT(1)       NOT NULL DEFAULT 0,
  activo           TINYINT(1)       NOT NULL DEFAULT 1,
  creado_en        TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado      TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sku (sku),
  KEY idx_categoria (categoria_id),
  KEY idx_destacado (destacado),
  KEY idx_activo    (activo),
  KEY idx_stock     (stock),
  CONSTRAINT fk_prod_cat
    FOREIGN KEY (categoria_id) REFERENCES categorias (id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 3: clientes
-- ==============================================================
CREATE TABLE clientes (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(100)     NOT NULL,
  email         VARCHAR(150)     NOT NULL,
  telefono      VARCHAR(20)      DEFAULT NULL,
  password_hash VARCHAR(255)     DEFAULT NULL,
  activo        TINYINT(1)       NOT NULL DEFAULT 1,
  creado_en     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 4: direcciones
-- ==============================================================
CREATE TABLE direcciones (
  id             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  cliente_id     INT UNSIGNED     NOT NULL,
  alias          VARCHAR(50)      NOT NULL DEFAULT 'Casa',
  direccion      VARCHAR(255)     NOT NULL,
  ciudad         VARCHAR(80)      NOT NULL DEFAULT 'Managua',
  departamento   VARCHAR(80)      NOT NULL DEFAULT 'Managua',
  pais           VARCHAR(60)      NOT NULL DEFAULT 'Nicaragua',
  referencia     TEXT             DEFAULT NULL,
  predeterminada TINYINT(1)       NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_dir_cliente (cliente_id),
  CONSTRAINT fk_dir_cliente
    FOREIGN KEY (cliente_id) REFERENCES clientes (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 5: pedidos
-- ==============================================================
CREATE TABLE pedidos (
  id              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  numero_orden    VARCHAR(20)      NOT NULL,
  cliente_id      INT UNSIGNED     DEFAULT NULL,
  nombre_cliente  VARCHAR(100)     NOT NULL,
  email_cliente   VARCHAR(150)     NOT NULL,
  telefono        VARCHAR(20)      DEFAULT NULL,
  direccion       VARCHAR(255)     NOT NULL DEFAULT '',
  ciudad          VARCHAR(80)      NOT NULL DEFAULT 'Managua',
  departamento    VARCHAR(80)      NOT NULL DEFAULT 'Managua',
  notas           TEXT             DEFAULT NULL,
  subtotal        DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
  costo_envio     DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
  descuento       DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
  total           DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
  metodo_pago     VARCHAR(20)      NOT NULL DEFAULT 'efectivo',
  estado_pago     VARCHAR(20)      NOT NULL DEFAULT 'pendiente',
  estado          VARCHAR(20)      NOT NULL DEFAULT 'nuevo',
  notas_internas  TEXT             DEFAULT NULL,
  creado_en       TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_numero_orden (numero_orden),
  KEY idx_ped_cliente (cliente_id),
  KEY idx_ped_estado  (estado),
  KEY idx_ped_creado  (creado_en),
  CONSTRAINT fk_ped_cliente
    FOREIGN KEY (cliente_id) REFERENCES clientes (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 6: pedido_items
-- ==============================================================
CREATE TABLE pedido_items (
  id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  pedido_id   INT UNSIGNED     NOT NULL,
  producto_id INT UNSIGNED     NOT NULL,
  nombre      VARCHAR(150)     NOT NULL,
  sku         VARCHAR(30)      NOT NULL,
  precio_unit DECIMAL(10,2)    NOT NULL,
  cantidad    INT UNSIGNED     NOT NULL DEFAULT 1,
  subtotal    DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
  PRIMARY KEY (id),
  KEY idx_item_pedido   (pedido_id),
  KEY idx_item_producto (producto_id),
  CONSTRAINT fk_item_pedido
    FOREIGN KEY (pedido_id)   REFERENCES pedidos   (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_item_producto
    FOREIGN KEY (producto_id) REFERENCES productos (id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 7: contacto_mensajes
-- ==============================================================
CREATE TABLE contacto_mensajes (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre     VARCHAR(100)     NOT NULL,
  email      VARCHAR(150)     NOT NULL,
  telefono   VARCHAR(20)      DEFAULT NULL,
  asunto     VARCHAR(200)     DEFAULT NULL,
  mensaje    TEXT             NOT NULL,
  leido      TINYINT(1)       NOT NULL DEFAULT 0,
  respondido TINYINT(1)       NOT NULL DEFAULT 0,
  creado_en  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 8: historial_stock
-- ==============================================================
CREATE TABLE historial_stock (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  producto_id   INT UNSIGNED     NOT NULL,
  tipo          VARCHAR(15)      NOT NULL DEFAULT 'salida',
  cantidad      INT              NOT NULL DEFAULT 0,
  stock_antes   INT UNSIGNED     NOT NULL DEFAULT 0,
  stock_despues INT UNSIGNED     NOT NULL DEFAULT 0,
  referencia    VARCHAR(50)      DEFAULT NULL,
  notas         TEXT             DEFAULT NULL,
  creado_en     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_hstock_prod (producto_id),
  CONSTRAINT fk_hstock_prod
    FOREIGN KEY (producto_id) REFERENCES productos (id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================
-- TABLA 9: banners_promocionales
-- ==============================================================
CREATE TABLE banners_promocionales (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  titulo        VARCHAR(150)     NOT NULL,
  subtitulo     VARCHAR(255)     DEFAULT NULL,
  producto_id   INT UNSIGNED     DEFAULT NULL,
  descuento_pct TINYINT UNSIGNED DEFAULT NULL,
  imagen_url    VARCHAR(300)     DEFAULT NULL,
  activo        TINYINT(1)       NOT NULL DEFAULT 1,
  fecha_inicio  DATE             DEFAULT NULL,
  fecha_fin     DATE             DEFAULT NULL,
  creado_en     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_banner_prod
    FOREIGN KEY (producto_id) REFERENCES productos (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================
--  DATOS: CATEGORÍAS (6 categorías)
-- ==============================================================
INSERT INTO categorias (nombre, emoji, descripcion) VALUES
  ('Tarjetas Madres',   '🖥️',  'Placas base Intel y AMD, ATX, mATX y Mini-ITX'),
  ('Tarjetas Gráficas', '🎮',  'GPUs NVIDIA GeForce y AMD Radeon para gaming'),
  ('Procesadores',      '⚙️',  'CPUs Intel Core y AMD Ryzen de última generación'),
  ('Memorias RAM',      '💾',  'Módulos DDR4 y DDR5 para escritorio y laptop'),
  ('Almacenamiento',    '💿',  'SSD NVMe, SSD SATA, HDD y unidades M.2'),
  ('Periféricos',       '🎧',  'Teclados, ratones, audífonos y accesorios gaming');


-- ==============================================================
--  DATOS: PRODUCTOS (20 productos)
-- ==============================================================

-- ── Tarjetas Madres (categoria_id = 1) ──
INSERT INTO productos
  (sku, nombre, categoria_id, especificaciones, precio, precio_anterior, stock, emoji, badge, badge_tipo, destacado)
VALUES
  ('mb-01',
   'ASUS ROG Strix Z790-E',
   1,
   'Socket LGA1700 - DDR5 - Wi-Fi 6E',
   449.00, NULL, 12, '🖥️', 'Top Seller', 'cyan', 1),

  ('mb-02',
   'MSI MAG B760M Mortar',
   1,
   'Socket LGA1700 - DDR4/DDR5 - mATX',
   189.00, NULL, 25, '🖥️', NULL, NULL, 0),

  ('mb-03',
   'Gigabyte X670E Aorus Master',
   1,
   'Socket AM5 - DDR5 - PCIe 5.0',
   529.00, NULL, 8, '🖥️', 'Nuevo', 'azul', 0);

-- ── Tarjetas Gráficas (categoria_id = 2) ──
INSERT INTO productos
  (sku, nombre, categoria_id, especificaciones, precio, precio_anterior, stock, emoji, badge, badge_tipo, destacado)
VALUES
  ('gpu-rtx5090',
   'NVIDIA RTX 5090 Ti 32 GB',
   2,
   'GDDR7 - PCIe 5.0 - 450W TDP',
   1149.00, 1499.00, 5, '🎮', 'Oferta', 'rojo', 1),

  ('gpu-rx7900',
   'AMD Radeon RX 7900 XTX',
   2,
   '24 GB GDDR6 - PCIe 4.0 - 355W',
   879.00, NULL, 7, '🎮', NULL, NULL, 1),

  ('gpu-rtx4070',
   'NVIDIA RTX 4070 Super 12 GB',
   2,
   'GDDR6X - PCIe 4.0 - 220W',
   599.00, 699.00, 0, '🎮', 'Oferta', 'rojo', 0);

-- ── Procesadores (categoria_id = 3) ──
INSERT INTO productos
  (sku, nombre, categoria_id, especificaciones, precio, precio_anterior, stock, emoji, badge, badge_tipo, destacado)
VALUES
  ('cpu-i9',
   'Intel Core i9-14900K',
   3,
   '24 núcleos - 5.8 GHz boost - 125W',
   549.00, NULL, 14, '⚙️', 'Top', 'cyan', 1),

  ('cpu-r9',
   'AMD Ryzen 9 7950X',
   3,
   '16 núcleos - 5.7 GHz - AM5 - 170W',
   699.00, NULL, 9, '⚙️', NULL, NULL, 0),

  ('cpu-r5',
   'AMD Ryzen 5 7600X',
   3,
   '6 núcleos - 5.3 GHz - AM5 - 105W',
   249.00, 299.00, 20, '⚙️', 'Oferta', 'rojo', 0);

-- ── Memorias RAM (categoria_id = 4) ──
INSERT INTO productos
  (sku, nombre, categoria_id, especificaciones, precio, precio_anterior, stock, emoji, badge, badge_tipo, destacado)
VALUES
  ('ram-01',
   'Corsair Dominator 32 GB DDR5',
   4,
   'DDR5-6000 - CL36 - RGB',
   169.00, NULL, 30, '💾', NULL, NULL, 0),

  ('ram-02',
   'G.Skill Trident Z5 64 GB DDR5',
   4,
   'DDR5-6400 - CL32 - Kit 2x32 GB',
   289.00, NULL, 15, '💾', 'Nuevo', 'azul', 1),

  ('ram-03',
   'Kingston Fury Beast 16 GB DDR4',
   4,
   'DDR4-3600 - CL17 - Kit 2x8 GB',
   69.00, NULL, 50, '💾', NULL, NULL, 0);

-- ── Almacenamiento (categoria_id = 5) ──
INSERT INTO productos
  (sku, nombre, categoria_id, especificaciones, precio, precio_anterior, stock, emoji, badge, badge_tipo, destacado)
VALUES
  ('ssd-01',
   'Samsung 990 Pro 2 TB NVMe',
   5,
   'PCIe 5.0 M.2 - 12400 MB/s',
   219.00, NULL, 22, '💿', 'Top Seller', 'cyan', 1),

  ('ssd-02',
   'WD Black SN850X 1 TB',
   5,
   'PCIe 4.0 M.2 - 7300 MB/s NVMe 2.0',
   129.00, NULL, 18, '💿', NULL, NULL, 0),

  ('hdd-01',
   'Seagate Barracuda 4 TB HDD',
   5,
   'SATA III - 7200 RPM - 256 MB cache',
   79.00, NULL, 40, '💿', NULL, NULL, 0),

  ('ssd-03',
   'Crucial P5 Plus 500 GB SSD',
   5,
   'PCIe 4.0 NVMe M.2 - 6600 MB/s',
   59.00, 79.00, 35, '💿', 'Oferta', 'rojo', 0);

-- ── Periféricos (categoria_id = 6) ──
INSERT INTO productos
  (sku, nombre, categoria_id, especificaciones, precio, precio_anterior, stock, emoji, badge, badge_tipo, destacado)
VALUES
  ('per-kb',
   'Logitech G Pro X TKL',
   6,
   'Teclado mecanico - RGB - inalambrico',
   149.00, NULL, 17, '⌨️', NULL, NULL, 1),

  ('per-ms',
   'Razer DeathAdder V3 Pro',
   6,
   'Mouse inalambrico - 63 g - 30000 DPI',
   119.00, NULL, 23, '🖱️', 'Nuevo', 'azul', 0),

  ('per-hd',
   'HyperX Cloud Alpha Wireless',
   6,
   'Audifonos - 300 h bateria - 7.1 virtual',
   199.00, NULL, 0, '🎧', NULL, NULL, 0),

  ('per-ms2',
   'SteelSeries Rival 650 Wireless',
   6,
   'Mouse gaming - 256 DPI - dual sensor',
   89.00, 119.00, 11, '🖱️', 'Oferta', 'rojo', 0);


-- ==============================================================
--  BANNER PROMOCIONAL INICIAL
-- ==============================================================
INSERT INTO banners_promocionales (titulo, subtitulo, producto_id, descuento_pct, activo)
VALUES ('Oferta Especial RTX 5090 Ti', 'Semana de ofertas — 23% de descuento', 4, 23, 1);


-- ==============================================================
--  VERIFICACIÓN FINAL
--  Al importar verás estos conteos:
--    categorias       → 6 filas
--    productos        → 20 filas
--    pedidos          → 0 filas (se llenarán desde la web)
--    pedido_items     → 0 filas
--    contacto_mensajes→ 0 filas
-- ==============================================================
SELECT 'categorias'        AS tabla, COUNT(*) AS registros FROM categorias
UNION ALL
SELECT 'productos',                  COUNT(*)               FROM productos
UNION ALL
SELECT 'clientes',                   COUNT(*)               FROM clientes
UNION ALL
SELECT 'pedidos',                    COUNT(*)               FROM pedidos
UNION ALL
SELECT 'pedido_items',               COUNT(*)               FROM pedido_items
UNION ALL
SELECT 'contacto_mensajes',          COUNT(*)               FROM contacto_mensajes
UNION ALL
SELECT 'historial_stock',            COUNT(*)               FROM historial_stock
UNION ALL
SELECT 'banners_promocionales',      COUNT(*)               FROM banners_promocionales;

