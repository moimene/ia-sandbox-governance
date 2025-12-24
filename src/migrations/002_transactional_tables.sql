-- =============================================
-- Migration 002: Transactional Tables
-- IA_Sandbox - Sistema de Preevaluación
-- =============================================

-- CABECERA DE SOLICITUD
CREATE TABLE IF NOT EXISTS applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    risk_profile JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'DRAFT' 
        CHECK (status IN ('DRAFT', 'IN_PROGRESS', 'COMPLETED', 'EXPORTED')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER applications_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- EVALUACIÓN DE MEDIDAS GUÍA (MG)
CREATE TABLE IF NOT EXISTS assessments_mg (
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    measure_id TEXT NOT NULL REFERENCES master_measures(id) ON DELETE RESTRICT,
    difficulty TEXT CHECK (difficulty IN ('00', '01', '02')),
    maturity TEXT CHECK (maturity IN ('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8')),
    diagnosis_status TEXT DEFAULT '00' CHECK (diagnosis_status IN ('00', '01')),
    adaptation_plan TEXT CHECK (adaptation_plan IN ('01', '02', '03', '04', '05')),
    notes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (application_id, measure_id)
);

CREATE TRIGGER assessments_mg_updated_at
    BEFORE UPDATE ON assessments_mg
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- MEDIDAS ADICIONALES (MA)
CREATE TABLE IF NOT EXISTS measures_additional (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    attachment_url TEXT,
    doc_provided BOOLEAN GENERATED ALWAYS AS (attachment_url IS NOT NULL) STORED,
    sedia_status TEXT DEFAULT '00',
    sedia_comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CRUCE MA <-> REQUISITOS (Relación N:M)
CREATE TABLE IF NOT EXISTS rel_ma_requirements (
    measure_additional_id UUID NOT NULL REFERENCES measures_additional(id) ON DELETE CASCADE,
    requirement_id TEXT NOT NULL REFERENCES master_requirements(id) ON DELETE RESTRICT,
    PRIMARY KEY (measure_additional_id, requirement_id)
);

-- EVALUACIÓN DE MA (Contextualizada por Requisito)
CREATE TABLE IF NOT EXISTS assessments_ma (
    measure_additional_id UUID NOT NULL,
    requirement_id TEXT NOT NULL,
    difficulty TEXT CHECK (difficulty IN ('00', '01', '02')),
    maturity TEXT CHECK (maturity IN ('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8')),
    diagnosis_status TEXT DEFAULT '00',
    adaptation_plan TEXT CHECK (adaptation_plan IN ('01', '02', '03', '04', '05')),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    FOREIGN KEY (measure_additional_id, requirement_id) 
        REFERENCES rel_ma_requirements(measure_additional_id, requirement_id) ON DELETE CASCADE,
    PRIMARY KEY (measure_additional_id, requirement_id)
);

CREATE TRIGGER assessments_ma_updated_at
    BEFORE UPDATE ON assessments_ma
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- =============================================
-- Índices
-- =============================================

CREATE INDEX IF NOT EXISTS idx_applications_user ON applications(user_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_assessments_mg_application ON assessments_mg(application_id);
CREATE INDEX IF NOT EXISTS idx_ma_application ON measures_additional(application_id);
CREATE INDEX IF NOT EXISTS idx_rel_ma_measure ON rel_ma_requirements(measure_additional_id);
