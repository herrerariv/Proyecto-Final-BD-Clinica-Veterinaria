-- ============================================================
-- FUNCIÓN: Calcular total facturado de una mascota.

CREATE OR REPLACE FUNCTION calcular_total_facturado_mascota(p_id_mascota INT)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total NUMERIC(10,2);
BEGIN
    SELECT COALESCE(SUM(fd.subtotal), 0)
    INTO total
    FROM mascota m
    INNER JOIN cita c
        ON m.id_mascota = c.id_mascota
    INNER JOIN factura f
        ON c.id_cita = f.id_cita
    INNER JOIN factura_detalle fd
        ON f.id_factura = fd.id_factura
    WHERE m.id_mascota = p_id_mascota
      AND f.estado_factura = 'Pagada';

    RETURN total;
END;
$$;

-- sentencia de ejemplo para ver el funcionamiento:
SELECT 
    m.id_mascota,
    m.nombre_mascota,
    calcular_total_facturado_mascota(m.id_mascota) AS total_facturado
FROM mascota m
WHERE m.id_mascota = 3;

-- ====================================================================

-- PROCEDIMIENTO ALMACENADO: historial clínico de una mascota dado su ID

CREATE OR REPLACE PROCEDURE generar_historial_clinico_mascota(p_id_mascota INT)
LANGUAGE plpgsql
AS $$
DECLARE
    total_registros INT;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS historial_clinico_temp (
        nombre_mascota VARCHAR(60),
        fecha_cita DATE,
        motivo_cita VARCHAR(150),
        diagnostico VARCHAR(255),
        tratamiento VARCHAR(100),
        medicamento VARCHAR(80),
        procedimiento VARCHAR(100)
    ) ON COMMIT PRESERVE ROWS;

    TRUNCATE TABLE historial_clinico_temp;

    INSERT INTO historial_clinico_temp (
        nombre_mascota,
        fecha_cita,
        motivo_cita,
        diagnostico,
        tratamiento,
        medicamento,
        procedimiento
    )
    SELECT 
        m.nombre_mascota,
        c.fecha_cita,
        c.motivo_cita,
        d.descripcion_diagnostico,
        t.nombre_tratamiento,
        med.nombre_medicamento,
        pr.nombre_procedimiento
    FROM mascota m
    INNER JOIN cita c
        ON m.id_mascota = c.id_mascota
    INNER JOIN diagnostico d
        ON c.id_cita = d.id_cita
    LEFT JOIN tratamiento t
        ON d.id_diagnostico = t.id_diagnostico
    LEFT JOIN tratamiento_medicamento tm
        ON t.id_tratamiento = tm.id_tratamiento
    LEFT JOIN medicamento med
        ON tm.id_medicamento = med.id_medicamento
    LEFT JOIN procedimiento pr
        ON d.id_diagnostico = pr.id_diagnostico
    WHERE m.id_mascota = p_id_mascota
    ORDER BY c.fecha_cita DESC;

    GET DIAGNOSTICS total_registros = ROW_COUNT;

    IF total_registros = 0 THEN
        RAISE NOTICE 'No se encontró historial clínico para la mascota con ID %.', p_id_mascota;
    ELSE
        RAISE NOTICE 'Historial clínico generado correctamente para la mascota con ID %. Registros encontrados: %.',
        p_id_mascota, total_registros;
    END IF;
END;
$$;

-- Mandar a llamar el procedimiento y el id de la mascota en especifico:
CALL generar_historial_clinico_mascota(3);

SELECT * FROM historial_clinico_temp;

-- ====================================================================

-- TRIGGER: Validar alergia antes de asignar medicamento

-- ============================================================
-- TRIGGER: VALIDACIÓN DE ALERGIAS A MEDICAMENTOS
-- ============================================================
-- Propósito:
-- Evitar que se asigne a una mascota un medicamento al que tiene
-- una alergia registrada.

CREATE OR REPLACE FUNCTION validar_alergia_medicamento()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_mascota INT;
    v_nombre_mascota VARCHAR(60);
    v_nombre_medicamento VARCHAR(80);
BEGIN
    SELECT 
        c.id_mascota,
        m.nombre_mascota,
        med.nombre_medicamento
    INTO 
        v_id_mascota,
        v_nombre_mascota,
        v_nombre_medicamento
    FROM tratamiento t
    INNER JOIN diagnostico d 
        ON t.id_diagnostico = d.id_diagnostico
    INNER JOIN cita c 
        ON d.id_cita = c.id_cita
    INNER JOIN mascota m 
        ON c.id_mascota = m.id_mascota
    INNER JOIN medicamento med 
        ON med.id_medicamento = NEW.id_medicamento
    WHERE t.id_tratamiento = NEW.id_tratamiento;

    IF EXISTS (
        SELECT 1
        FROM mascota_alergia ma
        WHERE ma.id_mascota = v_id_mascota
          AND ma.id_medicamento = NEW.id_medicamento
    ) THEN
        RAISE EXCEPTION 
        'No se puede asignar el medicamento %, porque la mascota % tiene una alergia registrada.',
        v_nombre_medicamento, v_nombre_mascota;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_alergia_medicamento
ON tratamiento_medicamento;

CREATE TRIGGER trg_validar_alergia_medicamento
BEFORE INSERT OR UPDATE ON tratamiento_medicamento
FOR EACH ROW
EXECUTE FUNCTION validar_alergia_medicamento();

-- ===================================================================

-- Caso: Lilyan, no presenta alergias:
-- sentencia para verificar si no las presenta.
SELECT 
    m.id_mascota,
    m.nombre_mascota,
    med.id_medicamento,
    med.nombre_medicamento,
    ma.descripcion_alergia,
    t.id_tratamiento
FROM mascota m
CROSS JOIN medicamento med
LEFT JOIN mascota_alergia ma
    ON m.id_mascota = ma.id_mascota
   AND med.id_medicamento = ma.id_medicamento
INNER JOIN cita c
    ON m.id_mascota = c.id_mascota
INNER JOIN diagnostico d
    ON c.id_cita = d.id_cita
INNER JOIN tratamiento t
    ON d.id_diagnostico = t.id_diagnostico
WHERE m.id_mascota = 18
  AND med.id_medicamento = 1
  AND t.id_tratamiento = 18;

-- Insercción del medicamento permitido.
BEGIN;

INSERT INTO tratamiento_medicamento (
    dosis_indicada,
    frecuencia_administracion,
    via_administracion,
    duracion_dias,
    id_tratamiento,
    id_medicamento
)
VALUES (
    '1 tableta',
    'Cada 24 horas',
    'Oral',
    5,
    18,
    1
)
RETURNING 
    id_tratamiento_medicamento,
    dosis_indicada,
    frecuencia_administracion,
    via_administracion,
    duracion_dias,
    id_tratamiento,
    id_medicamento;

-- Rollback para no guardar ese dato permanente.
ROLLBACK;

-- Caso: Payton, presenta alergias, el trigger no permitira la insercción.

-- sentencia para verificar que sí Payton presenta alergias:
SELECT 
    m.id_mascota,
    m.nombre_mascota,
    med.id_medicamento,
    med.nombre_medicamento,
    ma.descripcion_alergia,
    t.id_tratamiento
FROM mascota m
INNER JOIN mascota_alergia ma
    ON m.id_mascota = ma.id_mascota
INNER JOIN medicamento med
    ON ma.id_medicamento = med.id_medicamento
INNER JOIN cita c
    ON m.id_mascota = c.id_mascota
INNER JOIN diagnostico d
    ON c.id_cita = d.id_cita
INNER JOIN tratamiento t
    ON d.id_diagnostico = t.id_diagnostico
WHERE m.id_mascota = 1
  AND med.id_medicamento = 1
  AND t.id_tratamiento = 1;

-- Intentar insertar el medicamento bloqueado:
INSERT INTO tratamiento_medicamento (
    dosis_indicada,
    frecuencia_administracion,
    via_administracion,
    duracion_dias,
    id_tratamiento,
    id_medicamento
)
VALUES (
    '5 ml',
    'Cada 12 horas',
    'Oral',
    7,
    1,
    1
);
-- ERROR: No se puede asignar el medicamento Amoxicilina, porque la mascota Payton tiene una alergia registrada.

-- Despues del error, ejecutar ROLLBACK
ROLLBACK;

-- ====================================================================

-- TRANSACCIÓN: Anulación de factura y cancelación de cita relacionada

-- 
-- Se utiliza ROLLBACK al final porque es una demostración. Si se quisiera
-- guardar el cambio de forma permanente, se usaría COMMIT.

SELECT 
    f.id_factura,
    f.numero_factura,
    f.estado_factura,
    c.id_cita,
    c.estado_cita,
    c.observaciones_cita
FROM factura f
INNER JOIN cita c
    ON f.id_cita = c.id_cita
WHERE f.id_factura = 1;

-- =============================================================
BEGIN;

UPDATE factura
SET estado_factura = 'Anulada'
WHERE id_factura = 1;

UPDATE cita
SET 
    estado_cita = 'Cancelada',
    observaciones_cita = 'Cita cancelada por anulación de factura'
WHERE id_cita = (
    SELECT id_cita
    FROM factura
    WHERE id_factura = 1
);

-- =============================================================
SELECT 
    f.id_factura,
    f.numero_factura,
    f.estado_factura,
    c.id_cita,
    c.estado_cita,
    c.observaciones_cita
FROM factura f
INNER JOIN cita c
    ON f.id_cita = c.id_cita
WHERE f.id_factura = 1;
-- =============================================================

ROLLBACK;

-- =============================================================
SELECT 
    f.id_factura,
    f.numero_factura,
    f.estado_factura,
    c.id_cita,
    c.estado_cita,
    c.observaciones_cita
FROM factura f
INNER JOIN cita c
    ON f.id_cita = c.id_cita
WHERE f.id_factura = 1;

-- =============================================================
