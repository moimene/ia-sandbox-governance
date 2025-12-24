-- =============================================
-- Migration 001: Master Tables (Static Catalog)
-- IA_Sandbox - Sistema de Preevaluación
-- =============================================

-- REQUISITOS DEL RIA (12 requisitos según Guía 16 AESIA)
CREATE TABLE IF NOT EXISTS master_requirements (
    id TEXT PRIMARY KEY,
    article_ref TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MEDIDAS GUÍA (MG - Catálogo AESIA)
CREATE TABLE IF NOT EXISTS master_measures (
    id TEXT PRIMARY KEY,
    requirement_id TEXT NOT NULL REFERENCES master_requirements(id) ON DELETE RESTRICT,
    guide_ref TEXT,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para búsqueda por requisito
CREATE INDEX IF NOT EXISTS idx_measures_requirement ON master_measures(requirement_id);

-- =============================================
-- Seed Data: 12 Requisitos del RIA
-- =============================================

INSERT INTO master_requirements (id, article_ref, title, description) VALUES
('REQ_01', 'Art. 6-7', 'Sistema de gestión de riesgos', 'Establecer, implementar, documentar y mantener un sistema de gestión de riesgos'),
('REQ_02', 'Art. 10', 'Datos y gobernanza de datos', 'Requisitos sobre los conjuntos de datos de entrenamiento, validación y prueba'),
('REQ_03', 'Art. 11', 'Documentación técnica', 'Elaborar documentación técnica antes de la comercialización'),
('REQ_04', 'Art. 12', 'Registro de operaciones', 'Capacidad de registro automático de eventos durante el funcionamiento'),
('REQ_05', 'Art. 13', 'Transparencia e información', 'Diseño para permitir interpretación de resultados por los usuarios'),
('REQ_06', 'Art. 14', 'Supervisión humana', 'Diseño para supervisión efectiva por personas físicas'),
('REQ_07', 'Art. 15', 'Precisión, robustez y ciberseguridad', 'Niveles adecuados durante todo el ciclo de vida'),
('REQ_08', 'Art. 16', 'Obligaciones del proveedor', 'Garantizar conformidad del sistema de IA'),
('REQ_09', 'Art. 17', 'Sistema de gestión de calidad', 'Establecer un sistema de gestión de calidad'),
('REQ_10', 'Art. 18-19', 'Conservación de documentación', 'Documentación y registros técnicos'),
('REQ_11', 'Art. 20-21', 'Registro y evaluación', 'Inscripción en base de datos de la UE'),
('REQ_12', 'Art. 22-25', 'Monitorización post-comercialización', 'Sistema de seguimiento tras comercialización')
ON CONFLICT (id) DO UPDATE SET
    article_ref = EXCLUDED.article_ref,
    title = EXCLUDED.title,
    description = EXCLUDED.description;

-- =============================================
-- Seed Data: Medidas Guía de ejemplo (MG)
-- =============================================

INSERT INTO master_measures (id, requirement_id, guide_ref, description) VALUES
-- Requisito 1: Gestión de riesgos
('MG_01_01', 'REQ_01', 'Guía 4', 'Identificar y analizar los riesgos conocidos y previsibles'),
('MG_01_02', 'REQ_01', 'Guía 4', 'Estimar y evaluar los riesgos que puedan surgir'),
('MG_01_03', 'REQ_01', 'Guía 4', 'Evaluar otros riesgos basándose en datos de seguimiento'),
('MG_01_04', 'REQ_01', 'Guía 4', 'Adoptar medidas de gestión de riesgos adecuadas'),

-- Requisito 2: Datos y gobernanza
('MG_02_01', 'REQ_02', 'Guía 5', 'Establecer prácticas de gobernanza de datos'),
('MG_02_02', 'REQ_02', 'Guía 5', 'Examinar posibles sesgos en los datos'),
('MG_02_03', 'REQ_02', 'Guía 5', 'Identificar lagunas o deficiencias en los datos'),

-- Requisito 3: Documentación técnica
('MG_03_01', 'REQ_03', 'Guía 6', 'Preparar documentación técnica completa'),
('MG_03_02', 'REQ_03', 'Guía 6', 'Mantener documentación actualizada'),

-- Requisito 9: Gestión de calidad
('MG_09_01', 'REQ_09', 'Guía 12', 'Estrategia de cumplimiento regulatorio'),
('MG_09_02', 'REQ_09', 'Guía 12', 'Técnicas y procedimientos de diseño'),
('MG_09_03', 'REQ_09', 'Guía 12', 'Examen, prueba y validación'),
('MG_09_04', 'REQ_09', 'Guía 12', 'Gestión de modificaciones')
ON CONFLICT (id) DO UPDATE SET
    requirement_id = EXCLUDED.requirement_id,
    guide_ref = EXCLUDED.guide_ref,
    description = EXCLUDED.description;
