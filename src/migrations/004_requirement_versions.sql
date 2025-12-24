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
