-- Migration 020: Fix Permissions and Diagnostics
-- Addresses "Database error querying schema" on Login
-- Ensures authenticated users can access the public schema

BEGIN;

-- 1. Grant Usage on Schema
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

-- 2. Grant Access to All Tables (Safety Net)
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 3. Grant Access to All Sequences (for IDs)
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 4. Ensure RLS is enabled on key tables (just in case)
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- 5. Diagnostic: List Test Users (to verify 019 ran)
-- This will return the users if run in SQL Editor
SELECT id, email, role FROM auth.users WHERE email LIKE '%@testco.com';

-- 6. Diagnostic: Check RLS Policies existence (Query system catalog)
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('organizations', 'org_members', 'applications');

COMMIT;
