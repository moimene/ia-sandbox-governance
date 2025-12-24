-- ============================================================
-- Migration 017: Evidence Library
-- ============================================================
-- "Write Once, Reference Many" approach to compliance evidence.

-- 1. Evidence Items (The artifacts)
CREATE TABLE IF NOT EXISTS evidence_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id),
    
    title TEXT NOT NULL,
    description TEXT,
    
    -- Categorization
    typology VARCHAR(50) CHECK (
        typology IN ('POLICY', 'PROCEDURE', 'TECHNICAL_DOC', 'TEST_RESULT', 'CERTIFICATE', 'LOG_EXTRACT', 'TRAINING_RECORD')
    ),
    
    -- File Management
    storage_path TEXT NOT NULL, -- Path in 'ma-documents' or new 'evidence' bucket
    file_name TEXT NOT NULL,
    file_hash VARCHAR(64), -- SHA-256 for integrity
    file_size_bytes BIGINT,
    
    -- Validity
    valid_from DATE,
    valid_until DATE, -- For certificates/policies that expire
    
    -- Security
    confidentiality VARCHAR(20) DEFAULT 'INTERNAL' CHECK (
        confidentiality IN ('INTERNAL', 'CONFIDENTIAL', 'SECRET')
    ),
    
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Evidence -> Control Link (N:M)
-- Connecting Evidence to specific Active Controls
CREATE TABLE IF NOT EXISTS evidence_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evidence_id UUID REFERENCES evidence_items(id) ON DELETE CASCADE,
    active_control_id UUID REFERENCES active_controls(id) ON DELETE CASCADE,
    
    notes TEXT, -- Specific context, e.g. "See page 45"
    
    linked_by UUID REFERENCES auth.users(id),
    linked_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(evidence_id, active_control_id)
);

-- Trigger: Update Active Control status when evidence is added
CREATE OR REPLACE FUNCTION update_control_evidence_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Optimistic update: If a link is added, status might be VALID or PENDING_REVIEW
    -- Here we just mark it PENDING_REVIEW if it was MISSING
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

-- RLS Policies
ALTER TABLE evidence_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to ensure idempotency when recreating
DROP POLICY IF EXISTS "evidence_select" ON evidence_items;
DROP POLICY IF EXISTS "evidence_insert" ON evidence_items;

CREATE POLICY "evidence_select" ON evidence_items
FOR SELECT USING (
    public.check_org_access(org_id)
);

CREATE POLICY "evidence_insert" ON evidence_items
FOR INSERT WITH CHECK (
    public.check_org_access(org_id)
);

-- Indexing
CREATE INDEX IF NOT EXISTS idx_evidence_org ON evidence_items(org_id);
CREATE INDEX IF NOT EXISTS idx_evidence_typology ON evidence_items(typology);
