-- =============================================================================
-- Migration 010: Complete RLS Policies
-- Schema-verified multi-tenant Row Level Security
-- Executed: 2024-12-22
-- =============================================================================

-- =============================================================================
-- HELPER FUNCTION: Check organization membership
-- Uses accepted_at IS NOT NULL instead of status='active' per actual schema
-- =============================================================================
CREATE OR REPLACE FUNCTION public.check_org_access(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.org_members
        WHERE org_id = target_org_id
        AND user_id = auth.uid()
        AND accepted_at IS NOT NULL
    );
$$;

-- =============================================================================
-- ENABLE RLS ON ALL TABLES
-- =============================================================================
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments_mg ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments_ma ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measures_additional ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_measures ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- APPLICATIONS TABLE POLICIES
-- =============================================================================
CREATE POLICY "applications_select" ON public.applications FOR SELECT
USING (user_id = auth.uid() OR public.check_org_access(org_id));

CREATE POLICY "applications_insert" ON public.applications FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL AND (user_id = auth.uid() OR org_id IS NULL OR public.check_org_access(org_id)));

CREATE POLICY "applications_update" ON public.applications FOR UPDATE
USING (user_id = auth.uid() OR public.check_org_access(org_id));

CREATE POLICY "applications_delete" ON public.applications FOR DELETE
USING (user_id = auth.uid());

-- =============================================================================
-- ORGANIZATIONS AND ORG_MEMBERS POLICIES
-- =============================================================================
CREATE POLICY "org_select_member" ON public.organizations FOR SELECT
USING (public.check_org_access(id));

CREATE POLICY "org_insert_authenticated" ON public.organizations FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "org_members_select" ON public.org_members FOR SELECT
USING (public.check_org_access(org_id));

CREATE POLICY "org_members_insert" ON public.org_members FOR INSERT
WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- ASSESSMENTS_MG POLICIES (access through application)
-- =============================================================================
CREATE POLICY "assessments_mg_select" ON public.assessments_mg FOR SELECT
USING (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "assessments_mg_insert" ON public.assessments_mg FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "assessments_mg_update" ON public.assessments_mg FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "assessments_mg_delete" ON public.assessments_mg FOR DELETE
USING (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND a.user_id = auth.uid()));

-- =============================================================================
-- MEASURES_ADDITIONAL POLICIES
-- =============================================================================
CREATE POLICY "measures_additional_select" ON public.measures_additional FOR SELECT
USING (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "measures_additional_insert" ON public.measures_additional FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "measures_additional_update" ON public.measures_additional FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "measures_additional_delete" ON public.measures_additional FOR DELETE
USING (EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND a.user_id = auth.uid()));

-- =============================================================================
-- ASSESSMENTS_MA POLICIES (access through measures_additional -> application)
-- =============================================================================
CREATE POLICY "assessments_ma_select" ON public.assessments_ma FOR SELECT
USING (EXISTS (SELECT 1 FROM public.measures_additional ma JOIN public.applications a ON a.id = ma.application_id WHERE ma.id = measure_additional_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "assessments_ma_insert" ON public.assessments_ma FOR INSERT
WITH CHECK (EXISTS (SELECT 1 FROM public.measures_additional ma JOIN public.applications a ON a.id = ma.application_id WHERE ma.id = measure_additional_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "assessments_ma_update" ON public.assessments_ma FOR UPDATE
USING (EXISTS (SELECT 1 FROM public.measures_additional ma JOIN public.applications a ON a.id = ma.application_id WHERE ma.id = measure_additional_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

-- =============================================================================
-- EXPORTS POLICIES
-- =============================================================================
CREATE POLICY "exports_select" ON public.exports FOR SELECT
USING (generated_by = auth.uid() OR EXISTS (SELECT 1 FROM public.applications a WHERE a.id = application_id AND (a.user_id = auth.uid() OR public.check_org_access(a.org_id))));

CREATE POLICY "exports_insert" ON public.exports FOR INSERT
WITH CHECK (generated_by = auth.uid());

-- =============================================================================
-- AUDIT_LOGS POLICIES
-- =============================================================================
CREATE POLICY "audit_logs_select" ON public.audit_logs FOR SELECT
USING (user_id = auth.uid() OR public.check_org_access(org_id));

CREATE POLICY "audit_logs_insert" ON public.audit_logs FOR INSERT
WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- MASTER TABLES (read-only for all authenticated users)
-- =============================================================================
CREATE POLICY "master_req_read" ON public.master_requirements FOR SELECT USING (true);
CREATE POLICY "master_measures_read" ON public.master_measures FOR SELECT USING (true);

-- =============================================================================
-- VERIFICATION QUERY (run separately)
-- =============================================================================
-- SELECT tablename, policyname, cmd FROM pg_policies 
-- WHERE schemaname = 'public' ORDER BY tablename, policyname;
-- Expected: 25 policies across 10 tables
