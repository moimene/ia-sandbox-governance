'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { supabase, getApplication, getAssessmentsMGForRequirement, exportRequirementExcel, downloadBlob } from '../../../lib/supabase'
import styles from './page.module.css'

interface RequirementProgress {
    code: string
    title: string
    article_ref: string
    completedCount: number
    totalCount: number
    status: 'pending' | 'in_progress' | 'completed'
}

const REQUIREMENTS = [
    { code: 'QUALITY_MGMT', title: 'Sistema de gestión de la calidad', article_ref: 'Art. 17' },
    { code: 'RISK_MGMT', title: 'Sistema de gestión de riesgos', article_ref: 'Arts. 6-7' },
    { code: 'HUMAN_OVERSIGHT', title: 'Supervisión humana', article_ref: 'Art. 14' },
    { code: 'DATA_GOVERNANCE', title: 'Datos y gobernanza de datos', article_ref: 'Art. 10' },
    { code: 'TRANSPARENCY', title: 'Transparencia', article_ref: 'Art. 13' },
    { code: 'ACCURACY', title: 'Precisión', article_ref: 'Art. 15' },
    { code: 'ROBUSTNESS', title: 'Solidez (Robustez)', article_ref: 'Art. 15' },
    { code: 'CYBERSECURITY', title: 'Ciberseguridad', article_ref: 'Art. 15' },
    { code: 'LOGGING', title: 'Registros', article_ref: 'Art. 12' },
    { code: 'TECHNICAL_DOC', title: 'Documentación técnica', article_ref: 'Art. 11' },
    { code: 'POST_MARKET', title: 'Vigilancia poscomercialización', article_ref: 'Art. 72' },
    { code: 'INCIDENT_MGMT', title: 'Gestión de incidentes graves', article_ref: 'Art. 73' },
]

export default function ApplicationDetailPage() {
    const params = useParams()
    const router = useRouter()
    const applicationId = params.id as string

    const [loading, setLoading] = useState(true)
    const [exporting, setExporting] = useState(false)
    const [application, setApplication] = useState<any>(null)
    const [requirements, setRequirements] = useState<RequirementProgress[]>([])

    useEffect(() => {
        loadData()
    }, [applicationId])

    const loadData = async () => {
        setLoading(true)

        // Load application
        const app = await getApplication(applicationId)
        setApplication(app)

        // For now, use static requirements with mock progress
        // TODO: Load actual progress from assessments_mg
        const reqs: RequirementProgress[] = REQUIREMENTS.map(r => ({
            ...r,
            completedCount: 0,
            totalCount: 10, // Placeholder
            status: 'pending' as const
        }))
        setRequirements(reqs)

        setLoading(false)
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'completed':
                return <span className={styles.badgeCompleted}>Completado</span>
            case 'in_progress':
                return <span className={styles.badgeProgress}>En progreso</span>
            default:
                return <span className={styles.badgePending}>Pendiente</span>
        }
    }

    const getProgressPercent = (req: RequirementProgress) => {
        if (req.totalCount === 0) return 0
        return Math.round((req.completedCount / req.totalCount) * 100)
    }

    const handleExport = async () => {
        if (!application) return
        setExporting(true)
        try {
            // Fetch all requirement codes
            const requirementCodes = requirements.map(r => r.code)

            // Fetch MG assessments for all requirements
            const allMGData: any[] = []

            for (const code of requirementCodes) {
                const mgData = await getAssessmentsMGForRequirement(applicationId, code)
                allMGData.push(...mgData.map(mg => ({
                    mg_id: mg.measure_id,
                    subpart_id: mg.subpart_id,
                    maturity: mg.maturity,
                    difficulty: mg.difficulty
                })))
            }

            // Call export API with correct signature
            const blob = await exportRequirementExcel(
                'ALL',
                allMGData,
                [],
                [],
                [],
                {
                    application_id: applicationId,
                    project_name: application.project_metadata?.nombre || 'Sin nombre'
                }
            )

            if (!blob) {
                throw new Error('Export returned empty response')
            }

            // Trigger download
            const filename = `evaluacion_${application.project_metadata?.nombre || applicationId}_${new Date().toISOString().split('T')[0]}.xlsx`
            downloadBlob(blob, filename)
        } catch (error) {
            console.error('Export error:', error)
            alert('Error al exportar. Por favor, inténtelo de nuevo.')
        } finally {
            setExporting(false)
        }
    }

    if (loading) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl)' }}>
                <div className={styles.loading}>
                    <div className={styles.spinner}></div>
                    <p>Cargando aplicación...</p>
                </div>
            </div>
        )
    }

    if (!application) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl)' }}>
                <div className={styles.errorCard}>
                    <h2>Aplicación no encontrada</h2>
                    <Link href="/mis-evaluaciones" className="btn btn-primary">
                        Volver a Mis Evaluaciones
                    </Link>
                </div>
            </div>
        )
    }

    return (
        <div className="container" style={{ padding: 'var(--spacing-xl) 0' }}>
            {/* Header */}
            <div className={styles.header}>
                <div>
                    <Link href="/mis-evaluaciones" className={styles.backLink}>
                        ← Volver a Mis Evaluaciones
                    </Link>
                    <h1>{application.project_metadata?.nombre || 'Sin nombre'}</h1>
                    <p className={styles.subtitle}>
                        Evaluación de cumplimiento RIA • {application.project_metadata?.sector || 'Sin sector'}
                    </p>
                </div>
                <div className={styles.headerActions}>
                    <button className="btn btn-outline">
                        📝 Editar Ficha Técnica
                    </button>
                    <button
                        className="btn btn-primary"
                        onClick={handleExport}
                        disabled={exporting}
                    >
                        {exporting ? '⏳ Exportando...' : '📥 Exportar Excel'}
                    </button>
                </div>
            </div>

            {/* Progress Summary */}
            <div className={styles.summaryCards}>
                <div className={styles.summaryCard}>
                    <span className={styles.summaryValue}>
                        {requirements.filter(r => r.status === 'completed').length}
                    </span>
                    <span className={styles.summaryLabel}>Requisitos Completados</span>
                </div>
                <div className={styles.summaryCard}>
                    <span className={styles.summaryValue}>
                        {requirements.filter(r => r.status === 'in_progress').length}
                    </span>
                    <span className={styles.summaryLabel}>En Progreso</span>
                </div>
                <div className={styles.summaryCard}>
                    <span className={styles.summaryValue}>
                        {requirements.filter(r => r.status === 'pending').length}
                    </span>
                    <span className={styles.summaryLabel}>Pendientes</span>
                </div>
                <div className={styles.summaryCard}>
                    <span className={styles.summaryValue}>12</span>
                    <span className={styles.summaryLabel}>Total Requisitos</span>
                </div>
            </div>

            {/* Requirements Grid */}
            <h2 className={styles.sectionTitle}>Checklists por Requisito</h2>
            <p className={styles.sectionSubtitle}>
                Haga clic en un requisito para comenzar o continuar la evaluación
            </p>

            <div className={styles.requirementsGrid}>
                {requirements.map((req, idx) => (
                    <Link
                        key={req.code}
                        href={`/evaluacion/${applicationId}/${req.code}`}
                        className={styles.requirementCard}
                    >
                        <div className={styles.reqHeader}>
                            <span className={styles.reqNumber}>{idx + 1}</span>
                            {getStatusBadge(req.status)}
                        </div>
                        <h3>{req.title}</h3>
                        <span className={styles.articleRef}>{req.article_ref}</span>
                        <div className={styles.progressBar}>
                            <div
                                className={styles.progressFill}
                                style={{ width: `${getProgressPercent(req)}%` }}
                            />
                        </div>
                        <span className={styles.progressText}>
                            {req.completedCount} / {req.totalCount} medidas
                        </span>
                    </Link>
                ))}
            </div>
        </div>
    )
}
