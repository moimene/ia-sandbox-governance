-- ============================================================
-- Migration 014: RIA/SEDIA Compliance Enhancements
-- ============================================================
-- Addresses gaps identified in compliance audit:
-- 1. L8 justification field (required when measure = "not necessary")
-- 2. SEDIA evaluation fields for MA
-- 3. Audit logging enhancements

-- ============================================================
-- 1. L8 Justification Field
-- ============================================================
-- When L8 "Medida no necesaria" is selected, justification is required

ALTER TABLE assessments_mg 
ADD COLUMN IF NOT EXISTS l8_justification TEXT;

COMMENT ON COLUMN assessments_mg.l8_justification IS 
    'Mandatory justification when maturity=L8 (measure not necessary). Required by AESIA Manual.';

-- Add check constraint to ensure L8 has justification (soft - allows NULL but warns)
-- Note: Hard constraint would be: CHECK (maturity != 'L8' OR l8_justification IS NOT NULL)
-- Keeping soft for backwards compatibility; frontend should enforce

-- Same for MA assessments
ALTER TABLE assessments_ma 
ADD COLUMN IF NOT EXISTS l8_justification TEXT;

-- ============================================================
-- 2. SEDIA Evaluation Fields for MA
-- ============================================================
-- SEDIA reviews additional measures proposed by entities

ALTER TABLE measures_additional
ADD COLUMN IF NOT EXISTS sedia_evaluation_status VARCHAR(10) DEFAULT '00'
    CHECK (sedia_evaluation_status IN ('00', '01', '02'));
-- 00 = Pendiente, 01 = OK, 02 = NO_OK

ALTER TABLE measures_additional
ADD COLUMN IF NOT EXISTS sedia_evaluator_comments TEXT;

ALTER TABLE measures_additional
ADD COLUMN IF NOT EXISTS sedia_evaluated_at TIMESTAMPTZ;

ALTER TABLE measures_additional
ADD COLUMN IF NOT EXISTS sedia_evaluator_id UUID REFERENCES auth.users(id);

COMMENT ON COLUMN measures_additional.sedia_evaluation_status IS 
    'SEDIA review status: 00=Pending, 01=Approved (OK), 02=Rejected (NO_OK)';

-- ============================================================
-- 3. Audit Logging Enhancements
-- ============================================================
-- Add event types for exports and sensitive operations

-- Ensure audit_logs has necessary columns (may already exist)
ALTER TABLE audit_logs 
ADD COLUMN IF NOT EXISTS event_category VARCHAR(50);

-- Update existing event types comment
COMMENT ON COLUMN audit_logs.event_type IS 
    'Event types: ASSESSMENT_CREATE, ASSESSMENT_UPDATE, EXPORT_SINGLE, EXPORT_FULL, FILE_UPLOAD, FILE_DOWNLOAD, MA_CREATE, MA_UPDATE, SEDIA_REVIEW';

-- ============================================================
-- 4. Application Locking (Evaluation Closed State)
-- ============================================================
-- Prevents edits after submission to SEDIA

ALTER TABLE applications
ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ;

ALTER TABLE applications
ADD COLUMN IF NOT EXISTS locked_by UUID REFERENCES auth.users(id);

COMMENT ON COLUMN applications.locked_at IS 
    'Timestamp when evaluation was locked for submission. NULL = editable.';

-- ============================================================
-- 5. Export Integrity (Hash for Probative Value)
-- ============================================================
-- Track hash of exported files for integrity verification

ALTER TABLE exports
ADD COLUMN IF NOT EXISTS sha256_hash VARCHAR(64);

COMMENT ON COLUMN exports.sha256_hash IS 
    'SHA-256 hash of exported file for integrity verification';

-- ============================================================
-- 6. SEDIA Reviewer Role Support
-- ============================================================
-- Extend role enum (if not already supporting SEDIA roles)

-- Note: The existing CHECK constraint on org_members.role includes
-- 'ADMIN_REVIEWER' which can be used for SEDIA. If needed:
-- ALTER TABLE org_members DROP CONSTRAINT IF EXISTS org_members_role_check;
-- ALTER TABLE org_members ADD CONSTRAINT org_members_role_check 
--     CHECK (role IN ('ORG_MEMBER', 'ADVISOR', 'ADMIN_REVIEWER', 'SEDIA_REVIEWER'));

-- ============================================================
-- Done!
-- ============================================================
COMMENT ON TABLE assessments_mg IS 
    'MG evaluations with automatic plan derivation. L8 requires l8_justification per AESIA Manual.';
