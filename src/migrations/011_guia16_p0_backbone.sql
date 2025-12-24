-- ============================================================
-- Migration 011: Guía 16 Compliance - P0 Database Backbone
-- ============================================================
-- This migration implements the critical P0 items for Guía 16 compliance:
-- 1. Seed master_mg_to_subpart for TRANSPARENCY (pilot)
-- 2. Fix RISK_MGMT article reference
-- 3. Add UNIQUE constraint on assessments_mg
-- 4. Create trigger for derived fields
-- 5. Create RPC for preseed

-- ============================================================
-- 1. FIX: RISK_MGMT Article Reference (Art. 9, not Arts. 6-7)
-- ============================================================
UPDATE master_requirements
SET article_ref = 'Art. 9'
WHERE code = 'RISK_MGMT';

-- ============================================================
-- 2. SEED: master_mg_to_subpart (TRANSPARENCY as pilot)
-- ============================================================
-- First, ensure the table exists
CREATE TABLE IF NOT EXISTS master_mg_to_subpart (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requirement_code VARCHAR(50) NOT NULL,
    requirement_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    mg_id VARCHAR(50) NOT NULL,
    subpart_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (requirement_code, requirement_version, mg_id, subpart_id)
);

-- Seed MG measures for TRANSPARENCY
INSERT INTO master_measures (id, requirement_code, requirement_version, guide_ref, description)
VALUES 
    ('MG_TRANS_01', 'TRANSPARENCY', '1.0', 'Guía 8', 'Diseñar el sistema para que su funcionamiento sea suficientemente transparente'),
    ('MG_TRANS_02', 'TRANSPARENCY', '1.0', 'Guía 8', 'Proporcionar identidad y datos de contacto del proveedor'),
    ('MG_TRANS_03', 'TRANSPARENCY', '1.0', 'Guía 8', 'Documentar características, capacidades y limitaciones del sistema'),
    ('MG_TRANS_04', 'TRANSPARENCY', '1.0', 'Guía 8', 'Declarar nivel de precisión y métricas pertinentes'),
    ('MG_TRANS_05', 'TRANSPARENCY', '1.0', 'Guía 8', 'Describir circunstancias de uso indebido previsible'),
    ('MG_TRANS_06', 'TRANSPARENCY', '1.0', 'Guía 8', 'Especificar requisitos de entrada del sistema'),
    ('MG_TRANS_07', 'TRANSPARENCY', '1.0', 'Guía 8', 'Informar sobre datos de entrenamiento utilizados'),
    ('MG_TRANS_08', 'TRANSPARENCY', '1.0', 'Guía 8', 'Documentar cambios durante el ciclo de vida'),
    ('MG_TRANS_09', 'TRANSPARENCY', '1.0', 'Guía 8', 'Describir medidas de supervisión humana'),
    ('MG_TRANS_10', 'TRANSPARENCY', '1.0', 'Guía 8', 'Especificar recursos computacionales necesarios'),
    ('MG_TRANS_11', 'TRANSPARENCY', '1.0', 'Guía 8', 'Proporcionar historial de decisiones con registro automático')
ON CONFLICT (id) DO UPDATE SET description = EXCLUDED.description;

-- Seed MG ↔ Subpart relations for TRANSPARENCY
INSERT INTO master_mg_to_subpart (requirement_code, requirement_version, mg_id, subpart_id)
VALUES 
    -- MG_TRANS_01 -> 13.1
    ('TRANSPARENCY', '1.0', 'MG_TRANS_01', '13.1'),
    -- MG_TRANS_02 -> 13.3.a
    ('TRANSPARENCY', '1.0', 'MG_TRANS_02', '13.3.a'),
    -- MG_TRANS_03 -> 13.3.b.i
    ('TRANSPARENCY', '1.0', 'MG_TRANS_03', '13.3.b.i'),
    -- MG_TRANS_04 -> 13.3.b.ii
    ('TRANSPARENCY', '1.0', 'MG_TRANS_04', '13.3.b.ii'),
    -- MG_TRANS_05 -> 13.3.b.iii
    ('TRANSPARENCY', '1.0', 'MG_TRANS_05', '13.3.b.iii'),
    -- MG_TRANS_06 -> 13.3.b.iv
    ('TRANSPARENCY', '1.0', 'MG_TRANS_06', '13.3.b.iv'),
    -- MG_TRANS_07 -> 13.3.b.v
    ('TRANSPARENCY', '1.0', 'MG_TRANS_07', '13.3.b.v'),
    -- MG_TRANS_08 -> 13.3.c
    ('TRANSPARENCY', '1.0', 'MG_TRANS_08', '13.3.c'),
    -- MG_TRANS_09 -> 13.3.d
    ('TRANSPARENCY', '1.0', 'MG_TRANS_09', '13.3.d'),
    -- MG_TRANS_10 -> 13.3.e
    ('TRANSPARENCY', '1.0', 'MG_TRANS_10', '13.3.e'),
    -- MG_TRANS_11 -> 13.3.f
    ('TRANSPARENCY', '1.0', 'MG_TRANS_11', '13.3.f')
ON CONFLICT (requirement_code, requirement_version, mg_id, subpart_id) DO NOTHING;

-- ============================================================
-- 3. CONSTRAINT: Unique assessments per relation
-- ============================================================
-- Add UNIQUE constraint for idempotent preseed
ALTER TABLE assessments_mg
DROP CONSTRAINT IF EXISTS uq_assessments_mg_app_measure_subpart;

ALTER TABLE assessments_mg
ADD CONSTRAINT uq_assessments_mg_app_measure_subpart
UNIQUE (application_id, measure_id, subpart_id);

-- ============================================================
-- 4. TRIGGER: Derive diagnosis_status and adaptation_plan
-- ============================================================
CREATE OR REPLACE FUNCTION public.derive_diagnosis_and_plan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- diagnosis_status: '00' if no maturity, '01' if maturity is set
    IF NEW.maturity IS NULL OR NEW.maturity = '' THEN
        NEW.diagnosis_status := '00';
        NEW.adaptation_plan := NULL;
    ELSE
        NEW.diagnosis_status := '01';
        -- Plan de Adaptación according to Guía 16 mapping
        NEW.adaptation_plan := CASE NEW.maturity
            WHEN 'L1' THEN '01'  -- Documentar e Implementar
            WHEN 'L2' THEN '01'  -- Documentar e Implementar
            WHEN 'L3' THEN '02'  -- Implementar
            WHEN 'L4' THEN '02'  -- Implementar
            WHEN 'L5' THEN '03'  -- Adaptación Completa
            WHEN 'L6' THEN '04'  -- Documentar
            WHEN 'L7' THEN '04'  -- Documentar
            WHEN 'L8' THEN '05'  -- Ninguna acción (medida no necesaria)
            ELSE NULL
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trg_assessments_mg_derive ON assessments_mg;

-- Create trigger on INSERT and UPDATE of maturity
CREATE TRIGGER trg_assessments_mg_derive
BEFORE INSERT OR UPDATE OF maturity
ON assessments_mg
FOR EACH ROW
EXECUTE FUNCTION public.derive_diagnosis_and_plan();

-- ============================================================
-- 5. RPC: Preseed assessments_mg (tenant-safe)
-- ============================================================
CREATE OR REPLACE FUNCTION public.preseed_assessments_mg(
    p_application_id UUID,
    p_requirement_code TEXT,
    p_requirement_version TEXT DEFAULT '1.0'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user UUID;
    v_org UUID;
    v_inserted INT := 0;
BEGIN
    -- Get current user
    v_user := auth.uid();
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify application belongs to user's organization
    SELECT a.org_id INTO v_org
    FROM applications a
    JOIN org_members m ON m.org_id = a.org_id
    WHERE a.id = p_application_id
      AND m.user_id = v_user
    LIMIT 1;

    IF v_org IS NULL THEN
        RAISE EXCEPTION 'Forbidden: application not accessible';
    END IF;

    -- Insert pre-seeded rows from master_mg_to_subpart
    WITH rel AS (
        SELECT mg_id, subpart_id
        FROM master_mg_to_subpart
        WHERE requirement_code = p_requirement_code
          AND requirement_version = p_requirement_version
    ),
    ins AS (
        INSERT INTO assessments_mg (
            application_id,
            measure_id,
            requirement_code,
            requirement_version,
            subpart_id,
            source,
            diagnosis_status
        )
        SELECT
            p_application_id,
            rel.mg_id,
            p_requirement_code,
            p_requirement_version,
            rel.subpart_id,
            'PRESEED',
            '00'
        FROM rel
        ON CONFLICT (application_id, measure_id, subpart_id) DO NOTHING
        RETURNING 1
    )
    SELECT COUNT(*) INTO v_inserted FROM ins;

    RETURN v_inserted;
END;
$$;

-- Grant execute to authenticated users only
REVOKE ALL ON FUNCTION public.preseed_assessments_mg(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.preseed_assessments_mg(UUID, TEXT, TEXT) TO authenticated;

-- ============================================================
-- 6. VIEW: Easy access to assessments with measure/subpart info
-- ============================================================
CREATE OR REPLACE VIEW v_assessments_mg_detail AS
SELECT 
    a.application_id,
    a.measure_id,
    a.subpart_id,
    a.requirement_code,
    a.difficulty,
    a.maturity,
    a.diagnosis_status,
    a.adaptation_plan,
    a.notes,
    a.source,
    m.description AS measure_description,
    m.guide_ref,
    s.title_short AS subpart_title,
    s.article_number
FROM assessments_mg a
LEFT JOIN master_measures m ON m.id = a.measure_id
LEFT JOIN master_article_subparts s 
    ON s.requirement_code = a.requirement_code 
    AND s.subpart_id = a.subpart_id
    AND s.requirement_version = COALESCE(a.requirement_version, '1.0');

COMMENT ON VIEW v_assessments_mg_detail IS 'Assessments joined with measure and subpart metadata';

-- ============================================================
-- Done!
-- ============================================================
