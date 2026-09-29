-- SECCIÓN 8: EVENTOS PROGRAMADOS (VERSION SIMPLIFICADA)
USE Ecommerce;

SET GLOBAL event_scheduler = OFF;
SHOW VARIABLES LIKE 'event_scheduler';

-- 1. Asegurar columnas necesarias en la tabla Clientes (ejecutar antes)
ALTER TABLE Clientes ADD COLUMN nivel_lealtad VARCHAR(20) DEFAULT 'Bronce';
ALTER TABLE Clientes ADD COLUMN estado VARCHAR(20) DEFAULT 'Activo';
ALTER TABLE Clientes ADD COLUMN fecha_nacimiento DATE DEFAULT NULL;


-- 1. evt_generate_weekly_sales_report
DROP EVENT IF EXISTS evt_generate_weekly_sales_report;
DELIMITER //
CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Reporte_Semanal_Ventas (
        id_reporte INT AUTO_INCREMENT PRIMARY KEY,
        fecha_reporte DATE,
        total_ventas INT,
        monto_total DECIMAL(10,2)
    );
    INSERT INTO Reporte_Semanal_Ventas (fecha_reporte, total_ventas, monto_total)
    SELECT CURDATE(), COUNT(id_venta), IFNULL(SUM(total), 0)
    FROM Ventas
    WHERE fecha_venta >= NOW() - INTERVAL 1 WEEK;
END //
DELIMITER ;

-- 2. evt_cleanup_temp_tables_daily
DROP EVENT IF EXISTS evt_cleanup_temp_tables_daily;
DELIMITER //
CREATE EVENT evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM Log_Precios WHERE fecha_cambio < NOW() - INTERVAL 7 DAY;
END //
DELIMITER ;

-- 3. evt_archive_old_logs_monthly
DROP EVENT IF EXISTS evt_archive_old_logs_monthly;
DELIMITER //
CREATE EVENT evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Historico_Log_Precios LIKE Log_Precios;
    INSERT INTO Historico_Log_Precios SELECT * FROM Log_Precios WHERE fecha_cambio < NOW() - INTERVAL 6 MONTH;
    DELETE FROM Log_Precios WHERE fecha_cambio < NOW() - INTERVAL 6 MONTH;
END //
DELIMITER ;

-- 4. evt_deactivate_expired_promotions_hourly
DROP EVENT IF EXISTS evt_deactivate_expired_promotions_hourly;
DELIMITER //
CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Promociones (
        id_promocion INT AUTO_INCREMENT PRIMARY KEY,
        codigo VARCHAR(50),
        fecha_fin DATETIME,
        activa BOOLEAN DEFAULT TRUE
    );
    UPDATE Promociones SET activa = FALSE WHERE fecha_fin <= NOW() AND activa = TRUE;
END //
DELIMITER ;

-- 5. evt_recalculate_customer_loyalty_tiers_nightly
DROP EVENT IF EXISTS evt_recalculate_customer_loyalty_tiers_nightly;
DELIMITER //
CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY)
DO
BEGIN
    UPDATE Clientes SET nivel_lealtad = 'Oro' WHERE total_gastado >= 1000;
    UPDATE Clientes SET nivel_lealtad = 'Plata' WHERE total_gastado >= 500 AND total_gastado < 1000;
END //
DELIMITER ;

-- 6. evt_generate_reorder_list_daily
DROP EVENT IF EXISTS evt_generate_reorder_list_daily;
DELIMITER //
CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Lista_Reabastecimiento (
        id_lista INT AUTO_INCREMENT PRIMARY KEY,
        id_producto INT,
        stock_actual INT,
        fecha_registro DATE
    );
    INSERT INTO Lista_Reabastecimiento (id_producto, stock_actual, fecha_registro)
    SELECT id_producto, stock, CURDATE() FROM Productos WHERE stock <= 5;
END //
DELIMITER ;

-- 7. evt_rebuild_indexes_weekly
DROP EVENT IF EXISTS evt_rebuild_indexes_weekly;
DELIMITER //
CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP
DO
BEGIN
    OPTIMIZE TABLE Clientes, Productos, Ventas, Detalle_de_ventas;
END //
DELIMITER ;

-- 8. evt_suspend_inactive_accounts_quarterly
DROP EVENT IF EXISTS evt_suspend_inactive_accounts_quarterly;
DELIMITER //
CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE Clientes SET estado = 'Suspendido'
    WHERE fecha_ultimo_pedido IS NULL OR fecha_ultimo_pedido < NOW() - INTERVAL 1 YEAR;
END //
DELIMITER ;

-- 9. evt_aggregate_daily_sales_data
DROP EVENT IF EXISTS evt_aggregate_daily_sales_data;
DELIMITER //
CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY)
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Resumen_Diario_Ventas (
        fecha DATE PRIMARY KEY,
        total_ordenes INT,
        ingresos DECIMAL(10,2)
    );
    INSERT INTO Resumen_Diario_Ventas (fecha, total_ordenes, ingresos)
    SELECT DATE(fecha_venta), COUNT(id_venta), IFNULL(SUM(total), 0)
    FROM Ventas WHERE DATE(fecha_venta) = CURDATE() - INTERVAL 1 DAY
    ON DUPLICATE KEY UPDATE total_ordenes = VALUES(total_ordenes), ingresos = VALUES(ingresos);
END //
DELIMITER ;

-- 10. evt_check_data_consistency_nightly
DROP EVENT IF EXISTS evt_check_data_consistency_nightly;
DELIMITER //
CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY)
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Inconsistencias_Datos (
        id_inconsistencia INT AUTO_INCREMENT PRIMARY KEY,
        tabla VARCHAR(50),
        id_registro INT,
        descripcion VARCHAR(255),
        fecha DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO Inconsistencias_Datos (tabla, id_registro, descripcion)
    SELECT 'Ventas', v.id_venta, 'Venta sin detalles asociados'
    FROM Ventas v LEFT JOIN Detalle_de_ventas dv ON v.id_venta = dv.id_venta
    WHERE dv.id_venta IS NULL;
END //
DELIMITER ;

-- 11. evt_send_birthday_greetings_daily
DROP EVENT IF EXISTS evt_send_birthday_greetings_daily;
DELIMITER //
CREATE EVENT evt_send_birthday_greetings_daily
ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Cupones_Cumpleanos (
        id_cupon INT AUTO_INCREMENT PRIMARY KEY,
        id_cliente INT,
        codigo_cupon VARCHAR(50),
        fecha_emision DATE
    );
    INSERT INTO Cupones_Cumpleanos (id_cliente, codigo_cupon, fecha_emision)
    SELECT id_cliente, CONCAT('CUMPLE-', id_cliente), CURDATE()
    FROM Clientes WHERE DATE_FORMAT(fecha_nacimiento, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d');
END //
DELIMITER ;

-- 12. evt_update_product_rankings_hourly
DROP EVENT IF EXISTS evt_update_product_rankings_hourly;
DELIMITER //
CREATE EVENT evt_update_product_rankings_hourly
ON SCHEDULE EVERY 1 HOUR STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Ranking_Productos (
        id_producto INT PRIMARY KEY,
        total_vendido INT,
        posicion INT
    );
    TRUNCATE TABLE Ranking_Productos;
    INSERT INTO Ranking_Productos (id_producto, total_vendido, posicion)
    SELECT id_producto, SUM(cantidad) AS total_v, ROW_NUMBER() OVER (ORDER BY SUM(cantidad) DESC)
    FROM Detalle_de_ventas GROUP BY id_producto;
END //
DELIMITER ;

-- 13. evt_backup_critical_tables_daily
DROP EVENT IF EXISTS evt_backup_critical_tables_daily;
DELIMITER //
CREATE EVENT evt_backup_critical_tables_daily
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY)
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Backup_Diario_Ventas LIKE Ventas;
    TRUNCATE TABLE Backup_Diario_Ventas;
    INSERT INTO Backup_Diario_Ventas SELECT * FROM Ventas;
END //
DELIMITER ;

-- 14. evt_clear_abandoned_carts_daily
DROP EVENT IF EXISTS evt_clear_abandoned_carts_daily;
DELIMITER //
CREATE EVENT evt_clear_abandoned_carts_daily
ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Carritos (
        id_carrito INT AUTO_INCREMENT PRIMARY KEY,
        id_cliente INT,
        fecha_modificacion DATETIME
    );
    DELETE FROM Carritos WHERE fecha_modificacion < NOW() - INTERVAL 72 HOUR;
END //
DELIMITER ;

-- 15. evt_calculate_monthly_kpis
DROP EVENT IF EXISTS evt_calculate_monthly_kpis;
DELIMITER //
CREATE EVENT evt_calculate_monthly_kpis
ON SCHEDULE EVERY 1 MONTH STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS KPIs_Mensuales (
        id_kpi INT AUTO_INCREMENT PRIMARY KEY,
        mes_anio VARCHAR(7),
        total_ingresos DECIMAL(10,2),
        ticket_promedio DECIMAL(10,2)
    );
    INSERT INTO KPIs_Mensuales (mes_anio, total_ingresos, ticket_promedio)
    SELECT DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m'), IFNULL(SUM(total), 0), IFNULL(AVG(total), 0)
    FROM Ventas WHERE MONTH(fecha_venta) = MONTH(NOW() - INTERVAL 1 MONTH);
END //
DELIMITER ;

-- 16. evt_refresh_materialized_views_nightly
DROP EVENT IF EXISTS evt_refresh_materialized_views_nightly;
DELIMITER //
CREATE EVENT evt_refresh_materialized_views_nightly
ON SCHEDULE EVERY 1 DAY STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY)
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Vista_Resumen_Productos (
        id_producto INT PRIMARY KEY,
        nombre VARCHAR(100),
        total_ventas INT
    );
    TRUNCATE TABLE Vista_Resumen_Productos;
    INSERT INTO Vista_Resumen_Productos (id_producto, nombre, total_ventas)
    SELECT p.id_producto, p.nombre, IFNULL(SUM(dv.cantidad), 0)
    FROM Productos p LEFT JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
    GROUP BY p.id_producto, p.nombre;
END //
DELIMITER ;

-- 17. evt_log_database_size_weekly
DROP EVENT IF EXISTS evt_log_database_size_weekly;
DELIMITER //
CREATE EVENT evt_log_database_size_weekly
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Log_Tamano_BD (
        id_log INT AUTO_INCREMENT PRIMARY KEY,
        tamano_mb DECIMAL(10,2),
        fecha DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO Log_Tamano_BD (tamano_mb)
    SELECT SUM(data_length + index_length) / 1024 / 1024
    FROM information_schema.tables WHERE table_schema = DATABASE();
END //
DELIMITER ;

-- 18. evt_detect_fraudulent_activity_hourly
DROP EVENT IF EXISTS evt_detect_fraudulent_activity_hourly;
DELIMITER //
CREATE EVENT evt_detect_fraudulent_activity_hourly
ON SCHEDULE EVERY 1 HOUR STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Alertas_Fraude (
        id_alerta INT AUTO_INCREMENT PRIMARY KEY,
        id_cliente INT,
        motivo VARCHAR(255),
        fecha DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO Alertas_Fraude (id_cliente, motivo)
    SELECT id_cliente, 'Mas de 3 pedidos cancelados en la ultima hora'
    FROM Ventas WHERE estado = 'Cancelado' AND fecha_venta >= NOW() - INTERVAL 1 HOUR
    GROUP BY id_cliente HAVING COUNT(*) >= 3;
END //
DELIMITER ;

-- 19. evt_generate_supplier_performance_report_monthly
DROP EVENT IF EXISTS evt_generate_supplier_performance_report_monthly;
DELIMITER //
CREATE EVENT evt_generate_supplier_performance_report_monthly
ON SCHEDULE EVERY 1 MONTH STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS Reporte_Proveedores (
        id_reporte INT AUTO_INCREMENT PRIMARY KEY,
        id_proveedor INT,
        total_productos_vendidos INT,
        fecha_generacion DATE
    );
    INSERT INTO Reporte_Proveedores (id_proveedor, total_productos_vendidos, fecha_generacion)
    SELECT p.id_proveedor, IFNULL(SUM(dv.cantidad), 0), CURDATE()
    FROM Productos p JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
    GROUP BY p.id_proveedor;
END //
DELIMITER ;

-- 20. evt_purge_soft_deleted_records_weekly
DROP EVENT IF EXISTS evt_purge_soft_deleted_records_weekly;
DELIMITER //
CREATE EVENT evt_purge_soft_deleted_records_weekly
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM Ventas_Archivo WHERE fecha_eliminacion < NOW() - INTERVAL 30 DAY;
END //
DELIMITER ;

