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
