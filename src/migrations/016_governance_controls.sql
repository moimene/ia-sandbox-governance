-- ============================================================
-- Migration 016: Governance & Control Framework
-- ============================================================
-- Moves from "Checklist" to "Managed Controls".
-- Controls are persistent, owned, and stateful obligations.

-- 1. Master Library of Corporate Controls
-- Allows creating a superset of obligations (AESIA + ISO 42001 + Internal)
CREATE TABLE IF NOT EXISTS master_controls (
    id VARCHAR(50) PRIMARY KEY, -- e.g. 'CTRL-HUM-01'
    title TEXT NOT NULL,
    description TEXT,
    domain VARCHAR(50), -- 'SECURITY', 'DATA', 'ETHICS', 'ROBUSTNESS'
    default_owner_role VARCHAR(50), -- 'CISO', 'EPO', 'DEV_LEAD'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Mapping Controls to AESIA Measures (Subpart mapping)
-- One Control can satisfy multiple AESIA requirements
CREATE TABLE IF NOT EXISTS map_control_to_mg (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id VARCHAR(50) REFERENCES master_controls(id) ON DELETE CASCADE,
    
    -- Linking to the existing catalog
    mg_id VARCHAR(50), -- Soft link to master_measures.id
    
    -- Ideally, we link to specific subparts, but starting with MG level
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(control_id, mg_id)
);

-- 3. Active Controls (Instance of a Control on a System)
CREATE TABLE IF NOT EXISTS active_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID REFERENCES ai_systems(id) ON DELETE CASCADE,
    control_id VARCHAR(50) REFERENCES master_controls(id),
    
    -- Operational Status
    status VARCHAR(50) DEFAULT 'NOT_STARTED' CHECK (
        status IN ('NOT_STARTED', 'IN_PROGRESS', 'IMPLEMENTED', 'REVIEWED', 'EXCEPTION', 'NOT_APPLICABLE')
    ),
    
    owner_id UUID REFERENCES auth.users(id),
    due_date DATE,
    next_review_date DATE,
    
    -- Evidence Summary (Computed or Updated by Triggers)
    evidence_status VARCHAR(20) DEFAULT 'MISSING' CHECK (
        evidence_status IN ('MISSING', 'PENDING_REVIEW', 'VALID', 'EXPIRED')
    ),
    
    -- Verification
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMPTZ,
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(system_id, control_id)
);

-- 4. Exceptions & Justifications
-- Formal process for "Not Applicable" or "Temporary Exception"
CREATE TABLE IF NOT EXISTS control_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    active_control_id UUID REFERENCES active_controls(id) ON DELETE CASCADE,
    
    reason_type VARCHAR(50) CHECK (
        reason_type IN ('TECHNICAL_LIMITATION', 'BUSINESS_RISK_ACCEPTED', 'NOT_APPLICABLE_BY_DESIGN', 'LEGACY_SYSTEM')
    ),
    description TEXT NOT NULL,
    compensating_measure TEXT,
    
    -- Approval Workflow
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'APPROVED', 'REJECTED')
    ),
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    
    expiration_date DATE, -- Exceptions should expire!
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE active_controls ENABLE ROW LEVEL SECURITY;

-- Access via System Organization
DROP POLICY IF EXISTS "active_controls_select" ON active_controls;
CREATE POLICY "active_controls_select" ON active_controls
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM ai_systems s
        WHERE s.id = active_controls.system_id
        AND public.check_org_access(s.org_id)
    )
);

DROP POLICY IF EXISTS "active_controls_modify" ON active_controls;
CREATE POLICY "active_controls_modify" ON active_controls
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM ai_systems s
        WHERE s.id = active_controls.system_id
        AND public.check_org_access(s.org_id)
    )
);

-- Indexes for Dashboard Performance
CREATE INDEX IF NOT EXISTS idx_active_controls_system ON active_controls(system_id);
CREATE INDEX IF NOT EXISTS idx_active_controls_status ON active_controls(status);
CREATE INDEX IF NOT EXISTS idx_active_controls_owner ON active_controls(owner_id);
