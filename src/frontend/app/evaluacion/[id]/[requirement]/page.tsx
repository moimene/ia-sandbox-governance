'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { supabase } from '../../../../lib/supabase'
import { RequirementWizard, Requirement, Subpart, MeasureGuide, MGToSubpart } from '../../../../components/RequirementWizard'
import styles from './page.module.css'

export default function RequirementWizardPage() {
    const params = useParams()
    const router = useRouter()
    const applicationId = params.id as string
    const requirementCode = params.requirement as string

    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    // Data state
    const [requirement, setRequirement] = useState<Requirement | null>(null)
    const [subparts, setSubparts] = useState<Subpart[]>([])
    const [measures, setMeasures] = useState<MeasureGuide[]>([])
    const [mgToSubpart, setMgToSubpart] = useState<MGToSubpart[]>([])

    useEffect(() => {
        loadRequirementData()
    }, [requirementCode])

    const loadRequirementData = async () => {
        setLoading(true)
        setError(null)

        try {
            // Load requirement
            const { data: reqData, error: reqError } = await supabase
                .from('master_requirements')
                .select('code, title, article_ref')
                .eq('code', requirementCode)
                .single()

            if (reqError) throw reqError

            // Get active version
            const { data: versionData } = await supabase
                .from('master_requirement_versions')
                .select('version')
                .eq('requirement_code', requirementCode)
                .eq('active', true)
                .single()

            const version = versionData?.version || '1.0'

            setRequirement({
                code: reqData.code,
                title: reqData.title,
                article_ref: reqData.article_ref,
                version
            })

            // Load subparts
            const { data: subpartsData } = await supabase
                .from('master_article_subparts')
                .select('*')
                .eq('requirement_code', requirementCode)
                .eq('requirement_version', version)
                .order('order_index')

            setSubparts(subpartsData || [])

            // Load measures
            const { data: measuresData } = await supabase
                .from('master_measures')
                .select('*')
                .eq('requirement_code', requirementCode)
                .order('order_index')

            setMeasures((measuresData || []).map(m => ({
                id: m.id,
                code: m.code,
                title: m.title,
                description: m.description,
                guidance_questions: m.guidance_questions || [],
                order_index: m.order_index || 0
            })))

            // Load MG to Subpart mappings
            const { data: mappingsData } = await supabase
                .from('master_mg_to_subpart')
                .select('*')
                .eq('requirement_code', requirementCode)
                .eq('requirement_version', version)

            setMgToSubpart((mappingsData || []).map(m => ({
                mg_id: m.mg_id,
                subpart_id: m.subpart_id,
                is_primary: m.is_primary ?? true
            })))

        } catch (err: any) {
            console.error('Error loading requirement:', err)
            setError(err.message || 'Error cargando datos del requisito')
        } finally {
            setLoading(false)
        }
    }

    const handleComplete = () => {
        // TODO: Save assessments to database
        router.push(`/evaluacion/${applicationId}`)
    }

    const handleBack = () => {
        router.push(`/evaluacion/${applicationId}`)
    }

    if (loading) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl)' }}>
                <div className={styles.loading}>
                    <div className={styles.spinner}></div>
                    <p>Cargando checklist...</p>
                </div>
            </div>
        )
    }

    if (error || !requirement) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl)' }}>
                <div className={styles.errorCard}>
                    <h2>Error</h2>
                    <p>{error || 'Requisito no encontrado'}</p>
                    <Link href={`/evaluacion/${applicationId}`} className="btn btn-primary">
                        Volver
                    </Link>
                </div>
            </div>
        )
    }

    return (
        <div className="container" style={{ padding: 'var(--spacing-xl) 0' }}>
            <RequirementWizard
                applicationId={applicationId}
                requirement={requirement}
                subparts={subparts}
                measures={measures}
                mgToSubpart={mgToSubpart}
                onComplete={handleComplete}
                onBack={handleBack}
            />
        </div>
    )
}
