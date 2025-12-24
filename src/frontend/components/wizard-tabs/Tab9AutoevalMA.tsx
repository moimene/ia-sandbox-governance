import { AdditionalMeasure, Subpart, AssessmentMAData } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    additionalMeasures: AdditionalMeasure[]
    subparts: Subpart[]
    assessments: AssessmentMAData[]
    onAssessmentChange: (ma_id: string, subpart_id: string, field: 'difficulty' | 'maturity', value: string) => void
}

const DIFFICULTY_OPTIONS = [
    { value: '00', label: '00 - Alto' },
    { value: '01', label: '01 - Medio' },
    { value: '02', label: '02 - Bajo' },
]

const MATURITY_OPTIONS = ['L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8']

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

export function Tab9AutoevalMA({ additionalMeasures, subparts, assessments, onAssessmentChange }: Props) {
    const getMaTitle = (ma_id: string) => {
        const ma = additionalMeasures.find(m => m.id === ma_id)
        return ma?.title || ma_id
    }

    const getSubpartTitle = (subpart_id: string) => {
        const subpart = subparts.find(s => s.subpart_id === subpart_id)
        return subpart?.title_short || subpart_id
    }

    if (assessments.length === 0) {
        return (
            <div className={styles.tabContainer}>
                <div className={styles.emptyState}>
                    <h3>No hay relaciones MA para evaluar</h3>
                    <p>
                        Vuelva a la pestaña 8 para establecer relaciones entre sus
                        Medidas Adicionales y los apartados del artículo.
                    </p>
                </div>
            </div>
        )
    }

    const completed = assessments.filter(a => a.maturity !== null).length
    const total = assessments.length

    return (
        <div className={styles.tabContainer}>
            <div className={styles.tabHeader}>
                <div>
                    <h2>Autoevaluación de Medidas Adicionales</h2>
                    <p className={styles.subtitle}>
                        Evalúe el nivel de madurez y dificultad para cada relación MA ↔ Apartado
                    </p>
                </div>
                <div className={styles.progressBadge}>
                    {completed} / {total} evaluadas
                </div>
            </div>

            <table className={styles.evalTable}>
                <thead>
                    <tr>
                        <th>MA</th>
                        <th>Apartado</th>
                        <th style={{ width: '140px' }}>Dificultad</th>
                        <th style={{ width: '100px' }}>Madurez</th>
                        <th style={{ width: '120px' }}>Estado</th>
                        <th style={{ width: '80px' }}>Plan</th>
                    </tr>
                </thead>
                <tbody>
                    {assessments.map((assessment, idx) => (
                        <tr key={idx}>
                            <td>
                                <span className={styles.maId}>{assessment.ma_id}</span>
                                <small className={styles.measureTitle}>{getMaTitle(assessment.ma_id)}</small>
                            </td>
                            <td>
                                <span className={styles.subpartId}>{assessment.subpart_id}</span>
                            </td>
                            <td>
                                <select
                                    className="form-input"
                                    value={assessment.difficulty || ''}
                                    onChange={e => onAssessmentChange(assessment.ma_id, assessment.subpart_id, 'difficulty', e.target.value)}
                                >
                                    <option value="">Seleccionar...</option>
                                    {DIFFICULTY_OPTIONS.map(opt => (
                                        <option key={opt.value} value={opt.value}>{opt.label}</option>
                                    ))}
                                </select>
                            </td>
                            <td>
                                <div className={styles.maturityBtns}>
                                    {MATURITY_OPTIONS.map(level => (
                                        <button
                                            key={level}
                                            type="button"
                                            className={`${styles.maturityBtn} ${assessment.maturity === level ? styles.selected : ''}`}
                                            onClick={() => onAssessmentChange(assessment.ma_id, assessment.subpart_id, 'maturity', level)}
                                        >
                                            {level}
                                        </button>
                                    ))}
                                </div>
                            </td>
                            <td>
                                <span className={assessment.maturity ? styles.statusComplete : styles.statusPending}>
                                    {assessment.maturity ? '01 Diagnosticada' : '00 Pendiente'}
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

            <div className={styles.infoBox}>
                <strong>✅ Último paso:</strong> Una vez completadas todas las evaluaciones,
                haga clic en "Completar" para guardar y volver al resumen del requisito.
            </div>
        </div>
    )
}
