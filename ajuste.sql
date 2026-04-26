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
--===========================================================

-- ==========================================================
-- LLAVES 3 Y 4
-- Rama: feature/mercado-limpieza
-- Laboratorio: Hashy el Goloso - TEC Arquitectura de Datos
-- ==========================================================

-- ----------------------------------------------------------
-- LLAVE 3: fn_espia_tortuga
-- Consulta el precio de referencia en mercado_negro y
-- retorna el factor 1.2 (si precio_finca > mercado)
-- o 0.8 (si precio_finca <= mercado).
-- ----------------------------------------------------------

DROP FUNCTION IF EXISTS fn_espia_tortuga;

DELIMITER $$

CREATE FUNCTION fn_espia_tortuga(p_cat VARCHAR(100), p_prec DECIMAL(10,2))
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
    DECLARE v_precio_mercado DECIMAL(10,2);
    DECLARE v_factor         DECIMAL(3,2);

    -- Paso 1: Obtener el precio de referencia del mercado negro para esa categoria
    SELECT precio_referencia
    INTO   v_precio_mercado
    FROM   mercado_negro
    WHERE  categoria = p_cat;

    -- Paso 2: Si no se encontro la categoria, usar factor neutro para evitar nulos
    IF v_precio_mercado IS NULL THEN
        SET v_factor = 1.0;
    -- Paso 3: Comparar precio de finca vs precio de mercado
    ELSEIF p_prec > v_precio_mercado THEN
        SET v_factor = 1.2;
    ELSE
        SET v_factor = 0.8;
    END IF;

    -- Paso 4: Retornar el factor calculado
    RETURN v_factor;
END$$

DELIMITER ;

-- Pruebas de la Llave 3
-- Gomitas: precio_referencia = 20.00
SELECT fn_espia_tortuga('Gomitas', 22.00) AS factor; -- Esperado: 1.2  (22 > 20)
SELECT fn_espia_tortuga('Gomitas', 18.00) AS factor; -- Esperado: 0.8  (18 <= 20)
-- Chocolates: precio_referencia = 45.00
SELECT fn_espia_tortuga('Chocolates', 55.00) AS factor; -- Esperado: 1.2 (55 > 45)
SELECT fn_espia_tortuga('Chocolates', 40.00) AS factor; -- Esperado: 0.8 (40 <= 45)
-- Caramelos: precio_referencia = 15.00
SELECT fn_espia_tortuga('Caramelos', 12.00) AS factor; -- Esperado: 0.8 (12 <= 15)
SELECT fn_espia_tortuga('Caramelos', 18.00) AS factor; -- Esperado: 1.2 (18 > 15)


-- ----------------------------------------------------------
-- LLAVE 4: fn_purificador
-- Recibe el nombre sucio del producto, elimina todo caracter
-- no alfabetico usando REGEXP_REPLACE y retorna el nombre limpio.
-- ----------------------------------------------------------

DROP FUNCTION IF EXISTS fn_purificador;

DELIMITER $$

CREATE FUNCTION fn_purificador(p_nombre TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE v_sin_simbolos TEXT;
    DECLARE v_nombre_limpio TEXT;

    -- Paso 1: Eliminar cualquier caracter que NO sea letra (a-z, A-Z)
    -- Esto borra guiones, underscores, signos, espacios internos, etc.
    SET v_sin_simbolos = REGEXP_REPLACE(p_nombre, '[^a-zA-Z]', '');

    -- Paso 2: Eliminar espacios sobrantes al inicio y al final
    SET v_nombre_limpio = TRIM(v_sin_simbolos);

    -- Paso 3: Retornar la cadena purificada
    RETURN v_nombre_limpio;
END$$

DELIMITER ;

-- Pruebas de la Llave 4
SELECT fn_purificador('  cArr-Amelo_Menta  ')   AS nombre_limpio; -- Esperado: cArrAmeloMenta
SELECT fn_purificador('CHoco-late...Amargo')     AS nombre_limpio; -- Esperado: CHocolateAmargo
SELECT fn_purificador(' gomita-O_O-fresa ')      AS nombre_limpio; -- Esperado: gomitaOOfresa
SELECT fn_purificador('---TRUFA_Oscura---')      AS nombre_limpio; -- Esperado: TRUFAOscura
SELECT fn_purificador('Caramelo_Salado!!')       AS nombre_limpio; -- Esperado: CarameloSalado
SELECT fn_purificador('Gomita_Osa')              AS nombre_limpio; -- Esperado: GomitaOsa
SELECT fn_purificador('  !!Gomita_Mágica??  ')   AS nombre_limpio; -- Esperado: GomitaMgica
-- ----------------------------------------------------------
