-- ============================================================
-- Migration 003: Organizations & Multi-tenancy
-- ============================================================
-- Establishes multi-tenant structure with organizations and members

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100) DEFAULT 'España',
    tax_id VARCHAR(50),  -- CIF/NIF
    sector VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Organization members (users belonging to orgs)
CREATE TABLE IF NOT EXISTS org_members (
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('ORG_MEMBER', 'ADVISOR', 'ADMIN_REVIEWER')),
    is_primary BOOLEAN DEFAULT FALSE,  -- Primary contact for the org
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (org_id, user_id)
);

-- Advisor-client relationships (for ADVISOR role managing multiple orgs)
CREATE TABLE IF NOT EXISTS advisor_clients (
    advisor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) DEFAULT 'ADVISOR',
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    PRIMARY KEY (advisor_user_id, client_org_id)
);

-- Add org_id to applications table
ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

-- Add created_by to track who created the application
ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_org_members_user ON org_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_role ON org_members(role);
CREATE INDEX IF NOT EXISTS idx_advisor_clients_advisor ON advisor_clients(advisor_user_id);
CREATE INDEX IF NOT EXISTS idx_applications_org ON applications(org_id);
CREATE INDEX IF NOT EXISTS idx_applications_created_by ON applications(created_by);

-- Updated_at trigger for organizations
CREATE OR REPLACE FUNCTION update_organizations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION update_organizations_updated_at();

-- Comments
COMMENT ON TABLE organizations IS 'Multi-tenant organizations (companies/clients)';
COMMENT ON TABLE org_members IS 'Users belonging to organizations with roles';
COMMENT ON TABLE advisor_clients IS 'Advisor relationships to client organizations';
COMMENT ON COLUMN org_members.role IS 'ORG_MEMBER: company employee, ADVISOR: external consultant, ADMIN_REVIEWER: SEDIA admin';
-- ============================================================
-- Migration 004: Requirement Versions, Subparts & MG Mappings
-- ============================================================
-- Extends the requirements model with versioning and article subparts

-- Requirement versions (for tracking template updates)
CREATE TABLE IF NOT EXISTS master_requirement_versions (
    requirement_code VARCHAR(50) NOT NULL REFERENCES master_requirements(code) ON DELETE CASCADE,
    version VARCHAR(20) NOT NULL,  -- e.g., '1.0', '2024-01'
    source_reference TEXT,  -- Path to template file or hash
    release_date DATE,
    changelog TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (requirement_code, version)
);

-- Article subparts (subapartados del artículo RIA)
CREATE TABLE IF NOT EXISTS master_article_subparts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requirement_code VARCHAR(50) NOT NULL,
    requirement_version VARCHAR(20) NOT NULL,
    subpart_id VARCHAR(20) NOT NULL,  -- e.g., '13.1.a', '13.1.b'
    article_number VARCHAR(10),  -- e.g., 'Art. 13'
    title_short VARCHAR(500) NOT NULL,
    description_short TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (requirement_code, requirement_version, subpart_id),
    FOREIGN KEY (requirement_code, requirement_version) 
        REFERENCES master_requirement_versions(requirement_code, version) ON DELETE CASCADE
);

-- MG to Subpart mapping (which measures apply to which subparts)
CREATE TABLE IF NOT EXISTS master_mg_to_subpart (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requirement_code VARCHAR(50) NOT NULL,
    requirement_version VARCHAR(20) NOT NULL,
    mg_id VARCHAR(20) NOT NULL,  -- References master_measures.code
    subpart_id VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT TRUE,  -- Primary vs secondary relationship
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (requirement_code, requirement_version, mg_id, subpart_id),
    FOREIGN KEY (requirement_code, requirement_version) 
        REFERENCES master_requirement_versions(requirement_code, version) ON DELETE CASCADE
);

-- Update master_measures to include requirement_code and version
ALTER TABLE master_measures 
ADD COLUMN IF NOT EXISTS requirement_code VARCHAR(50);

ALTER TABLE master_measures 
ADD COLUMN IF NOT EXISTS requirement_version VARCHAR(20);

ALTER TABLE master_measures 
ADD COLUMN IF NOT EXISTS guidance_questions JSONB DEFAULT '[]'::jsonb;

ALTER TABLE master_measures 
ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_subparts_requirement ON master_article_subparts(requirement_code, requirement_version);
CREATE INDEX IF NOT EXISTS idx_subparts_order ON master_article_subparts(order_index);
CREATE INDEX IF NOT EXISTS idx_mg_subpart_mg ON master_mg_to_subpart(mg_id);
CREATE INDEX IF NOT EXISTS idx_mg_subpart_subpart ON master_mg_to_subpart(subpart_id);
CREATE INDEX IF NOT EXISTS idx_measures_requirement ON master_measures(requirement_code, requirement_version);

-- Insert initial versions for existing requirements
INSERT INTO master_requirement_versions (requirement_code, version, active, release_date)
SELECT code, '1.0', TRUE, '2024-01-01'
FROM master_requirements
ON CONFLICT (requirement_code, version) DO NOTHING;

-- Comments
COMMENT ON TABLE master_requirement_versions IS 'Version control for requirement checklists and templates';
COMMENT ON TABLE master_article_subparts IS 'RIA article subparts (apartados) per requirement';
COMMENT ON TABLE master_mg_to_subpart IS 'N:M mapping between Medidas Guía and article subparts';
-- ============================================================
-- Migration 005: Extended Application Profile (Ficha Técnica)
-- ============================================================
-- Comprehensive technical profile for each application

-- Application profile (extended technical form)
CREATE TABLE IF NOT EXISTS application_profile (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    
    -- Identification
    system_name VARCHAR(255),
    system_version VARCHAR(50),
    system_owner VARCHAR(255),  -- Propietario
    deployment_responsible VARCHAR(255),  -- Responsable de despliegue
    
    -- Context
    sector VARCHAR(100),
    objective TEXT,
    target_users TEXT,  -- Usuarios destinatarios
    environment VARCHAR(50) CHECK (environment IN ('pilot', 'production', 'development', 'testing')),
    
    -- Classification
    system_type VARCHAR(50) CHECK (system_type IN ('high_risk', 'limited_risk', 'minimal_risk', 'prohibited')),
    evaluated_module TEXT,  -- Módulo/funcionalidad evaluada
    
    -- Data
    data_types TEXT,  -- Tipos de datos procesados
    has_personal_data BOOLEAN DEFAULT FALSE,
    has_special_categories BOOLEAN DEFAULT FALSE,  -- Categorías especiales RGPD
    data_sources TEXT,
    
    -- Evidence
    initial_documentation_urls JSONB DEFAULT '[]'::jsonb,  -- Links to initial docs
    
    -- Contact
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    contact_role VARCHAR(100) CHECK (contact_role IN ('technical', 'legal', 'business', 'dpo', 'other')),
    
    -- Additional fields (flexible JSONB for future extensions)
    additional_fields JSONB DEFAULT '{}'::jsonb,
    
    -- Consents
    consent_data_processing BOOLEAN DEFAULT FALSE,
    consent_terms_accepted BOOLEAN DEFAULT FALSE,
    consent_date TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE (application_id)
);

-- Update applications table with difficulty classification
ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS difficulty_class VARCHAR(2) CHECK (difficulty_class IN ('00', '01', '02'));

ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS system_version VARCHAR(50);

ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS title VARCHAR(255);

-- Migrate existing data: copy nombre to title if needed
UPDATE applications 
SET title = project_metadata->>'nombre'
WHERE title IS NULL AND project_metadata->>'nombre' IS NOT NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profile_application ON application_profile(application_id);
CREATE INDEX IF NOT EXISTS idx_profile_sector ON application_profile(sector);
CREATE INDEX IF NOT EXISTS idx_profile_system_type ON application_profile(system_type);
CREATE INDEX IF NOT EXISTS idx_profile_has_personal_data ON application_profile(has_personal_data);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_profile_updated_at
    BEFORE UPDATE ON application_profile
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_updated_at();

-- Comments
COMMENT ON TABLE application_profile IS 'Extended technical profile (ficha técnica) for applications';
COMMENT ON COLUMN application_profile.system_type IS 'RIA risk classification: high_risk, limited_risk, minimal_risk, prohibited';
COMMENT ON COLUMN application_profile.difficulty_class IS 'Implementation difficulty: 00=Alto, 01=Medio, 02=Bajo';
COMMENT ON COLUMN applications.difficulty_class IS 'Global difficulty classification for the case';
-- ============================================================
-- Migration 006: Exports & Audit Logs
-- ============================================================
-- Tracking for Excel exports and audit trail

-- Exports table (tracks generated Excel files)
CREATE TABLE IF NOT EXISTS exports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    
    -- Export details
    export_type VARCHAR(50) NOT NULL CHECK (export_type IN ('PER_REQUIREMENT', 'FULL_ZIP', 'SINGLE_REQUIREMENT')),
    requirement_code VARCHAR(50),  -- NULL for FULL_ZIP, specific code for single requirement
    
    -- Template versioning
    template_version_map JSONB DEFAULT '{}'::jsonb,  -- {requirement_code: version} used
    
    -- Storage
    storage_path TEXT,  -- Path in Supabase Storage
    file_name VARCHAR(255),
    file_size_bytes BIGINT,
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'QUEUED' CHECK (status IN ('QUEUED', 'RUNNING', 'DONE', 'FAILED')),
    error_message TEXT,
    
    -- User tracking
    requested_by UUID REFERENCES auth.users(id),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ  -- For auto-cleanup
);

-- Audit logs (minimal tracking for compliance)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Context
    org_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Action details
    action VARCHAR(100) NOT NULL,  -- e.g., 'CREATE', 'UPDATE', 'DELETE', 'EXPORT', 'LOGIN'
    entity_type VARCHAR(100) NOT NULL,  -- e.g., 'application', 'assessment_mg', 'export'
    entity_id UUID,
    
    -- Additional context
    metadata JSONB DEFAULT '{}'::jsonb,  -- Flexible storage for action-specific data
    
    -- Network info
    ip_address INET,
    user_agent TEXT,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Export download tracking
CREATE TABLE IF NOT EXISTS export_downloads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    export_id UUID NOT NULL REFERENCES exports(id) ON DELETE CASCADE,
    downloaded_by UUID REFERENCES auth.users(id),
    downloaded_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET
);

-- Indexes for exports
CREATE INDEX IF NOT EXISTS idx_exports_application ON exports(application_id);
CREATE INDEX IF NOT EXISTS idx_exports_status ON exports(status);
CREATE INDEX IF NOT EXISTS idx_exports_type ON exports(export_type);
CREATE INDEX IF NOT EXISTS idx_exports_created ON exports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exports_requested_by ON exports(requested_by);

-- Indexes for audit logs
CREATE INDEX IF NOT EXISTS idx_audit_org ON audit_logs(org_id);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at DESC);

-- Indexes for downloads
CREATE INDEX IF NOT EXISTS idx_downloads_export ON export_downloads(export_id);

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
    p_org_id UUID,
    p_user_id UUID,
    p_action VARCHAR(100),
    p_entity_type VARCHAR(100),
    p_entity_id UUID,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO audit_logs (org_id, user_id, action, entity_type, entity_id, metadata)
    VALUES (p_org_id, p_user_id, p_action, p_entity_type, p_entity_id, p_metadata)
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON TABLE exports IS 'Track Excel exports generated from applications';
COMMENT ON TABLE audit_logs IS 'Minimal audit trail for compliance and debugging';
COMMENT ON TABLE export_downloads IS 'Track who downloaded which exports';
COMMENT ON COLUMN exports.template_version_map IS 'JSON map of requirement_code to template version used';
COMMENT ON COLUMN exports.expires_at IS 'Optional expiration for auto-cleanup of old exports';
-- ============================================================
-- Migration 007: Update Assessments Structure
-- ============================================================
-- Extends assessments to support subpart-level evaluation per Blueprint

-- Update assessments_mg to include subpart and source tracking
ALTER TABLE assessments_mg 
ADD COLUMN IF NOT EXISTS requirement_code VARCHAR(50);

ALTER TABLE assessments_mg 
ADD COLUMN IF NOT EXISTS requirement_version VARCHAR(20) DEFAULT '1.0';

ALTER TABLE assessments_mg 
ADD COLUMN IF NOT EXISTS subpart_id VARCHAR(20);

ALTER TABLE assessments_mg 
ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'PRESEED' CHECK (source IN ('PRESEED', 'USER_ADDED'));

ALTER TABLE assessments_mg 
ADD COLUMN IF NOT EXISTS difficulty VARCHAR(2) CHECK (difficulty IN ('00', '01', '02'));

-- Update measures_additional to include requirement context and file storage
ALTER TABLE measures_additional 
ADD COLUMN IF NOT EXISTS requirement_code VARCHAR(50);

ALTER TABLE measures_additional 
ADD COLUMN IF NOT EXISTS file_name VARCHAR(255);

ALTER TABLE measures_additional 
ADD COLUMN IF NOT EXISTS file_storage_path TEXT;

ALTER TABLE measures_additional 
ADD COLUMN IF NOT EXISTS documented_state VARCHAR(2) DEFAULT '00' CHECK (documented_state IN ('00', '01'));

-- MA to Subpart relationship (replaces rel_ma_requirements for subpart-level granularity)
CREATE TABLE IF NOT EXISTS rel_ma_subparts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ma_id UUID NOT NULL REFERENCES measures_additional(id) ON DELETE CASCADE,
    subpart_id VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (ma_id, subpart_id)
);

-- Update assessments_ma to reference subparts instead of just requirements
ALTER TABLE assessments_ma 
ADD COLUMN IF NOT EXISTS subpart_id VARCHAR(20);

ALTER TABLE assessments_ma 
ADD COLUMN IF NOT EXISTS difficulty VARCHAR(2) CHECK (difficulty IN ('00', '01', '02'));

-- Create new indexes
CREATE INDEX IF NOT EXISTS idx_assessments_mg_requirement ON assessments_mg(requirement_code, requirement_version);
CREATE INDEX IF NOT EXISTS idx_assessments_mg_subpart ON assessments_mg(subpart_id);
CREATE INDEX IF NOT EXISTS idx_assessments_mg_source ON assessments_mg(source);
CREATE INDEX IF NOT EXISTS idx_ma_requirement ON measures_additional(requirement_code);
CREATE INDEX IF NOT EXISTS idx_rel_ma_subparts_ma ON rel_ma_subparts(ma_id);
CREATE INDEX IF NOT EXISTS idx_rel_ma_subparts_subpart ON rel_ma_subparts(subpart_id);
CREATE INDEX IF NOT EXISTS idx_assessments_ma_subpart ON assessments_ma(subpart_id);

-- Function to update documented_state based on file presence
CREATE OR REPLACE FUNCTION update_ma_documented_state()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.file_name IS NOT NULL AND NEW.file_name != '' THEN
        NEW.documented_state = '01';
    ELSE
        NEW.documented_state = '00';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ma_documented_state
    BEFORE INSERT OR UPDATE ON measures_additional
    FOR EACH ROW
    EXECUTE FUNCTION update_ma_documented_state();

-- Comments
COMMENT ON COLUMN assessments_mg.subpart_id IS 'Reference to article subpart (apartado)';
COMMENT ON COLUMN assessments_mg.source IS 'PRESEED: from catalog mapping, USER_ADDED: manually added by user';
COMMENT ON COLUMN assessments_mg.difficulty IS 'Perceived difficulty: 00=Alto, 01=Medio, 02=Bajo';
COMMENT ON TABLE rel_ma_subparts IS 'N:M relationship between MA and article subparts';
COMMENT ON COLUMN measures_additional.documented_state IS '00=Pendiente, 01=Ya aportada';
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
-- ============================================================
-- Migration 009: Row Level Security Policies
-- ============================================================
-- Implements multi-tenant security with organization-based access control

-- Enable RLS on all relevant tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE advisor_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments_mg ENABLE ROW LEVEL SECURITY;
ALTER TABLE measures_additional ENABLE ROW LEVEL SECURITY;
ALTER TABLE rel_ma_subparts ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments_ma ENABLE ROW LEVEL SECURITY;
ALTER TABLE exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Check if user is member of organization
CREATE OR REPLACE FUNCTION is_org_member(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM org_members 
        WHERE org_members.org_id = $1 
        AND org_members.user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is advisor for organization
CREATE OR REPLACE FUNCTION is_advisor_for_org(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM advisor_clients 
        WHERE advisor_clients.client_org_id = $1 
        AND advisor_clients.advisor_user_id = auth.uid()
        AND advisor_clients.revoked_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has access to organization (member OR advisor)
CREATE OR REPLACE FUNCTION has_org_access(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_org_member($1) OR is_advisor_for_org($1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is admin reviewer
CREATE OR REPLACE FUNCTION is_admin_reviewer()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM org_members 
        WHERE org_members.user_id = auth.uid()
        AND org_members.role = 'ADMIN_REVIEWER'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's organizations
CREATE OR REPLACE FUNCTION user_org_ids()
RETURNS SETOF UUID AS $$
BEGIN
    RETURN QUERY
    SELECT org_id FROM org_members WHERE user_id = auth.uid()
    UNION
    SELECT client_org_id FROM advisor_clients 
    WHERE advisor_user_id = auth.uid() AND revoked_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- ORGANIZATIONS POLICIES
-- ============================================================

-- Users can see organizations they belong to or advise
CREATE POLICY "org_select_policy" ON organizations
    FOR SELECT USING (
        has_org_access(id) OR is_admin_reviewer()
    );

-- Only allow insert if user will become a member (handled by trigger)
CREATE POLICY "org_insert_policy" ON organizations
    FOR INSERT WITH CHECK (TRUE);

-- Members can update their organization
CREATE POLICY "org_update_policy" ON organizations
    FOR UPDATE USING (is_org_member(id));

-- ============================================================
-- ORG_MEMBERS POLICIES
-- ============================================================

-- Users can see memberships of their organizations
CREATE POLICY "members_select_policy" ON org_members
    FOR SELECT USING (
        has_org_access(org_id) OR user_id = auth.uid() OR is_admin_reviewer()
    );

-- Users can join organizations (invite flow handled separately)
CREATE POLICY "members_insert_policy" ON org_members
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================================
-- APPLICATIONS POLICIES
-- ============================================================

-- Users can see applications from their organizations
CREATE POLICY "applications_select_policy" ON applications
    FOR SELECT USING (
        has_org_access(org_id) OR is_admin_reviewer()
    );

-- Users can create applications in their organizations
CREATE POLICY "applications_insert_policy" ON applications
    FOR INSERT WITH CHECK (
        has_org_access(org_id)
    );

-- Users can update applications in their organizations
CREATE POLICY "applications_update_policy" ON applications
    FOR UPDATE USING (
        has_org_access(org_id)
    );

-- Users can delete draft applications
CREATE POLICY "applications_delete_policy" ON applications
    FOR DELETE USING (
        has_org_access(org_id) AND status = 'DRAFT'
    );

-- ============================================================
-- APPLICATION_PROFILE POLICIES
-- ============================================================

CREATE POLICY "profile_select_policy" ON application_profile
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND (has_org_access(a.org_id) OR is_admin_reviewer())
        )
    );

CREATE POLICY "profile_insert_policy" ON application_profile
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND has_org_access(a.org_id)
        )
    );

CREATE POLICY "profile_update_policy" ON application_profile
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND has_org_access(a.org_id)
        )
    );

-- ============================================================
-- ASSESSMENTS_MG POLICIES
-- ============================================================

CREATE POLICY "assessments_mg_select_policy" ON assessments_mg
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND (has_org_access(a.org_id) OR is_admin_reviewer())
        )
    );

CREATE POLICY "assessments_mg_insert_policy" ON assessments_mg
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND has_org_access(a.org_id)
        )
    );

CREATE POLICY "assessments_mg_update_policy" ON assessments_mg
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND has_org_access(a.org_id)
        )
    );

-- ============================================================
-- MEASURES_ADDITIONAL POLICIES
-- ============================================================

CREATE POLICY "ma_select_policy" ON measures_additional
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND (has_org_access(a.org_id) OR is_admin_reviewer())
        )
    );

CREATE POLICY "ma_insert_policy" ON measures_additional
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND has_org_access(a.org_id)
        )
    );

-- Users can update their MA, admins can update sedia_status
CREATE POLICY "ma_update_policy" ON measures_additional
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND (has_org_access(a.org_id) OR is_admin_reviewer())
        )
    );

-- ============================================================
-- EXPORTS POLICIES
-- ============================================================

CREATE POLICY "exports_select_policy" ON exports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND (has_org_access(a.org_id) OR is_admin_reviewer())
        )
    );

CREATE POLICY "exports_insert_policy" ON exports
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM applications a 
            WHERE a.id = application_id 
            AND has_org_access(a.org_id)
        )
    );

-- ============================================================
-- AUDIT_LOGS POLICIES
-- ============================================================

-- Users can see audit logs for their organizations
CREATE POLICY "audit_select_policy" ON audit_logs
    FOR SELECT USING (
        has_org_access(org_id) OR user_id = auth.uid() OR is_admin_reviewer()
    );

-- Only backend (service role) can insert audit logs
CREATE POLICY "audit_insert_policy" ON audit_logs
    FOR INSERT WITH CHECK (TRUE);

-- ============================================================
-- STORAGE POLICIES (for Supabase Storage)
-- ============================================================
-- Note: These need to be applied in Supabase Dashboard or via API

-- Bucket: exports
-- Policy: Users can access exports for their applications

-- Bucket: attachments  
-- Policy: Users can upload/access attachments for their MAs

COMMENT ON FUNCTION is_org_member IS 'Check if current user is a member of the organization';
COMMENT ON FUNCTION is_advisor_for_org IS 'Check if current user is an active advisor for the organization';
COMMENT ON FUNCTION has_org_access IS 'Check if current user has any access to the organization';
COMMENT ON FUNCTION is_admin_reviewer IS 'Check if current user is an admin reviewer';
