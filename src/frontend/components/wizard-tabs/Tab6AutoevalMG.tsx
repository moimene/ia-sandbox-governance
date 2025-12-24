import { useState } from 'react'
import { MeasureGuide, Subpart, AssessmentMGData } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    measures: MeasureGuide[]
    subparts: Subpart[]
    assessments: AssessmentMGData[]
    onAssessmentChange: (mg_id: string, subpart_id: string, field: 'difficulty' | 'maturity', value: string) => void
    onAddRelation: (mg_id: string, subpart_id: string) => void
}

const DIFFICULTY_OPTIONS = [
    { value: '00', label: '00 - Alto' },
    { value: '01', label: '01 - Medio' },
    { value: '02', label: '02 - Bajo' },
]

const MATURITY_OPTIONS = [
    { value: 'L1', label: 'L1' },
    { value: 'L2', label: 'L2' },
    { value: 'L3', label: 'L3' },
    { value: 'L4', label: 'L4' },
    { value: 'L5', label: 'L5' },
    { value: 'L6', label: 'L6' },
    { value: 'L7', label: 'L7' },
    { value: 'L8', label: 'L8' },
]

const getPlan = (maturity: string | null): string => {
    if (!maturity) return '-'
    const plans: Record<string, string> = {
        L1: '01', L2: '01',
        L3: '02', L4: '02',
        L5: '03',
        L6: '04', L7: '04',
        L8: '05'
    }
    return plans[maturity] || '-'
}

const getDiagnosticState = (maturity: string | null): string => {
    return maturity ? '01 Diagnosticada' : '00 Pendiente'
}

export function Tab6AutoevalMG({ measures, subparts, assessments, onAssessmentChange, onAddRelation }: Props) {
    const [showAddForm, setShowAddForm] = useState(false)
    const [newMgId, setNewMgId] = useState('')
    const [newSubpartId, setNewSubpartId] = useState('')

    const getMeasureTitle = (mg_id: string) => {
        const measure = measures.find(m => m.code === mg_id)
        return measure?.title || mg_id
    }

    const getSubpartTitle = (subpart_id: string) => {
        const subpart = subparts.find(s => s.subpart_id === subpart_id)
        return subpart?.title_short || subpart_id
    }

    const handleAddRelation = () => {
        if (newMgId && newSubpartId) {
            onAddRelation(newMgId, newSubpartId)
            setNewMgId('')
            setNewSubpartId('')
            setShowAddForm(false)
        }
    }

    // Stats
    const completed = assessments.filter(a => a.maturity !== null).length
    const total = assessments.length

    return (
        <div className={styles.tabContainer}>
            <div className={styles.tabHeader}>
                <div>
                    <h2>Autoevaluación de Medidas Guía</h2>
                    <p className={styles.subtitle}>
                        Evalúe el nivel de madurez y dificultad para cada relación MG ↔ Apartado
                    </p>
                </div>
                <div className={styles.progressBadge}>
                    {completed} / {total} evaluadas
                </div>
            </div>

            <table className={styles.evalTable}>
                <thead>
                    <tr>
                        <th>MG</th>
                        <th>Apartado</th>
                        <th style={{ width: '140px' }}>Dificultad</th>
                        <th style={{ width: '100px' }}>Madurez</th>
                        <th style={{ width: '120px' }}>Estado</th>
                        <th style={{ width: '80px' }}>Plan</th>
                    </tr>
                </thead>
                <tbody>
                    {assessments.map((assessment, idx) => (
                        <tr key={idx} className={assessment.source === 'USER_ADDED' ? styles.userAdded : ''}>
                            <td>
                                <span className={styles.measureCode}>{assessment.mg_id}</span>
                                <small className={styles.measureTitle}>{getMeasureTitle(assessment.mg_id)}</small>
                            </td>
                            <td>
                                <span className={styles.subpartId}>{assessment.subpart_id}</span>
                            </td>
                            <td>
                                <select
                                    className="form-input"
                                    value={assessment.difficulty || ''}
                                    onChange={e => onAssessmentChange(assessment.mg_id, assessment.subpart_id, 'difficulty', e.target.value)}
                                >
                                    <option value="">Seleccionar...</option>
                                    {DIFFICULTY_OPTIONS.map(opt => (
                                        <option key={opt.value} value={opt.value}>{opt.label}</option>
                                    ))}
                                </select>
                            </td>
                            <td>
                                <div className={styles.maturityBtns}>
                                    {MATURITY_OPTIONS.map(opt => (
                                        <button
                                            key={opt.value}
                                            type="button"
                                            className={`${styles.maturityBtn} ${assessment.maturity === opt.value ? styles.selected : ''}`}
                                            onClick={() => onAssessmentChange(assessment.mg_id, assessment.subpart_id, 'maturity', opt.value)}
                                        >
                                            {opt.value}
                                        </button>
                                    ))}
                                </div>
                            </td>
                            <td>
                                <span className={assessment.maturity ? styles.statusComplete : styles.statusPending}>
                                    {getDiagnosticState(assessment.maturity)}
                                </span>
                            </td>
                            <td>
                                <span className={styles.planBadge}>
                                    {getPlan(assessment.maturity)}
                                </span>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>

            {/* Add extra relation */}
            <div className={styles.addRelationSection}>
                {!showAddForm ? (
                    <button
                        className="btn btn-outline"
                        onClick={() => setShowAddForm(true)}
                    >
                        + Añadir relación adicional
                    </button>
                ) : (
                    <div className={styles.addRelationForm}>
                        <select
                            className="form-input"
                            value={newMgId}
                            onChange={e => setNewMgId(e.target.value)}
                        >
                            <option value="">Seleccionar MG...</option>
                            {measures.map(m => (
                                <option key={m.id} value={m.code}>{m.code} - {m.title}</option>
                            ))}
                        </select>
                        <select
                            className="form-input"
                            value={newSubpartId}
                            onChange={e => setNewSubpartId(e.target.value)}
                        >
                            <option value="">Seleccionar Apartado...</option>
                            {subparts.map(s => (
                                <option key={s.id} value={s.subpart_id}>{s.subpart_id} - {s.title_short}</option>
                            ))}
                        </select>
                        <button
                            className="btn btn-primary"
                            onClick={handleAddRelation}
                            disabled={!newMgId || !newSubpartId}
                        >
                            Añadir
                        </button>
                        <button
                            className="btn btn-outline"
                            onClick={() => setShowAddForm(false)}
                        >
                            Cancelar
                        </button>
                    </div>
                )}
            </div>
        </div>
    )
}
