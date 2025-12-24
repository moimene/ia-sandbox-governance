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
