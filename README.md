# Proyecto_BD_Avanzada_Ecommerce

## Descripción Breve
Este proyecto implementa una solución integral de base de datos relacional para una plataforma de comercio electrónico (E-commerce) en MySQL 8.0 desplegada mediante contenedores con Docker. Incluye el diseño del esquema de datos, consultas de analítica avanzada, funciones almacenadas, control de acceso basado en roles (RBAC) con directivas de seguridad de 20 puntos, disparadores de auditoría, eventos programados de mantenimiento y procedimientos para generación de reportes comerciales.

## Integrantes
* Marlon Andres Silva Garcia

## Instrucciones de Ejecución

Para construir, poblar y desplegar correctamente la base de datos `Ecommerce`, asegúrate de tener el contenedor de Docker activo (`docker compose up -d`) y ejecuta los archivos SQL en el gestor de tu preferencia (como DBeaver) en el siguiente orden secuencial:

1. **`01_Esquema_y_Datos.sql`**: Crea la estructura general de las tablas, relaciones, claves primarias/foráneas y carga el conjunto de datos iniciales.
2. **`02_Consultas_Avanzadas.sql`**: Implementa las vistas y consultas complejas para reportes analíticos y métricas de negocio.
3. **`03_Funciones.sql`**: Registra las funciones almacenadas reutilizables para cálculos de totales, descuentos e impuestos.
4. **`04_Seguridad.sql`**: Aplica el módulo de seguridad, la definición de roles (RBAC), asignación de permisos y creación de usuarios del sistema.
5. **`05_Triggers.sql`**: Configura los disparadores automáticos para auditoría de cambios de precios y control de inventario.
6. **`06_Eventos.sql`**: Establece los eventos programados en MySQL para tareas periódicas de mantenimiento y depuración.
7. **`07_Procedimientos_Almacenados.sql`**: Agrega los procedimientos almacenados para generación de reportes mensuales y operaciones complejas.
