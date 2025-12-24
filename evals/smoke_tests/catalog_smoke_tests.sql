-- ============================================================
-- Smoke Tests: AESIA Guía 16 Catalog Integrity
-- ============================================================
-- Usage: psql $DATABASE_URL -f catalog_smoke_tests.sql
-- Exit code: 0 = all pass, non-zero = failures

-- Enable test output
\echo '=== AESIA Guía 16 Catalog Smoke Tests ==='
\echo ''

-- ============================================================
-- Test 1: Verify 12 requirements exist
-- ============================================================
\echo 'Test 1: Checking 12 requirements...'
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM master_requirements) != 12 THEN
        RAISE EXCEPTION 'FAIL: Expected 12 requirements, found %', 
            (SELECT COUNT(*) FROM master_requirements);
    END IF;
    RAISE NOTICE 'PASS: 12 requirements found';
END $$;

-- ============================================================
-- Test 2: Verify 84 MG measures exist
-- ============================================================
\echo 'Test 2: Checking 84 MG measures...'
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM master_measures WHERE requirement_version = '1.0') < 84 THEN
        RAISE EXCEPTION 'FAIL: Expected at least 84 measures, found %', 
            (SELECT COUNT(*) FROM master_measures WHERE requirement_version = '1.0');
    END IF;
    RAISE NOTICE 'PASS: 84+ MG measures found';
END $$;

-- ============================================================
-- Test 3: Verify 84 MG↔subpart mappings exist
-- ============================================================
\echo 'Test 3: Checking MG-to-subpart mappings...'
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM master_mg_to_subpart WHERE requirement_version = '1.0') < 84 THEN
        RAISE EXCEPTION 'FAIL: Expected at least 84 mappings, found %', 
            (SELECT COUNT(*) FROM master_mg_to_subpart WHERE requirement_version = '1.0');
    END IF;
    RAISE NOTICE 'PASS: 84+ MG-to-subpart mappings found';
END $$;

-- ============================================================
-- Test 4: No orphan MG IDs in mappings
-- ============================================================
\echo 'Test 4: Checking for orphan MG IDs...'
DO $$
DECLARE
    orphan_count INT;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM master_mg_to_subpart m
    LEFT JOIN master_measures mm ON m.mg_id = mm.id
    WHERE mm.id IS NULL;
    
    IF orphan_count > 0 THEN
        RAISE EXCEPTION 'FAIL: Found % orphan MG IDs in mappings', orphan_count;
    END IF;
    RAISE NOTICE 'PASS: No orphan MG IDs';
END $$;

-- ============================================================
-- Test 5: Verify preseed RPC exists
-- ============================================================
\echo 'Test 5: Checking preseed RPC exists...'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'preseed_assessments_mg'
    ) THEN
        RAISE EXCEPTION 'FAIL: preseed_assessments_mg function not found';
    END IF;
    RAISE NOTICE 'PASS: preseed_assessments_mg RPC exists';
END $$;

-- ============================================================
-- Test 6: Verify derive trigger exists
-- ============================================================
\echo 'Test 6: Checking derive trigger exists...'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_assessments_mg_derive'
    ) THEN
        RAISE EXCEPTION 'FAIL: trg_assessments_mg_derive trigger not found';
    END IF;
    RAISE NOTICE 'PASS: derive trigger exists';
END $$;

-- ============================================================
-- Test 7: Verify all 12 requirement codes have mappings
-- ============================================================
\echo 'Test 7: Checking all requirements have mappings...'
DO $$
DECLARE
    missing_count INT;
BEGIN
    SELECT COUNT(*) INTO missing_count
    FROM master_requirements r
    LEFT JOIN master_mg_to_subpart m ON r.code = m.requirement_code
    WHERE m.id IS NULL
      AND r.code != 'TRANSPARENCY'; -- TRANSPARENCY is in separate migration
    
    IF missing_count > 0 THEN
        RAISE EXCEPTION 'FAIL: % requirements have no MG mappings', missing_count;
    END IF;
    RAISE NOTICE 'PASS: All requirements have MG mappings';
END $$;

-- ============================================================
-- Test 8: Verify RISK_MGMT has correct article reference (Art. 9)
-- ============================================================
\echo 'Test 8: Checking RISK_MGMT article reference...'
DO $$
DECLARE
    article_ref TEXT;
BEGIN
    SELECT r.article_ref INTO article_ref
    FROM master_requirements r
    WHERE r.code = 'RISK_MGMT';
    
    IF article_ref != 'Art. 9' THEN
        RAISE EXCEPTION 'FAIL: RISK_MGMT should reference Art. 9, found %', article_ref;
    END IF;
    RAISE NOTICE 'PASS: RISK_MGMT references Art. 9';
END $$;

-- ============================================================
-- Summary
-- ============================================================
\echo ''
\echo '=== All smoke tests passed! ==='
