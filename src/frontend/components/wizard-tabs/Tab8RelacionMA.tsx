import { AdditionalMeasure, Subpart, MAToSubpart } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    additionalMeasures: AdditionalMeasure[]
    subparts: Subpart[]
    relations: MAToSubpart[]
    onToggle: (ma_id: string, subpart_id: string) => void
}

export function Tab8RelacionMA({ additionalMeasures, subparts, relations, onToggle }: Props) {
    const hasRelation = (ma_id: string, subpart_id: string) => {
        return relations.some(r => r.ma_id === ma_id && r.subpart_id === subpart_id)
    }

    if (additionalMeasures.length === 0) {
        return (
            <div className={styles.tabContainer}>
                <div className={styles.emptyState}>
                    <h3>No hay Medidas Adicionales</h3>
                    <p>
                        Vuelva a la pestaña anterior para crear Medidas Adicionales
                        antes de establecer relaciones con los apartados.
                    </p>
                </div>
            </div>
        )
    }

    return (
        <div className={styles.tabContainer}>
            <h2>Relación MA ↔ Apartados</h2>
            <p className={styles.subtitle}>
                Marque con X las relaciones entre sus Medidas Adicionales y los apartados del artículo
            </p>

            <div className={styles.matrixContainer}>
                <table className={styles.relationMatrix}>
                    <thead>
                        <tr>
                            <th className={styles.cornerCell}>MA \ Apartado</th>
                            {subparts.map(subpart => (
                                <th key={subpart.id} className={styles.rotatedHeader}>
                                    <span>{subpart.subpart_id}</span>
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {additionalMeasures.map(ma => (
                            <tr key={ma.id}>
                                <td className={styles.measureCell}>
                                    <span className={styles.maId}>{ma.id}</span>
                                    <small>{ma.title}</small>
                                </td>
                                {subparts.map(subpart => (
                                    <td
                                        key={subpart.id}
                                        className={`${styles.relationCell} ${styles.clickable} ${hasRelation(ma.id, subpart.subpart_id) ? styles.hasRelation : ''}`}
                                        onClick={() => onToggle(ma.id, subpart.subpart_id)}
                                    >
                                        {hasRelation(ma.id, subpart.subpart_id) && (
                                            <span className={styles.xMark}>X</span>
                                        )}
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            <div className={styles.relationStats}>
                <strong>Relaciones establecidas:</strong> {relations.length}
            </div>

            <div className={styles.infoBox}>
                <strong>💡 Consejo:</strong> Haga clic en una celda para marcar/desmarcar la relación.
                Las relaciones marcadas generarán filas de evaluación en la pestaña 9.
            </div>
        </div>
    )
}
