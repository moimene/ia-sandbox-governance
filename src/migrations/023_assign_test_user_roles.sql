-- Migration 023: Assign Roles to Test Users (Created via Dashboard)
-- UUIDs verified from auth.users query

DO $$
DECLARE
    v_org_id UUID := '00000000-0000-0000-0000-000000000001';
    
    -- VERIFIED UUIDs from auth.users
    v_admin_id UUID := '70c68a44-996f-4fef-8ae0-5b076d3aa04b';   -- admin@testco.com
    v_advisor_id UUID := '493a26e1-ceec-4c44-8e3f-181ed6320bd6'; -- asesor@testco.com
    v_user_id UUID := 'be617c35-9a97-460d-8b0d-e77a33e02b76';    -- usuario@testco.com
BEGIN
    INSERT INTO organizations (id, name, country, sector)
    VALUES (v_org_id, 'Test Co', 'España', 'Testing')
    ON CONFLICT (id) DO UPDATE SET name = 'Test Co';

    INSERT INTO org_members (org_id, user_id, role) 
    VALUES (v_org_id, v_admin_id, 'ADMIN_REVIEWER')
    ON CONFLICT (org_id, user_id) DO UPDATE SET role = 'ADMIN_REVIEWER';

    INSERT INTO org_members (org_id, user_id, role) 
    VALUES (v_org_id, v_advisor_id, 'ADVISOR')
    ON CONFLICT (org_id, user_id) DO UPDATE SET role = 'ADVISOR';

    INSERT INTO org_members (org_id, user_id, role) 
    VALUES (v_org_id, v_user_id, 'ORG_MEMBER')
    ON CONFLICT (org_id, user_id) DO UPDATE SET role = 'ORG_MEMBER';
END $$;

-- Verify
SELECT u.email, o.name, m.role
FROM org_members m
JOIN auth.users u ON u.id = m.user_id
JOIN organizations o ON o.id = m.org_id
WHERE o.id = '00000000-0000-0000-0000-000000000001';
