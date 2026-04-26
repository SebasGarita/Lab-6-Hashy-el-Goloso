<<<<<<< HEAD
-- ==========================================================
-- LABORATORIO HASHY EL GOLOSO
-- INTEGRANTE C - Rama: feature/estetica-seguridad
-- Llaves 5, 6 y 7 + Consulta Maestra
-- ==========================================================

USE hashy_db; -- Ajusta al nombre de la BD que use el equipo

-- ==========================================================
-- LLAVE 5: fn_escultor
-- Aplica UPPER/LOWER según el factor recibido y agrega sufijo
-- ==========================================================
DROP FUNCTION IF EXISTS fn_escultor;

DELIMITER $$

=======
USE hashy_db;

-- Permitir creación de funciones que modifican datos
SET GLOBAL log_bin_trust_function_creators = 1;

-- LLAVE 5: fn_escultor
-- Aplica UPPER/LOWER según el factor recibido y agrega sufijo
DROP FUNCTION IF EXISTS fn_escultor;

>>>>>>> cd81cb2 (Versión final probada: funciones sin DELIMITER y Consulta Maestra)
CREATE FUNCTION fn_escultor(p_nombre TEXT, p_factor DECIMAL(3,2))
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE v_texto_transformado TEXT DEFAULT '';
    DECLARE v_sufijo VARCHAR(50) DEFAULT '';
    DECLARE v_resultado TEXT DEFAULT '';

    -- Manejo de nulidad: si entra NULL, devolvemos texto vacío
    IF p_nombre IS NULL OR p_factor IS NULL THEN
        SET v_resultado = '';
    ELSE
        -- Si el factor indica alta prioridad (>1), mayúsculas
        IF p_factor > 1 THEN
            SET v_texto_transformado = UPPER(p_nombre);
            SET v_sufijo = '_PREMIUM';
        ELSE
            SET v_texto_transformado = LOWER(p_nombre);
            SET v_sufijo = '_basico';
        END IF;
<<<<<<< HEAD

=======
>>>>>>> cd81cb2 (Versión final probada: funciones sin DELIMITER y Consulta Maestra)
        SET v_resultado = CONCAT(v_texto_transformado, v_sufijo);
    END IF;

    RETURN v_resultado;
<<<<<<< HEAD
END$$

DELIMITER ;


-- ==========================================================
-- LLAVE 6: fn_notario
-- Inserta en logs_hashy y retorna el texto sin modificarlo
-- ==========================================================
DROP FUNCTION IF EXISTS fn_notario;

DELIMITER $$

=======
END;

-- LLAVE 6: fn_notario
-- Inserta en logs_hashy y retorna el texto sin modificarlo
-- Incluye DECLARE EXIT HANDLER para manejo de excepciones
DROP FUNCTION IF EXISTS fn_notario;

>>>>>>> cd81cb2 (Versión final probada: funciones sin DELIMITER y Consulta Maestra)
CREATE FUNCTION fn_notario(p_texto TEXT)
RETURNS TEXT
MODIFIES SQL DATA
BEGIN
    DECLARE v_mensaje TEXT DEFAULT '';
    DECLARE v_texto_seguro TEXT DEFAULT '';

    -- Manejo de excepciones: si algo falla, no rompemos el pipeline
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN COALESCE(p_texto, '');
    END;

    -- Manejo de nulidad
    IF p_texto IS NULL THEN
        SET v_texto_seguro = '[NULO]';
    ELSE
        SET v_texto_seguro = p_texto;
    END IF;

    SET v_mensaje = CONCAT('Pipeline procesado - Estado: ', v_texto_seguro);

<<<<<<< HEAD
    -- INSERT en la bitácora
    -- fecha_ejecucion y usuario_db tienen defaults, no los pasamos
=======
    -- INSERT en la bitácora (fecha y usuario tienen DEFAULT)
>>>>>>> cd81cb2 (Versión final probada: funciones sin DELIMITER y Consulta Maestra)
    INSERT INTO logs_hashy (nombre_funcion, mensaje_accion)
    VALUES ('fn_notario', v_mensaje);

    RETURN v_texto_seguro;
<<<<<<< HEAD
END$$

DELIMITER ;


-- ==========================================================
-- LLAVE 7: fn_gran_sello
-- Aplica MD5 al texto final y devuelve hash de longitud fija
-- ==========================================================
DROP FUNCTION IF EXISTS fn_gran_sello;

DELIMITER $$

=======
END;


-- LLAVE 7: fn_gran_sello
-- Aplica MD5 al texto final y devuelve hash de longitud fija
DROP FUNCTION IF EXISTS fn_gran_sello;

>>>>>>> cd81cb2 (Versión final probada: funciones sin DELIMITER y Consulta Maestra)
CREATE FUNCTION fn_gran_sello(p_texto TEXT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE v_texto_base TEXT DEFAULT '';
    DECLARE v_hash_crudo VARCHAR(255) DEFAULT '';
    DECLARE v_sello_final VARCHAR(255) DEFAULT '';

    -- Manejo de nulidad
    IF p_texto IS NULL THEN
        SET v_texto_base = '';
    ELSE
        SET v_texto_base = p_texto;
    END IF;

    -- Algoritmo de resumen criptográfico
    SET v_hash_crudo = MD5(v_texto_base);
<<<<<<< HEAD
    -- Aseguramos longitud fija (MD5 siempre devuelve 32 hex)
    SET v_sello_final = LPAD(v_hash_crudo, 32, '0');

    RETURN v_sello_final;
END$$

DELIMITER ;


-- ==========================================================
-- CONSULTA MAESTRA - PIPELINE DE LAS 7 LLAVES
-- Resultado esperado: hash de los IDs 3 y 7 separados por #
-- ==========================================================
=======
    -- Aseguramos longitud fija de 32 caracteres
    SET v_sello_final = LPAD(v_hash_crudo, 32, '0');

    RETURN v_sello_final;
END;


-- CONSULTA MAESTRA - PIPELINE DE LAS 7 LLAVES
-- Resultado esperado: hash MD5 de los IDs 3 y 7 separados por #
>>>>>>> cd81cb2 (Versión final probada: funciones sin DELIMITER y Consulta Maestra)
SELECT
    GROUP_CONCAT(
        fn_gran_sello(
            fn_notario(
                fn_escultor(
                    fn_purificador(nombre_sucio),
                    fn_espia_tortuga(categoria, precio_finca)
                )
            )
        )
        ORDER BY id ASC
        SEPARATOR ' # '
    ) AS resultado_final_del_trio
FROM inventario_pirata
WHERE
    fn_cernidor(id) = TRUE
    AND
    fn_reloj_arena(fecha_ingreso, meses_validez) = 'Fresco';