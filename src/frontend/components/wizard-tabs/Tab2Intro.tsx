import { Requirement } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    requirement: Requirement
}

export function Tab2Intro({ requirement }: Props) {
    return (
        <div className={styles.tabContainer}>
            <h2>Introducción al Autodiagnóstico</h2>
            <p className={styles.subtitle}>
                Guía para completar la evaluación del requisito: <strong>{requirement.title}</strong>
            </p>

            <div className={styles.introSection}>
                <h3>🎯 Objetivo</h3>
                <p>
                    Este checklist le permite evaluar el nivel de madurez de su sistema de IA
                    respecto al requisito <strong>{requirement.article_ref}</strong> del Reglamento de IA (RIA).
                </p>
            </div>

            <div className={styles.introSection}>
                <h3>📊 Escala de Madurez (L1-L8)</h3>
                <table className={styles.maturityTable}>
                    <thead>
                        <tr>
                            <th>Nivel</th>
                            <th>Descripción</th>
                            <th>Plan de Adaptación</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><span className={styles.levelBadge}>L1</span></td>
                            <td>No documentada ni implementada</td>
                            <td>01 - Documentar e Implementar</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L2</span></td>
                            <td>Documentación en curso, no implementada</td>
                            <td>01 - Documentar e Implementar</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L3</span></td>
                            <td>Documentada, no implementada</td>
                            <td>02 - Implementar</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L4</span></td>
                            <td>Documentada, implementación en curso</td>
                            <td>02 - Implementar</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L5</span></td>
                            <td>Documentada e implementada</td>
                            <td>03 - Adaptación completa</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L6</span></td>
                            <td>No documentada e implementada</td>
                            <td>04 - Documentar</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L7</span></td>
                            <td>Documentación en curso e implementada</td>
                            <td>04 - Documentar</td>
                        </tr>
                        <tr>
                            <td><span className={styles.levelBadge}>L8</span></td>
                            <td>Medida no necesaria para el sistema</td>
                            <td>05 - Ninguna adaptación</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div className={styles.introSection}>
                <h3>⚡ Dificultad Percibida</h3>
                <p>Además del nivel de madurez, deberá indicar la dificultad percibida para cada medida:</p>
                <ul>
                    <li><strong>00 - Alto:</strong> Implementación compleja, cambios estructurales significativos</li>
                    <li><strong>01 - Medio:</strong> Cambios relevantes pero acotados</li>
                    <li><strong>02 - Bajo:</strong> Cambios menores, mayoritariamente documentales</li>
                </ul>
            </div>

            <div className={styles.infoBox}>
                <strong>💡 Consejo:</strong> Revise las pestañas 3-5 antes de completar la autoevaluación.
                Contienen información sobre los apartados del artículo y las medidas guía que le ayudarán
                a realizar una evaluación más precisa.
            </div>
        </div>
    )
}
