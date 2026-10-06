use Ecommerce;

-- 1. CREACIÓN DE LA TABLA DE AUDITORÍA
-- Esta tabla guardará el historial cada vez que se modifique el email o la dirección de un cliente.

CREATE TABLE IF NOT EXISTS Auditoria_Clientes (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY, 
    id_cliente INT NOT NULL,                    
    campo_modificado VARCHAR(50) NOT NULL,       
    valor_antiguo VARCHAR(255),                  
    valor_nuevo VARCHAR(255),                    
    fecha_modificacion DATETIME DEFAULT NOW()    
);

-- 2. CREACIÓN DEL TRIGGER DE AUDITORÍA
-- Este trigger se ejecuta DESPUÉS de que se actualice cualquier registro en la tabla Clientes.

DELIMITER //

CREATE TRIGGER trg_audit_cliente_after_update
AFTER UPDATE ON Clientes
FOR EACH ROW
BEGIN
    -- Verificamos si el campo 'email' cambió comparando el valor antiguo (OLD) con el nuevo (NEW)
    IF OLD.email <> NEW.email THEN
        INSERT INTO Auditoria_Clientes (
            id_cliente, 
            campo_modificado, 
            valor_antiguo, 
            valor_nuevo
        )
        VALUES (
            OLD.id_cliente, 
            'email', 
            OLD.email, 
            NEW.email
        );
    END IF;

    -- Verificamos si el campo 'direccion_envio' cambió
    -- Usamos NULL-safe operator (<=>) o control de NULLs en caso de que la dirección antigua fuera NULL
    IF NOT (OLD.direccion_envio <=> NEW.direccion_envio) THEN
        INSERT INTO Auditoria_Clientes (
            id_cliente, 
            campo_modificado, 
            valor_antiguo, 
            valor_nuevo
        )
        VALUES (
            OLD.id_cliente, 
            'direccion_envio', 
            OLD.direccion_envio, 
            NEW.direccion_envio
        );
    END IF;
END //

DELIMITER ;

-- Prueba email

UPDATE Clientes 
SET email = 'carlos.mendoza_nuevo@email.com' 
WHERE id_cliente = 1;

-- Prueba direccion

UPDATE Clientes 
SET direccion_envio = 'Carrera 15 #45-12' 
WHERE id_cliente = 1;

-- Prueba AMBOS

UPDATE Clientes 
SET email = 'ana.gomez_nueva@email.com',
    direccion_envio = 'Avenida Siempreviva 742'
WHERE id_cliente = 2;













