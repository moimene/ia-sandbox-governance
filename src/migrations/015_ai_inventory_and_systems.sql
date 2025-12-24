-- ============================================================
-- Migration 015: AI Inventory & Systems Domain
-- ============================================================
-- Establishes the "Corporate Inventory" layer, distinct from 
-- specific Sandbox Applications. 
-- "AI Systems" are persistent assets; "Applications" are 
-- point-in-time regulatory submissions.

-- 1. AI Systems (The Assets)
CREATE TABLE IF NOT EXISTS ai_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id),
    name TEXT NOT NULL,
    internal_code VARCHAR(50), -- e.g. "SYS-001"
    description TEXT,
    
    -- Lifecycle Management
    lifecycle_stage VARCHAR(50) CHECK (
        lifecycle_stage IN ('DESIGN', 'DEVELOPMENT', 'TESTING', 'DEPLOYED', 'RETIRED')
    ),
    
    -- High-level Risk Classification
    risk_level VARCHAR(20) CHECK (
        risk_level IN ('MINIMAL', 'LIMITED', 'HIGH', 'UNACCEPTABLE')
    ),
    
    provider_type VARCHAR(20) CHECK (
        provider_type IN ('INTERNAL', 'EXTERNAL', 'HYBRID')
    ),
    provider_name TEXT, -- Logic for external providers
    
    owner_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. System Use Cases (Context)
-- A system might have multiple specific use cases
CREATE TABLE IF NOT EXISTS system_use_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES ai_systems(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sector VARCHAR(100), -- e.g. 'HEALTH', 'FINANCE', 'PUBLIC_ADMIN'
    deployment_context TEXT,
    affected_stakeholders TEXT[], -- e.g. ['EMPLOYEES', 'CUSTOMERS']
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Link for Legacy Compatibility (Optional/Transitional)
-- Link existing Applications (regulatory snapshots) to the persistent System
ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS system_id UUID REFERENCES ai_systems(id);

COMMENT ON TABLE ai_systems IS 
  'Persistent inventory of AI assets. Parent entity for regulatory applications.';
  
COMMENT ON COLUMN applications.system_id IS 
  'Reference to the persistent AI System this application is evaluating.';

-- RLS Policies for AI Systems
ALTER TABLE ai_systems ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ai_systems_select" ON ai_systems;
CREATE POLICY "ai_systems_select" ON ai_systems
FOR SELECT USING (
    public.check_org_access(org_id)
);

DROP POLICY IF EXISTS "ai_systems_insert" ON ai_systems;
CREATE POLICY "ai_systems_insert" ON ai_systems
FOR INSERT WITH CHECK (
    public.check_org_access(org_id)
);

DROP POLICY IF EXISTS "ai_systems_update" ON ai_systems;
CREATE POLICY "ai_systems_update" ON ai_systems
FOR UPDATE USING (
    public.check_org_access(org_id)
);

DROP POLICY IF EXISTS "ai_systems_delete" ON ai_systems;
CREATE POLICY "ai_systems_delete" ON ai_systems
FOR DELETE USING (
    -- Strict delete policy: Only owners or admins?
    public.check_org_access(org_id)     
);
