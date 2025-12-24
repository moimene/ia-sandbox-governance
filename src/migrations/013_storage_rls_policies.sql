-- Migration: Create ma-documents storage bucket with RLS policies
-- This allows authenticated users to upload/download files for their own applications

-- Note: Storage bucket creation must be done via Supabase Dashboard or Admin API
-- The policies below assume the bucket 'ma-documents' already exists

-- ============================================================
-- Storage RLS Policies for ma-documents bucket
-- ============================================================

-- Policy 1: Allow authenticated users to upload files to their own application folders
-- Path pattern: {applicationId}/{maId}/{timestamp}_{filename}
CREATE POLICY "Users can upload MA documents to their applications"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'ma-documents'
    AND (
        -- Extract applicationId from path (first segment)
        -- Verify user owns this application
        EXISTS (
            SELECT 1 FROM public.applications a
            WHERE a.id::text = (string_to_array(name, '/'))[1]
            AND a.user_id = auth.uid()
        )
    )
);

-- Policy 2: Allow authenticated users to read files from their own applications
CREATE POLICY "Users can read MA documents from their applications"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'ma-documents'
    AND (
        EXISTS (
            SELECT 1 FROM public.applications a
            WHERE a.id::text = (string_to_array(name, '/'))[1]
            AND a.user_id = auth.uid()
        )
    )
);

-- Policy 3: Allow authenticated users to delete files from their own applications
CREATE POLICY "Users can delete MA documents from their applications"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'ma-documents'
    AND (
        EXISTS (
            SELECT 1 FROM public.applications a
            WHERE a.id::text = (string_to_array(name, '/'))[1]
            AND a.user_id = auth.uid()
        )
    )
);

-- Policy 4: Allow authenticated users to update files in their own applications
CREATE POLICY "Users can update MA documents in their applications"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'ma-documents'
    AND (
        EXISTS (
            SELECT 1 FROM public.applications a
            WHERE a.id::text = (string_to_array(name, '/'))[1]
            AND a.user_id = auth.uid()
        )
    )
)
WITH CHECK (
    bucket_id = 'ma-documents'
    AND (
        EXISTS (
            SELECT 1 FROM public.applications a
            WHERE a.id::text = (string_to_array(name, '/'))[1]
            AND a.user_id = auth.uid()
        )
    )
);
