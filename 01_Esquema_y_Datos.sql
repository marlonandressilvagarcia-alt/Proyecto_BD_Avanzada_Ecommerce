CREATE DATABASE IF NOT EXISTS Ecommerce;
USE Ecommerce;

CREATE TABLE IF NOT EXISTS Categorias (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS Proveedores (
    id_proveedor INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email_contacto VARCHAR(100) UNIQUE,
    telefono_contacto VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    contraseña VARCHAR(100) NOT NULL,
    direccion_envio VARCHAR(150),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Productos (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    costo DECIMAL(10,2) NOT NULL CHECK (costo >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    sku VARCHAR(50) NOT NULL UNIQUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo BOOL DEFAULT TRUE,
    id_categoria INT NOT NULL,
    id_proveedor INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES Categorias (id_categoria),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedores (id_proveedor)
);

CREATE TABLE IF NOT EXISTS Ventas (
    id_venta INT PRIMARY KEY AUTO_INCREMENT,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL DEFAULT 'Pendiente de Pago',
    total DECIMAL(10,2) DEFAULT 0.00,
    id_cliente INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Clientes (id_cliente)
);

CREATE TABLE IF NOT EXISTS Detalle_de_ventas (
    id_detalle INT PRIMARY KEY AUTO_INCREMENT,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_congelado DECIMAL(10,2) NOT NULL,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES Ventas (id_venta),
    FOREIGN KEY (id_producto) REFERENCES Productos (id_producto)
);

CREATE TABLE IF NOT EXISTS Sucursales (
    id_sucursal INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL
);

ALTER TABLE Categorias 
ADD COLUMN cantidad_productos INT DEFAULT 0 CHECK (cantidad_productos >= 0);

ALTER TABLE Clientes 
ADD COLUMN ciudad VARCHAR(100) DEFAULT 'Bogotá',
ADD COLUMN fecha_nacimiento DATE,
ADD COLUMN total_gastado DECIMAL(10,2) DEFAULT 0.00 CHECK (total_gastado >= 0),
ADD COLUMN id_sucursal INT,
ADD COLUMN id_referidor INT,
ADD CONSTRAINT fk_cliente_sucursal FOREIGN KEY (id_sucursal) REFERENCES Sucursales(id_sucursal),
ADD CONSTRAINT fk_cliente_referidor FOREIGN KEY (id_referidor) REFERENCES Clientes(id_cliente);

ALTER TABLE Productos 
ADD COLUMN stock_minimo INT NOT NULL DEFAULT 5 CHECK (stock_minimo >= 0),
ADD COLUMN peso_kg DECIMAL(5,2) DEFAULT 1.00 CHECK (peso_kg > 0),
ADD COLUMN fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE Ventas 
ADD COLUMN id_sucursal INT NOT NULL DEFAULT 1,
ADD CONSTRAINT fk_venta_sucursal FOREIGN KEY (id_sucursal) REFERENCES Sucursales(id_sucursal);

CREATE TABLE IF NOT EXISTS Alertas_Stock (
    id_alerta INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    mensaje VARCHAR(255) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES Productos (id_producto)
);

CREATE TABLE IF NOT EXISTS Log_Precios (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    precio_anterior DECIMAL(10,2),
    precio_nuevo DECIMAL(10,2),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES Productos (id_producto)
);

CREATE TABLE IF NOT EXISTS Vistas_Productos (
    id_vista INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_cliente INT,
    fecha_vista DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES Productos (id_producto),
    FOREIGN KEY (id_cliente) REFERENCES Clientes (id_cliente)
);

CREATE TABLE IF NOT EXISTS Promociones (
    id_promocion INT PRIMARY KEY AUTO_INCREMENT,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    porcentaje_descuento DECIMAL(5,2) NOT NULL,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME NOT NULL,
    activa BOOL DEFAULT TRUE
);


INSERT INTO Sucursales (nombre, ciudad) VALUES
('Sucursal Central', 'Bogotá'),
('Sucursal Norte', 'Medellín'),
('Sucursal Occidente', 'Cali');

INSERT INTO Categorias (nombre, descripcion) VALUES
('Tecnología', 'Dispositivos electrónicos, computadores y gadgets'),
('Ropa', 'Prendas de vestir masculinas, femeninas e infantiles'),
('Electrodomésticos', 'Aparatos eléctricos para el hogar y la cocina'),
('General', 'Categoría por defecto para productos sin clasificar');

INSERT INTO Proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechSupply S.A.', 'contacto@techsupply.com', '3001234567'),
('Moda Express Ltda.', 'ventas@modaexpress.com', '3109876543'),
('ElectroHogar Inc.', 'info@electrohogar.com', '3205551234'),
('Global Trade Co.', 'servicio@globaltrade.com', '3154448899'),
('Distribuidora Digital', 'soporte@distdigital.com', '3017773322');

INSERT INTO Clientes (nombre, apellido, email, contraseña, direccion_envio, ciudad, fecha_nacimiento, fecha_registro, id_sucursal, id_referidor) VALUES
('Carlos', 'Mendoza', 'carlos.mendoza@email.com', 'HashPass123!', 'Calle 100 #15-20', 'Bogotá', '1990-05-12', '2025-01-15 10:00:00', 1, NULL),
('Ana', 'Gomez', 'ana.gomez@email.com', 'SecureKey456!', 'Carrera 43A #1-50', 'Medellín', '1985-08-22', '2025-02-01 11:30:00', 2, 1),
('Juan', 'Rodriguez', 'juan.rodriguez@email.com', 'PassWord789!', 'Avenida 6N #26-10', 'Cali', '1998-12-03', '2025-02-10 14:15:00', 3, 1),
('Laura', 'Martinez', 'laura.martinez@email.com', 'LauraPass2025', 'Calle 72 #9-55', 'Bogotá', '2001-03-30', '2025-03-05 09:20:00', 1, 2),
('Diego', 'Hernandez', 'diego.hernandez@email.com', 'DiegoSafe321', 'Carrera 7 #45-10', 'Bogotá', '1992-11-18', '2025-03-12 16:40:00', 1, NULL),
('Sofia', 'Lopez', 'sofia.lopez@email.com', 'SofiClave654', 'Calle 10 #30-15', 'Medellín', '1995-07-04', '2025-03-20 18:00:00', 2, NULL),
('Mateo', 'Ramirez', 'mateo.ramirez@email.com', 'MateoPsw987', 'Carrera 100 #11-30', 'Cali', '1988-01-25', '2025-04-01 08:10:00', 3, NULL),
('Valentina', 'Torres', 'valentina.torres@email.com', 'ValenKey111', 'Calle 170 #20-05', 'Bogotá', '2003-09-14', '2025-04-10 12:00:00', 1, 4),
('Gabriel', 'Vargas', 'gabriel.vargas@email.com', 'GabiPass222', 'Calle 33 #65-20', 'Medellín', '1991-04-02', '2025-04-15 15:50:00', 2, NULL),
('Camila', 'Castro', 'camila.castro@email.com', 'CamiSecure333', 'Carrera 1 #10-00', 'Cali', '1997-06-28', '2025-04-20 17:30:00', 3, 3);

INSERT INTO Productos (nombre, descripcion, precio, costo, stock, stock_minimo, peso_kg, sku, id_categoria, id_proveedor) VALUES
('Laptop Pro 15', 'Portátil de alto rendimiento i7 16GB RAM', 4500000.00, 3200000.00, 15, 3, 2.10, 'TEC-001', 1, 1),
('Smartphone X10', 'Teléfono móvil 128GB cámara 48MP', 1800000.00, 1100000.00, 25, 5, 0.40, 'TEC-002', 1, 1),
('Audífonos Wireless BT', 'Audífonos Bluetooth con cancelación de ruido', 350000.00, 180000.00, 40, 8, 0.25, 'TEC-003', 1, 5),
('Monitor Gamer 27', 'Monitor 144Hz IPS 1ms QHD', 1200000.00, 800000.00, 8, 2, 5.50, 'TEC-004', 1, 1),
('Teclado Mecánico RGB', 'Teclado mecánico switches red español', 280000.00, 140000.00, 30, 5, 1.10, 'TEC-005', 1, 5),
('Mouse Inalámbrico Pro', 'Mouse ergonómico 16000 DPI', 150000.00, 75000.00, 50, 10, 0.15, 'TEC-006', 1, 5),
('Tablet Touch 10', 'Tablet Android 64GB pantalla HD', 750000.00, 480000.00, 12, 4, 0.60, 'TEC-007', 1, 1),
('Reloj Inteligente Fit', 'Smartwatch con sensor de ritmo cardíaco', 220000.00, 110000.00, 3, 5, 0.10, 'TEC-008', 1, 5),
('Cámara Web HD 1080p', 'Webcam micrófono integrado para streaming', 180000.00, 90000.00, 2, 4, 0.30, 'TEC-009', 1, 1),
('Disco Duro Externo 2TB', 'Almacenamiento USB 3.0 resistente', 320000.00, 200000.00, 18, 5, 0.35, 'TEC-010', 1, 5),
('Camiseta Algodón Premium', 'Camiseta básica 100% algodón', 60000.00, 25000.00, 100, 15, 0.20, 'ROP-001', 2, 2),
('Jeans Slim Fit', 'Pantalón de mezclilla azul oscuro', 140000.00, 65000.00, 45, 10, 0.70, 'ROP-002', 2, 2),
('Chaqueta Impermeable', 'Chaqueta ligera con capucha para lluvia', 220000.00, 100000.00, 20, 5, 0.85, 'ROP-003', 2, 2),
('Zapatillas Deportivas', 'Calzado cómodo para correr', 260000.00, 130000.00, 25, 6, 0.90, 'ROP-004', 2, 4),
('Buzo con Capucha', 'Buzo térmico diseño casual', 110000.00, 48000.00, 35, 8, 0.65, 'ROP-005', 2, 2),
('Nevera No Frost 300L', 'Refrigerador de bajo consumo clase A', 2100000.00, 1450000.00, 6, 2, 55.00, 'ELE-001', 3, 3),
('Lavadora Carga Frontal 15kg', 'Lavadora automática con ciclos rápidos', 1850000.00, 1250000.00, 5, 2, 62.00, 'ELE-002', 3, 3),
('Microondas Digital 20L', 'Horno microondas 800W con grill', 380000.00, 220000.00, 14, 4, 11.00, 'ELE-003', 3, 3),
('Licuadora de Alta Potencia', 'Licuadora vaso de vidrio 1000W', 190000.00, 95000.00, 22, 5, 3.20, 'ELE-004', 3, 3),
('Cafetera de Goteo', 'Cafetera programable 12 tazas', 130000.00, 65000.00, 16, 4, 2.10, 'ELE-005', 3, 3);

UPDATE Categorias SET cantidad_productos = 10 WHERE id_categoria = 1;
UPDATE Categorias SET cantidad_productos = 5 WHERE id_categoria = 2;
UPDATE Categorias SET cantidad_productos = 5 WHERE id_categoria = 3;

INSERT INTO Ventas (fecha_venta, estado, total, id_cliente, id_sucursal) VALUES
('2025-02-15 10:30:00', 'Entregado', 4850000.00, 1, 1),
('2025-02-20 14:20:00', 'Entregado', 2150000.00, 2, 2),
('2025-03-01 09:15:00', 'Entregado', 200000.00, 1, 1),
('2025-03-10 16:45:00', 'Entregado', 1480000.00, 3, 3),
('2025-03-15 11:00:00', 'Enviado', 2200000.00, 4, 1),
('2025-03-22 18:30:00', 'Procesando', 430000.00, 5, 1),
('2025-04-02 13:10:00', 'Pendiente de Pago', 1800000.00, 6, 2),
('2025-04-05 15:25:00', 'Entregado', 380000.00, 2, 2),
('2025-04-12 10:05:00', 'Entregado', 260000.00, 7, 3),
('2025-04-18 17:40:00', 'Cancelado', 190000.00, 8, 1);

INSERT INTO Detalle_de_ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) VALUES
(1, 1, 1, 4500000.00),
(1, 3, 1, 350000.00),
(2, 2, 1, 1800000.00),
(2, 3, 1, 350000.00),
(3, 11, 1, 60000.00),
(3, 12, 1, 140000.00),
(4, 4, 1, 1200000.00),
(4, 5, 1, 280000.00),
(5, 16, 1, 2100000.00),
(5, 15, 1, 110000.00),
(6, 6, 1, 150000.00),
(6, 5, 1, 280000.00),
(7, 2, 1, 1800000.00),
(8, 18, 1, 380000.00),
(9, 14, 1, 260000.00),
(10, 19, 1, 190000.00);

UPDATE Clientes SET total_gastado = 5050000.00 WHERE id_cliente = 1;
UPDATE Clientes SET total_gastado = 2530000.00 WHERE id_cliente = 2;
UPDATE Clientes SET total_gastado = 1480000.00 WHERE id_cliente = 3;
UPDATE Clientes SET total_gastado = 0.00 WHERE id_cliente = 4;
UPDATE Clientes SET total_gastado = 260000.00 WHERE id_cliente = 7;

INSERT INTO Promociones (codigo, porcentaje_descuento, fecha_inicio, fecha_fin, activa) VALUES
('PROMO10', 10.00, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE),
('EXPIRED20', 20.00, '2025-01-01 00:00:00', '2025-03-01 00:00:00', TRUE);

INSERT INTO Vistas_Productos (id_producto, id_cliente) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
(2, 2), (2, 6), (2, 7),
(3, 1), (3, 2), (3, 8),
(8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 8);








