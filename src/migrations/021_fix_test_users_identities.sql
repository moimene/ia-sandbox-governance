-- Migration 021: Fix Test Users Authentication
-- The previous migration inserted users into auth.users but forgot auth.identities
-- Supabase Auth requires BOTH for email login to work

DO $$
DECLARE
    v_admin_id UUID := 'a0000000-0000-0000-0000-000000000001';
    v_advisor_id UUID := 'a0000000-0000-0000-0000-000000000002';
    v_user_id UUID := 'a0000000-0000-0000-0000-000000000003';
BEGIN
    -- 1. Delete old broken identities (if any partial attempts)
    DELETE FROM auth.identities WHERE user_id IN (v_admin_id, v_advisor_id, v_user_id);
    
    -- 2. Create identity for Admin
    INSERT INTO auth.identities (
        id,
        user_id, 
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        v_admin_id,
        v_admin_id,
        jsonb_build_object('sub', v_admin_id::text, 'email', 'admin@testco.com', 'email_verified', true),
        'email',
        'admin@testco.com',
        NOW(),
        NOW(),
        NOW()
    ) ON CONFLICT (provider, provider_id) DO NOTHING;

    -- 3. Create identity for Advisor
    INSERT INTO auth.identities (
        id,
        user_id, 
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        v_advisor_id,
        v_advisor_id,
        jsonb_build_object('sub', v_advisor_id::text, 'email', 'asesor@testco.com', 'email_verified', true),
        'email',
        'asesor@testco.com',
        NOW(),
        NOW(),
        NOW()
    ) ON CONFLICT (provider, provider_id) DO NOTHING;

    -- 4. Create identity for Standard User
    INSERT INTO auth.identities (
        id,
        user_id, 
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', 'usuario@testco.com', 'email_verified', true),
        'email',
        'usuario@testco.com',
        NOW(),
        NOW(),
        NOW()
    ) ON CONFLICT (provider, provider_id) DO NOTHING;
    
    -- 5. Verify users exist
    RAISE NOTICE 'Users and identities should now be correctly linked.';
END $$;

-- Diagnostic: Verify the fix
SELECT 
    u.id, 
    u.email, 
    i.provider,
    i.provider_id
FROM auth.users u
LEFT JOIN auth.identities i ON u.id = i.user_id
WHERE u.email LIKE '%@testco.com';
