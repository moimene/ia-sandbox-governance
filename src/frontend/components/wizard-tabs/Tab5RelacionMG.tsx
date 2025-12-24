import { MeasureGuide, Subpart, MGToSubpart } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    measures: MeasureGuide[]
    subparts: Subpart[]
    mgToSubpart: MGToSubpart[]
}

export function Tab5RelacionMG({ measures, subparts, mgToSubpart }: Props) {
    // Check if a relation exists
    const hasRelation = (mg_id: string, subpart_id: string) => {
        return mgToSubpart.some(r => r.mg_id === mg_id && r.subpart_id === subpart_id)
    }

    const isPrimary = (mg_id: string, subpart_id: string) => {
        const rel = mgToSubpart.find(r => r.mg_id === mg_id && r.subpart_id === subpart_id)
        return rel?.is_primary ?? false
    }

    return (
        <div className={styles.tabContainer}>
            <h2>Relación MG ↔ Apartados</h2>
            <p className={styles.subtitle}>
                Matriz que muestra qué Medidas Guía aplican a cada apartado del artículo
            </p>

            <div className={styles.matrixContainer}>
                <table className={styles.relationMatrix}>
                    <thead>
                        <tr>
                            <th className={styles.cornerCell}>MG \ Apartado</th>
                            {subparts.map(subpart => (
                                <th key={subpart.id} className={styles.rotatedHeader}>
                                    <span>{subpart.subpart_id}</span>
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {measures.map(measure => (
                            <tr key={measure.id}>
                                <td className={styles.measureCell}>
                                    <span className={styles.measureCode}>{measure.code}</span>
                                </td>
                                {subparts.map(subpart => (
                                    <td
                                        key={subpart.id}
                                        className={`${styles.relationCell} ${hasRelation(measure.code, subpart.subpart_id) ? styles.hasRelation : ''}`}
                                    >
                                        {hasRelation(measure.code, subpart.subpart_id) && (
                                            <span className={isPrimary(measure.code, subpart.subpart_id) ? styles.primaryMark : styles.secondaryMark}>
                                                ✓
                                            </span>
                                        )}
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            <div className={styles.legend}>
                <span><span className={styles.primaryMark}>✓</span> Relación primaria</span>
                <span><span className={styles.secondaryMark}>✓</span> Relación secundaria</span>
            </div>

            <div className={styles.infoBox}>
                <strong>ℹ️ Información:</strong> Esta matriz muestra las relaciones predefinidas
                entre las Medidas Guía y los apartados del artículo. En la pestaña 6 evaluará
                cada una de estas relaciones. También podrá añadir relaciones adicionales si
                considera que aplican a su caso.
            </div>
        </div>
    )
}
