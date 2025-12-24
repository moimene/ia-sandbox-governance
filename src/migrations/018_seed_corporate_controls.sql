-- ============================================================
-- Migration 018: Seed Base Corporate Controls (Example Set)
-- ============================================================
-- Populates the Master Control Library with standard AI Governance controls
-- and maps them to AESIA Guía 16 MGs.

-- 1. Seed Master Controls
-- Using a standard naming convention: CTRL-[DOMAIN]-[SEQ]
INSERT INTO master_controls (id, title, description, domain, default_owner_role)
VALUES 
    -- GOVERNANCE & STRATEGY
    ('CTRL-GOV-01', 'Política de IA Responsable', 'La organización debe contar con una política aprobada que defina principios éticos y límites de uso de IA.', 'GOVERNANCE', 'CISO'),
    ('CTRL-GOV-02', 'Inventario de Sistemas de IA', 'Mantenimiento de un registro actualizado de todos los sistemas de IA desarrollados o adquiridos.', 'GOVERNANCE', 'DTO'),
    
    -- RISK MANAGEMENT
    ('CTRL-RISK-01', 'Metodología de Análisis de Riesgos IA', 'Procedimiento para identificar y evaluar riesgos específicos de IA (sesgo, robustez, seguridad).', 'RISK', 'RISK_MANAGER'),
    ('CTRL-RISK-02', 'Evaluación de Impacto Fundamental', 'Evaluación de impacto en derechos fundamentales para sistemas de alto riesgo.', 'RISK', 'LEGAL'),
    
    -- DATA GOVERNANCE
    ('CTRL-DATA-01', 'Linaje y Calidad de Datos', 'Trazabilidad del origen de datos de entrenamiento y métricas de calidad (representatividad, errores).', 'DATA', 'CDO'),
    ('CTRL-DATA-02', 'Sesgo y Equidad', 'Pruebas técnicas para detectar y mitigar sesgos en datos y modelos.', 'DATA', 'DATA_SCIENTIST'),
    
    -- HUMAN OVERSIGHT
    ('CTRL-HUM-01', 'Mecanismo de Supervisión Humana', 'Definición de nivel de autonomía y protocolo de intervención humana (Human-in-the-loop).', 'ETHICS', 'PRODUCT_OWNER'),
    ('CTRL-HUM-02', 'Formación de Supervisores', 'Capacitación específica para el personal encargado de supervisar las decisiones del sistema.', 'ETHICS', 'HR'),
    
    -- SECURITY & ROBUSTNESS
    ('CTRL-SEC-01', 'Robustez ante Ataques Adversarios', 'Pruebas de seguridad contra inyección de prompts, envenenamiento de datos o evasión.', 'SECURITY', 'CISO'),
    
    -- TRANSPARENCY
    ('CTRL-TRANS-01', 'Ficha de Transparencia (System Card)', 'Documentación accesible para usuarios sobre capacidades y limitaciones del sistema.', 'TRANSPARENCY', 'PRODUCT_OWNER')
ON CONFLICT (id) DO NOTHING;

-- 2. Map Controls to AESIA Measures (Illustrative Mapping)
-- This allows calculating compliance from the Control status.

-- Example: CTRL-GOV-01 (Policy) maps to QUALITY_MGMT measures
-- Note: 'MG_QUALITY_01' is illustrative, matching assumed catalog IDs from previous migrations
-- Since we don't have the exact MG IDs in front of us, we will assume standard prefixes based on Guía 16
-- Real implementation would require querying master_measures first.

-- Strategy: We use a DO block to look up MGs by requirement to handle dynamic IDs if needed,
-- or assumes standard seeding names if migration 012 was deterministic.
-- Assuming migration 012 used semantic IDs like 'MG_CALIDAD_01'.

-- Let's try to map broadly to Requirements if MG IDs are not known, 
-- but our table map_control_to_mg requires mg_id. 
-- We will infer some mappings based on typical AESIA structure.

INSERT INTO map_control_to_mg (control_id, mg_id)
SELECT 'CTRL-RISK-01', id FROM master_measures WHERE requirement_id = 'RISK_MGMT' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO map_control_to_mg (control_id, mg_id)
SELECT 'CTRL-DATA-01', id FROM master_measures WHERE requirement_id = 'DATA_GOV' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO map_control_to_mg (control_id, mg_id)
SELECT 'CTRL-HUM-01', id FROM master_measures WHERE requirement_id = 'HUMAN_OVERSIGHT' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO map_control_to_mg (control_id, mg_id)
SELECT 'CTRL-SEC-01', id FROM master_measures WHERE requirement_id = 'CYBERSECURITY' LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO map_control_to_mg (control_id, mg_id)
SELECT 'CTRL-TRANS-01', id FROM master_measures WHERE requirement_id = 'TRANSPARENCY' LIMIT 1
ON CONFLICT DO NOTHING;

-- ============================================================
-- NOTE: In a production environment, this mapping needs to be 
-- comprehensive (approx 84 mappings). This is a demonstrator set.
-- ============================================================
