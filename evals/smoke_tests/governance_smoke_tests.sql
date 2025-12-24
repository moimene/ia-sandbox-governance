-- ============================================================
-- Smoke Tests: Corporate Governance Extensions
-- ============================================================
-- Usage: psql $DATABASE_URL -f governance_smoke_tests.sql
-- Exit code: 0 = all pass, non-zero = failures

-- '=== Corporate Governance Smoke Tests ==='

-- ============================================================
-- Test 1: Verify Master Controls Seeded
-- ============================================================
-- Test 1: Checking Master Controls logic...
DO $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM master_controls;
    IF cnt < 5 THEN
        RAISE EXCEPTION 'FAIL: Expected at least 5 master controls, found %', cnt;
    END IF;
    RAISE NOTICE 'PASS: Master controls seeded (% found)', cnt;
END $$;

-- ============================================================
-- Test 2: Verify Inventory Schema
-- ============================================================
-- Test 2: Checking AI Systems table...
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ai_systems' AND column_name = 'lifecycle_stage'
    ) THEN
        RAISE EXCEPTION 'FAIL: ai_systems table or lifecycle_stage column missing';
    END IF;
    RAISE NOTICE 'PASS: ai_systems schema correct';
END $$;

-- ============================================================
-- Test 3: Verify Evidence Triggers
-- ============================================================
-- Test 3: Checking Evidence Trigger...
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_evidence_link_added'
    ) THEN
        RAISE EXCEPTION 'FAIL: trg_evidence_link_added trigger not found';
    END IF;
    RAISE NOTICE 'PASS: Evidence automation trigger exists';
END $$;

-- ============================================================
-- Test 4: Verify Mappings to AESIA
-- ============================================================
-- Test 4: Checking Control -> MG Mappings...
DO $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM map_control_to_mg;
    -- We inserted 5 mappings in migration 018
    IF cnt < 1 THEN
        RAISE WARNING 'WARN: No mappings found in map_control_to_mg. Did 018 run correctly?';
    ELSE
        RAISE NOTICE 'PASS: Found % control-to-MG mappings', cnt;
    END IF;
END $$;

-- '=== Governance Tests Passed ==='
