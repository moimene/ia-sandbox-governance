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
