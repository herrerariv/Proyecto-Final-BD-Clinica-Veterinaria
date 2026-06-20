-- =============================================================
-- CONSULTAS:
-- =============================================================

-- 1: Mascotas más atendidas por mes
WITH citas_por_mascota AS (
    SELECT 
        EXTRACT(YEAR FROM c.fecha_cita) AS anio,
        EXTRACT(MONTH FROM c.fecha_cita) AS mes_numero,
        TRIM(TO_CHAR(c.fecha_cita, 'Month YYYY')) AS mes_anio,
        m.id_mascota,
        m.nombre_mascota,
        COUNT(c.id_cita) AS total_citas
    FROM mascota m
    INNER JOIN cita c
        ON m.id_mascota = c.id_mascota
    WHERE c.estado_cita = 'Atendida'
    GROUP BY 
        EXTRACT(YEAR FROM c.fecha_cita),
        EXTRACT(MONTH FROM c.fecha_cita),
        TRIM(TO_CHAR(c.fecha_cita, 'Month YYYY')),
        m.id_mascota,
        m.nombre_mascota
),
ranking AS (
    SELECT 
        anio,
        mes_numero,
        mes_anio,
        id_mascota,
        nombre_mascota,
        total_citas,
        ROW_NUMBER() OVER (
            PARTITION BY anio, mes_numero
            ORDER BY total_citas DESC, nombre_mascota ASC
        ) AS posicion
    FROM citas_por_mascota
)
SELECT 
    mes_anio,
    id_mascota,
    nombre_mascota,
    total_citas
FROM ranking
WHERE posicion = 1
ORDER BY anio, mes_numero;

-- 2. Veterinario con más citas por trimestre.

-- Trimestre 1: empiezan desde julio 2025
-- Trimestre 4: termina en junio 2026

WITH citas_por_veterinario AS (
    SELECT 
        CASE
            WHEN c.fecha_cita BETWEEN '2025-07-01' AND '2025-09-30' THEN 1
            WHEN c.fecha_cita BETWEEN '2025-10-01' AND '2025-12-31' THEN 2
            WHEN c.fecha_cita BETWEEN '2026-01-01' AND '2026-03-31' THEN 3
            WHEN c.fecha_cita BETWEEN '2026-04-01' AND '2026-06-30' THEN 4
        END AS trimestre_numero,
        CASE
            WHEN c.fecha_cita BETWEEN '2025-07-01' AND '2025-09-30' THEN 'Trimestre 1: Julio - Septiembre 2025'
            WHEN c.fecha_cita BETWEEN '2025-10-01' AND '2025-12-31' THEN 'Trimestre 2: Octubre - Diciembre 2025'
            WHEN c.fecha_cita BETWEEN '2026-01-01' AND '2026-03-31' THEN 'Trimestre 3: Enero - Marzo 2026'
            WHEN c.fecha_cita BETWEEN '2026-04-01' AND '2026-06-30' THEN 'Trimestre 4: Abril - Junio 2026'
        END AS trimestre,
        v.id_veterinario,
        CONCAT(v.nombres, ' ', v.apellidos) AS nombre_veterinario,
        COUNT(c.id_cita) AS total_citas
    FROM veterinario v
    INNER JOIN cita c
        ON v.id_veterinario = c.id_veterinario
    WHERE c.estado_cita = 'Atendida'
    GROUP BY 
        trimestre_numero,
        trimestre,
        v.id_veterinario,
        v.nombres,
        v.apellidos
)
SELECT DISTINCT ON (trimestre_numero)
    trimestre,
    id_veterinario,
    nombre_veterinario,
    total_citas
FROM citas_por_veterinario
ORDER BY 
    trimestre_numero,
    total_citas DESC,
    nombre_veterinario ASC;
    
-- 3.Medicamentos prescritos con mayor frecuencia


SELECT 
    med.id_medicamento,
    med.nombre_medicamento,
    med.tipo_medicamento,
    COUNT(tm.id_tratamiento_medicamento) AS total_prescripciones
FROM medicamento med
INNER JOIN tratamiento_medicamento tm
    ON med.id_medicamento = tm.id_medicamento
INNER JOIN tratamiento t
    ON tm.id_tratamiento = t.id_tratamiento
GROUP BY 
    med.id_medicamento,
    med.nombre_medicamento,
    med.tipo_medicamento
ORDER BY total_prescripciones DESC;


-- 4. Ingresos reales por especialidad veterinaria
SELECT 
    e.nombre_especialidad,
    COUNT(f.id_factura) AS total_facturas,
    ROUND(SUM(f.total_factura), 2) AS ingresos_reales
FROM especialidad e
INNER JOIN veterinario v 
    ON e.id_especialidad = v.id_especialidad
INNER JOIN cita c 
    ON v.id_veterinario = c.id_veterinario
INNER JOIN factura f 
    ON c.id_cita = f.id_cita
WHERE f.estado_factura = 'Pagada'
GROUP BY e.nombre_especialidad
ORDER BY ingresos_reales DESC;


-- Ejercicio 5. Propietarios con mascotas sin citas en los últimos 6 meses

SELECT 
    CONCAT(p.nombres, ' ', p.apellidos) AS propietario,
    m.nombre_mascota,
    e.nombre_especie,
    MAX(c.fecha_cita) AS ultima_cita,
    CASE
        WHEN MAX(c.fecha_cita) IS NULL THEN 'Sin citas registradas'
        ELSE CONCAT((CURRENT_DATE - MAX(c.fecha_cita))::INT, ' dias')
    END AS tiempo_sin_cita
FROM propietario p
INNER JOIN mascota m 
    ON p.id_propietario = m.id_propietario
INNER JOIN especie e 
    ON m.id_especie = e.id_especie
LEFT JOIN cita c 
    ON m.id_mascota = c.id_mascota
GROUP BY 
    p.id_propietario,
    p.nombres,
    p.apellidos,
    m.id_mascota,
    m.nombre_mascota,
    e.nombre_especie
HAVING 
    MAX(c.fecha_cita) IS NULL
    OR MAX(c.fecha_cita) < CURRENT_DATE - INTERVAL '6 months'
ORDER BY ultima_cita NULLS FIRST, propietario;

-- 6. Listado de propietarios y mascotas, contacto y especie con formato de texto

SELECT 
    UPPER(CONCAT(p.nombres, ' ', p.apellidos)) AS propietario,
    INITCAP(m.nombre_mascota) AS mascota,
    LOWER(e.nombre_especie) AS especie,
    CONCAT('Telefono: ', COALESCE(p.telefono, 'Sin telefono')) AS contacto
FROM propietario p
INNER JOIN mascota m
    ON p.id_propietario = m.id_propietario
INNER JOIN especie e
    ON m.id_especie = e.id_especie
ORDER BY propietario, mascota;

--  7. Veterinarios con alta cantidad de citas atendidas

SELECT 
    v.id_veterinario,
    CONCAT(v.nombres, ' ', v.apellidos) AS nombre_veterinario,
    COUNT(c.id_cita) AS total_citas_atendidas
FROM veterinario v
INNER JOIN cita c
    ON v.id_veterinario = c.id_veterinario
WHERE c.estado_cita = 'Atendida'
GROUP BY 
    v.id_veterinario,
    v.nombres,
    v.apellidos
HAVING COUNT(c.id_cita) > 1
ORDER BY total_citas_atendidas DESC, nombre_veterinario ASC;

-- 8. Mascotas con más citas que el promedio general


SELECT 
    m.id_mascota,
    m.nombre_mascota,
    COUNT(c.id_cita) AS total_citas
FROM mascota m
INNER JOIN cita c
    ON m.id_mascota = c.id_mascota
GROUP BY 
    m.id_mascota,
    m.nombre_mascota
HAVING COUNT(c.id_cita) > (
    SELECT AVG(total_por_mascota)
    FROM (
        SELECT COUNT(c2.id_cita) AS total_por_mascota
        FROM mascota m2
        INNER JOIN cita c2
            ON m2.id_mascota = c2.id_mascota
        GROUP BY m2.id_mascota
    ) AS promedio_citas
)
ORDER BY total_citas DESC, m.nombre_mascota ASC

-- 9. Facturas con su total calculado desde el detalle

SELECT 
    f.id_factura,
    f.numero_factura,
    f.total_factura,
    SUM(fd.subtotal) AS total_detalles,
    CASE
        WHEN f.total_factura = SUM(fd.subtotal) THEN 'Correcta'
        ELSE 'Revisar'
    END AS estado_validacion
FROM factura f
INNER JOIN factura_detalle fd
    ON f.id_factura = fd.id_factura
GROUP BY 
    f.id_factura,
    f.numero_factura,
    f.total_factura


-- 10. Historial básico de atención por mascota.
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
INNER JOIN tratamiento t 
    ON d.id_diagnostico = t.id_diagnostico
INNER JOIN tratamiento_medicamento tm 
    ON t.id_tratamiento = tm.id_tratamiento
INNER JOIN medicamento med 
    ON tm.id_medicamento = med.id_medicamento
INNER JOIN procedimiento pr 
    ON d.id_diagnostico = pr.id_diagnostico
WHERE m.id_mascota = 1
ORDER BY c.fecha_cita DESC;

-- 11. Mascotas con alergias registradas a medicamentos
SELECT 
    m.nombre_mascota,
    med.nombre_medicamento,
    ma.descripcion_alergia
FROM mascota m
INNER JOIN mascota_alergia ma
    ON m.id_mascota = ma.id_mascota
INNER JOIN medicamento med
    ON ma.id_medicamento = med.id_medicamento
ORDER BY m.nombre_mascota;
-- =============================================================

-- 12. -- Ejercicio 12. Distribución de citas por estado

SELECT 
    estado_cita,
    COUNT(*) AS total_citas
FROM cita
GROUP BY estado_cita
ORDER BY total_citas DESC;

-- 13. cantidad de citas registradas por cada especie de mascota

SELECT 
    e.id_especie,
    e.nombre_especie,
    COUNT(c.id_cita) AS total_citas
FROM especie e
INNER JOIN mascota m
    ON e.id_especie = m.id_especie
INNER JOIN cita c
    ON m.id_mascota = c.id_mascota
GROUP BY 
    e.id_especie,
    e.nombre_especie
ORDER BY total_citas DESC;

--14. Promedio de ingresos por factura según método de pago
SELECT 
    f.metodo_pago,
    COUNT(f.id_factura) AS total_facturas,
    ROUND(AVG(f.total_factura), 2) AS promedio_factura,
    ROUND(SUM(f.total_factura), 2) AS total_facturado
FROM factura f
WHERE f.estado_factura = 'Pagada'
GROUP BY f.metodo_pago
ORDER BY total_facturado DESC;

-- 15. Tratamientos con mayor cantidad de medicamentos asociados

SELECT 
    t.nombre_tratamiento,
    COUNT(tm.id_medicamento) AS total_medicamentos_asociados
FROM tratamiento t
INNER JOIN tratamiento_medicamento tm
    ON t.id_tratamiento = tm.id_tratamiento
INNER JOIN medicamento med
    ON tm.id_medicamento = med.id_medicamento
GROUP BY t.nombre_tratamiento
ORDER BY total_medicamentos_asociados DESC;
