'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { MaturitySelector } from '../../components/MaturitySelector'
import {
    createApplication,
    updateApplication,
    getApplication,
    saveAssessments,
    getAssessments,
    Application
} from '../../lib/supabase'
import styles from './page.module.css'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

// Sample measures for demo
const SAMPLE_MEASURES = [
    {
        id: 'MG_01_01',
        requirement: 'REQ_01',
        title: 'Identificar y analizar los riesgos conocidos y previsibles',
        guideRef: 'Guía 4',
    },
    {
        id: 'MG_01_02',
        requirement: 'REQ_01',
        title: 'Estimar y evaluar los riesgos que puedan surgir',
        guideRef: 'Guía 4',
    },
    {
        id: 'MG_02_01',
        requirement: 'REQ_02',
        title: 'Establecer prácticas de gobernanza de datos',
        guideRef: 'Guía 5',
    },
]

export default function EvaluacionPage() {
    const searchParams = useSearchParams()
    const applicationId = searchParams.get('id')

    const [projectName, setProjectName] = useState('')
    const [sector, setSector] = useState('')
    const [proveedor, setProveedor] = useState('')
    const [evaluations, setEvaluations] = useState<Record<string, string>>({})
    const [step, setStep] = useState(1)
    const [exporting, setExporting] = useState(false)
    const [saving, setSaving] = useState(false)
    const [currentAppId, setCurrentAppId] = useState<string | null>(applicationId)
    const [saveMessage, setSaveMessage] = useState('')

    // Load existing application if ID provided
    useEffect(() => {
        if (applicationId) {
            loadApplication(applicationId)
        }
    }, [applicationId])

    const loadApplication = async (id: string) => {
        const app = await getApplication(id)
        if (app) {
            setProjectName(app.project_metadata.nombre || '')
            setSector(app.project_metadata.sector || '')
            setProveedor(app.project_metadata.proveedor || '')
            setCurrentAppId(app.id)

            // Load assessments
            const assessments = await getAssessments(id)
            setEvaluations(assessments)

            // Determine step based on data
            if (Object.keys(assessments).length > 0) {
                setStep(3)
            } else if (app.project_metadata.nombre) {
                setStep(2)
            }
        }
    }

    const handleMaturityChange = (measureId: string, level: string) => {
        setEvaluations(prev => ({
            ...prev,
            [measureId]: level,
        }))
    }

    const handleSaveProject = async () => {
        setSaving(true)
        setSaveMessage('')

        try {
            const metadata = { nombre: projectName, sector: sector, proveedor: proveedor || undefined }

            if (currentAppId) {
                // Update existing
                await updateApplication(currentAppId, {
                    project_metadata: metadata,
                    status: 'IN_PROGRESS'
                })
            } else {
                // Create new
                const app = await createApplication(metadata)
                if (app) {
                    setCurrentAppId(app.id)
                    // Update URL without reload
                    window.history.pushState({}, '', `/evaluacion?id=${app.id}`)
                }
            }
            setSaveMessage('✓ Guardado')
            setTimeout(() => setSaveMessage(''), 2000)
        } catch (error) {
            console.error('Error saving:', error)
            setSaveMessage('Error al guardar')
        } finally {
            setSaving(false)
        }
    }

    const handleSaveAssessments = async () => {
        if (!currentAppId) {
            alert('Primero guarda los datos del proyecto')
            return
        }

        setSaving(true)
        try {
            const success = await saveAssessments(currentAppId, evaluations)
            if (success) {
                await updateApplication(currentAppId, { status: 'COMPLETED' })
                setSaveMessage('✓ Evaluación guardada')
                setTimeout(() => setSaveMessage(''), 2000)
            }
        } catch (error) {
            console.error('Error saving assessments:', error)
            setSaveMessage('Error al guardar')
        } finally {
            setSaving(false)
        }
    }

    const handleExportExcel = async () => {
        setExporting(true)
        try {
            const assessments = Object.entries(evaluations).map(([measureId, maturity]) => ({
                measure_id: measureId,
                maturity: maturity,
            }))

            const response = await fetch(`${API_URL}/api/export-excel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    project_metadata: { nombre: projectName, sector: sector },
                    assessments: assessments,
                }),
            })

            if (!response.ok) throw new Error('Error al exportar')

            const blob = await response.blob()
            const url = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = `preevaluacion_${projectName.replace(/\s+/g, '_')}.xlsx`
            document.body.appendChild(a)
            a.click()
            window.URL.revokeObjectURL(url)
            document.body.removeChild(a)

            // Update status to EXPORTED
            if (currentAppId) {
                await updateApplication(currentAppId, { status: 'EXPORTED' })
            }

        } catch (error) {
            console.error('Error:', error)
            alert('Error al exportar el Excel. Asegúrate de que el backend está corriendo.')
        } finally {
            setExporting(false)
        }
    }

    const completedCount = Object.keys(evaluations).length
    const progress = (completedCount / SAMPLE_MEASURES.length) * 100

    return (
        <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
            {/* Progress Bar */}
            <div className={styles.progressContainer}>
                <div className={styles.progressHeader}>
                    <span>Paso {step} de 3</span>
                    <span>
                        {completedCount} de {SAMPLE_MEASURES.length} medidas evaluadas
                        {currentAppId && <span className={styles.appId}> · ID: {currentAppId.slice(0, 8)}...</span>}
                    </span>
                </div>
                <div className={styles.progressBar}>
                    <div className={styles.progressFill} style={{ width: `${progress}%` }} />
                </div>
            </div>

            {step === 1 && (
                <div className="card">
                    <h2>Datos del Proyecto</h2>
                    <p style={{ color: 'var(--color-gray-600)', marginBottom: 'var(--spacing-xl)' }}>
                        Introduce la información básica de tu sistema de IA.
                    </p>

                    <div className="form-group">
                        <label className="form-label">Nombre del Proyecto *</label>
                        <input
                            type="text"
                            className="form-input"
                            value={projectName}
                            onChange={e => setProjectName(e.target.value)}
                            placeholder="Ej: Sistema de clasificación de documentos"
                        />
                    </div>

                    <div className="form-group">
                        <label className="form-label">Sector *</label>
                        <select
                            className="form-input"
                            value={sector}
                            onChange={e => setSector(e.target.value)}
                        >
                            <option value="">Selecciona un sector</option>
                            <option value="salud">Salud</option>
                            <option value="finanzas">Finanzas</option>
                            <option value="educacion">Educación</option>
                            <option value="transporte">Transporte</option>
                            <option value="administracion_publica">Administración Pública</option>
                            <option value="justicia">Justicia</option>
                            <option value="otro">Otro</option>
                        </select>
                    </div>

                    <div className="form-group">
                        <label className="form-label">Empresa / Cliente <span style={{ fontWeight: 'normal', color: 'var(--color-gray-500)' }}>(para asesores)</span></label>
                        <input
                            type="text"
                            className="form-input"
                            value={proveedor}
                            onChange={e => setProveedor(e.target.value)}
                            placeholder="Ej: Garrigues, ACME Corp, Cliente ABC..."
                        />
                        <small style={{ color: 'var(--color-gray-500)', fontSize: 'var(--font-size-xs)' }}>
                            Opcional. Útil para agrupar evaluaciones por cliente en la vista de asesor.
                        </small>
                    </div>

                    <div style={{ display: 'flex', gap: 'var(--spacing-md)', alignItems: 'center' }}>
                        <button
                            className="btn btn-primary"
                            onClick={async () => {
                                await handleSaveProject()
                                setStep(2)
                            }}
                            disabled={!projectName || !sector || saving}
                        >
                            {saving ? 'Guardando...' : 'Guardar y Continuar →'}
                        </button>
                        {saveMessage && <span style={{ color: 'var(--color-success)' }}>{saveMessage}</span>}
                    </div>
                </div>
            )}

            {step === 2 && (
                <div className="card">
                    <h2>Evaluación de Medidas</h2>
                    <p style={{ color: 'var(--color-gray-600)', marginBottom: 'var(--spacing-xl)' }}>
                        Selecciona el nivel de madurez para cada medida según la Guía 16 AESIA.
                    </p>

                    {SAMPLE_MEASURES.map(measure => (
                        <div key={measure.id} className={styles.measureItem}>
                            <div className={styles.measureHeader}>
                                <span className={styles.measureId}>{measure.id}</span>
                                <span className={styles.measureGuide}>{measure.guideRef}</span>
                            </div>
                            <MaturitySelector
                                value={evaluations[measure.id] || ''}
                                onChange={level => handleMaturityChange(measure.id, level)}
                                measureTitle={measure.title}
                            />
                        </div>
                    ))}

                    <div style={{ display: 'flex', gap: 'var(--spacing-md)', marginTop: 'var(--spacing-xl)', alignItems: 'center' }}>
                        <button className="btn btn-outline" onClick={() => setStep(1)}>
                            ← Volver
                        </button>
                        <button
                            className="btn btn-primary"
                            onClick={async () => {
                                await handleSaveAssessments()
                                setStep(3)
                            }}
                            disabled={completedCount < SAMPLE_MEASURES.length || saving}
                        >
                            {saving ? 'Guardando...' : 'Guardar y Ver Resumen →'}
                        </button>
                        {saveMessage && <span style={{ color: 'var(--color-success)' }}>{saveMessage}</span>}
                    </div>
                </div>
            )}

            {step === 3 && (
                <div className="card">
                    <h2>Resumen de Evaluación</h2>
                    <p style={{ color: 'var(--color-gray-600)', marginBottom: 'var(--spacing-xl)' }}>
                        Revisa tu evaluación antes de generar el informe.
                    </p>

                    <div className={styles.summaryGrid}>
                        <div className={styles.summaryItem}>
                            <span className={styles.summaryLabel}>Proyecto</span>
                            <span className={styles.summaryValue}>{projectName}</span>
                        </div>
                        <div className={styles.summaryItem}>
                            <span className={styles.summaryLabel}>Sector</span>
                            <span className={styles.summaryValue}>{sector}</span>
                        </div>
                        <div className={styles.summaryItem}>
                            <span className={styles.summaryLabel}>Medidas evaluadas</span>
                            <span className={styles.summaryValue}>{completedCount}</span>
                        </div>
                    </div>

                    <h3 style={{ marginTop: 'var(--spacing-xl)', marginBottom: 'var(--spacing-md)' }}>
                        Resultados por Medida
                    </h3>
                    <table className={styles.resultsTable}>
                        <thead>
                            <tr>
                                <th>Medida</th>
                                <th>Madurez</th>
                                <th>Plan</th>
                            </tr>
                        </thead>
                        <tbody>
                            {SAMPLE_MEASURES.map(measure => (
                                <tr key={measure.id}>
                                    <td>{measure.id}</td>
                                    <td>
                                        <span className="badge badge-success">{evaluations[measure.id]}</span>
                                    </td>
                                    <td>{getPlanForLevel(evaluations[measure.id])}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>

                    <div style={{ display: 'flex', gap: 'var(--spacing-md)', marginTop: 'var(--spacing-xl)', flexWrap: 'wrap' }}>
                        <button className="btn btn-outline" onClick={() => setStep(2)}>
                            ← Modificar
                        </button>
                        {currentAppId && (
                            <Link
                                href={`/medidas-adicionales?app=${currentAppId}`}
                                className="btn btn-outline"
                            >
                                📋 Medidas Adicionales
                            </Link>
                        )}
                        <button
                            className="btn btn-success"
                            onClick={handleExportExcel}
                            disabled={exporting}
                        >
                            {exporting ? '⏳ Generando...' : '📄 Exportar Excel'}
                        </button>
                    </div>

                    {currentAppId && (
                        <p style={{ marginTop: 'var(--spacing-lg)', fontSize: 'var(--font-size-sm)', color: 'var(--color-gray-500)' }}>
                            💾 Evaluación guardada. Puedes volver a acceder con: <code>/evaluacion?id={currentAppId}</code>
                        </p>
                    )}
                </div>
            )}
        </div>
    )
}

function getPlanForLevel(level: string): string {
    const plans: Record<string, string> = {
        L1: '01 - Documentar e Implementar',
        L2: '01 - Documentar e Implementar',
        L3: '02 - Implementar',
        L4: '02 - Implementar',
        L5: '03 - Adaptación Completa',
        L6: '04 - Documentar',
        L7: '04 - Documentar',
        L8: '05 - Ninguna acción',
    }
    return plans[level] || '-'
}
