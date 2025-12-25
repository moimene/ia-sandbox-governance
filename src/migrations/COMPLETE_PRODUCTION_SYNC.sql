-- ============================================================
-- DEFINITIVE PRODUCTION SYNC (MIGRATIONS 004 - 018)
-- ============================================================
-- This script catches up the production database from the initial state (001-003)
-- to the full Guía 16 + Governance state (018).
-- It handles the schema transition from legacy IDs (REQ_01) to Guía 16 Codes (RISK_MGMT).

-- ============================================================
-- PART 0: SCHEMA RECOVERY (Pre-requisites for 004+)
-- ============================================================

-- Ensure master_requirements has 'code' and 'active' columns
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_requirements' AND column_name='code') THEN
        ALTER TABLE master_requirements ADD COLUMN code VARCHAR(50);
        ALTER TABLE master_requirements ADD CONSTRAINT uq_requirements_code UNIQUE(code);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_requirements' AND column_name='active') THEN
        ALTER TABLE master_requirements ADD COLUMN active BOOLEAN DEFAULT TRUE;
    END IF;

    -- Ensure master_requirement_versions has 'release_date' (sometimes missing in legacy schemas)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='master_requirement_versions') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='master_requirement_versions' AND column_name='release_date') THEN
            ALTER TABLE master_requirement_versions ADD COLUMN release_date DATE;
        END IF;
    END IF;
END $$;

-- Ensure master_measures has requirement_code and version
ALTER TABLE master_measures ADD COLUMN IF NOT EXISTS requirement_code VARCHAR(50);
ALTER TABLE master_measures ADD COLUMN IF NOT EXISTS requirement_version VARCHAR(20);
ALTER TABLE master_measures ADD COLUMN IF NOT EXISTS guidance_questions JSONB DEFAULT '[]'::jsonb;
ALTER TABLE master_measures ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;

-- ============================================================
-- PART 1: MIGRATION 004 - VERSIONING & SUBPARTS
-- ============================================================

CREATE TABLE IF NOT EXISTS master_requirement_versions (
    requirement_code VARCHAR(50) NOT NULL REFERENCES master_requirements(code) ON DELETE CASCADE,
    version VARCHAR(20) NOT NULL,
    source_reference TEXT,
    release_date DATE,
    changelog TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (requirement_code, version)
);

CREATE TABLE IF NOT EXISTS master_article_subparts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requirement_code VARCHAR(50) NOT NULL,
    requirement_version VARCHAR(20) NOT NULL,
    subpart_id VARCHAR(20) NOT NULL,
    article_number VARCHAR(10),
    title_short VARCHAR(500) NOT NULL,
    description_short TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (requirement_code, requirement_version, subpart_id),
    FOREIGN KEY (requirement_code, requirement_version) REFERENCES master_requirement_versions(requirement_code, version) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS master_mg_to_subpart (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requirement_code VARCHAR(50) NOT NULL,
    requirement_version VARCHAR(20) NOT NULL,
    mg_id VARCHAR(50) NOT NULL,
    subpart_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (requirement_code, requirement_version, mg_id, subpart_id)
);

-- ============================================================
-- PART 2: MIGRATION 008 - SEED REQUIREMENTS (MODIFIED)
-- ============================================================
-- We insert using id=code to satisfy the legacy id PRIMARY KEY
-- and populate the new code column.

-- 1. QUALITY_MGMT
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('QUALITY_MGMT', 'QUALITY_MGMT', 'Sistema de gestión de la calidad', 'Requisitos calidad Art. 17', 'Art. 17', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('QUALITY_MGMT', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 2. RISK_MGMT
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('RISK_MGMT', 'RISK_MGMT', 'Sistema de gestión de riesgos', 'Gestión de riesgos Art. 9', 'Art. 9', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('RISK_MGMT', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 3. HUMAN_OVERSIGHT
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('HUMAN_OVERSIGHT', 'HUMAN_OVERSIGHT', 'Supervisión humana', 'Supervisión humana Art. 14', 'Art. 14', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('HUMAN_OVERSIGHT', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 4. DATA_GOVERNANCE
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('DATA_GOVERNANCE', 'DATA_GOVERNANCE', 'Datos y gobernanza de datos', 'Gobernanza datos Art. 10', 'Art. 10', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('DATA_GOVERNANCE', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 5. TRANSPARENCY
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('TRANSPARENCY', 'TRANSPARENCY', 'Transparencia', 'Transparencia Art. 13', 'Art. 13', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('TRANSPARENCY', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 6. ACCURACY
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('ACCURACY', 'ACCURACY', 'Precisión', 'Precisión Art. 15', 'Art. 15', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('ACCURACY', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 7. ROBUSTNESS
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('ROBUSTNESS', 'ROBUSTNESS', 'Solidez (Robustez)', 'Robustez Art. 15', 'Art. 15', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('ROBUSTNESS', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 8. CYBERSECURITY
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('CYBERSECURITY', 'CYBERSECURITY', 'Ciberseguridad', 'Ciberseguridad Art. 15', 'Art. 15', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('CYBERSECURITY', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 9. LOGGING
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('LOGGING', 'LOGGING', 'Registros', 'Registros Art. 12', 'Art. 12', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('LOGGING', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 10. TECHNICAL_DOC
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('TECHNICAL_DOC', 'TECHNICAL_DOC', 'Documentación técnica', 'Doc técnica Art. 11', 'Art. 11', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('TECHNICAL_DOC', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 11. POST_MARKET
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('POST_MARKET', 'POST_MARKET', 'Vigilancia poscomercialización', 'Vigilancia Art. 72', 'Art. 72', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('POST_MARKET', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;

-- 12. INCIDENT_MGMT
INSERT INTO master_requirements (id, code, title, description, article_ref, active)
VALUES ('INCIDENT_MGMT', 'INCIDENT_MGMT', 'Gestión de incidentes graves', 'Incidentes Art. 73', 'Art. 73', TRUE)
ON CONFLICT (id) DO UPDATE SET code = EXCLUDED.code, article_ref = EXCLUDED.article_ref;

INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
VALUES ('INCIDENT_MGMT', '1.0', TRUE, '2024-01-01') ON CONFLICT DO NOTHING;


-- ============================================================
-- PART 3: MIGRATION 007 - UPDATE ASSESSMENTS STRUCTURE
-- ============================================================
ALTER TABLE assessments_mg ADD COLUMN IF NOT EXISTS requirement_code VARCHAR(50);
ALTER TABLE assessments_mg ADD COLUMN IF NOT EXISTS requirement_version VARCHAR(20) DEFAULT '1.0';
ALTER TABLE assessments_mg ADD COLUMN IF NOT EXISTS subpart_id VARCHAR(50);
ALTER TABLE assessments_mg ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'PRESEED' CHECK (source IN ('PRESEED', 'USER_ADDED'));
ALTER TABLE assessments_mg ADD COLUMN IF NOT EXISTS difficulty VARCHAR(2) CHECK (difficulty IN ('00', '01', '02'));

-- ============================================================
-- PART 4: MIGRATION 011/012 - GUÍA 16 BACKBONE & SEEDING
-- ============================================================

-- Seed Mappings (Only example set here, user should run full 012 if needed, but we include critical ones)
-- We insert the "Master Measures" using id=code as well to satisfy FK constraints if any legacy ones exist
-- But master_measures.id is just TEXT PRIMARY KEY, so we can use whatever ID we want.
-- We use MG_ID from 012.

-- Example: RISK_MGMT Mappings (from 012)
INSERT INTO master_article_subparts (requirement_code, requirement_version, subpart_id, article_number, title_short, order_index) VALUES 
('RISK_MGMT', '1.0', '9.2.a', 'Art. 9', 'Identificación riesgos', 1),
('RISK_MGMT', '1.0', '9.2.b', 'Art. 9', 'Estimación riesgos', 2),
('TRANSPARENCY', '1.0', '13.1', 'Art. 13', 'Diseño transparencia', 1)
ON CONFLICT (requirement_code, requirement_version, subpart_id) DO NOTHING;
-- (Note: Full subpart seeding from 008 is huge, user should use the file if they want ALL text, but this is backbone recovery)

-- TRIGGER
CREATE OR REPLACE FUNCTION public.derive_diagnosis_and_plan() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.maturity IS NULL OR NEW.maturity = '' THEN
        NEW.diagnosis_status := '00'; NEW.adaptation_plan := NULL;
    ELSE
        NEW.diagnosis_status := '01';
        NEW.adaptation_plan := CASE NEW.maturity
            WHEN 'L1' THEN '01' WHEN 'L2' THEN '01' WHEN 'L3' THEN '02' WHEN 'L4' THEN '02'
            WHEN 'L5' THEN '03' WHEN 'L6' THEN '04' WHEN 'L7' THEN '04' WHEN 'L8' THEN '05' ELSE NULL END;
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_assessments_mg_derive ON assessments_mg;
CREATE TRIGGER trg_assessments_mg_derive BEFORE INSERT OR UPDATE OF maturity ON assessments_mg FOR EACH ROW EXECUTE FUNCTION public.derive_diagnosis_and_plan();

-- RPC
CREATE OR REPLACE FUNCTION public.preseed_assessments_mg(p_application_id UUID, p_requirement_code TEXT, p_requirement_version TEXT DEFAULT '1.0')
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_user UUID; v_org UUID; v_inserted INT := 0;
BEGIN
    v_user := auth.uid();
    SELECT a.org_id INTO v_org FROM applications a JOIN org_members m ON m.org_id = a.org_id WHERE a.id = p_application_id AND m.user_id = v_user LIMIT 1;
    IF v_org IS NULL THEN RAISE EXCEPTION 'Forbidden'; END IF;

    WITH rel AS (SELECT mg_id, subpart_id FROM master_mg_to_subpart WHERE requirement_code = p_requirement_code AND requirement_version = p_requirement_version),
    ins AS (INSERT INTO assessments_mg (application_id, measure_id, requirement_code, requirement_version, subpart_id, source, diagnosis_status)
    SELECT p_application_id, rel.mg_id, p_requirement_code, p_requirement_version, rel.subpart_id, 'PRESEED', '00' FROM rel ON CONFLICT DO NOTHING RETURNING 1)
    SELECT COUNT(*) INTO v_inserted FROM ins;
    RETURN v_inserted;
END;
$$;
REVOKE ALL ON FUNCTION public.preseed_assessments_mg(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.preseed_assessments_mg(UUID, TEXT, TEXT) TO authenticated;

-- ============================================================
-- PART 5: MIGRATION 015-018 - GOVERNANCE (Recover P0 Governance)
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS system_id UUID REFERENCES ai_systems(id);
ALTER TABLE ai_systems ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS master_controls (
    id VARCHAR(50) PRIMARY KEY, title TEXT NOT NULL, domain VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS active_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES ai_systems(id) ON DELETE CASCADE,
    control_id VARCHAR(50) REFERENCES master_controls(id),
    status VARCHAR(50) DEFAULT 'NOT_STARTED',
    UNIQUE(system_id, control_id)
);
ALTER TABLE active_controls ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- FINAL: Policies (Safety Net)
-- ============================================================
DROP POLICY IF EXISTS "strict_org_access" ON ai_systems;
CREATE POLICY "strict_org_access" ON ai_systems FOR ALL USING (public.check_org_access(org_id));

-- Done
