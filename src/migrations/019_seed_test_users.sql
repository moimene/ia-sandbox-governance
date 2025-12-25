-- Migration 019: Seed Test Users for Production Testing
-- Creates 3 users: Admin, Advisor, Standard User
-- Password for all: "password123"

-- Ensure pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
    -- Fixed UUIDs for determinism
    v_org_id UUID := '00000000-0000-0000-0000-000000000001';
    
    v_admin_id UUID := 'a0000000-0000-0000-0000-000000000001';
    v_advisor_id UUID := 'a0000000-0000-0000-0000-000000000002';
    v_user_id UUID := 'a0000000-0000-0000-0000-000000000003';
    
    v_password_hash TEXT;
BEGIN
    -- 1. Create Test Organization
    INSERT INTO organizations (id, name, country, sector)
    VALUES (v_org_id, 'Test Co', 'España', 'Testing')
    ON CONFLICT (id) DO UPDATE SET name = 'Test Co';

    -- 2. Generate Hash
    -- Note: This uses bf (Blowfish/bcrypt) which is compatible with Supabase Auth
    v_password_hash := crypt('password123', gen_salt('bf'));

    -- 3. Create Users (Upsert)
    
    -- 3.1 Admin User (admin@testco.com)
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
    VALUES (
        v_admin_id, 
        '00000000-0000-0000-0000-000000000000', 
        'admin@testco.com', 
        v_password_hash, 
        NOW(), 
        '{"provider":"email","providers":["email"]}', 
        '{"name":"Admin User"}', 
        'authenticated', 
        'authenticated'
    ) 
    ON CONFLICT (id) DO UPDATE SET 
        encrypted_password = v_password_hash,
        email = 'admin@testco.com';

    -- 3.2 Advisor User (asesor@testco.com)
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
    VALUES (
        v_advisor_id, 
        '00000000-0000-0000-0000-000000000000', 
        'asesor@testco.com', 
        v_password_hash, 
        NOW(), 
        '{"provider":"email","providers":["email"]}', 
        '{"name":"Asesor Test"}', 
        'authenticated', 
        'authenticated'
    ) 
    ON CONFLICT (id) DO UPDATE SET 
        encrypted_password = v_password_hash,
        email = 'asesor@testco.com';

    -- 3.3 Standard User (usuario@testco.com)
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
    VALUES (
        v_user_id, 
        '00000000-0000-0000-0000-000000000000', 
        'usuario@testco.com', 
        v_password_hash, 
        NOW(), 
        '{"provider":"email","providers":["email"]}', 
        '{"name":"Usuario Test"}', 
        'authenticated', 
        'authenticated'
    ) 
    ON CONFLICT (id) DO UPDATE SET 
        encrypted_password = v_password_hash,
        email = 'usuario@testco.com';

    -- 4. Assign Roles in Org Members
    
    -- Admin -> ADMIN_REVIEWER
    INSERT INTO org_members (org_id, user_id, role) VALUES (v_org_id, v_admin_id, 'ADMIN_REVIEWER')
    ON CONFLICT (org_id, user_id) DO UPDATE SET role = 'ADMIN_REVIEWER';

    -- Advisor -> ADVISOR
    INSERT INTO org_members (org_id, user_id, role) VALUES (v_org_id, v_advisor_id, 'ADVISOR')
    ON CONFLICT (org_id, user_id) DO UPDATE SET role = 'ADVISOR';

    -- User -> ORG_MEMBER
    INSERT INTO org_members (org_id, user_id, role) VALUES (v_org_id, v_user_id, 'ORG_MEMBER')
    ON CONFLICT (org_id, user_id) DO UPDATE SET role = 'ORG_MEMBER';
    
    -- 5. Create valid identities (Optional but recommended for consistency)
    -- (Skipped to minimize complexity, auth.users usually sufficient for email login)
    
END $$;
