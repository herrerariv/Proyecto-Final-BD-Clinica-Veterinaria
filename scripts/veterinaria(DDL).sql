-- ===========================================================================================================
-- PROYECTO FINAL - CLÍNICA VETERINARIA
-- PostgreSQL
-- ===========================================================================================================

-- Crear la base de datos.
-- CREATE DATABASE veterinaria;
-- Después de ejecutar esta línea, conectarse a la base de datos "veterinaria"
-- y ejecutar el resto del script.
-- ó puedes crear directamente la base de datos en tu interfaz.
-- ============================================================================================================
-- TABLA PROPIETARIO:

CREATE TABLE propietario (
    id_propietario SERIAL,
    nombres VARCHAR(60) NOT NULL,
    apellidos VARCHAR(60) NOT NULL,
    sexo CHAR(1) NOT NULL,
    dui CHAR(10) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    direccion VARCHAR(255),
    telefono VARCHAR(14),

    CONSTRAINT pk_propietario PRIMARY KEY (id_propietario),
    CONSTRAINT uq_propietario_dui UNIQUE (dui),
    CONSTRAINT uq_propietario_correo UNIQUE (correo),
    CONSTRAINT uq_propietario_telefono UNIQUE (telefono),
    CONSTRAINT chk_propietario_sexo CHECK (sexo IN ('M', 'F')),
    CONSTRAINT chk_propietario_dui CHECK (dui ~ '^[0-9]{8}-[0-9]{1}$'),
    CONSTRAINT chk_propietario_correo CHECK (correo LIKE '%@gmail.com' OR correo LIKE '%@outlook.com'),
    CONSTRAINT chk_propietario_telefono CHECK (telefono IS NULL OR telefono ~ '^\+503 [0-9]{4}-[0-9]{4}$')
);
-- =============================================================================================================
-- TABLA ESPECIE:

CREATE TABLE especie (
    id_especie SERIAL,
    nombre_especie VARCHAR(50) NOT NULL,
    descripcion_especie VARCHAR(255),

    CONSTRAINT pk_especie PRIMARY KEY (id_especie),
    CONSTRAINT uq_especie_nombre UNIQUE (nombre_especie)
);
-- =============================================================================================================
-- TABLA ESPECIALIDAD:

CREATE TABLE especialidad (
    id_especialidad SERIAL,
    nombre_especialidad VARCHAR(60) NOT NULL,
    descripcion_especialidad VARCHAR(255),

    CONSTRAINT pk_especialidad PRIMARY KEY (id_especialidad),
    CONSTRAINT uq_especialidad_nombre UNIQUE (nombre_especialidad)
);
-- =============================================================================================================
-- TABLA MASCOTA:

CREATE TABLE mascota (
    id_mascota SERIAL,
    nombre_mascota VARCHAR(60) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo CHAR(1) NOT NULL,
    color VARCHAR(60),
    observaciones_mascota VARCHAR(255),
    estado_mascota VARCHAR(8) NOT NULL,
    peso NUMERIC(6,2) NOT NULL,
    id_propietario INT NOT NULL,
    id_especie INT NOT NULL,

    CONSTRAINT pk_mascota PRIMARY KEY (id_mascota),
    CONSTRAINT fk_mascota_propietario FOREIGN KEY (id_propietario) REFERENCES propietario(id_propietario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mascota_especie FOREIGN KEY (id_especie) REFERENCES especie(id_especie) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_mascota_sexo CHECK (sexo IN ('M', 'F')),
    CONSTRAINT chk_mascota_fecha_nacimiento CHECK (fecha_nacimiento <= CURRENT_DATE),
    CONSTRAINT chk_mascota_peso CHECK (peso >= 1 AND peso <= 150),
    CONSTRAINT chk_mascota_estado CHECK (estado_mascota IN ('Activo', 'Inactivo'))
);
-- =============================================================================================================
-- TABLA VETERINARIO:

CREATE TABLE veterinario (
    id_veterinario SERIAL,
    nombres VARCHAR(60) NOT NULL,
    apellidos VARCHAR(60) NOT NULL,
    sexo CHAR(1) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    dui CHAR(10) NOT NULL,
    licencia VARCHAR(20) NOT NULL,
    telefono VARCHAR(14),
    direccion VARCHAR(255),
    estado_veterinario VARCHAR(8) NOT NULL,
    id_especialidad INT NOT NULL,

    CONSTRAINT pk_veterinario PRIMARY KEY (id_veterinario),
    CONSTRAINT fk_veterinario_especialidad FOREIGN KEY (id_especialidad) REFERENCES especialidad(id_especialidad) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_veterinario_correo UNIQUE (correo),
    CONSTRAINT uq_veterinario_dui UNIQUE (dui),
    CONSTRAINT uq_veterinario_licencia UNIQUE (licencia),
    CONSTRAINT uq_veterinario_telefono UNIQUE (telefono),
    CONSTRAINT chk_veterinario_sexo CHECK (sexo IN ('M', 'F', 'O')),
    CONSTRAINT chk_veterinario_dui CHECK (dui ~ '^[0-9]{8}-[0-9]{1}$'),
    CONSTRAINT chk_veterinario_correo CHECK (correo LIKE '%@gmail.com' OR correo LIKE '%@outlook.com'),
    CONSTRAINT chk_veterinario_telefono CHECK (telefono IS NULL OR telefono ~ '^\+503 [0-9]{4}-[0-9]{4}$'),
    CONSTRAINT chk_veterinario_licencia CHECK (licencia ~ '^JVPMV-[0-9]{2,4}$'),
    CONSTRAINT chk_veterinario_estado CHECK (estado_veterinario IN ('Activo', 'Inactivo'))
);
-- =============================================================================================================
-- TABLA CITA:

CREATE TABLE cita (
    id_cita SERIAL,
    motivo_cita VARCHAR(150) NOT NULL,
    fecha_cita DATE NOT NULL,
    hora_cita TIME NOT NULL,
    observaciones_cita VARCHAR(255),
    estado_cita VARCHAR(15) NOT NULL,
    id_mascota INT NOT NULL,
    id_veterinario INT NOT NULL,

    CONSTRAINT pk_cita PRIMARY KEY (id_cita),
    CONSTRAINT fk_cita_mascota FOREIGN KEY (id_mascota) REFERENCES mascota(id_mascota) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cita_veterinario FOREIGN KEY (id_veterinario) REFERENCES veterinario(id_veterinario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_cita_fecha_estado CHECK ((estado_cita = 'Programada' AND fecha_cita >= CURRENT_DATE) OR (estado_cita IN ('Atendida', 'Cancelada') AND fecha_cita <= CURRENT_DATE)),
    CONSTRAINT chk_cita_estado CHECK (estado_cita IN ('Programada', 'Atendida', 'Cancelada'))
);
-- =============================================================================================================
-- TABLA DIAGNOSTICO:

CREATE TABLE diagnostico (
    id_diagnostico SERIAL,
    descripcion_diagnostico VARCHAR(255) NOT NULL,
    fecha_diagnostico DATE NOT NULL,
    observaciones_diagnostico VARCHAR(255),
    indicaciones_diagnostico VARCHAR(255),
    id_cita INT NOT NULL,

    CONSTRAINT pk_diagnostico PRIMARY KEY (id_diagnostico),
    CONSTRAINT fk_diagnostico_cita FOREIGN KEY (id_cita) REFERENCES cita(id_cita) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_diagnostico_cita UNIQUE (id_cita),
    CONSTRAINT chk_diagnostico_fecha CHECK (fecha_diagnostico <= CURRENT_DATE)
);
-- =============================================================================================================
-- TABLA TRATAMIENTO:

CREATE TABLE tratamiento (
    id_tratamiento SERIAL,
    nombre_tratamiento VARCHAR(100) NOT NULL,
    descripcion_tratamiento VARCHAR(255) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado_tratamiento VARCHAR(15) NOT NULL,
    id_diagnostico INT NOT NULL,

    CONSTRAINT pk_tratamiento PRIMARY KEY (id_tratamiento),
    CONSTRAINT fk_tratamiento_diagnostico FOREIGN KEY (id_diagnostico) REFERENCES diagnostico(id_diagnostico) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_tratamiento_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT chk_tratamiento_estado CHECK (estado_tratamiento IN ('Activo', 'Finalizado', 'Suspendido'))
);
-- =============================================================================================================
-- TABLA PROCEDIMIENTO:

CREATE TABLE procedimiento (
    id_procedimiento SERIAL,
    nombre_procedimiento VARCHAR(100) NOT NULL,
    descripcion_procedimiento VARCHAR(255),
    estado_procedimiento VARCHAR(15) NOT NULL,
    id_diagnostico INT NOT NULL,

    CONSTRAINT pk_procedimiento PRIMARY KEY (id_procedimiento),
    CONSTRAINT fk_procedimiento_diagnostico FOREIGN KEY (id_diagnostico) REFERENCES diagnostico(id_diagnostico) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_procedimiento_estado CHECK (estado_procedimiento IN ('Realizado', 'Pendiente', 'Cancelado'))
);
-- =============================================================================================================
-- TABLA MEDICAMENTO:

CREATE TABLE medicamento (
    id_medicamento SERIAL,
    nombre_medicamento VARCHAR(80) NOT NULL,
    tipo_medicamento VARCHAR(40) NOT NULL,
    descripcion_medicamento VARCHAR(255),
    precio_medicamento NUMERIC(8,2) NOT NULL,
    estado_medicamento VARCHAR(15) NOT NULL,

    CONSTRAINT pk_medicamento PRIMARY KEY (id_medicamento),
    CONSTRAINT uq_medicamento_nombre UNIQUE (nombre_medicamento),
    CONSTRAINT chk_medicamento_precio CHECK (precio_medicamento > 0),
    CONSTRAINT chk_medicamento_tipo CHECK (tipo_medicamento IN ('Antibiotico', 'Analgesico', 'Antiinflamatorio', 'Antiparasitario', 'Vacuna', 'Vitamina', 'Otro')),
    CONSTRAINT chk_medicamento_estado CHECK (estado_medicamento IN ('Activo', 'Inactivo'))
);
-- =============================================================================================================
-- TABLA TRATAMIENTO_MEDICAMENTO:

CREATE TABLE tratamiento_medicamento (
    id_tratamiento_medicamento SERIAL,
    dosis_indicada VARCHAR(80) NOT NULL,
    frecuencia_administracion VARCHAR(80) NOT NULL,
    via_administracion VARCHAR(30) NOT NULL,
    duracion_dias INT NOT NULL,
    id_tratamiento INT NOT NULL,
    id_medicamento INT NOT NULL,

    CONSTRAINT pk_tratamiento_medicamento PRIMARY KEY (id_tratamiento_medicamento),
    CONSTRAINT fk_tratamiento_medicamento_tratamiento FOREIGN KEY (id_tratamiento) REFERENCES tratamiento(id_tratamiento) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_tratamiento_medicamento_medicamento FOREIGN KEY (id_medicamento) REFERENCES medicamento(id_medicamento) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_tratamiento_medicamento UNIQUE (id_tratamiento, id_medicamento),
    CONSTRAINT chk_tratamiento_medicamento_duracion CHECK (duracion_dias > 0),
    CONSTRAINT chk_tratamiento_medicamento_via CHECK (via_administracion IN ('Oral', 'Topica', 'Inyectable', 'Inhalatoria', 'Oftalmica', 'Transdermica', 'Otro'))
);
-- =============================================================================================================
-- TABLA MASCOTA_ALERGIA:

CREATE TABLE mascota_alergia (
    id_mascota_alergia SERIAL,
    descripcion_alergia VARCHAR(255),
    id_mascota INT NOT NULL,
    id_medicamento INT NOT NULL,

    CONSTRAINT pk_mascota_alergia PRIMARY KEY (id_mascota_alergia),
    CONSTRAINT fk_mascota_alergia_mascota FOREIGN KEY (id_mascota) REFERENCES mascota(id_mascota) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_mascota_alergia_medicamento FOREIGN KEY (id_medicamento) REFERENCES medicamento(id_medicamento) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_mascota_alergia UNIQUE (id_mascota, id_medicamento)
);
-- =============================================================================================================
-- TABLA FACTURA:

CREATE TABLE factura (
    id_factura SERIAL,
    numero_factura VARCHAR(20) NOT NULL,
    fecha_emision DATE NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    estado_factura VARCHAR(15) NOT NULL,
    total_factura NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    id_cita INT NOT NULL,

    CONSTRAINT pk_factura PRIMARY KEY (id_factura),
    CONSTRAINT fk_factura_cita FOREIGN KEY (id_cita) REFERENCES cita(id_cita) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_factura_numero UNIQUE (numero_factura),
    CONSTRAINT uq_factura_cita UNIQUE (id_cita),
    CONSTRAINT chk_factura_fecha_emision CHECK (fecha_emision <= CURRENT_DATE),
    CONSTRAINT chk_factura_total CHECK (total_factura >= 0),
    CONSTRAINT chk_factura_metodo_pago CHECK (metodo_pago IN ('Efectivo', 'Tarjeta', 'Transferencia')),
    CONSTRAINT chk_factura_estado CHECK (estado_factura IN ('Pendiente', 'Pagada', 'Anulada'))
);
-- =============================================================================================================
-- TABLA FACTURA_DETALLE:

CREATE TABLE factura_detalle (
    id_factura_detalle SERIAL,
    concepto_detalle VARCHAR(100) NOT NULL,
    descripcion_detalle VARCHAR(255),
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(8,2) NOT NULL,
    subtotal NUMERIC(8,2) NOT NULL,
    id_factura INT NOT NULL,

    CONSTRAINT pk_factura_detalle PRIMARY KEY (id_factura_detalle),
    CONSTRAINT fk_factura_detalle_factura FOREIGN KEY (id_factura) REFERENCES factura(id_factura) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_factura_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_factura_detalle_precio CHECK (precio_unitario > 0),
    CONSTRAINT chk_factura_detalle_subtotal CHECK (subtotal = ROUND(cantidad * precio_unitario, 2))
);
-- =============================================================================================================
