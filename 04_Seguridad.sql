USE Ecommerce;

-- 1. RESTAURAR PODERES AL ADMINISTRADOR
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- 2. LIMPIEZA TOTAL DE INTENTOS ANTERIORES
DROP ROLE IF EXISTS 'Administrador_Sistema', 'Gerente_Marketing', 'Analista_Datos', 
                    'Empleado_Inventario', 'Atencion_Cliente', 'Auditor_Financiero', 'Visitante';
DROP USER IF EXISTS 'admin_user'@'%', 'marketing_user'@'%', 'inventory_user'@'%', 'support_user'@'%', 'analista_user'@'%';
FLUSH PRIVILEGES;

-- 3. CREACIÓN DE ROLES
CREATE ROLE 'Administrador_Sistema';
CREATE ROLE 'Gerente_Marketing';
CREATE ROLE 'Analista_Datos';
CREATE ROLE 'Empleado_Inventario';
CREATE ROLE 'Atencion_Cliente';
CREATE ROLE 'Auditor_Financiero';
CREATE ROLE 'Visitante';

-- 4. PRIVILEGIOS DE LOS ROLES
-- Administrador_Sistema
GRANT ALL PRIVILEGES ON Ecommerce.* TO 'Administrador_Sistema';

-- Gerente_Marketing
GRANT SELECT ON Ecommerce.Ventas TO 'Gerente_Marketing';
GRANT SELECT ON Ecommerce.Clientes TO 'Gerente_Marketing';
GRANT EXECUTE ON PROCEDURE Ecommerce.sp_GenerarReporteMensualVentas TO 'Gerente_Marketing';

-- Analista_Datos
GRANT SELECT ON Ecommerce.Clientes TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.Productos TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.Ventas TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.Detalle_de_ventas TO 'Analista_Datos';

-- Empleado_Inventario (Solo stock y ubicacion, prohibido precio por defecto)
GRANT SELECT ON Ecommerce.Productos TO 'Empleado_Inventario';
GRANT UPDATE (stock, ubicacion) ON Ecommerce.Productos TO 'Empleado_Inventario';

-- Auditor_Financiero
GRANT SELECT ON Ecommerce.Ventas TO 'Auditor_Financiero';
GRANT SELECT ON Ecommerce.Productos TO 'Auditor_Financiero';
GRANT SELECT ON Ecommerce.Log_Precios TO 'Auditor_Financiero';

-- Visitante
GRANT SELECT ON Ecommerce.Productos TO 'Visitante';

-- 5. VISTAS Y ATENCIÓN AL CLIENTE
CREATE OR REPLACE VIEW v_info_clientes_basica AS
SELECT id_cliente, nombre, apellido, email, ciudad, estado FROM Clientes;

GRANT SELECT ON Ecommerce.v_info_clientes_basica TO 'Atencion_Cliente';
GRANT SELECT ON Ecommerce.Ventas TO 'Atencion_Cliente';

-- 6. CREACIÓN DE USUARIOS Y ASIGNACIÓN
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'AdminPass1234!';
GRANT 'Administrador_Sistema' TO 'admin_user'@'%';
ALTER USER 'admin_user'@'%' DEFAULT ROLE 'Administrador_Sistema';

CREATE USER 'marketing_user'@'%' IDENTIFIED BY 'MktPass1234!';
GRANT 'Gerente_Marketing' TO 'marketing_user'@'%';
ALTER USER 'marketing_user'@'%' DEFAULT ROLE 'Gerente_Marketing';

CREATE USER 'inventory_user'@'%' IDENTIFIED BY 'InvPass1234!';
GRANT 'Empleado_Inventario' TO 'inventory_user'@'%';
ALTER USER 'inventory_user'@'%' DEFAULT ROLE 'Empleado_Inventario';

CREATE USER 'support_user'@'%' IDENTIFIED BY 'SuppPass1234!';
GRANT 'Atencion_Cliente' TO 'support_user'@'%';
ALTER USER 'support_user'@'%' DEFAULT ROLE 'Atencion_Cliente';

-- Requerimiento 18: Usuario analista con límite de consultas
CREATE USER 'analista_user'@'%' IDENTIFIED BY 'DataPass1234!' WITH MAX_QUERIES_PER_HOUR 1000;
GRANT 'Analista_Datos' TO 'analista_user'@'%';
ALTER USER 'analista_user'@'%' DEFAULT ROLE 'Analista_Datos';

-- 7. POLÍTICAS GLOBALES Y AUDITORÍA
SET GLOBAL log_error_verbosity = 2;

-- APLICAR TODOS LOS CAMBIOS
FLUSH PRIVILEGES;

