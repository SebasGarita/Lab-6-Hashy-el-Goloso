-- ==========================================================
-- SCRIPT DE TRABAJO: LABORATORIO HASHY EL GOLOSO (MySQL)
-- TEC - Arquitectura de Datos
-- ==========================================================

-- 1. BITÁCORA DE OPERACIONES (Misión de la Llave 6)
-- Registra el rastro de cada transformación del pipeline.
CREATE TABLE logs_hashy (
    id SERIAL PRIMARY KEY,
    nombre_funcion VARCHAR(255),
    fecha_ejecucion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mensaje_accion TEXT,
    usuario_db VARCHAR(100) DEFAULT (CURRENT_USER())
);

-- 2. MERCADO NEGRO DE TORTUGA (Misión de la Llave 3)
-- Sirve para realizar las subconsultas de comparación de precios.
CREATE TABLE mercado_negro (
    id SERIAL PRIMARY KEY,
    categoria VARCHAR(100) UNIQUE, 
    precio_referencia DECIMAL(10,2),
    ultima_actualizacion DATE
);

-- 3. INVENTARIO DE GOLOSINAS (La tabla principal)
-- Contiene los datos "sucios" que deben ser procesados por las 7 llaves.
CREATE TABLE inventario_pirata (
    id INT PRIMARY KEY,               -- Usado para la Llave 1 (Primalidad)
    nombre_sucio VARCHAR(255),        -- Usado para la Llave 4 (Sanitización)
    categoria VARCHAR(100),           -- Relación con Mercado Negro
    precio_finca DECIMAL(10,2),       -- Usado para la Llave 3 (Tasación)
    prioridad_logica INT,             -- Metadata adicional
    fecha_ingreso DATE,               -- Usado para la Llave 2 (Reloj de Arena)
    meses_validez INT,                -- Usado para la Llave 2 (Reloj de Arena)
    FOREIGN KEY (categoria) REFERENCES mercado_negro(categoria)
);

-- ==========================================================
-- DATOS SEMILLA
-- ==========================================================

-- Llenado del Mercado Negro
INSERT INTO mercado_negro (categoria, precio_referencia, ultima_actualizacion) VALUES 
('Caramelos', 15.00, '2026-01-01'),
('Chocolates', 45.00, '2026-01-01'),
('Gomitas', 20.00, '2026-01-01');

-- Llenado del Inventario
-- Incluimos la 'Gomita Mágica' (ID 7) para que haya variedad en el resultado.
INSERT INTO inventario_pirata (id, nombre_sucio, categoria, precio_finca, prioridad_logica, fecha_ingreso, meses_validez) VALUES 
(1, '  cArr-Amelo_Menta  ', 'Caramelos', 12.00, 2, '2026-02-15', 6),   -- ID 1: No es primo.
(2, 'CHoco-late...Amargo', 'Chocolates', 55.00, 3, '2025-10-01', 3),     -- ID 2: VENCIDO.
(3, ' gomita-O_O-fresa ', 'Gomitas', 18.00, 4, '2026-03-01', 12),         -- ID 3: PASA (Primo + Fresco).
(4, '---TRUFA_Oscura---', 'Chocolates', 40.00, 5, '2026-01-10', 5),       -- ID 4: No es primo.
(5, 'Caramelo_Salado!!', 'Caramelos', 18.00, 7, '2025-12-01', 2),         -- ID 5: VENCIDO.
(6, 'Gomita_Osa', 'Gomitas', 25.00, 11, '2026-04-10', 8),                  -- ID 6: No es primo.
(7, '  !!Gomita_Mágica??  ', 'Gomitas', 22.00, 13, '2026-04-01', 10);     -- ID 7: PASA (Primo + Fresco).

-- ==========================================================
-- RESULTADO FINAL ESPERADO (VERIFICACIÓN)
-- ==========================================================
-- Los únicos IDs que deben generar un Hash al final son el 3 y el 7.
-- La consulta final debe devolver: hash(ID 3) # hash(ID 7)



-- INTEGRANTE B: Sebastián Garita
-- Llaves 3 y 4: fn_espia_tortuga y fn_purificador

-- LLAVE 3 — fn_espia_tortuga
SET GLOBAL log_bin_trust_function_creators = 1;

DROP FUNCTION IF EXISTS fn_espia_tortuga;

CREATE FUNCTION fn_espia_tortuga(
    p_cat   VARCHAR(100),
    p_prec  DECIMAL(10,2)
)
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
    DECLARE v_precio_mercado DECIMAL(10,2) DEFAULT 0;
    DECLARE v_factor         DECIMAL(3,2)  DEFAULT 1.0;
 
    IF p_cat IS NULL OR p_prec IS NULL THEN
        RETURN NULL;
    END IF;
 
    SELECT precio_referencia
    INTO   v_precio_mercado
    FROM   mercado_negro
    WHERE  categoria = p_cat
    LIMIT  1;
 
    IF v_precio_mercado IS NULL OR v_precio_mercado = 0 THEN
        RETURN NULL;
    END IF;
 
    IF p_prec > v_precio_mercado THEN
        SET v_factor = 1.2;
    ELSE
        SET v_factor = 0.8;
    END IF;
 
    RETURN v_factor;
END


-- PRUEBAS DE fn_espia_tortuga
SELECT
    id,
    nombre_sucio,
    categoria,
    precio_finca,
    fn_espia_tortuga(categoria, precio_finca) AS factor_calculado
FROM inventario_pirata;

-- LLAVE 4 — fn_purificador


DROP FUNCTION IF EXISTS fn_purificador;


CREATE FUNCTION fn_purificador(
    p_nombre TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE v_texto_limpio TEXT DEFAULT '';
    IF p_nombre IS NULL THEN
        RETURN NULL;
    END IF;

    SET v_texto_limpio = REGEXP_REPLACE(p_nombre, '[^a-zA-ZÀ-ÿ]', '');
    SET v_texto_limpio = TRIM(v_texto_limpio);
   
    IF v_texto_limpio = '' THEN
        RETURN NULL;
    END IF;

    RETURN v_texto_limpio;
end;


-- PRUEBAS DE fn_purificador
SELECT
    id,
    nombre_sucio,
    fn_purificador(nombre_sucio) AS nombre_limpio
FROM inventario_pirata;
-- ==========================================================
-- LLAVES 1 Y 2
-- Laboratorio: Hashy el Goloso - TEC Arquitectura de Datos
-- ==========================================================

-- ----------------------------------------------------------
-- LLAVE 1: fn_cernidor
-- Recibe el ID del producto y verifica si es un numero primo.
-- Retorna TRUE si es primo, FALSE si no lo es.
-- Numeros primos en el inventario: 2, 3, 5, 7
-- Numeros NO primos: 1, 4, 6
-- ----------------------------------------------------------

DROP FUNCTION IF EXISTS fn_cernidor;

DELIMITER $$

CREATE FUNCTION fn_cernidor(p_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_divisor INT;
    DECLARE v_es_primo BOOLEAN;

    -- Paso 1: Los numeros menores a 2 no son primos
    IF p_id < 2 THEN
        RETURN FALSE;
    END IF;

    -- Paso 2: El 2 es el unico primo par, se retorna directo
    IF p_id = 2 THEN
        RETURN TRUE;
    END IF;

    -- Paso 3: Cualquier numero par mayor a 2 no es primo
    IF MOD(p_id, 2) = 0 THEN
        RETURN FALSE;
    END IF;

    -- Paso 4: Revisar divisores impares desde 3 hasta la raiz cuadrada del numero
    SET v_divisor = 3;
    SET v_es_primo = TRUE;

    WHILE v_divisor <= FLOOR(SQRT(p_id)) DO
        IF MOD(p_id, v_divisor) = 0 THEN
            SET v_es_primo = FALSE;
            SET v_divisor = p_id; -- Forzar salida del ciclo
        END IF;
        SET v_divisor = v_divisor + 2;
    END WHILE;

    -- Paso 5: Retornar el resultado
    RETURN v_es_primo;
END$$

DELIMITER ;

-- Pruebas de la Llave 1
-- Resultados esperados segun el inventario:
SELECT fn_cernidor(1) AS es_primo; -- Esperado: FALSE (1 no es primo)
SELECT fn_cernidor(2) AS es_primo; -- Esperado: TRUE
SELECT fn_cernidor(3) AS es_primo; -- Esperado: TRUE
SELECT fn_cernidor(4) AS es_primo; -- Esperado: FALSE
SELECT fn_cernidor(5) AS es_primo; -- Esperado: TRUE
SELECT fn_cernidor(6) AS es_primo; -- Esperado: FALSE
SELECT fn_cernidor(7) AS es_primo; -- Esperado: TRUE

-- Verificacion directa contra la tabla
SELECT id, fn_cernidor(id) AS es_primo
FROM inventario_pirata;
-- Solo los IDs 2, 3, 5 y 7 deben dar TRUE


-- ----------------------------------------------------------
-- LLAVE 2: fn_reloj_arena
-- Recibe la fecha de ingreso y la cantidad de meses de validez.
-- Suma los meses a la fecha y compara con la fecha actual.
-- Retorna 'Fresco' si aun no vence, 'Expirado' si ya vencio.
-- ----------------------------------------------------------

DROP FUNCTION IF EXISTS fn_reloj_arena;

DELIMITER $$

CREATE FUNCTION fn_reloj_arena(p_fecha DATE, p_meses INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE v_fecha_vencimiento DATE;
    DECLARE v_estado            VARCHAR(10);

    -- Paso 1: Calcular la fecha de vencimiento sumando los meses de validez
    SET v_fecha_vencimiento = DATE_ADD(p_fecha, INTERVAL p_meses MONTH);

    -- Paso 2: Comparar la fecha de vencimiento con la fecha actual del sistema
    IF v_fecha_vencimiento >= CURDATE() THEN
        SET v_estado = 'Fresco';
    ELSE
        SET v_estado = 'Expirado';
    END IF;

    -- Paso 3: Retornar el estado
    RETURN v_estado;
END$$

DELIMITER ;

-- Pruebas de la Llave 2
-- Fecha de referencia del script: 2026-04-25
SELECT fn_reloj_arena('2026-02-15', 6)  AS estado; -- Vence 2026-08-15 -> Esperado: Fresco
SELECT fn_reloj_arena('2025-10-01', 3)  AS estado; -- Vence 2026-01-01 -> Esperado: Expirado
SELECT fn_reloj_arena('2026-03-01', 12) AS estado; -- Vence 2027-03-01 -> Esperado: Fresco
SELECT fn_reloj_arena('2026-01-10', 5)  AS estado; -- Vence 2026-06-10 -> Esperado: Fresco
SELECT fn_reloj_arena('2025-12-01', 2)  AS estado; -- Vence 2026-02-01 -> Esperado: Expirado
SELECT fn_reloj_arena('2026-04-10', 8)  AS estado; -- Vence 2026-12-10 -> Esperado: Fresco
SELECT fn_reloj_arena('2026-04-01', 10) AS estado; -- Vence 2027-02-01 -> Esperado: Fresco

-- Verificacion directa contra la tabla
SELECT id, fecha_ingreso, meses_validez,
       DATE_ADD(fecha_ingreso, INTERVAL meses_validez MONTH) AS fecha_vencimiento,
       fn_reloj_arena(fecha_ingreso, meses_validez)          AS estado
FROM inventario_pirata;
-- IDs 2 y 5 deben aparecer como Expirado, el resto como Fresco


