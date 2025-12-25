-- Migration 022: Cleanup Broken Test Users
-- The previous migrations created users with incompatible password hashes.
-- This script removes them so they can be recreated properly via Supabase Dashboard.

DO $$
DECLARE
    v_admin_id UUID := 'a0000000-0000-0000-0000-000000000001';
    v_advisor_id UUID := 'a0000000-0000-0000-0000-000000000002';
    v_user_id UUID := 'a0000000-0000-0000-0000-000000000003';
    v_org_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- 1. Remove org_members entries
    DELETE FROM public.org_members 
    WHERE user_id IN (v_admin_id, v_advisor_id, v_user_id);
    
    -- 2. Remove identities
    DELETE FROM auth.identities 
    WHERE user_id IN (v_admin_id, v_advisor_id, v_user_id);
    
    -- 3. Remove users
    DELETE FROM auth.users 
    WHERE id IN (v_admin_id, v_advisor_id, v_user_id);
    
    -- 4. Keep the test organization (optional cleanup)
    -- DELETE FROM public.organizations WHERE id = v_org_id;
    
    RAISE NOTICE 'Cleanup complete. Please create users via Supabase Dashboard.';
END $$;

-- Verify cleanup
SELECT id, email FROM auth.users WHERE email LIKE '%@testco.com';
