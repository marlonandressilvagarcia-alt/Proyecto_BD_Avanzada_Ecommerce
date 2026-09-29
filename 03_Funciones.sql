use Ecommerce;

-- 1. fn_CalcularTotalVenta
DELIMITER //
CREATE FUNCTION fn_CalcularTotalVenta(p_id_venta INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);
    SELECT COALESCE(SUM(cantidad * precio_unitario_congelado), 0.00) 
    INTO v_total
    FROM Detalle_de_ventas
    WHERE id_venta = p_id_venta;
    RETURN v_total;
END //
DELIMITER ;

-- 2. fn_VerificarDisponibilidadStock
DELIMITER //
CREATE FUNCTION fn_VerificarDisponibilidadStock(p_id_producto INT, p_cantidad INT) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock INT;
    SELECT stock INTO v_stock FROM Productos WHERE id_producto = p_id_producto;
    IF v_stock IS NOT NULL AND v_stock >= p_cantidad THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //
DELIMITER ;

-- 3. fn_ObtenerPrecioProducto
DELIMITER //
CREATE FUNCTION fn_ObtenerPrecioProducto(p_id_producto INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    SELECT precio INTO v_precio FROM Productos WHERE id_producto = p_id_producto;
    RETURN COALESCE(v_precio, 0.00);
END //
DELIMITER ;

-- 4. fn_CalcularEdadCliente
DELIMITER //
CREATE FUNCTION fn_CalcularEdadCliente(p_id_cliente INT) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_nac DATE;
    SELECT fecha_nacimiento INTO v_fecha_nac FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_fecha_nac IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN TIMESTAMPDIFF(YEAR, v_fecha_nac, CURDATE());
END //
DELIMITER ;

-- 5. fn_FormatearNombreCompleto
DELIMITER //
CREATE FUNCTION fn_FormatearNombreCompleto(p_id_cliente INT) 
RETURNS VARCHAR(205)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    SELECT nombre, apellido INTO v_nombre, v_apellido FROM Clientes WHERE id_cliente = p_id_cliente;
    IF v_nombre IS NULL AND v_apellido IS NULL THEN
        RETURN '';
    END IF;
    RETURN CONCAT(UPPER(LEFT(v_nombre, 1)), LOWER(SUBSTRING(v_nombre, 2)), ' ', UPPER(LEFT(v_apellido, 1)), LOWER(SUBSTRING(v_apellido, 2)));
END //
DELIMITER ;

-- 6. fn_EsClienteNuevo
DELIMITER //
CREATE FUNCTION fn_EsClienteNuevo(p_id_cliente INT) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_primera_compra DATETIME;
    SELECT MIN(fecha_venta) INTO v_primera_compra FROM Ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    IF v_primera_compra IS NOT NULL AND v_primera_compra >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //
DELIMITER ;

-- 7. fn_CalcularCostoEnvio
DELIMITER //
CREATE FUNCTION fn_CalcularCostoEnvio(p_id_venta INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_peso_total DECIMAL(10,2);
    DECLARE v_costo DECIMAL(10,2);
    SELECT COALESCE(SUM(dv.cantidad * p.peso_kg), 0.00) INTO v_peso_total
    FROM Detalle_de_ventas dv
    JOIN Productos p ON dv.id_producto = p.id_producto
    WHERE dv.id_venta = p_id_venta;
    
    IF v_peso_total <= 5.00 THEN
        SET v_costo = 10000.00;
    ELSEIF v_peso_total <= 20.00 THEN
        SET v_costo = 25000.00;
    ELSE
        SET v_costo = 25000.00 + ((v_peso_total - 20.00) * 1500.00);
    END IF;
    RETURN v_costo;
END //
DELIMITER ;

-- 8. fn_AplicarDescuento
DELIMITER //
CREATE FUNCTION fn_AplicarDescuento(p_monto DECIMAL(10,2), p_porcentaje DECIMAL(5,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RETURN 0.00;
    END IF;
    IF p_porcentaje IS NULL OR p_porcentaje <= 0 THEN
        RETURN p_monto;
    END IF;
    RETURN p_monto - (p_monto * (p_porcentaje / 100.00));
END //
DELIMITER ;

-- 9. fn_ObtenerUltimaFechaCompra
DELIMITER //
CREATE FUNCTION fn_ObtenerUltimaFechaCompra(p_id_cliente INT) 
RETURNS DATETIME
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ultima_fecha DATETIME;
    SELECT MAX(fecha_venta) INTO v_ultima_fecha FROM Ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    RETURN v_ultima_fecha;
END //
DELIMITER ;

-- 10. fn_ValidarFormatoEmail
DELIMITER //
CREATE FUNCTION fn_ValidarFormatoEmail(p_email VARCHAR(255)) 
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    IF p_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //
DELIMITER ;

-- 11. fn_ObtenerNombreCategoria
DELIMITER //
CREATE FUNCTION fn_ObtenerNombreCategoria(p_id_producto INT) 
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_nombre_cat VARCHAR(100);
    SELECT c.nombre INTO v_nombre_cat
    FROM Productos p
    JOIN Categorias c ON p.id_categoria = c.id_categoria
    WHERE p.id_producto = p_id_producto;
    RETURN COALESCE(v_nombre_cat, 'Sin Categoría');
END //
DELIMITER ;

-- 12. fn_ContarVentasCliente
DELIMITER //
CREATE FUNCTION fn_ContarVentasCliente(p_id_cliente INT) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_conteo INT;
    SELECT COUNT(*) INTO v_conteo FROM Ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    RETURN v_conteo;
END //
DELIMITER ;

-- 13. fn_CalcularDiasDesdeUltimaCompra
DELIMITER //
CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra(p_id_cliente INT) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ultima_fecha DATETIME;
    SELECT MAX(fecha_venta) INTO v_ultima_fecha FROM Ventas WHERE id_cliente = p_id_cliente AND estado != 'Cancelado';
    IF v_ultima_fecha IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN DATEDIFF(CURDATE(), v_ultima_fecha);
END //
DELIMITER ;

-- 14. fn_DeterminarEstadoLealtad
DELIMITER //
CREATE FUNCTION fn_DeterminarEstadoLealtad(p_id_cliente INT) 
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_gastado DECIMAL(10,2);
    SELECT COALESCE(total_gastado, 0.00) INTO v_total_gastado FROM Clientes WHERE id_cliente = p_id_cliente;
    
    IF v_total_gastado >= 5000000.00 THEN
        RETURN 'Oro';
    ELSEIF v_total_gastado >= 2000000.00 THEN
        RETURN 'Plata';
    ELSE
        RETURN 'Bronce';
    END IF;
END //
DELIMITER ;

-- 15. fn_GenerarSKU
DELIMITER //
CREATE FUNCTION fn_GenerarSKU(p_nombre VARCHAR(150), p_id_categoria INT) 
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_prefijo VARCHAR(3);
    DECLARE v_nombre_clean VARCHAR(10);
    DECLARE v_random VARCHAR(4);
    
    SELECT UPPER(LEFT(nombre, 3)) INTO v_prefijo FROM Categorias WHERE id_categoria = p_id_categoria;
    IF v_prefijo IS NULL THEN
        SET v_prefijo = 'GEN';
    END IF;
    
    SET v_nombre_clean = UPPER(REPLACE(p_nombre, ' ', ''));
    SET v_random = LPAD(FLOOR(RAND() * 10000), 4, '0');
    
    RETURN CONCAT(v_prefijo, '-', LEFT(v_nombre_clean, 3), '-', v_random);
END //
DELIMITER ;

-- 16. fn_CalcularIVA
DELIMITER //
CREATE FUNCTION fn_CalcularIVA(p_monto DECIMAL(10,2), p_porcentaje DECIMAL(5,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_porcentaje DECIMAL(5,2);
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RETURN 0.00;
    END IF;
    SET v_porcentaje = COALESCE(p_porcentaje, 19.00);
    RETURN p_monto * (v_porcentaje / 100.00);
END //
DELIMITER ;

-- 17. fn_ObtenerStockTotalPorCategoria
DELIMITER //
CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(p_id_categoria INT) 
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock_total INT;
    SELECT COALESCE(SUM(stock), 0) INTO v_stock_total FROM Productos WHERE id_categoria = p_id_categoria;
    RETURN v_stock_total;
END //
DELIMITER ;

-- 18. fn_EstimarFechaEntrega
DELIMITER //
CREATE FUNCTION fn_EstimarFechaEntrega(p_id_venta INT) 
RETURNS DATE
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ciudad VARCHAR(100);
    DECLARE v_fecha_venta DATETIME;
    DECLARE v_dias INT;
    
    SELECT c.ciudad, v.fecha_venta INTO v_ciudad, v_fecha_venta
    FROM Ventas v
    JOIN Clientes c ON v.id_cliente = c.id_cliente
    WHERE v.id_venta = p_id_venta;
    
    IF v_fecha_venta IS NULL THEN
        RETURN NULL;
    END IF;
    
    IF v_ciudad = 'Bogotá' THEN
        SET v_dias = 2;
    ELSEIF v_ciudad IN ('Medellín', 'Cali', 'Barranquilla') THEN
        SET v_dias = 3;
    ELSE
        SET v_dias = 5;
    END IF;
    
    RETURN DATE_ADD(DATE(v_fecha_venta), INTERVAL v_dias DAY);
END //
DELIMITER ;

-- 19. fn_ConvertirMoneda
DELIMITER //
CREATE FUNCTION fn_ConvertirMoneda(p_monto DECIMAL(10,2), p_tasa_cambio DECIMAL(10,4)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    IF p_monto IS NULL OR p_tasa_cambio IS NULL OR p_tasa_cambio <= 0 THEN
        RETURN 0.00;
    END IF;
    RETURN ROUND(p_monto / p_tasa_cambio, 2);
END //
DELIMITER ;

-- 20. fn_ValidarComplejidadContraseña
DELIMITER //
CREATE FUNCTION fn_ValidarComplejidadContraseña(p_password VARCHAR(255)) 
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    IF LENGTH(p_password) >= 8 
       AND p_password REGEXP '[A-Z]' 
       AND p_password REGEXP '[a-z]' 
       AND p_password REGEXP '[0-9]' 
       AND p_password REGEXP '[^A-Za-z0-9]' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END //
DELIMITER ;