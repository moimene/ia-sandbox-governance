-- ============================================================
-- Migration 008: Seed Data - Complete 12 Requirements
-- ============================================================
-- Populates the full catalog of 12 requirements with subparts and measures

-- Clear existing data for clean reseed (optional - comment out if you want to preserve)
-- DELETE FROM master_mg_to_subpart;
-- DELETE FROM master_article_subparts;
-- DELETE FROM master_requirement_versions;
-- DELETE FROM master_measures WHERE requirement_code IS NOT NULL;
-- DELETE FROM master_requirements WHERE code NOT IN ('REQ_01', 'REQ_02');

-- ============================================================
-- 1. SYSTEM OF QUALITY MANAGEMENT (Sistema de gestión de la calidad)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('QUALITY_MGMT', 'Sistema de gestión de la calidad', 
        'Requisitos del sistema de gestión de la calidad para proveedores de sistemas de IA de alto riesgo.',
        'Art. 17', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('QUALITY_MGMT', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

-- Subparts for Art. 17
INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('QUALITY_MGMT', '1.0', '17.1.a', 'Art. 17', 'Estrategia de cumplimiento normativo', 1),
    ('QUALITY_MGMT', '1.0', '17.1.b', 'Art. 17', 'Técnicas, procedimientos y acciones sistemáticas', 2),
    ('QUALITY_MGMT', '1.0', '17.1.c', 'Art. 17', 'Técnicas para diseño, control y verificación', 3),
    ('QUALITY_MGMT', '1.0', '17.1.d', 'Art. 17', 'Procedimientos para gestión de datos', 4),
    ('QUALITY_MGMT', '1.0', '17.1.e', 'Art. 17', 'Sistema de gestión de riesgos documentado', 5),
    ('QUALITY_MGMT', '1.0', '17.1.f', 'Art. 17', 'Vigilancia poscomercialización', 6),
    ('QUALITY_MGMT', '1.0', '17.1.g', 'Art. 17', 'Procedimientos de notificación', 7),
    ('QUALITY_MGMT', '1.0', '17.1.h', 'Art. 17', 'Comunicación con autoridades', 8),
    ('QUALITY_MGMT', '1.0', '17.1.i', 'Art. 17', 'Documentación y mantenimiento de información', 9),
    ('QUALITY_MGMT', '1.0', '17.1.j', 'Art. 17', 'Gestión de recursos', 10),
    ('QUALITY_MGMT', '1.0', '17.1.k', 'Art. 17', 'Marco de responsabilidad de la dirección', 11)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 2. RISK MANAGEMENT SYSTEM (Sistema de gestión de riesgos)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('RISK_MGMT', 'Sistema de gestión de riesgos', 
        'Establecimiento, documentación y mantenimiento de un sistema de gestión de riesgos.',
        'Arts. 6-7', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('RISK_MGMT', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

-- Subparts for Arts. 6-7
INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('RISK_MGMT', '1.0', '9.2.a', 'Art. 9', 'Identificación y análisis de riesgos conocidos y previsibles', 1),
    ('RISK_MGMT', '1.0', '9.2.b', 'Art. 9', 'Estimación y evaluación de riesgos', 2),
    ('RISK_MGMT', '1.0', '9.2.c', 'Art. 9', 'Evaluación de riesgos por uso previsto y uso indebido previsible', 3),
    ('RISK_MGMT', '1.0', '9.2.d', 'Art. 9', 'Adopción de medidas de gestión de riesgos', 4),
    ('RISK_MGMT', '1.0', '9.4', 'Art. 9', 'Pruebas y medidas de gestión apropiadas', 5),
    ('RISK_MGMT', '1.0', '9.5', 'Art. 9', 'Consideración de efectos e interacciones posibles', 6),
    ('RISK_MGMT', '1.0', '9.6', 'Art. 9', 'Diseño del sistema con nivel de riesgo aceptable', 7),
    ('RISK_MGMT', '1.0', '9.7', 'Art. 9', 'Pruebas para encontrar soluciones más apropiadas', 8),
    ('RISK_MGMT', '1.0', '9.8', 'Art. 9', 'Medidas de gestión que no creen riesgos nuevos', 9)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 3. HUMAN OVERSIGHT (Supervisión humana)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('HUMAN_OVERSIGHT', 'Supervisión humana', 
        'Diseño para supervisión efectiva por personas físicas durante el uso.',
        'Art. 14', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('HUMAN_OVERSIGHT', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('HUMAN_OVERSIGHT', '1.0', '14.1', 'Art. 14', 'Diseño para supervisión efectiva', 1),
    ('HUMAN_OVERSIGHT', '1.0', '14.2', 'Art. 14', 'Prevenir o minimizar riesgos', 2),
    ('HUMAN_OVERSIGHT', '1.0', '14.3.a', 'Art. 14', 'Identificar medidas de supervisión incorporables', 3),
    ('HUMAN_OVERSIGHT', '1.0', '14.3.b', 'Art. 14', 'Identificar medidas para responsable de despliegue', 4),
    ('HUMAN_OVERSIGHT', '1.0', '14.4.a', 'Art. 14', 'Comprensión de capacidades y limitaciones', 5),
    ('HUMAN_OVERSIGHT', '1.0', '14.4.b', 'Art. 14', 'Sesgos de automatización', 6),
    ('HUMAN_OVERSIGHT', '1.0', '14.4.c', 'Art. 14', 'Interpretación correcta de resultados', 7),
    ('HUMAN_OVERSIGHT', '1.0', '14.4.d', 'Art. 14', 'Decisión de no utilizar el sistema', 8),
    ('HUMAN_OVERSIGHT', '1.0', '14.4.e', 'Art. 14', 'Intervenir en funcionamiento o interrupción', 9)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 4. DATA GOVERNANCE (Datos y gobernanza de datos)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('DATA_GOVERNANCE', 'Datos y gobernanza de datos', 
        'Prácticas de gobernanza de datos para conjuntos de entrenamiento, validación y prueba.',
        'Art. 10', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('DATA_GOVERNANCE', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('DATA_GOVERNANCE', '1.0', '10.2.a', 'Art. 10', 'Decisiones de diseño pertinentes', 1),
    ('DATA_GOVERNANCE', '1.0', '10.2.b', 'Art. 10', 'Procesos de recogida de datos', 2),
    ('DATA_GOVERNANCE', '1.0', '10.2.c', 'Art. 10', 'Operaciones de tratamiento de datos', 3),
    ('DATA_GOVERNANCE', '1.0', '10.2.d', 'Art. 10', 'Formulación de supuestos', 4),
    ('DATA_GOVERNANCE', '1.0', '10.2.e', 'Art. 10', 'Evaluación de disponibilidad y cantidad de datos', 5),
    ('DATA_GOVERNANCE', '1.0', '10.2.f', 'Art. 10', 'Examen de posibles sesgos', 6),
    ('DATA_GOVERNANCE', '1.0', '10.2.g', 'Art. 10', 'Identificación de lagunas o deficiencias', 7),
    ('DATA_GOVERNANCE', '1.0', '10.3', 'Art. 10', 'Conjuntos de datos pertinentes, suficientemente representativos', 8),
    ('DATA_GOVERNANCE', '1.0', '10.4', 'Art. 10', 'Consideración de características contextuales', 9),
    ('DATA_GOVERNANCE', '1.0', '10.5', 'Art. 10', 'Tratamiento de categorías especiales de datos', 10)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 5. TRANSPARENCY (Transparencia)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('TRANSPARENCY', 'Transparencia', 
        'Transparencia y comunicación de información a los responsables del despliegue.',
        'Art. 13', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('TRANSPARENCY', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('TRANSPARENCY', '1.0', '13.1', 'Art. 13', 'Diseño para transparencia en funcionamiento', 1),
    ('TRANSPARENCY', '1.0', '13.3.a', 'Art. 13', 'Identidad y datos de contacto del proveedor', 2),
    ('TRANSPARENCY', '1.0', '13.3.b.i', 'Art. 13', 'Características, capacidades y limitaciones - finalidad prevista', 3),
    ('TRANSPARENCY', '1.0', '13.3.b.ii', 'Art. 13', 'Nivel de precisión y métricas', 4),
    ('TRANSPARENCY', '1.0', '13.3.b.iii', 'Art. 13', 'Circunstancias previsibles de uso indebido', 5),
    ('TRANSPARENCY', '1.0', '13.3.b.iv', 'Art. 13', 'Especificaciones de entrada', 6),
    ('TRANSPARENCY', '1.0', '13.3.b.v', 'Art. 13', 'Información sobre datos de entrenamiento', 7),
    ('TRANSPARENCY', '1.0', '13.3.c', 'Art. 13', 'Cambios durante ciclo de vida', 8),
    ('TRANSPARENCY', '1.0', '13.3.d', 'Art. 13', 'Medidas de supervisión humana', 9),
    ('TRANSPARENCY', '1.0', '13.3.e', 'Art. 13', 'Recursos computacionales y hardware esperados', 10),
    ('TRANSPARENCY', '1.0', '13.3.f', 'Art. 13', 'Historial de decisiones con registro automático', 11)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 6. ACCURACY (Precisión)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('ACCURACY', 'Precisión', 
        'Nivel adecuado de precisión en relación con finalidad prevista.',
        'Art. 15', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('ACCURACY', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('ACCURACY', '1.0', '15.1.prec', 'Art. 15', 'Alcanzar nivel adecuado de precisión', 1),
    ('ACCURACY', '1.0', '15.2.prec', 'Art. 15', 'Declaración de niveles de precisión', 2),
    ('ACCURACY', '1.0', '15.3.prec', 'Art. 15', 'Resiliencia frente a errores', 3)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 7. ROBUSTNESS (Solidez/Robustez)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('ROBUSTNESS', 'Solidez (Robustez)', 
        'Nivel adecuado de solidez técnica y fiabilidad.',
        'Art. 15', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('ROBUSTNESS', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('ROBUSTNESS', '1.0', '15.4.a', 'Art. 15', 'Resistencia a intentos de alterar uso o comportamiento', 1),
    ('ROBUSTNESS', '1.0', '15.4.b', 'Art. 15', 'Soluciones técnicas para mitigar manipulación', 2),
    ('ROBUSTNESS', '1.0', '15.5', 'Art. 15', 'Robustez en comportamiento autónomo', 3)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 8. CYBERSECURITY (Ciberseguridad)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('CYBERSECURITY', 'Ciberseguridad', 
        'Resiliencia frente a intentos de alterar uso o comportamiento por terceros.',
        'Art. 15', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('CYBERSECURITY', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('CYBERSECURITY', '1.0', '15.4.ciber.a', 'Art. 15', 'Protección contra acceso no autorizado', 1),
    ('CYBERSECURITY', '1.0', '15.4.ciber.b', 'Art. 15', 'Envenenamiento de datos', 2),
    ('CYBERSECURITY', '1.0', '15.4.ciber.c', 'Art. 15', 'Envenenamiento de modelos', 3),
    ('CYBERSECURITY', '1.0', '15.4.ciber.d', 'Art. 15', 'Entradas adversarias y explotación de vulnerabilidades', 4)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 9. LOGGING (Registros)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('LOGGING', 'Registros', 
        'Capacidades de registro automático durante funcionamiento.',
        'Art. 12', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('LOGGING', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('LOGGING', '1.0', '12.1', 'Art. 12', 'Capacidades de registro durante funcionamiento', 1),
    ('LOGGING', '1.0', '12.2.a', 'Art. 12', 'Registro de período de uso', 2),
    ('LOGGING', '1.0', '12.2.b', 'Art. 12', 'Base de datos de referencia para verificar datos de entrada', 3),
    ('LOGGING', '1.0', '12.2.c', 'Art. 12', 'Datos de entrada que dieron lugar a consulta', 4),
    ('LOGGING', '1.0', '12.2.d', 'Art. 12', 'Identificación de personas físicas implicadas', 5),
    ('LOGGING', '1.0', '12.3', 'Art. 12', 'Adecuación a finalidad prevista del sistema', 6),
    ('LOGGING', '1.0', '12.4', 'Art. 12', 'Requisitos similares para biometría e infraestructura', 7)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 10. TECHNICAL DOCUMENTATION (Documentación técnica)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('TECHNICAL_DOC', 'Documentación técnica', 
        'Elaboración de documentación técnica actualizada.',
        'Art. 11', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('TECHNICAL_DOC', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('TECHNICAL_DOC', '1.0', '11.1', 'Art. 11', 'Elaborar documentación técnica antes de introducción en mercado', 1),
    ('TECHNICAL_DOC', '1.0', '11.2', 'Art. 11', 'Actualización de documentación técnica', 2),
    ('TECHNICAL_DOC', '1.0', 'AnexoIV.1.a', 'Anexo IV', 'Descripción general del sistema', 3),
    ('TECHNICAL_DOC', '1.0', 'AnexoIV.1.b', 'Anexo IV', 'Descripción de elementos del sistema', 4),
    ('TECHNICAL_DOC', '1.0', 'AnexoIV.2.a', 'Anexo IV', 'Métodos de desarrollo y validación', 5),
    ('TECHNICAL_DOC', '1.0', 'AnexoIV.2.b', 'Anexo IV', 'Procedimientos de diseño', 6),
    ('TECHNICAL_DOC', '1.0', 'AnexoIV.2.c', 'Anexo IV', 'Descripción del sistema de pruebas', 7)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 11. POST-MARKET SURVEILLANCE (Vigilancia poscomercialización)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('POST_MARKET', 'Vigilancia poscomercialización', 
        'Sistema de vigilancia poscomercialización proporcional a naturaleza y riesgos.',
        'Art. 72', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('POST_MARKET', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('POST_MARKET', '1.0', '72.1', 'Art. 72', 'Establecer sistema de vigilancia poscomercialización', 1),
    ('POST_MARKET', '1.0', '72.2', 'Art. 72', 'Recoger, documentar y analizar datos pertinentes', 2),
    ('POST_MARKET', '1.0', '72.3', 'Art. 72', 'Plan de vigilancia poscomercialización', 3),
    ('POST_MARKET', '1.0', '72.4', 'Art. 72', 'Evaluación continua del cumplimiento', 4),
    ('POST_MARKET', '1.0', '72.5', 'Art. 72', 'Cooperación con responsables del despliegue', 5)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- 12. INCIDENT MANAGEMENT (Gestión de incidentes graves)
-- ============================================================
INSERT INTO master_requirements (code, title, description, article_ref, active)
VALUES ('INCIDENT_MGMT', 'Gestión de incidentes graves', 
        'Notificación y gestión de incidentes graves y mal funcionamiento.',
        'Art. 73', TRUE)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('INCIDENT_MGMT', '1.0', TRUE, '2024-01-01')
ON CONFLICT (requirement_code, version) DO NOTHING;

INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index)
VALUES 
    ('INCIDENT_MGMT', '1.0', '73.1', 'Art. 73', 'Notificar incidentes graves en 15 días', 1),
    ('INCIDENT_MGMT', '1.0', '73.2', 'Art. 73', 'Adoptar medidas correctoras inmediatas', 2),
    ('INCIDENT_MGMT', '1.0', '73.3', 'Art. 73', 'Investigar causas del incidente', 3),
    ('INCIDENT_MGMT', '1.0', '73.4', 'Art. 73', 'Cooperar con autoridades de vigilancia', 4),
    ('INCIDENT_MGMT', '1.0', '73.5', 'Art. 73', 'Mantener documentación de incidentes', 5)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;

-- ============================================================
-- SUMMARY VIEW
-- ============================================================
-- Create a view for easy requirement summary
CREATE OR REPLACE VIEW v_requirements_summary AS
SELECT 
    r.code,
    r.title,
    r.article_ref,
    rv.version,
    (SELECT COUNT(*) FROM master_article_subparts s 
     WHERE s.requirement_code = r.code AND s.requirement_version = rv.version) as subpart_count,
    (SELECT COUNT(*) FROM master_measures m 
     WHERE m.requirement_code = r.code AND m.requirement_version = rv.version) as measure_count
FROM master_requirements r
JOIN master_requirement_versions rv ON r.code = rv.requirement_code
WHERE r.active = TRUE AND rv.active = TRUE
ORDER BY r.code;

COMMENT ON VIEW v_requirements_summary IS 'Summary of all active requirements with counts';
