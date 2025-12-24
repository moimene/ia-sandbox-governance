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
