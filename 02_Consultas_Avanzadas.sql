use Ecommerce;

-- 1. Top 10 Productos Más Vendidos
SELECT 
    p.id_producto,
    p.nombre,
    SUM(dv.cantidad) AS total_unidades,
    SUM(dv.cantidad * dv.precio_unitario_congelado) AS total_ingresos
FROM Detalle_de_ventas dv
JOIN Productos p ON dv.id_producto = p.id_producto
JOIN Ventas v ON dv.id_venta = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre
ORDER BY total_ingresos DESC
LIMIT 10;

-- 2. Productos con Bajas Ventas
WITH VentasPorProducto AS (
    SELECT 
        p.id_producto,
        p.nombre,
        COALESCE(SUM(dv.cantidad * dv.precio_unitario_congelado), 0) AS total_ventas,
        NTILE(10) OVER (ORDER BY COALESCE(SUM(dv.cantidad * dv.precio_unitario_congelado), 0) ASC) AS percentil
    FROM Productos p
    LEFT JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN Ventas v ON dv.id_venta = v.id_venta AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre
)
SELECT id_producto, nombre, total_ventas
FROM VentasPorProducto
WHERE percentil = 1;

-- 3. Clientes VIP
SELECT 
    id_cliente,
    nombre,
    apellido,
    email,
    total_gastado
FROM Clientes
ORDER BY total_gastado DESC
LIMIT 5;

-- 4. Análisis de Ventas Mensuales
SELECT 
    YEAR(fecha_venta) AS anio,
    MONTH(fecha_venta) AS mes,
    COUNT(id_venta) AS total_transacciones,
    SUM(total) AS ventas_totales
FROM Ventas
WHERE estado != 'Cancelado'
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio DESC, mes DESC;

-- 5. Crecimiento de Clientes
SELECT 
    YEAR(fecha_registro) AS anio,
    QUARTER(fecha_registro) AS trimestre,
    COUNT(id_cliente) AS nuevos_clientes
FROM Clientes
GROUP BY YEAR(fecha_registro), QUARTER(fecha_registro)
ORDER BY anio DESC, trimestre DESC;

-- 6. Tasa de Compra Repetida
SELECT 
    (COUNT(CASE WHEN num_compras > 1 THEN 1 END) * 100.0 / COUNT(*)) AS tasa_compra_repetida_porcentaje
FROM (
    SELECT 
        id_cliente,
        COUNT(id_venta) AS num_compras
    FROM Ventas
    WHERE estado != 'Cancelado'
    GROUP BY id_cliente
) AS ConteoCompras;

-- 7. Productos Comprados Juntos Frecuentemente
SELECT 
    p1.nombre AS producto_1,
    p2.nombre AS producto_2,
    COUNT(*) AS veces_comprados_juntos
FROM Detalle_de_ventas dv1
JOIN Detalle_de_ventas dv2 ON dv1.id_venta = dv2.id_venta AND dv1.id_producto < dv2.id_producto
JOIN Productos p1 ON dv1.id_producto = p1.id_producto
JOIN Productos p2 ON dv2.id_producto = p2.id_producto
JOIN Ventas v ON dv1.id_venta = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY p1.nombre, p2.nombre
ORDER BY veces_comprados_juntos DESC;

-- 8. Rotación de Inventario
SELECT 
    c.nombre AS categoria,
    SUM(dv.cantidad) AS unidades_vendidas,
    SUM(p.stock) AS stock_actual,
    CASE 
        WHEN SUM(p.stock) > 0 THEN ROUND(SUM(dv.cantidad) / SUM(p.stock), 2)
        ELSE 0 
    END AS tasa_rotacion
FROM Categorias c
JOIN Productos p ON c.id_categoria = p.id_categoria
LEFT JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN Ventas v ON dv.id_venta = v.id_venta AND v.estado != 'Cancelado'
GROUP BY c.id_categoria, c.nombre;

-- 9. Productos que Necesitan Reabastecimiento
SELECT 
    id_producto,
    nombre,
    stock,
    stock_minimo
FROM Productos
WHERE stock < stock_minimo;

-- 10. Análisis de Carrito Abandonado (Simulado)
SELECT DISTINCT 
    c.id_cliente,
    c.nombre,
    c.apellido,
    c.email,
    vp.fecha_vista
FROM Vistas_Productos vp
JOIN Clientes c ON vp.id_cliente = c.id_cliente
LEFT JOIN Ventas v ON c.id_cliente = v.id_cliente AND v.fecha_venta >= vp.fecha_vista
WHERE v.id_venta IS NULL;

-- 11. Rendimiento de Proveedores
SELECT 
    pr.id_proveedor,
    pr.nombre AS proveedor,
    SUM(dv.cantidad) AS total_unidades_vendidas,
    COALESCE(SUM(dv.cantidad * dv.precio_unitario_congelado), 0) AS volumen_ventas_total
FROM Proveedores pr
JOIN Productos p ON pr.id_proveedor = p.id_proveedor
LEFT JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN Ventas v ON dv.id_venta = v.id_venta AND v.estado != 'Cancelado'
GROUP BY pr.id_proveedor, pr.nombre
ORDER BY volumen_ventas_total DESC;

-- 12. Análisis Geográfico de Ventas
SELECT 
    c.ciudad,
    COUNT(v.id_venta) AS total_ventas,
    SUM(v.total) AS ingresos_totales
FROM Ventas v
JOIN Clientes c ON v.id_cliente = c.id_cliente
WHERE v.estado != 'Cancelado'
GROUP BY c.ciudad
ORDER BY ingresos_totales DESC;

-- 13. Ventas por Hora del Día
SELECT 
    HOUR(fecha_venta) AS hora_dia,
    COUNT(id_venta) AS total_transacciones,
    SUM(total) AS total_ventas
FROM Ventas
WHERE estado != 'Cancelado'
GROUP BY HOUR(fecha_venta)
ORDER BY total_transacciones DESC;

-- 14. Impacto de Promociones
SELECT 
    pr.codigo AS promocion,
    p.nombre AS producto,
    SUM(CASE WHEN v.fecha_venta < pr.fecha_inicio THEN dv.cantidad ELSE 0 END) AS unidades_antes,
    SUM(CASE WHEN v.fecha_venta BETWEEN pr.fecha_inicio AND pr.fecha_fin THEN dv.cantidad ELSE 0 END) AS unidades_durante,
    SUM(CASE WHEN v.fecha_venta > pr.fecha_fin THEN dv.cantidad ELSE 0 END) AS unidades_despues
FROM Promociones pr
CROSS JOIN Productos p
LEFT JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN Ventas v ON dv.id_venta = v.id_venta AND v.estado != 'Cancelado'
WHERE pr.codigo = 'EXPIRED20'
GROUP BY pr.codigo, p.id_producto, p.nombre;

-- 15. Análisis de Cohort
WITH PrimeraCompra AS (
    SELECT 
        id_cliente,
        DATE_FORMAT(MIN(fecha_venta), '%Y-%m-01') AS cohorte
    FROM Ventas
    WHERE estado != 'Cancelado'
    GROUP BY id_cliente
)
SELECT 
    pc.cohorte,
    DATE_FORMAT(v.fecha_venta, '%Y-%m-01') AS mes_actividad,
    COUNT(DISTINCT v.id_cliente) AS clientes_activos
FROM PrimeraCompra pc
JOIN Ventas v ON pc.id_cliente = v.id_cliente AND v.estado != 'Cancelado'
GROUP BY pc.cohorte, DATE_FORMAT(v.fecha_venta, '%Y-%m-01')
ORDER BY pc.cohorte, mes_actividad;

-- 16. Margen de Beneficio por Producto
SELECT 
    id_producto,
    nombre,
    precio,
    costo,
    (precio - costo) AS margen_bruto,
    ROUND(((precio - costo) / precio) * 100, 2) AS porcentaje_margen
FROM Productos;

-- 17. Tiempo Promedio Entre Compras
WITH DiferenciasCompras AS (
    SELECT 
        id_cliente,
        DATEDIFF(fecha_venta, LAG(fecha_venta) OVER (PARTITION BY id_cliente ORDER BY fecha_venta)) AS dias_entre_compras
    FROM Ventas
    WHERE estado != 'Cancelado'
)
SELECT 
    ROUND(AVG(dias_entre_compras), 2) AS promedio_dias_entre_compras
FROM DiferenciasCompras
WHERE dias_entre_compras IS NOT NULL;

-- 18. Productos Más Vistos vs. Comprados
SELECT 
    p.id_producto,
    p.nombre,
    COUNT(DISTINCT vp.id_vista) AS total_vistas,
    COALESCE(SUM(dv.cantidad), 0) AS total_unidades_compradas
FROM Productos p
LEFT JOIN Vistas_Productos vp ON p.id_producto = vp.id_producto
LEFT JOIN Detalle_de_ventas dv ON p.id_producto = dv.id_producto
LEFT JOIN Ventas v ON dv.id_venta = v.id_venta AND v.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre
ORDER BY total_vistas DESC;

-- 19. Segmentación de Clientes (RFM)
WITH DatosRFM AS (
    SELECT 
        c.id_cliente,
        c.nombre,
        c.apellido,
        DATEDIFF('2025-05-01', MAX(v.fecha_venta)) AS recencia_dias,
        COUNT(v.id_venta) AS frecuencia,
        SUM(v.total) AS monetario
    FROM Clientes c
    JOIN Ventas v ON c.id_cliente = v.id_cliente
    WHERE v.estado != 'Cancelado'
    GROUP BY c.id_cliente, c.nombre, c.apellido
)
SELECT 
    id_cliente,
    nombre,
    apellido,
    recencia_dias,
    frecuencia,
    monetario,
    CASE 
        WHEN recencia_dias <= 30 AND frecuencia >= 3 AND monetario >= 1000000 THEN 'VIP / Leal'
        WHEN recencia_dias <= 60 AND frecuencia >= 1 THEN 'Cliente Activo'
        ELSE 'En Riesgo / Inactivo'
    END AS segmento_rfm
FROM DatosRFM;

-- 20. Predicción de Demanda Simple
WITH VentasHistoricas AS (
    SELECT 
        c.id_categoria,
        c.nombre AS categoria,
        DATE_FORMAT(v.fecha_venta, '%Y-%m') AS mes_anio,
        SUM(dv.cantidad) AS total_unidades
    FROM Detalle_de_ventas dv
    JOIN Productos p ON dv.id_producto = p.id_producto
    JOIN Categorias c ON p.id_categoria = c.id_categoria
    JOIN Ventas v ON dv.id_venta = v.id_venta
    WHERE v.estado != 'Cancelado'
    GROUP BY c.id_categoria, c.nombre, DATE_FORMAT(v.fecha_venta, '%Y-%m')
)
SELECT 
    categoria,
    ROUND(AVG(total_unidades), 0) AS proyeccion_unidades_proximo_mes
FROM VentasHistoricas
WHERE id_categoria = 1
GROUP BY categoria;

