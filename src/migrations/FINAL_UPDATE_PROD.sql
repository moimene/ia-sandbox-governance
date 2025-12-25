-- ============================================================
-- FINAL UPDATE SCRIPT FOR PRODUCTION (Supabase)
-- ============================================================
-- Copy/Paste this entire content into the SQL Editor of your Supabase Dashboard
-- to update your database with the new AI Governance tables.

-- PART 1: MIGRATION 015 (AI Inventory)
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id),
    name TEXT NOT NULL,
    internal_code VARCHAR(50), 
    description TEXT,
    lifecycle_stage VARCHAR(50) CHECK (
        lifecycle_stage IN ('DESIGN', 'DEVELOPMENT', 'TESTING', 'DEPLOYED', 'RETIRED')
    ),
    risk_level VARCHAR(20) CHECK (
        risk_level IN ('MINIMAL', 'LIMITED', 'HIGH', 'UNACCEPTABLE')
    ),
    provider_type VARCHAR(20) CHECK (
        provider_type IN ('INTERNAL', 'EXTERNAL', 'HYBRID')
    ),
    provider_name TEXT, 
    owner_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS system_use_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES ai_systems(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sector VARCHAR(100), 
    deployment_context TEXT,
    affected_stakeholders TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS system_id UUID REFERENCES ai_systems(id);

ALTER TABLE ai_systems ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ai_systems_select" ON ai_systems;
CREATE POLICY "ai_systems_select" ON ai_systems
FOR SELECT USING (public.check_org_access(org_id));

DROP POLICY IF EXISTS "ai_systems_insert" ON ai_systems;
CREATE POLICY "ai_systems_insert" ON ai_systems
FOR INSERT WITH CHECK (public.check_org_access(org_id));

DROP POLICY IF EXISTS "ai_systems_update" ON ai_systems;
CREATE POLICY "ai_systems_update" ON ai_systems
FOR UPDATE USING (public.check_org_access(org_id));

DROP POLICY IF EXISTS "ai_systems_delete" ON ai_systems;
CREATE POLICY "ai_systems_delete" ON ai_systems
FOR DELETE USING (public.check_org_access(org_id));


-- PART 2: MIGRATION 016 (Governance Controls)
-- ============================================================
CREATE TABLE IF NOT EXISTS master_controls (
    id VARCHAR(50) PRIMARY KEY, 
    title TEXT NOT NULL,
    description TEXT,
    domain VARCHAR(50), 
    default_owner_role VARCHAR(50), 
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS map_control_to_mg (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id VARCHAR(50) REFERENCES master_controls(id) ON DELETE CASCADE,
    mg_id VARCHAR(50), 
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(control_id, mg_id)
);

CREATE TABLE IF NOT EXISTS active_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES ai_systems(id) ON DELETE CASCADE,
    control_id VARCHAR(50) REFERENCES master_controls(id),
    status VARCHAR(50) DEFAULT 'NOT_STARTED' CHECK (
        status IN ('NOT_STARTED', 'IN_PROGRESS', 'IMPLEMENTED', 'REVIEWED', 'EXCEPTION', 'NOT_APPLICABLE')
    ),
    owner_id UUID REFERENCES auth.users(id),
    due_date DATE,
    next_review_date DATE,
    evidence_status VARCHAR(20) DEFAULT 'MISSING' CHECK (
        evidence_status IN ('MISSING', 'PENDING_REVIEW', 'VALID', 'EXPIRED')
    ),
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(system_id, control_id)
);

CREATE TABLE IF NOT EXISTS control_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    active_control_id UUID REFERENCES active_controls(id) ON DELETE CASCADE,
    reason_type VARCHAR(50) CHECK (
        reason_type IN ('TECHNICAL_LIMITATION', 'BUSINESS_RISK_ACCEPTED', 'NOT_APPLICABLE_BY_DESIGN', 'LEGACY_SYSTEM')
    ),
    description TEXT NOT NULL,
    compensating_measure TEXT,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'APPROVED', 'REJECTED')
    ),
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    expiration_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE active_controls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "active_controls_select" ON active_controls;
CREATE POLICY "active_controls_select" ON active_controls
FOR SELECT USING (
    EXISTS (SELECT 1 FROM ai_systems s WHERE s.id = active_controls.system_id AND public.check_org_access(s.org_id))
);

DROP POLICY IF EXISTS "active_controls_modify" ON active_controls;
CREATE POLICY "active_controls_modify" ON active_controls
FOR ALL USING (
    EXISTS (SELECT 1 FROM ai_systems s WHERE s.id = active_controls.system_id AND public.check_org_access(s.org_id))
);

CREATE INDEX IF NOT EXISTS idx_active_controls_system ON active_controls(system_id);
CREATE INDEX IF NOT EXISTS idx_active_controls_status ON active_controls(status);


-- PART 3: MIGRATION 017 (Evidence Library)
-- ============================================================
CREATE TABLE IF NOT EXISTS evidence_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id),
    title TEXT NOT NULL,
    description TEXT,
    typology VARCHAR(50) CHECK (
        typology IN ('POLICY', 'PROCEDURE', 'TECHNICAL_DOC', 'TEST_RESULT', 'CERTIFICATE', 'LOG_EXTRACT', 'TRAINING_RECORD')
    ),
    storage_path TEXT NOT NULL, 
    file_name TEXT NOT NULL,
    file_hash VARCHAR(64), 
    file_size_bytes BIGINT,
    valid_from DATE,
    valid_until DATE, 
    confidentiality VARCHAR(20) DEFAULT 'INTERNAL',
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS evidence_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evidence_id UUID REFERENCES evidence_items(id) ON DELETE CASCADE,
    active_control_id UUID REFERENCES active_controls(id) ON DELETE CASCADE,
    notes TEXT,
    linked_by UUID REFERENCES auth.users(id),
    linked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(evidence_id, active_control_id)
);

CREATE OR REPLACE FUNCTION update_control_evidence_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE active_controls
    SET evidence_status = 'PENDING_REVIEW',
        status = CASE WHEN status = 'NOT_STARTED' THEN 'IN_PROGRESS' ELSE status END
    WHERE id = NEW.active_control_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_evidence_link_added ON evidence_links;
CREATE TRIGGER trg_evidence_link_added
AFTER INSERT ON evidence_links
FOR EACH ROW EXECUTE FUNCTION update_control_evidence_status();

ALTER TABLE evidence_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "evidence_select" ON evidence_items;
CREATE POLICY "evidence_select" ON evidence_items FOR SELECT USING (public.check_org_access(org_id));

DROP POLICY IF EXISTS "evidence_insert" ON evidence_items;
CREATE POLICY "evidence_insert" ON evidence_items FOR INSERT WITH CHECK (public.check_org_access(org_id));

CREATE INDEX IF NOT EXISTS idx_evidence_org ON evidence_items(org_id);


-- PART 4: MIGRATION 018 (SEEDING)
-- ============================================================
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

-- Best-effort mappings to MGs (assuming existing requirement_id codes)
INSERT INTO map_control_to_mg (control_id, mg_id) SELECT 'CTRL-RISK-01', id FROM master_measures WHERE requirement_id = 'RISK_MGMT' LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO map_control_to_mg (control_id, mg_id) SELECT 'CTRL-DATA-01', id FROM master_measures WHERE requirement_id = 'DATA_GOV' LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO map_control_to_mg (control_id, mg_id) SELECT 'CTRL-HUM-01', id FROM master_measures WHERE requirement_id = 'HUMAN_OVERSIGHT' LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO map_control_to_mg (control_id, mg_id) SELECT 'CTRL-SEC-01', id FROM master_measures WHERE requirement_id = 'CYBERSECURITY' LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO map_control_to_mg (control_id, mg_id) SELECT 'CTRL-TRANS-01', id FROM master_measures WHERE requirement_id = 'TRANSPARENCY' LIMIT 1 ON CONFLICT DO NOTHING;

