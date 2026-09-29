-- SECCIÓN 7: TRIGGERS (DISPARADORES) - VERSIÓN JUNIOR
-- Base de Datos: Ecommerce | Entorno: MySQL + DBeaver

USE Ecommerce;

-- PREPARACIÓN: CREACIÓN DE TABLAS DE APOYO
CREATE TABLE IF NOT EXISTS Log_Precios (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT,
    precio_anterior DECIMAL(10,2),
    precio_nuevo DECIMAL(10,2),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) DEFAULT (CURRENT_USER())
);

CREATE TABLE IF NOT EXISTS Log_Clientes (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    nombre VARCHAR(100),
    email VARCHAR(100),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Log_Estados_Pedido (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Alertas_Stock (
    id_alerta INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT,
    stock_actual INT,
    mensaje VARCHAR(255),
    fecha_alerta DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Ventas_Archivo (
    id_venta INT PRIMARY KEY,
    id_cliente INT,
    fecha_venta DATETIME,
    total DECIMAL(10,2),
    estado VARCHAR(50),
    fecha_eliminacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Log_Permisos_Usuarios (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(100),
    accion VARCHAR(255),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- PREPARACIÓN: AGREGAR COLUMNAS DE APOYO
-- Nota: Si DBeaver muestra una advertencia de que la columna ya existe, presiona "Saltar" o "Skip"
ALTER TABLE Clientes ADD COLUMN total_gastado DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE Clientes ADD COLUMN fecha_ultimo_pedido DATETIME DEFAULT NULL;
ALTER TABLE Clientes ADD COLUMN id_referidor INT DEFAULT NULL;
ALTER TABLE Productos ADD COLUMN fecha_modificacion DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE Categorias ADD COLUMN total_productos INT DEFAULT 0;


-- 1. trg_audit_precio_producto_after_update: Guarda un log de cambios de precios.
DELIMITER //
CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO Log_Precios (id_producto, precio_anterior, precio_nuevo)
        VALUES (NEW.id_producto, OLD.precio, NEW.precio);
    END IF;
END //
DELIMITER ;

-- 2. trg_check_stock_before_insert_venta: Verifica el stock antes de registrar una venta.
DELIMITER //
CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON Detalle_de_ventas
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;
    
    SELECT stock INTO v_stock 
    FROM Productos 
    WHERE id_producto = NEW.id_producto;
    
    IF v_stock < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Stock insuficiente para realizar la venta.';
    END IF;
END //
DELIMITER ;

-- 3. trg_update_stock_after_insert_venta: Decrementa el stock después de una venta.
DELIMITER //
CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON Detalle_de_ventas
FOR EACH ROW
BEGIN
    UPDATE Productos 
    SET stock = stock - NEW.cantidad 
    WHERE id_producto = NEW.id_producto;
END //
DELIMITER ;

-- 4. trg_prevent_delete_categoria_with_products: Impide eliminar una categoría si tiene productos asociados.
DELIMITER //
CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON Categorias
FOR EACH ROW
BEGIN
    DECLARE v_cantidad INT;
    
    SELECT COUNT(*) INTO v_cantidad 
    FROM Productos 
    WHERE id_categoria = OLD.id_categoria;
    
    IF v_cantidad > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: No se puede eliminar la categoria porque tiene productos.';
    END IF;
END //
DELIMITER ;

-- 5. trg_log_new_customer_after_insert: Registra en una tabla de auditoría cada vez que se crea un nuevo cliente.
DELIMITER //
CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO Log_Clientes (id_cliente, nombre, email)
    VALUES (NEW.id_cliente, CONCAT(NEW.nombre, ' ', NEW.apellido), NEW.email);
END //
DELIMITER ;

-- 6. trg_update_total_gastado_cliente: Actualiza el total gastado en clientes después de una compra.
DELIMITER //
CREATE TRIGGER trg_update_total_gastado_cliente
AFTER INSERT ON Ventas
FOR EACH ROW
BEGIN
    UPDATE Clientes 
    SET total_gastado = total_gastado + NEW.total
    WHERE id_cliente = NEW.id_cliente;
END //
DELIMITER ;

-- 7. trg_set_fecha_modificacion_producto: Actualiza la fecha de última modificación de un producto.
DELIMITER //
CREATE TRIGGER trg_set_fecha_modificacion_producto
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN
    SET NEW.fecha_modificacion = NOW();
END //
DELIMITER ;

-- 8. trg_prevent_negative_stock: Impide que el stock de un producto se actualice a un valor negativo.
DELIMITER //
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN
    IF NEW.stock < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El stock no puede ser negativo.';
    END IF;
END //
DELIMITER ;

-- 9. trg_capitalize_nombre_cliente: Pone la primera letra del nombre y apellido en mayúscula.
DELIMITER //
CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON Clientes
FOR EACH ROW
BEGIN
    SET NEW.nombre = CONCAT(UPPER(SUBSTRING(NEW.nombre, 1, 1)), LOWER(SUBSTRING(NEW.nombre, 2)));
    SET NEW.apellido = CONCAT(UPPER(SUBSTRING(NEW.apellido, 1, 1)), LOWER(SUBSTRING(NEW.apellido, 2)));
END //
DELIMITER ;

-- 10. trg_recalculate_total_venta_on_detalle_change: Recalcula el total de la venta si se modifica un detalle.
DELIMITER //
CREATE TRIGGER trg_recalculate_total_venta_on_detalle_change
AFTER UPDATE ON Detalle_de_ventas
FOR EACH ROW
BEGIN
    DECLARE v_nuevo_total DECIMAL(10,2);
    
    SELECT SUM(subtotal) INTO v_nuevo_total 
    FROM Detalle_de_ventas 
    WHERE id_venta = NEW.id_venta;
    
    UPDATE Ventas 
    SET total = v_nuevo_total
    WHERE id_venta = NEW.id_venta;
END //
DELIMITER ;

-- 11. trg_log_order_status_change: Audita cada cambio de estado en un pedido.
DELIMITER //
CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON Ventas
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO Log_Estados_Pedido (id_venta, estado_anterior, estado_nuevo)
        VALUES (NEW.id_venta, OLD.estado, NEW.estado);
    END IF;
END //
DELIMITER ;

-- 12. trg_prevent_price_zero_or_less: Impide que el precio sea cero o negativo al insertar.
DELIMITER //
CREATE TRIGGER trg_prevent_price_zero_or_less
BEFORE INSERT ON Productos
FOR EACH ROW
BEGIN
    IF NEW.precio <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El precio debe ser mayor a cero.';
    END IF;
END //
DELIMITER ;

-- 13. trg_send_stock_alert_on_low_stock: Inserta un registro en alertas si el stock es bajo (5 o menos).
DELIMITER //
CREATE TRIGGER trg_send_stock_alert_on_low_stock
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN
    IF NEW.stock <= 5 AND OLD.stock > 5 THEN
        INSERT INTO Alertas_Stock (id_producto, stock_actual, mensaje)
        VALUES (NEW.id_producto, NEW.stock, 'Alerta: El stock de este producto es bajo.');
    END IF;
END //
DELIMITER ;

-- 14. trg_archive_deleted_venta: Copia una venta borrada a una tabla de archivo.
DELIMITER //
CREATE TRIGGER trg_archive_deleted_venta
BEFORE DELETE ON Ventas
FOR EACH ROW
BEGIN
    INSERT INTO Ventas_Archivo (id_venta, id_cliente, fecha_venta, total, estado)
    VALUES (OLD.id_venta, OLD.id_cliente, OLD.fecha_venta, OLD.total, OLD.estado);
END //
DELIMITER ;

-- 15. trg_validate_email_format_on_customer: Valida que el email contenga un arroba (@) y un punto (.).
DELIMITER //
CREATE TRIGGER trg_validate_email_format_on_customer
BEFORE INSERT ON Clientes
FOR EACH ROW
BEGIN
    IF NEW.email NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Formato de correo invalido.';
    END IF;
END //
DELIMITER ;

-- 16. trg_update_last_order_date_customer: Actualiza la fecha del último pedido en clientes.
DELIMITER //
CREATE TRIGGER trg_update_last_order_date_customer
AFTER INSERT ON Ventas
FOR EACH ROW
BEGIN
    UPDATE Clientes 
    SET fecha_ultimo_pedido = NEW.fecha_venta
    WHERE id_cliente = NEW.id_cliente;
END //
DELIMITER ;

-- 17. trg_prevent_self_referral: Impide que un cliente se recomiende a sí mismo.
DELIMITER //
CREATE TRIGGER trg_prevent_self_referral
BEFORE UPDATE ON Clientes
FOR EACH ROW
BEGIN
    IF NEW.id_referidor IS NOT NULL AND NEW.id_referidor = NEW.id_cliente THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Un cliente no puede referenciarse a si mismo.';
    END IF;
END //
DELIMITER ;

-- 18. trg_log_permission_changes: Registra un log cuando un cliente cambia su correo.
DELIMITER //
CREATE TRIGGER trg_log_permission_changes
AFTER UPDATE ON Clientes
FOR EACH ROW
BEGIN
    IF OLD.email <> NEW.email THEN
        INSERT INTO Log_Permisos_Usuarios (usuario, accion)
        VALUES (CURRENT_USER(), CONCAT('Se cambio el correo del cliente ', NEW.id_cliente));
    END IF;
END //
DELIMITER ;

-- 19. trg_assign_default_category_on_null: Asigna la categoría 1 si el producto no trae categoría.
DELIMITER //
CREATE TRIGGER trg_assign_default_category_on_null
BEFORE INSERT ON Productos
FOR EACH ROW
BEGIN
    IF NEW.id_categoria IS NULL THEN
        SET NEW.id_categoria = 1; 
    END IF;
END //
DELIMITER ;

-- 20. trg_update_producto_count_in_categoria: Suma 1 al contador de productos de la categoría.
DELIMITER //
CREATE TRIGGER trg_update_producto_count_in_categoria
AFTER INSERT ON Productos
FOR EACH ROW
BEGIN
    UPDATE Categorias 
    SET total_productos = total_productos + 1
    WHERE id_categoria = NEW.id_categoria;
END //
DELIMITER ;

