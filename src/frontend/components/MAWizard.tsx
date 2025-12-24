'use client'

import { useState } from 'react'
import styles from './MAWizard.module.css'

interface Requirement {
    id: string
    title: string
}

interface AdditionalMeasure {
    id?: string
    title: string
    description: string
    attachmentUrl?: string
    linkedRequirements: string[]
    evaluations: Record<string, { maturity: string; adaptationPlan: string }>
}

interface Props {
    isOpen: boolean
    onClose: () => void
    onSave: (measure: AdditionalMeasure) => void
    existingMeasure?: AdditionalMeasure
}

const REQUIREMENTS: Requirement[] = [
    { id: 'REQ_01', title: 'Sistema de gestión de riesgos' },
    { id: 'REQ_02', title: 'Datos y gobernanza de datos' },
    { id: 'REQ_03', title: 'Documentación técnica' },
    { id: 'REQ_04', title: 'Registro de operaciones' },
    { id: 'REQ_05', title: 'Transparencia e información' },
    { id: 'REQ_06', title: 'Supervisión humana' },
    { id: 'REQ_07', title: 'Precisión, robustez y ciberseguridad' },
    { id: 'REQ_08', title: 'Obligaciones del proveedor' },
    { id: 'REQ_09', title: 'Sistema de gestión de calidad' },
    { id: 'REQ_10', title: 'Conservación de documentación' },
    { id: 'REQ_11', title: 'Registro y evaluación' },
    { id: 'REQ_12', title: 'Monitorización post-comercialización' },
]

const MATURITY_LEVELS = [
    { code: 'L1', label: 'No identificada', plan: '01' },
    { code: 'L2', label: 'Identificada, no documentada', plan: '01' },
    { code: 'L3', label: 'Documentada, no implementada', plan: '02' },
    { code: 'L4', label: 'Parcialmente implementada', plan: '02' },
    { code: 'L5', label: 'Implementada sin evidencia', plan: '03' },
    { code: 'L6', label: 'Implementada, evidencia parcial', plan: '04' },
    { code: 'L7', label: 'Implementada, evidencia completa', plan: '04' },
    { code: 'L8', label: 'Cumplimiento total verificado', plan: '05' },
]

export function MAWizard({ isOpen, onClose, onSave, existingMeasure }: Props) {
    const [step, setStep] = useState(1)
    const [title, setTitle] = useState(existingMeasure?.title || '')
    const [description, setDescription] = useState(existingMeasure?.description || '')
    const [attachmentUrl, setAttachmentUrl] = useState(existingMeasure?.attachmentUrl || '')
    const [linkedRequirements, setLinkedRequirements] = useState<string[]>(
        existingMeasure?.linkedRequirements || []
    )
    const [evaluations, setEvaluations] = useState<Record<string, { maturity: string; adaptationPlan: string }>>(
        existingMeasure?.evaluations || {}
    )

    if (!isOpen) return null

    const toggleRequirement = (reqId: string) => {
        setLinkedRequirements(prev => {
            if (prev.includes(reqId)) {
                // Remove evaluation when unlinking
                const newEvals = { ...evaluations }
                delete newEvals[reqId]
                setEvaluations(newEvals)
                return prev.filter(id => id !== reqId)
            }
            return [...prev, reqId]
        })
    }

    const setMaturity = (reqId: string, maturity: string) => {
        const level = MATURITY_LEVELS.find(l => l.code === maturity)
        setEvaluations(prev => ({
            ...prev,
            [reqId]: {
                maturity,
                adaptationPlan: level?.plan || '00'
            }
        }))
    }

    const handleSave = () => {
        onSave({
            id: existingMeasure?.id,
            title,
            description,
            attachmentUrl: attachmentUrl || undefined,
            linkedRequirements,
            evaluations
        })
        onClose()
    }

    const canProceedStep1 = title.trim().length > 0
    const canProceedStep2 = linkedRequirements.length > 0
    const canProceedStep3 = linkedRequirements.every(reqId => evaluations[reqId]?.maturity)

    return (
        <div className={styles.overlay} onClick={onClose}>
            <div className={styles.modal} onClick={e => e.stopPropagation()}>
                <div className={styles.header}>
                    <h2>
                        {existingMeasure ? 'Editar' : 'Nueva'} Medida Adicional
                    </h2>
                    <button className={styles.closeBtn} onClick={onClose}>×</button>
                </div>

                <div className={styles.steps}>
                    <div className={`${styles.step} ${step >= 1 ? styles.active : ''}`}>1. Definir</div>
                    <div className={`${styles.step} ${step >= 2 ? styles.active : ''}`}>2. Vincular</div>
                    <div className={`${styles.step} ${step >= 3 ? styles.active : ''}`}>3. Evaluar</div>
                </div>

                <div className={styles.content}>
                    {step === 1 && (
                        <>
                            <div className="form-group">
                                <label className="form-label">Título de la Medida *</label>
                                <input
                                    type="text"
                                    className="form-input"
                                    value={title}
                                    onChange={e => setTitle(e.target.value)}
                                    placeholder="Ej: Auditoría externa de algoritmos"
                                />
                            </div>

                            <div className="form-group">
                                <label className="form-label">Descripción</label>
                                <textarea
                                    className="form-input"
                                    value={description}
                                    onChange={e => setDescription(e.target.value)}
                                    placeholder="Describe la medida adicional..."
                                    rows={3}
                                />
                            </div>

                            <div className="form-group">
                                <label className="form-label">URL del Documento (opcional)</label>
                                <input
                                    type="url"
                                    className="form-input"
                                    value={attachmentUrl}
                                    onChange={e => setAttachmentUrl(e.target.value)}
                                    placeholder="https://..."
                                />
                            </div>
                        </>
                    )}

                    {step === 2 && (
                        <>
                            <p className={styles.instruction}>
                                Selecciona los requisitos del RIA a los que aplica esta medida:
                            </p>
                            <div className={styles.requirementsList}>
                                {REQUIREMENTS.map(req => (
                                    <label key={req.id} className={styles.requirementItem}>
                                        <input
                                            type="checkbox"
                                            checked={linkedRequirements.includes(req.id)}
                                            onChange={() => toggleRequirement(req.id)}
                                        />
                                        <span className={styles.reqId}>{req.id}</span>
                                        <span className={styles.reqTitle}>{req.title}</span>
                                    </label>
                                ))}
                            </div>
                        </>
                    )}

                    {step === 3 && (
                        <>
                            <p className={styles.instruction}>
                                Evalúa el nivel de madurez para cada requisito vinculado:
                            </p>
                            {linkedRequirements.map(reqId => {
                                const req = REQUIREMENTS.find(r => r.id === reqId)
                                return (
                                    <div key={reqId} className={styles.evalItem}>
                                        <div className={styles.evalHeader}>
                                            <strong>{reqId}</strong>: {req?.title}
                                        </div>
                                        <div className={styles.maturityGrid}>
                                            {MATURITY_LEVELS.map(level => (
                                                <button
                                                    key={level.code}
                                                    type="button"
                                                    className={`${styles.maturityBtn} ${evaluations[reqId]?.maturity === level.code ? styles.selected : ''
                                                        }`}
                                                    onClick={() => setMaturity(reqId, level.code)}
                                                >
                                                    {level.code}
                                                </button>
                                            ))}
                                        </div>
                                        {evaluations[reqId]?.maturity && (
                                            <div className={styles.planFeedback}>
                                                Plan: {evaluations[reqId].adaptationPlan}
                                            </div>
                                        )}
                                    </div>
                                )
                            })}
                        </>
                    )}
                </div>

                <div className={styles.footer}>
                    {step > 1 && (
                        <button className="btn btn-outline" onClick={() => setStep(step - 1)}>
                            ← Anterior
                        </button>
                    )}
                    <div style={{ flex: 1 }} />
                    {step < 3 ? (
                        <button
                            className="btn btn-primary"
                            onClick={() => setStep(step + 1)}
                            disabled={step === 1 ? !canProceedStep1 : !canProceedStep2}
                        >
                            Siguiente →
                        </button>
                    ) : (
                        <button
                            className="btn btn-success"
                            onClick={handleSave}
                            disabled={!canProceedStep3}
                        >
                            💾 Guardar Medida
                        </button>
                    )}
                </div>
            </div>
        </div>
    )
}

export type { AdditionalMeasure }
