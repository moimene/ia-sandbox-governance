import { Requirement, MeasureGuide } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    requirement: Requirement
    measures: MeasureGuide[]
}

export function Tab4MedidasGuia({ requirement, measures }: Props) {
    return (
        <div className={styles.tabContainer}>
            <h2>Medidas Guía (MG)</h2>
            <p className={styles.subtitle}>
                Catálogo de medidas guía de AESIA para el requisito <strong>{requirement.title}</strong>
            </p>

            <div className={styles.measuresList}>
                {measures.map(measure => (
                    <div key={measure.id} className={styles.measureCard}>
                        <div className={styles.measureHeader}>
                            <span className={styles.measureCode}>{measure.code}</span>
                        </div>
                        <h4>{measure.title}</h4>
                        {measure.description && (
                            <p className={styles.measureDescription}>{measure.description}</p>
                        )}

                        {measure.guidance_questions && measure.guidance_questions.length > 0 && (
                            <div className={styles.guidanceQuestions}>
                                <strong>Cuestiones orientativas:</strong>
                                <ul>
                                    {measure.guidance_questions.map((q, idx) => (
                                        <li key={idx}>{q}</li>
                                    ))}
                                </ul>
                            </div>
                        )}
                    </div>
                ))}
            </div>

            {measures.length === 0 && (
                <div className={styles.emptyState}>
                    <p>No hay medidas guía cargadas para este requisito.</p>
                </div>
            )}

            <div className={styles.infoBox}>
                <strong>💡 Consejo:</strong> Las cuestiones orientativas le ayudarán a entender
                qué aspectos debe considerar al evaluar cada medida. En la pestaña 6 asignará
                un nivel de madurez a cada medida.
            </div>
        </div>
    )
}
