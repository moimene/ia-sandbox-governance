import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Types
export interface Application {
    id: string
    user_id: string
    project_metadata: {
        nombre: string
        sector: string
        trl?: number
        proveedor?: string
        descripcion?: string
    }
    risk_profile?: {
        nivel?: string
        justificacion?: string
    }
    status: 'DRAFT' | 'IN_PROGRESS' | 'COMPLETED' | 'EXPORTED'
    created_at: string
    updated_at: string
}

export interface AssessmentMG {
    application_id: string
    measure_id: string
    difficulty?: string
    maturity?: string
    diagnosis_status: string
    adaptation_plan?: string
    notes?: string
}

export interface AdditionalMeasure {
    id: string
    application_id: string
    title: string
    description?: string
    attachment_url?: string
    doc_provided: boolean
    sedia_status: string
    sedia_comments?: string
    created_at: string
}

export interface RelMARequirement {
    measure_additional_id: string
    requirement_id: string
}

export interface AssessmentMA {
    measure_additional_id: string
    requirement_id: string
    difficulty?: string
    maturity?: string
    diagnosis_status: string
    adaptation_plan?: string
}

// ============ Application Functions ============

export async function createApplication(
    projectMetadata: Application['project_metadata']
): Promise<Application | null> {
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        console.error('User not authenticated')
        return null
    }

    // Get user's organization
    const { data: orgMember } = await supabase
        .from('org_members')
        .select('org_id')
        .eq('user_id', user.id)
        .single()

    if (!orgMember) {
        console.error('User does not belong to any organization')
        return null
    }

    const { data, error } = await supabase
        .from('applications')
        .insert({
            user_id: user.id,
            org_id: orgMember.org_id,
            project_metadata: projectMetadata,
            status: 'DRAFT'
        })
        .select()
        .single()

    if (error) {
        console.error('Error creating application:', error)
        return null
    }
    return data
}

export async function updateApplication(
    id: string,
    updates: Partial<Application>
): Promise<Application | null> {
    const { data, error } = await supabase
        .from('applications')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

    if (error) {
        console.error('Error updating application:', error)
        return null
    }
    return data
}

export async function getApplication(id: string): Promise<Application | null> {
    const { data, error } = await supabase
        .from('applications')
        .select('*')
        .eq('id', id)
        .single()

    if (error) {
        console.error('Error getting application:', error)
        return null
    }
    return data
}

export async function getUserApplications(): Promise<Application[]> {
    const { data, error } = await supabase
        .from('applications')
        .select('*')
        .order('created_at', { ascending: false })

    if (error) {
        console.error('Error getting applications:', error)
        return []
    }
    return data || []
}

// ============ Assessments MG Functions ============

export async function saveAssessments(
    applicationId: string,
    assessments: Record<string, string>
): Promise<boolean> {
    const records = Object.entries(assessments).map(([measureId, maturity]) => ({
        application_id: applicationId,
        measure_id: measureId,
        maturity: maturity,
        diagnosis_status: '01',
        adaptation_plan: getAdaptationPlan(maturity)
    }))

    const { error } = await supabase
        .from('assessments_mg')
        .upsert(records, {
            onConflict: 'application_id,measure_id'
        })

    if (error) {
        console.error('Error saving assessments:', error)
        return false
    }
    return true
}

export async function getAssessments(
    applicationId: string
): Promise<Record<string, string>> {
    const { data, error } = await supabase
        .from('assessments_mg')
        .select('measure_id, maturity')
        .eq('application_id', applicationId)

    if (error) {
        console.error('Error getting assessments:', error)
        return {}
    }

    const result: Record<string, string> = {}
    for (const row of data || []) {
        if (row.maturity) {
            result[row.measure_id] = row.maturity
        }
    }
    return result
}

// ============ Additional Measures Functions ============

export async function createAdditionalMeasure(
    applicationId: string,
    measure: {
        title: string
        description?: string
        attachmentUrl?: string
        linkedRequirements: string[]
        evaluations: Record<string, { maturity: string; adaptationPlan: string }>
    }
): Promise<AdditionalMeasure | null> {
    // 1. Create the measure
    const { data: maData, error: maError } = await supabase
        .from('measures_additional')
        .insert({
            application_id: applicationId,
            title: measure.title,
            description: measure.description,
            attachment_url: measure.attachmentUrl
        })
        .select()
        .single()

    if (maError || !maData) {
        console.error('Error creating additional measure:', maError)
        return null
    }

    // 2. Link to requirements
    if (measure.linkedRequirements.length > 0) {
        const links = measure.linkedRequirements.map(reqId => ({
            measure_additional_id: maData.id,
            requirement_id: reqId
        }))

        const { error: linkError } = await supabase
            .from('rel_ma_requirements')
            .insert(links)

        if (linkError) {
            console.error('Error linking requirements:', linkError)
        }
    }

    // 3. Save evaluations for each linked requirement
    const evalRecords = Object.entries(measure.evaluations).map(([reqId, eval_]) => ({
        measure_additional_id: maData.id,
        requirement_id: reqId,
        maturity: eval_.maturity,
        adaptation_plan: eval_.adaptationPlan,
        diagnosis_status: '01'
    }))

    if (evalRecords.length > 0) {
        const { error: evalError } = await supabase
            .from('assessments_ma')
            .insert(evalRecords)

        if (evalError) {
            console.error('Error saving MA evaluations:', evalError)
        }
    }

    return maData
}

export async function getAdditionalMeasures(
    applicationId: string
): Promise<Array<{
    measure: AdditionalMeasure
    linkedRequirements: string[]
    evaluations: Record<string, { maturity: string; adaptationPlan: string }>
}>> {
    // Get measures
    const { data: measures, error: measuresError } = await supabase
        .from('measures_additional')
        .select('*')
        .eq('application_id', applicationId)
        .order('created_at', { ascending: true })

    if (measuresError || !measures) {
        console.error('Error getting additional measures:', measuresError)
        return []
    }

    const result = []

    for (const measure of measures) {
        // Get linked requirements
        const { data: links } = await supabase
            .from('rel_ma_requirements')
            .select('requirement_id')
            .eq('measure_additional_id', measure.id)

        const linkedRequirements = links?.map(l => l.requirement_id) || []

        // Get evaluations
        const { data: evals } = await supabase
            .from('assessments_ma')
            .select('requirement_id, maturity, adaptation_plan')
            .eq('measure_additional_id', measure.id)

        const evaluations: Record<string, { maturity: string; adaptationPlan: string }> = {}
        for (const e of evals || []) {
            if (e.maturity) {
                evaluations[e.requirement_id] = {
                    maturity: e.maturity,
                    adaptationPlan: e.adaptation_plan || getAdaptationPlan(e.maturity)
                }
            }
        }

        result.push({
            measure,
            linkedRequirements,
            evaluations
        })
    }

    return result
}

export async function deleteAdditionalMeasure(measureId: string): Promise<boolean> {
    const { error } = await supabase
        .from('measures_additional')
        .delete()
        .eq('id', measureId)

    if (error) {
        console.error('Error deleting additional measure:', error)
        return false
    }
    return true
}

// ============ Guía 16 Compliant Assessments MG Functions ============

/**
 * Preseed assessments_mg for a given application and requirement.
 * Calls the database RPC which inserts from master_mg_to_subpart.
 * Returns number of rows inserted.
 */
export async function preseedAssessmentsMG(
    applicationId: string,
    requirementCode: string,
    requirementVersion: string = '1.0'
): Promise<number> {
    const { data, error } = await supabase.rpc('preseed_assessments_mg', {
        p_application_id: applicationId,
        p_requirement_code: requirementCode,
        p_requirement_version: requirementVersion
    })

    if (error) {
        console.error('Error preseeding assessments:', error)
        return 0
    }
    return data || 0
}

/**
 * Extended assessment type including subpart and source
 */
export interface AssessmentMGExtended {
    id?: string
    application_id: string
    measure_id: string
    subpart_id: string | null
    requirement_code: string | null
    requirement_version: string | null
    difficulty: string | null
    maturity: string | null
    diagnosis_status: string
    adaptation_plan: string | null
    source: 'CATALOG' | 'USER_ADDED'
    notes: string | null
    created_at?: string
    updated_at?: string
}

/**
 * Get all assessments_mg for a specific application and requirement.
 * Returns full assessment data including subpart_id and source.
 */
export async function getAssessmentsMGForRequirement(
    applicationId: string,
    requirementCode: string
): Promise<AssessmentMGExtended[]> {
    const { data, error } = await supabase
        .from('assessments_mg')
        .select('*')
        .eq('application_id', applicationId)
        .eq('requirement_code', requirementCode)
        .order('measure_id')

    if (error) {
        console.error('Error getting assessments for requirement:', error)
        return []
    }
    return data || []
}

/**
 * Save or update a single assessment_mg record.
 * Uses upsert on (application_id, measure_id, subpart_id).
 * The trigger will auto-derive diagnosis_status and adaptation_plan.
 */
export async function saveAssessmentMG(
    assessment: {
        application_id: string
        measure_id: string
        subpart_id: string
        requirement_code: string
        requirement_version?: string
        difficulty?: string | null
        maturity?: string | null
        source?: 'CATALOG' | 'USER_ADDED'
        notes?: string | null
    }
): Promise<boolean> {
    const record = {
        application_id: assessment.application_id,
        measure_id: assessment.measure_id,
        subpart_id: assessment.subpart_id,
        requirement_code: assessment.requirement_code,
        requirement_version: assessment.requirement_version || '1.0',
        difficulty: assessment.difficulty,
        maturity: assessment.maturity,
        source: assessment.source || 'CATALOG',
        notes: assessment.notes
    }

    const { error } = await supabase
        .from('assessments_mg')
        .upsert(record, {
            onConflict: 'application_id,measure_id,subpart_id'
        })

    if (error) {
        console.error('Error saving assessment:', error)
        return false
    }
    return true
}

/**
 * Save multiple assessments_mg in bulk.
 * Returns success/failure status.
 */
export async function saveAssessmentsMGBulk(
    assessments: Array<{
        application_id: string
        measure_id: string
        subpart_id: string
        requirement_code: string
        requirement_version?: string
        difficulty?: string | null
        maturity?: string | null
        source?: 'CATALOG' | 'USER_ADDED'
    }>
): Promise<boolean> {
    if (assessments.length === 0) return true

    const records = assessments.map(a => ({
        application_id: a.application_id,
        measure_id: a.measure_id,
        subpart_id: a.subpart_id,
        requirement_code: a.requirement_code,
        requirement_version: a.requirement_version || '1.0',
        difficulty: a.difficulty,
        maturity: a.maturity,
        source: a.source || 'CATALOG'
    }))

    const { error } = await supabase
        .from('assessments_mg')
        .upsert(records, {
            onConflict: 'application_id,measure_id,subpart_id'
        })

    if (error) {
        console.error('Error saving bulk assessments:', error)
        return false
    }
    return true
}

// ============ Guía 16 Compliant MA Functions ============

export interface AdditionalMeasureExtended {
    id: string
    application_id: string
    requirement_code: string | null
    title: string
    description: string | null
    file_name: string | null
    file_storage_path: string | null
    sedia_evaluation_status: string
    sedia_evaluator_comments: string | null
    created_at: string
}

/**
 * Create a new Additional Measure for a requirement
 */
export async function createAdditionalMeasureForRequirement(
    applicationId: string,
    requirementCode: string,
    data: {
        title: string
        description?: string
        file_name?: string
    }
): Promise<AdditionalMeasureExtended | null> {
    const { data: ma, error } = await supabase
        .from('measures_additional')
        .insert({
            application_id: applicationId,
            requirement_code: requirementCode,
            title: data.title,
            description: data.description,
            file_name: data.file_name,
            sedia_evaluation_status: '00' // Default to pending
        })
        .select()
        .single()

    if (error) {
        console.error('Error creating additional measure:', error)
        return null
    }
    return ma
}

/**
 * Get all Additional Measures for a specific application and requirement
 */
export async function getAdditionalMeasuresForRequirement(
    applicationId: string,
    requirementCode: string
): Promise<AdditionalMeasureExtended[]> {
    const { data, error } = await supabase
        .from('measures_additional')
        .select('*')
        .eq('application_id', applicationId)
        .eq('requirement_code', requirementCode)
        .order('created_at')

    if (error) {
        console.error('Error getting additional measures:', error)
        return []
    }
    return data || []
}

/**
 * Delete an Additional Measure (cascades to relations and assessments)
 */
export async function deleteAdditionalMeasureById(maId: string): Promise<boolean> {
    const { error } = await supabase
        .from('measures_additional')
        .delete()
        .eq('id', maId)

    if (error) {
        console.error('Error deleting additional measure:', error)
        return false
    }
    return true
}

/**
 * MA-Subpart relation type
 */
export interface MASubpartRelation {
    id: string
    ma_id: string
    subpart_id: string
}

/**
 * Toggle a MA-Subpart relation (add or remove)
 */
export async function toggleMASubpartRelation(
    maId: string,
    subpartId: string
): Promise<{ added: boolean; removed: boolean }> {
    // First check if relation exists
    const { data: existing } = await supabase
        .from('rel_ma_subparts')
        .select('id')
        .eq('ma_id', maId)
        .eq('subpart_id', subpartId)
        .single()

    if (existing) {
        // Remove existing relation
        await supabase
            .from('rel_ma_subparts')
            .delete()
            .eq('id', existing.id)
        return { added: false, removed: true }
    } else {
        // Add new relation
        await supabase
            .from('rel_ma_subparts')
            .insert({ ma_id: maId, subpart_id: subpartId })
        return { added: true, removed: false }
    }
}

/**
 * Get all MA-Subpart relations for an application's MAs
 */
export async function getMASubpartRelations(
    applicationId: string,
    requirementCode: string
): Promise<MASubpartRelation[]> {
    const { data, error } = await supabase
        .from('rel_ma_subparts')
        .select('*, measures_additional!inner(application_id, requirement_code)')
        .eq('measures_additional.application_id', applicationId)
        .eq('measures_additional.requirement_code', requirementCode)

    if (error) {
        console.error('Error getting MA subpart relations:', error)
        return []
    }

    return (data || []).map(r => ({
        id: r.id,
        ma_id: r.ma_id,
        subpart_id: r.subpart_id
    }))
}

/**
 * Assessment MA extended type
 */
export interface AssessmentMAExtended {
    measure_additional_id: string
    requirement_id: string
    subpart_id: string | null
    difficulty: string | null
    maturity: string | null
    diagnosis_status: string
    adaptation_plan: string | null
}

/**
 * Get assessments for all MAs in a requirement
 */
export async function getAssessmentsMAForRequirement(
    applicationId: string,
    requirementCode: string
): Promise<AssessmentMAExtended[]> {
    const { data, error } = await supabase
        .from('assessments_ma')
        .select('*, measures_additional!inner(application_id)')
        .eq('measures_additional.application_id', applicationId)
        .eq('requirement_id', requirementCode)

    if (error) {
        console.error('Error getting MA assessments:', error)
        return []
    }

    return (data || []).map(a => ({
        measure_additional_id: a.measure_additional_id,
        requirement_id: a.requirement_id,
        subpart_id: a.subpart_id,
        difficulty: a.difficulty,
        maturity: a.maturity,
        diagnosis_status: a.diagnosis_status || '00',
        adaptation_plan: a.adaptation_plan
    }))
}

/**
 * Save MA assessment (upsert)
 */
export async function saveAssessmentMA(
    assessment: {
        measure_additional_id: string
        requirement_id: string
        subpart_id?: string
        difficulty?: string | null
        maturity?: string | null
    }
): Promise<boolean> {
    // Calculate derived fields (same as MG logic)
    const diagnosis_status = assessment.maturity ? '01' : '00'
    const adaptation_plan = assessment.maturity ? getAdaptationPlan(assessment.maturity) : null

    const { error } = await supabase
        .from('assessments_ma')
        .upsert({
            measure_additional_id: assessment.measure_additional_id,
            requirement_id: assessment.requirement_id,
            subpart_id: assessment.subpart_id,
            difficulty: assessment.difficulty,
            maturity: assessment.maturity,
            diagnosis_status,
            adaptation_plan
        }, {
            onConflict: 'measure_additional_id,requirement_id'
        })

    if (error) {
        console.error('Error saving MA assessment:', error)
        return false
    }
    return true
}

// ============ Helper Functions ============

function getAdaptationPlan(maturity: string): string {
    const plans: Record<string, string> = {
        L1: '01', L2: '01',
        L3: '02', L4: '02',
        L5: '03',
        L6: '04', L7: '04',
        L8: '05'
    }
    return plans[maturity] || '00'
}

// ============ Export API Functions ============

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'

export interface ExportMGData {
    mg_id: string
    subpart_id: string
    difficulty?: string | null
    maturity?: string | null
}

export interface ExportMAData {
    id: string
    title: string
    description?: string | null
    file_name?: string | null
}

export interface ExportMAAssessment {
    ma_id: string
    subpart_id: string
    difficulty?: string | null
    maturity?: string | null
}

/**
 * Export a single requirement's checklist as Excel file
 */
export async function exportRequirementExcel(
    requirementCode: string,
    assessmentsMG: ExportMGData[],
    measuresAdditional?: ExportMAData[],
    assessmentsMA?: ExportMAAssessment[],
    maToSubpart?: { ma_id: string; subpart_id: string }[],
    applicationInfo?: Record<string, any>
): Promise<Blob | null> {
    try {
        const response = await fetch(`${BACKEND_URL}/export/single/${requirementCode}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                requirement_code: requirementCode,
                assessments_mg: assessmentsMG,
                measures_additional: measuresAdditional,
                assessments_ma: assessmentsMA,
                ma_to_subpart: maToSubpart,
                application_info: applicationInfo
            })
        })

        if (!response.ok) {
            console.error('Export failed:', response.statusText)
            return null
        }

        return await response.blob()
    } catch (error) {
        console.error('Error exporting requirement:', error)
        return null
    }
}

/**
 * Trigger download of the exported Excel blob
 */
export function downloadBlob(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
}

// ============ MA Document Storage Functions ============

const STORAGE_BUCKET = 'ma-documents'

export interface UploadProgress {
    loaded: number
    total: number
    percentage: number
}

/**
 * Upload a document for an Additional Measure to Supabase Storage.
 * Returns the storage path on success, null on failure.
 */
export async function uploadMADocument(
    applicationId: string,
    maId: string,
    file: File,
    onProgress?: (progress: UploadProgress) => void
): Promise<{ path: string; fileName: string } | null> {
    try {
        // Generate unique file path: {applicationId}/{maId}/{timestamp}_{filename}
        const timestamp = Date.now()
        const sanitizedFileName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_')
        const storagePath = `${applicationId}/${maId}/${timestamp}_${sanitizedFileName}`

        // Upload to Supabase Storage
        const { data, error } = await supabase.storage
            .from(STORAGE_BUCKET)
            .upload(storagePath, file, {
                cacheControl: '3600',
                upsert: false
            })

        if (error) {
            console.error('Error uploading document:', error)
            return null
        }

        // Update the measures_additional record with file info
        const { error: updateError } = await supabase
            .from('measures_additional')
            .update({
                file_name: file.name,
                file_storage_path: data.path
            })
            .eq('id', maId)

        if (updateError) {
            console.error('Error updating MA with file info:', updateError)
            // Don't fail - file is uploaded, just metadata update failed
        }

        // Simulate progress for simple uploads (Supabase SDK doesn't provide real progress)
        if (onProgress) {
            onProgress({ loaded: file.size, total: file.size, percentage: 100 })
        }

        return { path: data.path, fileName: file.name }
    } catch (error) {
        console.error('Error in uploadMADocument:', error)
        return null
    }
}

/**
 * Get a signed URL for downloading an MA document.
 * URL is valid for 1 hour.
 */
export async function getMADocumentUrl(storagePath: string): Promise<string | null> {
    try {
        const { data, error } = await supabase.storage
            .from(STORAGE_BUCKET)
            .createSignedUrl(storagePath, 3600) // 1 hour expiry

        if (error) {
            console.error('Error getting document URL:', error)
            return null
        }

        return data.signedUrl
    } catch (error) {
        console.error('Error in getMADocumentUrl:', error)
        return null
    }
}

/**
 * Delete an MA document from storage.
 */
export async function deleteMADocument(storagePath: string): Promise<boolean> {
    try {
        const { error } = await supabase.storage
            .from(STORAGE_BUCKET)
            .remove([storagePath])

        if (error) {
            console.error('Error deleting document:', error)
            return false
        }

        return true
    } catch (error) {
        console.error('Error in deleteMADocument:', error)
        return false
    }
}

