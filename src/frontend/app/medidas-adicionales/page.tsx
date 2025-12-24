'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { MAWizard, AdditionalMeasure } from '../../components/MAWizard'
import {
    getApplication,
    getAdditionalMeasures,
    createAdditionalMeasure,
    deleteAdditionalMeasure,
    Application
} from '../../lib/supabase'
import styles from './page.module.css'

const REQUIREMENTS: Record<string, string> = {
    'REQ_01': 'Sistema de gestión de riesgos',
    'REQ_02': 'Datos y gobernanza de datos',
    'REQ_03': 'Documentación técnica',
    'REQ_04': 'Registro de operaciones',
    'REQ_05': 'Transparencia e información',
    'REQ_06': 'Supervisión humana',
    'REQ_07': 'Precisión, robustez y ciberseguridad',
    'REQ_08': 'Obligaciones del proveedor',
    'REQ_09': 'Sistema de gestión de calidad',
    'REQ_10': 'Conservación de documentación',
    'REQ_11': 'Registro y evaluación',
    'REQ_12': 'Monitorización post-comercialización',
}

interface MAWithDetails {
    id: string
    title: string
    description?: string
    attachmentUrl?: string
    linkedRequirements: string[]
    evaluations: Record<string, { maturity: string; adaptationPlan: string }>
}

export default function MedidasAdicionalesPage() {
    const searchParams = useSearchParams()
    const applicationId = searchParams.get('app')

    const [application, setApplication] = useState<Application | null>(null)
    const [measures, setMeasures] = useState<MAWithDetails[]>([])
    const [isWizardOpen, setIsWizardOpen] = useState(false)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        if (applicationId) {
            loadData()
        }
    }, [applicationId])

    const loadData = async () => {
        if (!applicationId) return

        setLoading(true)

        const app = await getApplication(applicationId)
        setApplication(app)

        const maData = await getAdditionalMeasures(applicationId)
        setMeasures(maData.map(m => ({
            id: m.measure.id,
            title: m.measure.title,
            description: m.measure.description,
            attachmentUrl: m.measure.attachment_url,
            linkedRequirements: m.linkedRequirements,
            evaluations: m.evaluations
        })))

        setLoading(false)
    }

    const handleSaveMeasure = async (measure: AdditionalMeasure) => {
        if (!applicationId) return

        await createAdditionalMeasure(applicationId, {
            title: measure.title,
            description: measure.description,
            attachmentUrl: measure.attachmentUrl,
            linkedRequirements: measure.linkedRequirements,
            evaluations: measure.evaluations
        })

        // Reload data
        loadData()
    }

    const handleDeleteMeasure = async (id: string) => {
        if (confirm('¿Eliminar esta medida adicional?')) {
            await deleteAdditionalMeasure(id)
            loadData()
        }
    }

    if (!applicationId) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
                <div className="card">
                    <h2>No se ha especificado una aplicación</h2>
                    <p>Necesitas acceder desde una evaluación existente.</p>
                    <Link href="/evaluacion" className="btn btn-primary">
                        Ir a Evaluación
                    </Link>
                </div>
            </div>
        )
    }

    if (loading) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
                <p>Cargando...</p>
            </div>
        )
    }

    return (
        <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
            <div className={styles.header}>
                <div>
                    <h1>Medidas Adicionales</h1>
                    {application && (
                        <p className={styles.projectName}>
                            Proyecto: <strong>{application.project_metadata.nombre}</strong>
                        </p>
                    )}
                </div>
                <button
                    className="btn btn-primary"
                    onClick={() => setIsWizardOpen(true)}
                >
                    + Nueva Medida
                </button>
            </div>

            {measures.length === 0 ? (
                <div className={styles.emptyState}>
                    <div className={styles.emptyIcon}>📋</div>
                    <h3>No hay medidas adicionales</h3>
                    <p>Las medidas adicionales son propuestas personalizadas fuera del catálogo AESIA.</p>
                    <button
                        className="btn btn-success"
                        onClick={() => setIsWizardOpen(true)}
                    >
                        Crear Primera Medida
                    </button>
                </div>
            ) : (
                <div className={styles.measuresList}>
                    {measures.map(measure => (
                        <div key={measure.id} className={styles.measureCard}>
                            <div className={styles.measureHeader}>
                                <h3>{measure.title}</h3>
                                <button
                                    className={styles.deleteBtn}
                                    onClick={() => handleDeleteMeasure(measure.id)}
                                    title="Eliminar"
                                >
                                    🗑️
                                </button>
                            </div>

                            {measure.description && (
                                <p className={styles.description}>{measure.description}</p>
                            )}

                            {measure.attachmentUrl && (
                                <a
                                    href={measure.attachmentUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className={styles.attachment}
                                >
                                    📎 Documento adjunto
                                </a>
                            )}

                            <div className={styles.linkedReqs}>
                                <strong>Requisitos vinculados:</strong>
                                <div className={styles.reqTags}>
                                    {measure.linkedRequirements.map(reqId => (
                                        <span key={reqId} className={styles.reqTag}>
                                            {reqId}
                                        </span>
                                    ))}
                                </div>
                            </div>

                            <div className={styles.evaluationsGrid}>
                                {Object.entries(measure.evaluations).map(([reqId, eval_]) => (
                                    <div key={reqId} className={styles.evalItem}>
                                        <span className={styles.evalReq}>{reqId}</span>
                                        <span className={styles.evalMaturity}>{eval_.maturity}</span>
                                        <span className={styles.evalPlan}>Plan {eval_.adaptationPlan}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            <div style={{ marginTop: 'var(--spacing-2xl)' }}>
                <Link
                    href={`/evaluacion?id=${applicationId}`}
                    className="btn btn-outline"
                >
                    ← Volver a Evaluación
                </Link>
            </div>

            <MAWizard
                isOpen={isWizardOpen}
                onClose={() => setIsWizardOpen(false)}
                onSave={handleSaveMeasure}
            />
        </div>
    )
}
