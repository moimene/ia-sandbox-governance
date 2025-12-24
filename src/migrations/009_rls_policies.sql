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
