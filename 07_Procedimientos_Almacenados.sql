-- SECCIÓN 9: PROCEDIMIENTOS ALMACENADOS
USE Ecommerce;

-- 1. sp_RealizarNuevaVenta
DROP PROCEDURE IF EXISTS sp_RealizarNuevaVenta;
DELIMITER //
CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_cantidad INT,
    IN p_precio_unitario DECIMAL(10,2)
)
BEGIN
    DECLARE v_id_venta INT;
    DECLARE v_subtotal DECIMAL(10,2);
    
    START TRANSACTION;
    SET v_subtotal = p_cantidad * p_precio_unitario;
    
    INSERT INTO Ventas (id_cliente, fecha_venta, total, estado)
    VALUES (p_id_cliente, NOW(), v_subtotal, 'Pendiente');
    
    SET v_id_venta = LAST_INSERT_ID();
    
    INSERT INTO Detalle_de_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal)
    VALUES (v_id_venta, p_id_producto, p_cantidad, p_precio_unitario, v_subtotal);
    
    COMMIT;
END //
DELIMITER ;

-- 2. sp_AgregarNuevoProducto
DROP PROCEDURE IF EXISTS sp_AgregarNuevoProducto;
DELIMITER //
CREATE PROCEDURE sp_AgregarNuevoProducto(
    IN p_nombre VARCHAR(100),
    IN p_precio DECIMAL(10,2),
    IN p_stock INT,
    IN p_id_categoria INT,
    IN p_id_proveedor INT
)
BEGIN
    INSERT INTO Productos (nombre, precio, stock, id_categoria, id_proveedor)
    VALUES (p_nombre, p_precio, p_stock, p_id_categoria, p_id_proveedor);
END //
DELIMITER ;

-- 3. sp_ActualizarDireccionCliente
DROP PROCEDURE IF EXISTS sp_ActualizarDireccionCliente;
DELIMITER //
CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_id_cliente INT,
    IN p_nueva_direccion VARCHAR(255)
)
BEGIN
    UPDATE Clientes 
    SET direccion = p_nueva_direccion 
    WHERE id_cliente = p_id_cliente;
END //
DELIMITER ;

-- 4. sp_ProcesarDevolucion
DROP PROCEDURE IF EXISTS sp_ProcesarDevolucion;
DELIMITER //
CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_id_venta INT,
    IN p_id_producto INT,
    IN p_cantidad INT
)
BEGIN
    START TRANSACTION;
    
    UPDATE Productos 
    SET stock = stock + p_cantidad 
    WHERE id_producto = p_id_producto;
    
    UPDATE Ventas 
    SET estado = 'Devuelto' 
    WHERE id_venta = p_id_venta;
    
    COMMIT;
END //
DELIMITER ;

-- 5. sp_ObtenerHistorialComprasCliente
DROP PROCEDURE IF EXISTS sp_ObtenerHistorialComprasCliente;
DELIMITER //
CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(
    IN p_id_cliente INT
)
BEGIN
    SELECT v.id_venta, v.fecha_venta, v.total, v.estado, dv.id_producto, p.nombre, dv.cantidad, dv.precio_unitario
    FROM Ventas v
    INNER JOIN Detalle_de_ventas dv ON v.id_venta = dv.id_venta
    INNER JOIN Productos p ON dv.id_producto = p.id_producto
    WHERE v.id_cliente = p_id_cliente
    ORDER BY v.fecha_venta DESC;
END //
DELIMITER ;

-- 6. sp_AjustarNivelStock
DROP PROCEDURE IF EXISTS sp_AjustarNivelStock;
DELIMITER //
CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_id_producto INT,
    IN p_nuevo_stock INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    UPDATE Productos 
    SET stock = p_nuevo_stock 
    WHERE id_producto = p_id_producto;
END //
DELIMITER ;

-- 7. sp_EliminarClienteDeFormaSegura
DROP PROCEDURE IF EXISTS sp_EliminarClienteDeFormaSegura;
DELIMITER //
CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(
    IN p_id_cliente INT
)
BEGIN
    UPDATE Clientes 
    SET nombre = 'Anonimo', 
        apellido = 'Anonimo', 
        email = CONCAT('anonimo_', p_id_cliente, '@deleted.com'),
        telefono = NULL,
        direccion = NULL
    WHERE id_cliente = p_id_cliente;
END //
DELIMITER ;

-- 8. sp_AplicarDescuentoPorCategoria
DROP PROCEDURE IF EXISTS sp_AplicarDescuentoPorCategoria;
DELIMITER //
CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_id_categoria INT,
    IN p_porcentaje_descuento DECIMAL(5,2)
)
BEGIN
    UPDATE Productos 
    SET precio = precio * (1 - (p_porcentaje_descuento / 100))
    WHERE id_categoria = p_id_categoria;
END //
DELIMITER ;

-- 9. sp_GenerarReporteMensualVentas
DROP PROCEDURE IF EXISTS sp_GenerarReporteMensualVentas;
DELIMITER //
CREATE PROCEDURE sp_GenerarReporteMensualVentas(
    IN p_mes INT,
    IN p_anio INT
)
BEGIN
    SELECT 
        COUNT(id_venta) AS total_ventas,
        IFNULL(SUM(total), 0) AS ingresos_totales,
        AVG(total) AS promedio_venta
    FROM Ventas
    WHERE MONTH(fecha_venta) = p_mes 
      AND YEAR(fecha_venta) = p_anio 
      AND estado <> 'Cancelado';
END //
DELIMITER ;

-- 10. sp_CambiarEstadoPedido
DROP PROCEDURE IF EXISTS sp_CambiarEstadoPedido;
DELIMITER //
CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN p_id_venta INT,
    IN p_nuevo_estado VARCHAR(50)
)
BEGIN
    UPDATE Ventas 
    SET estado = p_nuevo_estado 
    WHERE id_venta = p_id_venta;
END //
DELIMITER ;

-- 11. sp_RegistrarNuevoCliente
DROP PROCEDURE IF EXISTS sp_RegistrarNuevoCliente;
DELIMITER //
CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_direccion VARCHAR(255)
)
BEGIN
    IF EXISTS (SELECT 1 FROM Clientes WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: El email ya se encuentra registrado.';
    ELSE
        INSERT INTO Clientes (nombre, apellido, email, telefono, direccion)
        VALUES (p_nombre, p_apellido, p_email, p_telefono, p_direccion);
    END IF;
END //
DELIMITER ;

-- 12. sp_ObtenerDetallesProductoCompleto
DROP PROCEDURE IF EXISTS sp_ObtenerDetallesProductoCompleto;
DELIMITER //
CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(
    IN p_id_producto INT
)
BEGIN
    SELECT 
        p.id_producto, p.nombre AS producto, p.precio, p.stock,
        c.nombre AS categoria,
        pr.nombre AS proveedor, pr.contacto AS contacto_proveedor
    FROM Productos p
    LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
    LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
    WHERE p.id_producto = p_id_producto;
END //
DELIMITER ;

-- 13. sp_FusionarCuentasCliente
DROP PROCEDURE IF EXISTS sp_FusionarCuentasCliente;
DELIMITER //
CREATE PROCEDURE sp_FusionarCuentasCliente(
    IN p_id_cliente_origen INT,
    IN p_id_cliente_destino INT
)
BEGIN
    START TRANSACTION;
    
    UPDATE Ventas 
    SET id_cliente = p_id_cliente_destino 
    WHERE id_cliente = p_id_cliente_origen;
    
    DELETE FROM Clientes 
    WHERE id_cliente = p_id_cliente_origen;
    
    COMMIT;
END //
DELIMITER ;

-- 14. sp_AsignarProductoAProveedor
DROP PROCEDURE IF EXISTS sp_AsignarProductoAProveedor;
DELIMITER //
CREATE PROCEDURE sp_AsignarProductoAProveedor(
    IN p_id_producto INT,
    IN p_id_proveedor INT
)
BEGIN
    UPDATE Productos 
    SET id_proveedor = p_id_proveedor 
    WHERE id_producto = p_id_producto;
END //
DELIMITER ;

-- 15. sp_BuscarProductos
DROP PROCEDURE IF EXISTS sp_BuscarProductos;
DELIMITER //
CREATE PROCEDURE sp_BuscarProductos(
    IN p_nombre VARCHAR(100),
    IN p_id_categoria INT,
    IN p_precio_min DECIMAL(10,2),
    IN p_precio_max DECIMAL(10,2)
)
BEGIN
    SELECT * FROM Productos
    WHERE (p_nombre IS NULL OR nombre LIKE CONCAT('%', p_nombre, '%'))
      AND (p_id_categoria IS NULL OR id_categoria = p_id_categoria)
      AND (p_precio_min IS NULL OR precio >= p_precio_min)
      AND (p_precio_max IS NULL OR precio <= p_precio_max);
END //
DELIMITER ;

-- 16. sp_ObtenerDashboardAdmin
DROP PROCEDURE IF EXISTS sp_ObtenerDashboardAdmin;
DELIMITER //
CREATE PROCEDURE sp_ObtenerDashboardAdmin()
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM Ventas WHERE DATE(fecha_venta) = CURDATE()) AS ventas_hoy,
        (SELECT IFNULL(SUM(total), 0) FROM Ventas WHERE DATE(fecha_venta) = CURDATE()) AS ingresos_hoy,
        (SELECT COUNT(*) FROM Clientes) AS total_clientes,
        (SELECT COUNT(*) FROM Productos WHERE stock <= 5) AS productos_stock_bajo;
END //
DELIMITER ;

-- 17. sp_ProcesarPago
DROP PROCEDURE IF EXISTS sp_ProcesarPago;
DELIMITER //
CREATE PROCEDURE sp_ProcesarPago(
    IN p_id_venta INT
)
BEGIN
    UPDATE Ventas 
    SET estado = 'Pagado' 
    WHERE id_venta = p_id_venta;
END //
DELIMITER ;

-- 18. sp_AñadirReseñaProducto
DROP PROCEDURE IF EXISTS sp_AñadirReseñaProducto;
DELIMITER //
CREATE PROCEDURE sp_AñadirReseñaProducto(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_calificacion INT,
    IN p_comentario TEXT
)
BEGIN
    CREATE TABLE IF NOT EXISTS Resenas (
        id_resena INT AUTO_INCREMENT PRIMARY KEY,
        id_cliente INT,
        id_producto INT,
        calificacion INT,
        comentario TEXT,
        fecha DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    INSERT INTO Resenas (id_cliente, id_producto, calificacion, comentario)
    VALUES (p_id_cliente, p_id_producto, p_calificacion, p_comentario);
END //
DELIMITER ;

-- 19. sp_ObtenerProductosRelacionados
DROP PROCEDURE IF EXISTS sp_ObtenerProductosRelacionados;
DELIMITER //
CREATE PROCEDURE sp_ObtenerProductosRelacionados(
    IN p_id_producto INT
)
BEGIN
    DECLARE v_id_categoria INT;
    
    SELECT id_categoria INTO v_id_categoria 
    FROM Productos 
    WHERE id_producto = p_id_producto;
    
    SELECT id_producto, nombre, precio, stock 
    FROM Productos 
    WHERE id_categoria = v_id_categoria 
      AND id_producto <> p_id_producto 
    LIMIT 5;
END //
DELIMITER ;

-- 20. sp_MoverProductosEntreCategorias
DROP PROCEDURE IF EXISTS sp_MoverProductosEntreCategorias;
DELIMITER //
CREATE PROCEDURE sp_MoverProductosEntreCategorias(
    IN p_id_categoria_origen INT,
    IN p_id_categoria_destino INT
)
BEGIN
    UPDATE Productos 
    SET id_categoria = p_id_categoria_destino 
    WHERE id_categoria = p_id_categoria_origen;
END //
DELIMITER ;









