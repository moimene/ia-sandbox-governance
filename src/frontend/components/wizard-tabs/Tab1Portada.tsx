import { Requirement } from '../RequirementWizard'
import styles from './Tabs.module.css'

interface Props {
    requirement: Requirement
    accepted: boolean
    onAccept: () => void
}

export function Tab1Portada({ requirement, accepted, onAccept }: Props) {
    return (
        <div className={styles.tabContainer}>
            <div className={styles.portadaBox}>
                <div className={styles.portadaHeader}>
                    <h2>Checklist de Autoevaluación</h2>
                    <h3>{requirement.title}</h3>
                    <span className={styles.articleBadge}>{requirement.article_ref}</span>
                </div>

                <div className={styles.confidencialidad}>
                    <h4>⚠️ Aviso de Confidencialidad</h4>
                    <p>
                        Este documento contiene información confidencial destinada exclusivamente
                        a la entidad evaluada y a los evaluadores autorizados del Sandbox de IA.
                    </p>
                    <p>
                        Queda prohibida su reproducción, distribución o divulgación total o parcial
                        sin autorización expresa.
                    </p>
                </div>

                <div className={styles.instrucciones}>
                    <h4>📋 Instrucciones de Uso</h4>
                    <ul>
                        <li>Esta herramienta es un checklist de autodiagnóstico basado en la <strong>Guía 16 de AESIA</strong>.</li>
                        <li>Complete las pestañas en orden, de la 1 a la 9.</li>
                        <li>Las pestañas 1-5 son <strong>informativas</strong> (solo lectura).</li>
                        <li>Las pestañas 6-9 son <strong>operativas</strong> (requieren su input).</li>
                        <li>Al finalizar, podrá exportar el resultado en formato Excel compatible con AESIA.</li>
                    </ul>
                </div>

                <div className={styles.versioning}>
                    <p>
                        <strong>Versión del checklist:</strong> {requirement.version}<br />
                        <strong>Requisito:</strong> {requirement.code}
                    </p>
                </div>

                {!accepted ? (
                    <button
                        className="btn btn-primary"
                        onClick={onAccept}
                    >
                        ✓ He leído y acepto continuar
                    </button>
                ) : (
                    <div className={styles.acceptedMessage}>
                        ✓ Aceptado - Puede continuar a la siguiente pestaña
                    </div>
                )}
            </div>
        </div>
    )
}
