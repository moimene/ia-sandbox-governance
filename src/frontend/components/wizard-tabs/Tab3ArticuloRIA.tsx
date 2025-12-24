import { Requirement, Subpart } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    requirement: Requirement
    subparts: Subpart[]
}

export function Tab3ArticuloRIA({ requirement, subparts }: Props) {
    return (
        <div className={styles.tabContainer}>
            <h2>Artículo del Reglamento de IA</h2>
            <p className={styles.subtitle}>
                Apartados y subapartados del <strong>{requirement.article_ref}</strong> aplicables a este requisito
            </p>

            <div className={styles.articleInfo}>
                <span className={styles.articleBadge}>{requirement.article_ref}</span>
                <h3>{requirement.title}</h3>
            </div>

            <table className={styles.subpartsTable}>
                <thead>
                    <tr>
                        <th style={{ width: '120px' }}>Apartado</th>
                        <th>Descripción</th>
                    </tr>
                </thead>
                <tbody>
                    {subparts.map(subpart => (
                        <tr key={subpart.id}>
                            <td>
                                <span className={styles.subpartId}>{subpart.subpart_id}</span>
                            </td>
                            <td>
                                <strong>{subpart.title_short}</strong>
                                {subpart.description_short && (
                                    <p className={styles.subpartDescription}>{subpart.description_short}</p>
                                )}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>

            {subparts.length === 0 && (
                <div className={styles.emptyState}>
                    <p>No hay apartados cargados para este requisito.</p>
                </div>
            )}

            <div className={styles.infoBox}>
                <strong>ℹ️ Información:</strong> Estos apartados son las obligaciones específicas del RIA
                que su sistema debe cumplir. En la pestaña 5 verá cómo las Medidas Guía se relacionan
                con cada apartado.
            </div>
        </div>
    )
}
