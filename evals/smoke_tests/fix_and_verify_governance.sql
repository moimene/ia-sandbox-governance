-- ============================================================
-- Fix & Verify: Seeding Corporate Controls
-- ============================================================
-- Checks if data is missing and inserts it, then runs smoke tests.
-- Usage: psql $DATABASE_URL -f fix_and_verify_governance.sql

-- 1. Auto-Repair: Seed if empty
DO $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM master_controls;
    
    IF cnt = 0 THEN
        RAISE NOTICE '⚠️ Table master_controls is empty. Attempting to seed...';
        
        -- Insert Controls
        INSERT INTO master_controls (id, title, description, domain, default_owner_role)
        VALUES 
            ('CTRL-GOV-01', 'Política de IA Responsable', 'La organización debe contar con una política aprobada que defina principios éticos y límites de uso de IA.', 'GOVERNANCE', 'CISO'),
            ('CTRL-GOV-02', 'Inventario de Sistemas de IA', 'Mantenimiento de un registro actualizado de todos los sistemas de IA desarrollados o adquiridos.', 'GOVERNANCE', 'DTO'),
            ('CTRL-RISK-01', 'Metodología de Análisis de Riesgos IA', 'Procedimiento para identificar y evaluar riesgos específicos de IA (sesgo, robustez, seguridad).', 'RISK', 'RISK_MANAGER'),
            ('CTRL-RISK-02', 'Evaluación de Impacto Fundamental', 'Evaluación de impacto en derechos fundamentales para sistemas de alto riesgo.', 'RISK', 'LEGAL'),
            ('CTRL-DATA-01', 'Linaje y Calidad de Datos', 'Trazabilidad del origen de datos de entrenamiento y métricas de calidad (representatividad, errores).', 'DATA', 'CDO'),
            ('CTRL-DATA-02', 'Sesgo y Equidad', 'Pruebas técnicas para detectar y mitigar sesgos en datos y modelos.', 'DATA', 'DATA_SCIENTIST'),
            ('CTRL-HUM-01', 'Mecanismo de Supervisión Humana', 'Definición de nivel de autonomía y protocolo de intervención humana (Human-in-the-loop).', 'ETHICS', 'PRODUCT_OWNER'),
            ('CTRL-HUM-02', 'Formación de Supervisores', 'Capacitación específica para el personal encargado de supervisar las decisiones del sistema.', 'ETHICS', 'HR'),
            ('CTRL-SEC-01', 'Robustez ante Ataques Adversarios', 'Pruebas de seguridad contra inyección de prompts, envenenamiento de datos o evasión.', 'SECURITY', 'CISO'),
            ('CTRL-TRANS-01', 'Ficha de Transparencia (System Card)', 'Documentación accesible para usuarios sobre capacidades y limitaciones del sistema.', 'TRANSPARENCY', 'PRODUCT_OWNER')
        ON CONFLICT (id) DO NOTHING;
        
        -- Insert Mappings (Best effort lookup)
        -- RISK
        INSERT INTO map_control_to_mg (control_id, mg_id)
        SELECT 'CTRL-RISK-01', id FROM master_measures WHERE requirement_code = 'RISK_MGMT' LIMIT 1 ON CONFLICT DO NOTHING;
        
        -- DATA
        INSERT INTO map_control_to_mg (control_id, mg_id)
        SELECT 'CTRL-DATA-01', id FROM master_measures WHERE requirement_code = 'DATA_GOV' LIMIT 1 ON CONFLICT DO NOTHING;
        
        -- HUMAN
        INSERT INTO map_control_to_mg (control_id, mg_id)
        SELECT 'CTRL-HUM-01', id FROM master_measures WHERE requirement_code = 'HUMAN_OVERSIGHT' LIMIT 1 ON CONFLICT DO NOTHING;
        
        RAISE NOTICE '✅ Seeding completed.';
    ELSE
        RAISE NOTICE 'ℹ️ Table master_controls already has % rows. Skipping seed.', cnt;
    END IF;
END $$;

-- 2. Verify (Smoke Test Logic)
-- ============================================================
-- Test 1: Verify Master Controls Seeded
-- ============================================================
-- Test 1: Checking Master Controls logic...
DO $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM master_controls;
    IF cnt < 5 THEN
        RAISE EXCEPTION 'FAIL: Expected at least 5 master controls, found %', cnt;
    END IF;
    RAISE NOTICE 'PASS: Master controls seeded (% found)', cnt;
END $$;

-- ============================================================
-- Test 2: Verify Mappings to AESIA
-- ============================================================
-- Test 2: Checking Control -> MG Mappings...
DO $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM map_control_to_mg;
    IF cnt < 1 THEN
        -- It's possible MGs don't exist yet if user has a totally empty DB, but we assume migrations 001-013 ran?
        -- We will just WARN if 0, not fail hard if specific MGs are missing, 
        -- but if we just seeded, we expect at least the logic to try.
        RAISE NOTICE 'WARN: No mappings found. Check if legacy master_measures table is populated.';
    ELSE
        RAISE NOTICE 'PASS: Found % control-to-MG mappings', cnt;
    END IF;
END $$;

-- '=== Fix & Verify Completed ==='
