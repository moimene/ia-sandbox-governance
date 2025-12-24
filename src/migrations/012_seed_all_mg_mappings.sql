-- ============================================================
-- Migration 012: Seed MG Measures and Mappings for ALL Requirements
-- ============================================================
-- Complete seed data for all 12 requirements following the TRANSPARENCY pattern
-- This enables pre-population of assessments across the entire Guía 16 structure

-- ============================================================
-- 1. QUALITY_MGMT (Sistema de gestión de la calidad) - Art. 17
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_QUAL_01', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Establecer estrategia de cumplimiento normativo'),
    ('MG_QUAL_02', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Implementar técnicas y procedimientos sistemáticos'),
    ('MG_QUAL_03', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Aplicar técnicas de diseño, control y verificación'),
    ('MG_QUAL_04', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Establecer procedimientos de gestión de datos'),
    ('MG_QUAL_05', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Documentar sistema de gestión de riesgos'),
    ('MG_QUAL_06', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Implementar vigilancia poscomercialización'),
    ('MG_QUAL_07', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Establecer procedimientos de notificación'),
    ('MG_QUAL_08', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Definir comunicación con autoridades'),
    ('MG_QUAL_09', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Mantener documentación e información'),
    ('MG_QUAL_10', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Gestionar recursos adecuadamente'),
    ('MG_QUAL_11', 'QUALITY_MGMT', '1.0', 'Guía 12', 'Establecer marco de responsabilidad de dirección')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_01', '17.1.a'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_02', '17.1.b'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_03', '17.1.c'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_04', '17.1.d'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_05', '17.1.e'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_06', '17.1.f'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_07', '17.1.g'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_08', '17.1.h'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_09', '17.1.i'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_10', '17.1.j'),
    ('QUALITY_MGMT', '1.0', 'MG_QUAL_11', '17.1.k')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 2. RISK_MGMT (Sistema de gestión de riesgos) - Art. 9
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_RISK_01', 'RISK_MGMT', '1.0', 'Guía 2', 'Identificar y analizar riesgos conocidos y previsibles'),
    ('MG_RISK_02', 'RISK_MGMT', '1.0', 'Guía 2', 'Estimar y evaluar riesgos sistemáticamente'),
    ('MG_RISK_03', 'RISK_MGMT', '1.0', 'Guía 2', 'Evaluar riesgos de uso previsto e indebido'),
    ('MG_RISK_04', 'RISK_MGMT', '1.0', 'Guía 2', 'Adoptar medidas de gestión de riesgos'),
    ('MG_RISK_05', 'RISK_MGMT', '1.0', 'Guía 2', 'Realizar pruebas con medidas apropiadas'),
    ('MG_RISK_06', 'RISK_MGMT', '1.0', 'Guía 2', 'Considerar efectos e interacciones posibles'),
    ('MG_RISK_07', 'RISK_MGMT', '1.0', 'Guía 2', 'Diseñar sistema con nivel de riesgo aceptable'),
    ('MG_RISK_08', 'RISK_MGMT', '1.0', 'Guía 2', 'Probar para encontrar soluciones apropiadas'),
    ('MG_RISK_09', 'RISK_MGMT', '1.0', 'Guía 2', 'Asegurar que medidas no creen riesgos nuevos')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('RISK_MGMT', '1.0', 'MG_RISK_01', '9.2.a'),
    ('RISK_MGMT', '1.0', 'MG_RISK_02', '9.2.b'),
    ('RISK_MGMT', '1.0', 'MG_RISK_03', '9.2.c'),
    ('RISK_MGMT', '1.0', 'MG_RISK_04', '9.2.d'),
    ('RISK_MGMT', '1.0', 'MG_RISK_05', '9.4'),
    ('RISK_MGMT', '1.0', 'MG_RISK_06', '9.5'),
    ('RISK_MGMT', '1.0', 'MG_RISK_07', '9.6'),
    ('RISK_MGMT', '1.0', 'MG_RISK_08', '9.7'),
    ('RISK_MGMT', '1.0', 'MG_RISK_09', '9.8')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 3. HUMAN_OVERSIGHT (Supervisión humana) - Art. 14
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_HUMN_01', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Diseñar para supervisión efectiva'),
    ('MG_HUMN_02', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Prevenir o minimizar riesgos'),
    ('MG_HUMN_03', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Identificar medidas de supervisión incorporables'),
    ('MG_HUMN_04', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Definir medidas para responsable de despliegue'),
    ('MG_HUMN_05', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Facilitar comprensión de capacidades y limitaciones'),
    ('MG_HUMN_06', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Mitigar sesgos de automatización'),
    ('MG_HUMN_07', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Permitir interpretación correcta de resultados'),
    ('MG_HUMN_08', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Habilitar decisión de no utilizar el sistema'),
    ('MG_HUMN_09', 'HUMAN_OVERSIGHT', '1.0', 'Guía 9', 'Permitir intervención o interrupción')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_01', '14.1'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_02', '14.2'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_03', '14.3.a'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_04', '14.3.b'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_05', '14.4.a'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_06', '14.4.b'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_07', '14.4.c'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_08', '14.4.d'),
    ('HUMAN_OVERSIGHT', '1.0', 'MG_HUMN_09', '14.4.e')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 4. DATA_GOVERNANCE (Datos y gobernanza) - Art. 10
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_DATA_01', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Documentar decisiones de diseño pertinentes'),
    ('MG_DATA_02', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Establecer procesos de recogida de datos'),
    ('MG_DATA_03', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Definir operaciones de tratamiento'),
    ('MG_DATA_04', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Formular supuestos de datos'),
    ('MG_DATA_05', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Evaluar disponibilidad y cantidad'),
    ('MG_DATA_06', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Examinar posibles sesgos'),
    ('MG_DATA_07', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Identificar lagunas o deficiencias'),
    ('MG_DATA_08', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Asegurar conjuntos representativos'),
    ('MG_DATA_09', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Considerar características contextuales'),
    ('MG_DATA_10', 'DATA_GOVERNANCE', '1.0', 'Guía 3', 'Tratar categorías especiales de datos')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_01', '10.2.a'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_02', '10.2.b'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_03', '10.2.c'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_04', '10.2.d'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_05', '10.2.e'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_06', '10.2.f'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_07', '10.2.g'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_08', '10.3'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_09', '10.4'),
    ('DATA_GOVERNANCE', '1.0', 'MG_DATA_10', '10.5')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 5. ACCURACY (Precisión) - Art. 15
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_ACCU_01', 'ACCURACY', '1.0', 'Guía 10', 'Alcanzar nivel adecuado de precisión'),
    ('MG_ACCU_02', 'ACCURACY', '1.0', 'Guía 10', 'Declarar niveles de precisión'),
    ('MG_ACCU_03', 'ACCURACY', '1.0', 'Guía 10', 'Implementar resiliencia frente a errores')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('ACCURACY', '1.0', 'MG_ACCU_01', '15.1.prec'),
    ('ACCURACY', '1.0', 'MG_ACCU_02', '15.2.prec'),
    ('ACCURACY', '1.0', 'MG_ACCU_03', '15.3.prec')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 6. ROBUSTNESS (Solidez/Robustez) - Art. 15
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_ROBU_01', 'ROBUSTNESS', '1.0', 'Guía 10', 'Resistir intentos de alteración'),
    ('MG_ROBU_02', 'ROBUSTNESS', '1.0', 'Guía 10', 'Aplicar soluciones técnicas de mitigación'),
    ('MG_ROBU_03', 'ROBUSTNESS', '1.0', 'Guía 10', 'Asegurar robustez en comportamiento autónomo')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('ROBUSTNESS', '1.0', 'MG_ROBU_01', '15.4.a'),
    ('ROBUSTNESS', '1.0', 'MG_ROBU_02', '15.4.b'),
    ('ROBUSTNESS', '1.0', 'MG_ROBU_03', '15.5')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 7. CYBERSECURITY (Ciberseguridad) - Art. 15
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_CIBE_01', 'CYBERSECURITY', '1.0', 'Guía 10', 'Proteger contra acceso no autorizado'),
    ('MG_CIBE_02', 'CYBERSECURITY', '1.0', 'Guía 10', 'Prevenir envenenamiento de datos'),
    ('MG_CIBE_03', 'CYBERSECURITY', '1.0', 'Guía 10', 'Prevenir envenenamiento de modelos'),
    ('MG_CIBE_04', 'CYBERSECURITY', '1.0', 'Guía 10', 'Mitigar entradas adversarias y vulnerabilidades')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('CYBERSECURITY', '1.0', 'MG_CIBE_01', '15.4.ciber.a'),
    ('CYBERSECURITY', '1.0', 'MG_CIBE_02', '15.4.ciber.b'),
    ('CYBERSECURITY', '1.0', 'MG_CIBE_03', '15.4.ciber.c'),
    ('CYBERSECURITY', '1.0', 'MG_CIBE_04', '15.4.ciber.d')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 8. LOGGING (Registros) - Art. 12
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_LOGG_01', 'LOGGING', '1.0', 'Guía 5', 'Habilitar capacidades de registro'),
    ('MG_LOGG_02', 'LOGGING', '1.0', 'Guía 5', 'Registrar período de uso'),
    ('MG_LOGG_03', 'LOGGING', '1.0', 'Guía 5', 'Mantener base de datos de referencia'),
    ('MG_LOGG_04', 'LOGGING', '1.0', 'Guía 5', 'Registrar datos de entrada de consultas'),
    ('MG_LOGG_05', 'LOGGING', '1.0', 'Guía 5', 'Identificar personas físicas implicadas'),
    ('MG_LOGG_06', 'LOGGING', '1.0', 'Guía 5', 'Adecuar registros a finalidad prevista'),
    ('MG_LOGG_07', 'LOGGING', '1.0', 'Guía 5', 'Cumplir requisitos similares para biometría')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('LOGGING', '1.0', 'MG_LOGG_01', '12.1'),
    ('LOGGING', '1.0', 'MG_LOGG_02', '12.2.a'),
    ('LOGGING', '1.0', 'MG_LOGG_03', '12.2.b'),
    ('LOGGING', '1.0', 'MG_LOGG_04', '12.2.c'),
    ('LOGGING', '1.0', 'MG_LOGG_05', '12.2.d'),
    ('LOGGING', '1.0', 'MG_LOGG_06', '12.3'),
    ('LOGGING', '1.0', 'MG_LOGG_07', '12.4')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 9. TECHNICAL_DOC (Documentación técnica) - Art. 11
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_TDOC_01', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Elaborar documentación técnica'),
    ('MG_TDOC_02', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Actualizar documentación técnica'),
    ('MG_TDOC_03', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Describir sistema general'),
    ('MG_TDOC_04', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Describir elementos del sistema'),
    ('MG_TDOC_05', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Documentar métodos de desarrollo'),
    ('MG_TDOC_06', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Documentar procedimientos de diseño'),
    ('MG_TDOC_07', 'TECHNICAL_DOC', '1.0', 'Guía 4', 'Describir sistema de pruebas')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_01', '11.1'),
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_02', '11.2'),
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_03', 'AnexoIV.1.a'),
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_04', 'AnexoIV.1.b'),
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_05', 'AnexoIV.2.a'),
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_06', 'AnexoIV.2.b'),
    ('TECHNICAL_DOC', '1.0', 'MG_TDOC_07', 'AnexoIV.2.c')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 10. POST_MARKET (Vigilancia poscomercialización) - Art. 72
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_POST_01', 'POST_MARKET', '1.0', 'Guía 11', 'Establecer sistema de vigilancia'),
    ('MG_POST_02', 'POST_MARKET', '1.0', 'Guía 11', 'Recoger, documentar y analizar datos'),
    ('MG_POST_03', 'POST_MARKET', '1.0', 'Guía 11', 'Elaborar plan de vigilancia'),
    ('MG_POST_04', 'POST_MARKET', '1.0', 'Guía 11', 'Evaluar continuamente cumplimiento'),
    ('MG_POST_05', 'POST_MARKET', '1.0', 'Guía 11', 'Cooperar con responsables de despliegue')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('POST_MARKET', '1.0', 'MG_POST_01', '72.1'),
    ('POST_MARKET', '1.0', 'MG_POST_02', '72.2'),
    ('POST_MARKET', '1.0', 'MG_POST_03', '72.3'),
    ('POST_MARKET', '1.0', 'MG_POST_04', '72.4'),
    ('POST_MARKET', '1.0', 'MG_POST_05', '72.5')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 11. INCIDENT_MGMT (Gestión de incidentes) - Art. 73
-- ============================================================
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_INCI_01', 'INCIDENT_MGMT', '1.0', 'Guía 11', 'Notificar incidentes graves en 15 días'),
    ('MG_INCI_02', 'INCIDENT_MGMT', '1.0', 'Guía 11', 'Adoptar medidas correctoras inmediatas'),
    ('MG_INCI_03', 'INCIDENT_MGMT', '1.0', 'Guía 11', 'Investigar causas del incidente'),
    ('MG_INCI_04', 'INCIDENT_MGMT', '1.0', 'Guía 11', 'Cooperar con autoridades'),
    ('MG_INCI_05', 'INCIDENT_MGMT', '1.0', 'Guía 11', 'Mantener documentación de incidentes')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    ('INCIDENT_MGMT', '1.0', 'MG_INCI_01', '73.1'),
    ('INCIDENT_MGMT', '1.0', 'MG_INCI_02', '73.2'),
    ('INCIDENT_MGMT', '1.0', 'MG_INCI_03', '73.3'),
    ('INCIDENT_MGMT', '1.0', 'MG_INCI_04', '73.4'),
    ('INCIDENT_MGMT', '1.0', 'MG_INCI_05', '73.5')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- Summary: Total MG measures and mappings created
-- ============================================================
-- QUALITY_MGMT: 11 measures
-- RISK_MGMT: 9 measures  
-- HUMAN_OVERSIGHT: 9 measures
-- DATA_GOVERNANCE: 10 measures
-- TRANSPARENCY: 11 measures (already seeded in 011)
-- ACCURACY: 3 measures
-- ROBUSTNESS: 3 measures
-- CYBERSECURITY: 4 measures
-- LOGGING: 7 measures
-- TECHNICAL_DOC: 7 measures
-- POST_MARKET: 5 measures
-- INCIDENT_MGMT: 5 measures
-- TOTAL: 84 measures across all 12 requirements
